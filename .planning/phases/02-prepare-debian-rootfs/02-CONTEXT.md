# CONTEXT: Phase 2 - Prepare Debian Rootfs

## User Vision

Create a minimal Debian 10 i386 rootfs that can be imported into iSH, providing apt package management for the Blink-iSH integration.

---

## Decisions

### Locked (User Decided)

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

---

## Deferred Ideas

- Extended package set (vim, curl, git, etc.) — users can install via apt
- Developer package set (build-essential, python3) — too large for initial bundle
- Pre-built rootfs download — less control over contents

---

## Claude's Discretion

- CI/CD platform choice (GitHub Actions recommended for visibility)
- Exact package list beyond minimal set
- Rootfs compression method (gzip vs xz)
- Naming convention for rootfs files
- Documentation format for build process

---

## Key Considerations

### Constraints
- **Size target:** < 100MB for rootfs
- **Debian 10 EOL:** Must use archive.debian.org for apt sources
- **iSH compatibility:** Must work with iSH's syscall emulation
- **No ARM64:** x86 emulation only

### Build Requirements
- debootstrap for creating rootfs
- fakefsify tool for converting to iSH format
- SQLite (for fakefs backend)
- Linux environment (CI/CD)

### Success Metrics
- apt update succeeds
- apt install <package> works
- Rootfs imports into iSH without errors
- Size under 100MB
