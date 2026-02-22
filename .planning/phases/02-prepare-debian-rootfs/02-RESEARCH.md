# Phase 2: Prepare Debian Rootfs - Research

**Researched:** 2026-02-22
**Domain:** Linux rootfs creation, debootstrap, iSH filesystem format
**Confidence:** HIGH

## Summary

This phase requires creating a minimal Debian 10 (buster) i386 rootfs that can be imported into iSH. The key technical components are:

1. **debootstrap** - Standard Debian tool for creating minimal rootfs from repositories
2. **fakefsify** - iSH's tool that converts tar.gz rootfs to SQLite-based fakefs format
3. **archive.debian.org** - Required for Debian 10 (EOL since 2022-09-10) apt sources
4. **GitHub Actions** - CI/CD platform for reproducible builds

The fakefs format uses SQLite for metadata (permissions, symlinks, device nodes) with actual file content stored in a `data/` directory. This enables iSH to work around iOS filesystem limitations.

**Primary recommendation:** Use Docker-based build in GitHub Actions with multi-stage build: debootstrap → tar → fakefsify → bundle artifacts.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Rootfs source | **Build with debootstrap** | Full control over packages; reproducible |
| Package set | **Minimal** | apt, dpkg, bash, coreutils, grep, sed, awk — keeps size small |
| Verification | **Import into iSH app** | Confirms format is correct on actual iOS |
| Build host | **CI/CD pipeline** | Reproducible builds; no local Linux needed |
| iSH format | **Convert to fakefs** | Faster first launch; SQLite-based format |

### Prior Decisions (Already Locked)
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Distribution | **Debian 10 (buster) i386** | Only x86-32 Debian available; proven by debiSH |
| Delivery | **Bundle in app** | Works offline; no runtime download |

### Claude's Discretion
- CI/CD platform choice (GitHub Actions recommended for visibility)
- Exact package list beyond minimal set
- Rootfs compression method (gzip vs xz)
- Naming convention for rootfs files
- Documentation format for build process

### Deferred Ideas (OUT OF SCOPE)
- Extended package set (vim, curl, git, etc.) — users can install via apt
- Developer package set (build-essential, python3) — too large for initial bundle
- Pre-built rootfs download — less control over contents
</user_constraints>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| debootstrap | 1.0.123+ | Create minimal Debian rootfs | Official Debian bootstrap tool; single shell script |
| fakefsify | (from iSH) | Convert tar.gz to iSH fakefs format | Only tool that produces iSH-compatible format |
| libarchive | 3.6+ | tar.gz handling for fakefsify | Required by fakefsify for archive operations |
| SQLite | 3.40+ | fakefs metadata storage | Backend for iSH filesystem metadata |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| Docker | Build environment isolation | CI/CD builds |
| GitHub Actions | CI/CD automation | Automated reproducible builds |
| gzip/xz | Compression | Final tarball compression |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| debootstrap | multistrap | More complex config; less standard |
| fakefsify | raw tar.gz | Slower first launch; no pre-conversion |
| GitHub Actions | GitLab CI, CircleCI | Less GitHub integration; same complexity |

**Build dependencies:**
```bash
apt-get install debootstrap libarchive-dev sqlite3
```

## Architecture Patterns

### Recommended Build Pipeline Structure
```
.github/
└── workflows/
    └── build-rootfs.yml     # GitHub Actions workflow

rootfs/
├── build/
│   └── Dockerfile           # Multi-stage build
├── scripts/
│   ├── debootstrap.sh       # Create base rootfs
│   ├── configure.sh         # Set up apt sources, packages
│   └── convert.sh           # fakefsify conversion
└── output/
    └── debian10-ish/        # Fakefs format output
```

### Pattern 1: Multi-Stage Docker Build
**What:** Use Docker multi-stage builds for clean separation of concerns
**When to use:** Always - provides reproducibility and isolation
**Example:**
```dockerfile
# Stage 1: Create rootfs with debootstrap
FROM debian:bookworm AS builder
RUN apt-get update && apt-get install -y debootstrap
RUN debootstrap --arch=i386 --variant=minbase buster /rootfs http://archive.debian.org/debian

# Stage 2: Configure and convert
FROM debian:bookwig AS converter
COPY --from=builder /rootfs /rootfs
# Configure apt sources for archive.debian.org
# Run fakefsify
```

### Pattern 2: Two-Stage debootstrap (Not Needed)
**What:** `debootstrap --foreign` then `--second-stage` with QEMU
**When to use:** Cross-architecture builds (e.g., building ARM on x86)
**Note:** NOT needed for i386 on x86_64 host - direct debootstrap works

### Anti-Patterns to Avoid
- **Using deb.debian.org for Buster:** Repository moved to archive.debian.org; will 404
- **Skipping fakefsify:** Raw tar.gz works but slower first launch
- **Including man-db:** Causes long delays on iSH during package operations
- **Large package sets:** Exceeds 100MB target; users can apt install

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rootfs creation | Custom tarball scripts | debootstrap | Handles dependencies, symlinks, devices correctly |
| iSH format | Manual SQLite + data/ | fakefsify | Complex metadata handling; proven tool |
| Archive sources | Custom mirror logic | archive.debian.org | Official; guaranteed availability |
| CI/CD | Custom scripts | GitHub Actions + Docker | Standard; reproducible; artifact storage |

**Key insight:** debootstrap and fakefsify are battle-tested tools with years of edge case handling. Custom solutions will miss symlinks, device nodes, or special permissions.

## Common Pitfalls

### Pitfall 1: Archive Repository URLs
**What goes wrong:** Using `deb.debian.org` for Buster returns 404 errors
**Why it happens:** Debian 10 reached EOL on 2022-09-10; repos moved to archive
**How to avoid:** Always use `archive.debian.org` for Debian 10 sources
**Warning signs:** `apt update` fails with "Release file not found"

**Correct sources.list:**
```
deb http://archive.debian.org/debian buster main
deb http://archive.debian.org/debian-security buster/updates main
```

### Pitfall 2: man-db Trigger Delays
**What goes wrong:** Package installation hangs for minutes on iSH
**Why it happens:** man-db reindexes all man pages; slow on iSH emulation
**How to avoid:** Exclude man-db from base packages; let users opt-in
**Warning signs:** Package operations seem stuck after file copy

### Pitfall 3: 32-bit vs 64-bit Confusion
**What goes wrong:** Building amd64 rootfs instead of i386
**Why it happens:** Forgetting `--arch=i386` flag
**How to avoid:** Always specify `--arch=i386` in debootstrap
**Warning signs:** Rootfs contains /lib64 instead of /lib

### Pitfall 4: Incomplete fakefsify Build
**What goes wrong:** fakefsify binary missing from build output
**Why it happens:** libarchive not installed; meson didn't build tools
**How to avoid:** Ensure libarchive-dev installed; check build/tools/
**Warning signs:** Build succeeds but no fakefsify executable

## Code Examples

### Debootstrap Command (i386 on x86_64 host)
```bash
# Direct debootstrap - no QEMU needed for i386 on x86_64
debootstrap \
  --arch=i386 \
  --variant=minbase \
  --include=apt,dpkg,bash,coreutils,grep,sed,awk \
  buster \
  /rootfs \
  http://archive.debian.org/debian
```
Source: Debian Wiki - Debootstrap

### Configure Archive Sources
```bash
# Create sources.list for EOL Debian 10
cat > /rootfs/etc/apt/sources.list << 'EOF'
deb http://archive.debian.org/debian buster main
deb http://archive.debian.org/debian-security buster/updates main
EOF
```
Source: archive.debian.org

### fakefsify Conversion
```bash
# Create tarball from rootfs directory
tar -czf debian10-rootfs.tar.gz -C /rootfs .

# Convert to iSH fakefs format
fakefsify debian10-rootfs.tar.gz debian10-ish

# Output structure:
# debian10-ish/
# ├── data/        # Actual file content
# └── meta.db      # SQLite metadata
```
Source: /Users/b/ish-ios/tools/fakefsify.c

### GitHub Actions Workflow
```yaml
name: Build Debian Rootfs

on:
  push:
    paths: ['rootfs/**']
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build rootfs
        run: |
          docker build -t rootfs-builder rootfs/
          
      - name: Extract artifacts
        run: |
          docker create --name temp rootfs-builder
          docker cp temp:/output ./debian10-ish
          docker rm temp
          
      - uses: actions/upload-artifact@v4
        with:
          name: debian10-ish-rootfs
          path: debian10-ish/
```
Source: GitHub Actions docs - Publishing Docker images

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual tarball creation | debootstrap automation | Standard for years | Reproducible builds |
| Raw tar.gz in iSH | Pre-converted fakefs | iSH 1.2+ | Faster first launch |
| deb.debian.org for EOL | archive.debian.org | 2022 (Buster EOL) | Continued repo access |
| Local builds | CI/CD (GitHub Actions) | Industry standard | Reproducibility, visibility |

**Deprecated/outdated:**
- debiSH standalone project: Now integrated into AOK-Filesystem-Tools
- Pre-built rootfs downloads: Less control; security concerns

## Open Questions

1. **Should we build fakefsify from iSH source or use pre-built?**
   - What we know: fakefsify is in ish-ios/tools/, requires libarchive
   - What's unclear: Is there a standalone build or does it need full iSH build?
   - Recommendation: Build from iSH source in Docker for consistency

2. **What's the expected final compressed size?**
   - What we know: debiSH mentions 57MB (small) to 270MB (full)
   - What's unclear: Exact size with our minimal package set
   - Recommendation: Target 50-70MB compressed; verify during implementation

3. **Can we reuse AOK-Filesystem-Tools directly?**
   - What we know: Proven Debian 10 build system for iSH-AOK
   - What's unclear: License compatibility; integration complexity
   - Recommendation: Reference their approach but maintain independent build

## Sources

### Primary (HIGH confidence)
- `/Users/b/ish-ios/tools/fakefsify.c` - fakefsify implementation
- `/Users/b/ish-ios/tools/fakefs.c` - fakefs import/export logic
- `/Users/b/ish-ios/fs/fake.c` - fakefs runtime implementation
- `/Users/b/ish-ios/fs/fake-db.c` - SQLite backend
- https://manpages.debian.org/buster/debootstrap/debootstrap.8.en.html - Official docs

### Secondary (MEDIUM confidence)
- https://wiki.debian.org/Debootstrap - Debian Wiki usage guide
- https://archive.debian.org/debian/ - Official Debian archive
- https://github.com/ish-app/roots - iSH rootfs build examples
- https://github.com/emkey1/AOK-Filesystem-Tools - Proven Debian 10 on iSH
- https://docs.github.com/en/actions/use-cases-and-examples/publishing-packages/publishing-docker-images - GitHub Actions docs

### Tertiary (LOW confidence)
- https://github.com/jaclu/debiSH - Marked obsolete; references AOK-Filesystem-Tools
- Web search results for debootstrap tutorials - Verified against official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools are well-documented, in active use
- Architecture: HIGH - Pattern based on iSH's own roots repository and AOK-Filesystem-Tools
- Pitfalls: HIGH - Based on official Debian documentation and iSH code analysis

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (stable tools; EOL repos won't change)
