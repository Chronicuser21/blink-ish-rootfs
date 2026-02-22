# ROADMAP: Blink-iSH Integration

## Milestone v1.0: Local Linux Shell

**Goal:** Deliver a working Blink Shell IPA with integrated iSH providing apt package management.

---

## Phase 1: Build libiSH Framework

**Goal:** Compile iSH as a reusable iOS framework that Blink can link against.

### Dependencies
- None (foundation phase)

**Plans:** 4 plans in 3 waves

Plans:
- [x] 01-01-PLAN.md — Create Xcode framework target with public API headers
- [x] 01-02-PLAN.md — Configure Meson cross-compilation for iOS arm64
- [x] 01-03-PLAN.md — Link libraries into framework and verify with test app
- [x] 01-04-PLAN.md — Create test iOS app and verify framework builds correctly

### Key Tasks
- Extract iSH core (emulator, syscall translator, filesystem) from app code
- Create Xcode framework target with proper exports
- Build libiSH.a static library or libiSH.framework
- Verify framework compiles for iOS arm64
- Document public API for terminal integration

### Success Criteria
- [x] libiSH.framework builds successfully
- [x] Framework exposes necessary APIs (pty, process management, filesystem)
- [x] Can be linked into a test iOS app
- [x] Build documented in README

---

## Phase 2: Prepare Debian Rootfs

**Goal:** Create a minimal Debian 10 i386 rootfs with apt configured.

### Dependencies
- None (can parallel with Phase 1)

**Plans:** 2 plans in 2 waves

Plans:
- [ ] 02-01-PLAN.md — Create CI/CD build pipeline for Debian rootfs
- [ ] 02-02-PLAN.md — Build and verify rootfs in iSH app

### Key Tasks
- Use debootstrap to create Debian 10 (buster) i386 minimal rootfs
- Configure apt sources for archive.debian.org (EOL release)
- Pre-install essential packages: apt, dpkg, bash, coreutils
- Convert to iSH filesystem format using fakefsify
- Test rootfs imports successfully into standalone iSH
- Bundle rootfs.tar.gz in project

### Success Criteria
- [ ] Debian rootfs tarball created (< 100MB)
- [ ] apt update && apt install work in standalone iSH
- [ ] Rootfs bundled in project resources

---

## Phase 3: Create iSH Session for Blink

**Goal:** Implement iSHSession class that integrates iSH into Blink's terminal.

### Dependencies
- Phase 1 (libiSH framework)
- Phase 2 (Debian rootfs)

### Key Tasks
- Create iSHSession.swift following existing session patterns (SSHSession, MoshSession)
- Initialize iSH emulator with bundled rootfs
- Wire up PTY I/O to Blink's terminal view
- Implement session lifecycle (start, suspend, resume, terminate)
- Add "ish" command to Blink's command registry
- Handle filesystem persistence between app launches

### Success Criteria
- [ ] `ish` command launches local Linux shell
- [ ] Terminal I/O flows correctly
- [ ] Session persists state across app background/foreground
- [ ] Can run: `apt update && apt install vim`

---

## Phase 4: Integration & IPA Build

**Goal:** Produce a signed IPA ready for sideloading.

### Dependencies
- Phase 3 (iSH Session)

### Key Tasks
- Integrate libiSH.framework into Blink.xcodeproj
- Add rootfs to app bundle resources
- Configure build settings for custom provisioning
- Create build script for automated IPA generation
- Test on physical iOS device (simulator won't work - x86 emulation)
- Document sideload instructions (AltStore, Sideloadly, etc.)

### Success Criteria
- [ ] Clean build produces valid IPA
- [ ] IPA sideloads successfully
- [ ] iSH shell works on device
- [ ] apt commands function correctly
- [ ] Documentation complete

---

## Phase 5: Polish & Documentation

**Goal:** Refine UX and provide complete user documentation.

### Dependencies
- Phase 4 (working IPA)

### Key Tasks
- Add first-run setup wizard for rootfs initialization
- Implement filesystem export/import for backup
- Add settings UI for iSH configuration
- Write user guide: installation, usage, troubleshooting
- Create demo video or screenshots
- Set up GitHub Releases for IPA distribution

### Success Criteria
- [ ] First-run experience is smooth
- [ ] Users can backup/restore their Linux environment
- [ ] Complete README with screenshots
- [ ] IPA published for download
