# PROJECT: Blink-iSH Integration

## What This Is

A custom iOS IPA that integrates iSH (x86 Linux emulator) into Blink Shell, providing a local Linux environment with apt package manager directly in the terminal app. Users get a full Debian-like experience without leaving Blink.

## Core Value

**One app, all the shells.** No more switching between Blink for SSH/Mosh and iSH for local Linux — get both in a single, polished terminal experience with package management.

## Requirements

### Validated
- iSH provides x86 Linux emulation on iOS via syscall translation
- iSH uses Alpine Linux rootfs downloaded at build time (configurable via ROOTFS_URL)
- Debian 10 (i386) works on iSH via debiSH project — last x86-32 Debian
- iSH-AOK fork already supports Debian/Devuan filesystems with apt
- Blink Shell has a session-based architecture (SSHSession, MoshSession, MCPSession)
- Blink loads commands via plist files and frameworks via Package.swift

### Active
- Build iSH as a reusable library/framework (libiSH)
- Create iSHSession type for Blink's session architecture
- Configure rootfs with apt pre-installed (Debian 10 or Alpine + apt)
- Bundle rootfs in app or download on first launch
- Expose apt commands through Blink's terminal interface

### Out of Scope
- App Store distribution (Apple blocks package managers — sideload only)
- ARM64 support (iSH is x86-only, uses emulation)
- GUI package management (CLI only)

## Key Decisions

| Decision | Outcome | Rationale |
|----------|---------|-----------|
| Debian vs Alpine | **Debian 10 (buster) i386** | Only x86-32 Debian available; apt included; debiSH proved it works |
| Build approach | **Framework + Session** | Cleanest integration; follows Blink's existing patterns |
| Rootfs delivery | **Bundled in app** | No runtime download complexity; works offline |
| Base iSH version | **Upstream ish-ios** | Simpler than forking iSH-AOK; we only need the emulator |

## Constraints

### Hard Limits
- iOS sandbox prevents executing downloaded binaries
- Apple App Store forbids package managers — sideload/AltStore only
- x86 emulation only (no ARM64, even on M-series chips)
- Debian 10 is EOL (2022-09-10) — last x86-32 release

### Technical Limits
- iSH syscall coverage isn't complete — some apps won't work
- Performance is slower than native (emulation overhead)
- Memory constraints on iOS may limit complex operations

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    Blink Shell                       │
├─────────────────────────────────────────────────────┤
│  Sessions: SSH │ Mosh │ MCP │ iSH (NEW)             │
├─────────────────────────────────────────────────────┤
│                   libiSH.framework                   │
│  ┌─────────────────────────────────────────────┐   │
│  │  x86 Emulator │ Syscall Translator │ FS     │   │
│  └─────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│              Debian 10 Rootfs (bundled)             │
│  ┌─────────────────────────────────────────────┐   │
│  │  apt │ dpkg │ bash │ coreutils │ etc        │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## Relevant Files

### Blink Shell (blink-shell/)
- `Blink.xcodeproj/` — Main Xcode project
- `Blink/AppDelegate.m` — App initialization, command loading
- `Resources/blinkCommandsDictionary.plist` — Command registration
- `xcfs/Package.swift` — Framework dependencies
- `Sessions/` — Session types to model iSHSession after

### iSH (ish-ios/)
- `iSH.xcodeproj/` — Main Xcode project
- `app/iSH.xcconfig` — Build config with ROOTFS_URL
- `fs/` — Filesystem emulation (fake.c, fd.c, etc.)
- `kernel/` — Linux syscall emulation
- `emu/` — x86 instruction emulation

## References

- [iSH GitHub](https://github.com/ish-app/ish)
- [iSH-AOK Fork](https://github.com/emkey1/ish-AOK) — Enhanced iSH with Debian support
- [debiSH](https://github.com/jaclu/debiSH) — Debian 10 on iSH guide
- [AOK-Filesystem-Tools](https://github.com/emkey1/AOK-Filesystem-Tools) — Rootfs building
- [Blink Shell](https://github.com/blinksh/blink)
