# STATE: Blink-iSH Integration

## Project Reference

**Core Value:** One app, all the shells — Blink + iSH + apt in a single IPA.

**Current Focus:** Phase 1 complete — libiSH.framework built and verified.

---

## Current Position

**Phase:** 1 of 5
**Phase Name:** Build libiSH Framework  
**Plan:** 4 of 4 complete (Phase 1 done)
**Status:** Ready to plan

```
Progress: [████████████████████] 100%
```

---

## Recent Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
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

---

## Session Continuity

**Last session:** 2026-02-22
**Stopped at:** Completed 01-04-PLAN.md (Phase 1 complete)
**Resume file:** None
