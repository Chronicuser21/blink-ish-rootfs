---
phase: 01-build-libish-framework
plan: 03
subsystem: framework
tags: [xcode, framework, ios, arm64, static-linking, api-bridge]

requires:
  - phase: 01-build-libish-framework
    plan: 01
    provides: Framework target structure and public API headers
  - phase: 01-build-libish-framework
    plan: 02
    provides: Static libraries for iOS arm64 (libish.a, libish_emu.a, libfakefs.a)
provides:
  - libiSH.framework - Complete framework bundle for iOS arm64
  - libiSH.m - Implementation bridging public API to internal functions
  - libiSH_Private.h - Minimal type declarations avoiding iOS SDK conflicts
  - README-framework.md - Build and usage documentation
affects: [02-integrate-blink, 03-debian-rootfs]

tech-stack:
  added:
    - libsqlite3 (iOS system library)
  patterns:
    - Private header pattern to isolate iSH internal types from iOS SDK
    - Static library embedding in dynamic framework

key-files:
  created:
    - ish-ios/libiSH/libiSH.m
    - ish-ios/libiSH/libiSH_Private.h
    - ish-ios/README-framework.md
    - ish-ios/build/Release-iphoneos/libiSH.framework/libiSH
  modified:
    - ish-ios/libiSH.xcodeproj/project.pbxproj

key-decisions:
  - "Use private header (libiSH_Private.h) to avoid iSH internal header conflicts with iOS SDK"
  - "Disable CLANG_ENABLE_MODULES to prevent module build failures from fallthrough macro conflicts"
  - "Link SQLite dynamically from iOS system library rather than bundling"
  - "Return ENOSYS for unimplemented PTY output reading and signal sending"

patterns-established:
  - "Pattern: Private header provides minimal type declarations for linking without full iSH headers"
  - "Pattern: iSH errno constants (_EPERM, _EINVAL, etc.) for error returns"

requirements-completed: []

duration: 22min
completed: 2026-02-22
---

# Phase 1 Plan 3: Framework Linking and Documentation Summary

**Linked static libraries into complete libiSH.framework for iOS arm64 with public API bridge**

## Performance

- **Duration:** 22 min
- **Started:** 2026-02-22T00:19:18Z
- **Completed:** 2026-02-22T00:41:46Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Created libiSH.m implementing all public API functions (initialization, PTY, process management)
- Linked all three static libraries (libish.a, libish_emu.a, libfakefs.a) with SQLite
- Built complete framework for iOS arm64 (~950KB)
- Documented build process and API usage

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement public API bridge to internal functions** - `4f51b7bf` (feat)
2. **Task 2: Configure Xcode to link static libraries** - `80ecc131` (feat)
3. **Task 3: Create framework documentation** - `c4de774e` (docs)

## Files Created/Modified
- `libiSH/libiSH.m` - Implementation of public C API (235 lines)
- `libiSH/libiSH_Private.h` - Minimal type declarations (108 lines)
- `README-framework.md` - Build and usage documentation
- `libiSH.xcodeproj/project.pbxproj` - Xcode project configuration
- `build/Release-iphoneos/libiSH.framework/libiSH` - Compiled framework (949KB)

## Decisions Made
- **Private header approach:** Created libiSH_Private.h to provide minimal type declarations without pulling in iSH's Linux-centric internal headers that conflict with iOS SDK
- **Disabled modules:** CLANG_ENABLE_MODULES=NO to avoid conflicts between iSH's `fallthrough` macro and Darwin's definition
- **Dynamic SQLite:** Linked system libsqlite3.dylib instead of bundling SQLite
- **Stub implementations:** iSHPTYReadOutput and iSHSendSignal return ENOSYS pending full fd-based implementation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] iSH internal headers conflict with iOS SDK**
- **Found during:** Task 2 (Xcode build)
- **Issue:** iSH's misc.h defines `fallthrough` macro that conflicts with Darwin's os/base.h. kernel/time.h expects `clockid_t`, `CLOCK_MONOTONIC` which are Linux-specific.
- **Fix:** Created libiSH_Private.h with minimal type declarations (tty struct, winsize, termios, errno constants) and removed iSH header search paths from build settings
- **Files modified:** libiSH/libiSH_Private.h (new), libiSH/libiSH.m (updated imports)
- **Verification:** Framework compiles without header conflicts
- **Committed in:** 80ecc131

**2. [Rule 3 - Blocking] Missing SQLite linking**
- **Found during:** Task 2 (linker error)
- **Issue:** libfakefs.a requires sqlite3 symbols but -lsqlite3 wasn't in linker flags
- **Fix:** Added `-lsqlite3` to OTHER_LDFLAGS
- **Files modified:** libiSH.xcodeproj/project.pbxproj
- **Verification:** Linker succeeds, framework built
- **Committed in:** 80ecc131

---

**Total deviations:** 2 auto-fixed (1 bug fix, 1 blocking dependency)
**Impact on plan:** Both fixes necessary for framework to build. The private header approach is a cleaner solution than trying to patch iSH's headers.

## Issues Encountered
- iSH's internal headers are designed for Linux/POSIX and conflict with Darwin/iOS SDK
- Solution was to create a minimal private header that declares only what's needed

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Framework builds and links successfully for iOS arm64
- All public API symbols exported correctly (16 functions)
- Ready for Plan 04: Package as XCFramework (if needed) or proceed to Phase 2 integration

---
*Phase: 01-build-libish-framework*
*Completed: 2026-02-22*
