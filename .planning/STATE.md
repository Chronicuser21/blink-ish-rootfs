# STATE: Blink-iSH Integration

## Project Reference

**Core Value:** One app, all the shells — Blink + iSH + apt in a single IPA.

**Current Focus:** Phase 2 in progress — CI/CD pipeline created for Debian rootfs builds.

---

## Current Position

**Phase:** 2 of 5
**Phase Name:** Prepare Debian Rootfs
**Plan:** 1 of 2 complete
**Status:** In progress

```
Progress: [████░░░░░░░░░░░░░░░░] 20%
```

---

## Recent Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-22 | Multi-stage Docker build for rootfs | Separates builder (compile) from converter (runtime); smaller final image |
| 2026-02-22 | Build fakefsify from iSH source | Ensures version consistency; works across platforms |
| 2026-02-22 | Inline Dockerfile steps | Self-contained build; scripts provided as reference only |
| 2026-02-22 | Test app files only, no Xcode project | Minimal verification; proper project when integrated into Blink |
| 2026-02-22 | Private header for framework | Avoids iSH header conflicts with iOS SDK (fallthrough macro, clockid_t) |
| 2026-02-22 | Disable CLANG_ENABLE_MODULES | Prevents module build failures from header conflicts |
| 2026-02-22 | Link SQLite dynamically | System libsqlite3.dylib instead of bundling |
| 2026-02-22 | cpu_family = 'aarch64' for iOS | Matches gadgets-aarch64 directory in iSH |
| 2026-02-22 | system = 'darwin' for iOS | iOS shares platform code with macOS |
| 2026-02-22 | LLD linker required | VDSO needs i386 ELF compilation |
| 2026-02-22 | Pure C API for libiSH | Maximum ObjC/Swift compatibility; follows libc patterns |
| 2026-02-22 | Opaque PTY type (iSHPTYRef) | ABI stability; hides internal tty struct |
| 2026-02-22 | Disable module verifier | Header-only framework until static libs linked (plan 03) |
| 2026-02-21 | Use Debian 10 i386 | Only x86-32 Debian available; apt included; proven by debiSH |
| 2026-02-21 | Framework + Session approach | Cleanest integration; follows Blink's patterns |
| 2026-02-21 | Bundle rootfs in app | No runtime download; works offline |

---

## Pending Todos

No pending todos yet.

---

## Blockers / Concerns

- **Debian 10 EOL:** Security patches unavailable — acceptable for personal use
- **Apple restrictions:** App Store forbids package managers — sideload only
- **x86 only:** No ARM64 support even on M-series devices

---

## Performance Metrics

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 01 | 02 | 11min | 3 | 6 |
| 01 | 03 | 22min | 3 | 5 |
| 01 | 04 | 2min | 2 | 2 |
| 02 | 01 | 14min | 3 | 5 |

---

## Session Continuity

**Last session:** 2026-02-22
**Stopped at:** Completed 02-01-PLAN.md (CI/CD build pipeline)
**Resume file:** None
