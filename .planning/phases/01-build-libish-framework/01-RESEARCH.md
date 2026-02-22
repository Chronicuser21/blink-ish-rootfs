# Phase 1: Build libiSH Framework - Research

**Researched:** 2026-02-21
**Domain:** iOS Framework Development, x86 Emulation, Cross-Platform Build Systems
**Confidence:** HIGH

## Summary

iSH is a user-mode x86 emulator for iOS that translates Linux syscalls to iOS/Darwin equivalents. The codebase is already structured as reusable C libraries built via Meson, which are then linked into an iOS app via Xcode. The core emulator code (kernel/, fs/, emu/, asbestos/) is cleanly separated from the iOS UI layer (app/), making framework extraction straightforward.

Blink Shell uses a session-based architecture where terminal sessions (SSHSession, MoshSession) inherit from a base Session class and interface with TermDevice/TermStream for I/O. Blink distributes frameworks as XCFrameworks via Swift Package Manager.

**Primary recommendation:** Create a new Xcode framework target that builds the three existing iSH static libraries (libish.a, libish_emu.a, libfakefs.a) into a single libiSH.framework, and expose a minimal Objective-C wrapper API for PTY creation and process management.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Meson | 1.0+ | Build system for C code | iSH already uses Meson; produces static libs |
| Xcode | 15+ | iOS framework packaging | Required for iOS; Blink uses XCFrameworks |
| SQLite3 | System | Filesystem database | iSH's fakefs uses SQLite for persistence |
| libarchive | System | Rootfs extraction | Required for fakefsify tool |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Clang/LLD | System | Compiler for x86 emulation | Building asbestos assembly gadgets |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| XCFramework | Static library (.a) | Simpler but harder to distribute; XCFramework is Apple's recommended format |
| Objective-C wrapper | Pure C API | C API is simpler but ObjC integrates better with Blink |

**Installation:**
```bash
# Prerequisites (already installed for iSH development)
brew install meson ninja llvm libarchive
pip3 install meson
```

## Architecture Patterns

### iSH Codebase Structure
```
ish-ios/
├── emu/           # x86 instruction emulation (CPU, FPU, MMX, vectors)
├── asbestos/      # Interpreter/JIT engine (assembly gadgets)
├── kernel/        # Linux syscall translation
│   ├── init.c     # Initialization API (mount_root, become_first_process)
│   ├── calls.c    # Syscall implementations
│   ├── exec.c     # Process execution
│   ├── fork.c     # Process creation
│   ├── task.c     # Task management
│   └── signal.c   # Signal handling
├── fs/            # Filesystem emulation
│   ├── fake.c     # Fake filesystem (SQLite-backed)
│   ├── pty.c      # PTY implementation
│   ├── tty.c      # TTY driver framework
│   └── sock.c     # Socket emulation
├── app/           # iOS UI layer (NOT part of framework)
│   ├── Terminal.m # iOS terminal view
│   ├── AppDelegate.m
│   └── iOSFS.m    # iOS filesystem bridge
├── meson.build    # Meson build configuration
└── iSH.xcodeproj  # Xcode project (iOS app)
```

### Pattern 1: Static Library Separation
**What:** iSH already builds three separate static libraries:
- `libish_emu.a` - x86 emulation (emu/, asbestos/)
- `libfakefs.a` - SQLite-backed fake filesystem (fs/fake-*.c)
- `libish.a` - Main kernel/syscall layer (kernel/, fs/, platform/)

**When to use:** This is the existing pattern; we preserve it and add a framework wrapper.

**Example from meson.build:**
```python
# Line 69
libish_emu = library('ish_emu', emu_src, include_directories: includes)

# Line 71-74
libfakefs = library('fakefs',
    ['fs/fake-db.c', 'fs/fake-migrate.c', 'fs/fake-rebuild.c'],
    include_directories: includes,
    dependencies: sqlite3)

# Line 157-158
libish = library('ish', src, include_directories: includes)
```

### Pattern 2: PTY/TTY Integration
**What:** iSH provides a complete PTY implementation that can be connected to terminal I/O.

**Key structures:**
```c
// fs/tty.h - TTY driver framework
struct tty_driver {
    const struct tty_driver_ops *ops;
    int major;
    struct tty **ttys;
    unsigned limit;
};

struct tty_driver_ops {
    int (*init)(struct tty *tty);
    int (*open)(struct tty *tty);
    int (*close)(struct tty *tty);
    int (*write)(struct tty *tty, const void *buf, size_t len, bool blocking);
    int (*ioctl)(struct tty *tty, int cmd, void *arg);
    void (*cleanup)(struct tty *tty);
};

// fs/tty.h - TTY instance
struct tty {
    unsigned refcount;
    struct tty_driver *driver;
    char buf[TTY_BUF_SIZE];
    struct winsize_ winsize;
    struct termios_ termios;
    // ... PTY-specific fields
    struct {
        struct tty *other;  // For PTY: master/slave pair
        mode_t_ perms;
        uid_t_ uid;
        uid_t_ gid;
        bool locked;
        bool packet_mode;
    } pty;
};
```

### Pattern 3: Blink Session Architecture
**What:** Blink uses a base Session class that runs in a pthread and interfaces with TermDevice.

**Example from Blink Session.h:**
```objc
@interface Session : NSObject {
    pthread_t _tid;
    TermStream *_stream;
    TermDevice *_device;
}

@property (strong, atomic) SessionParams *sessionParams;
@property (strong) TermStream *stream;
@property (strong) TermDevice *device;
@property (readonly) pthread_t tid;
@property (weak) id<SessionDelegate> delegate;

- (id)initWithDevice:(TermDevice *)device andParams:(SessionParams *)params;
- (void)executeWithArgs:(NSString *)args;
- (int)main:(int)argc argv:(char **)argv;
- (void)sigwinch;
- (void)kill;
- (void)suspend;
@end
```

### Anti-Patterns to Avoid
- **Don't copy app/ directory:** The iOS UI code is not needed for the framework
- **Don't link iOSFS:** The iOS filesystem bridge is app-specific; framework should use fakefs
- **Don't expose internal kernel headers:** Only expose init.h, tty.h, and a new public API header

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PTY implementation | Custom PTY | iSH's fs/pty.c | Already implements Linux PTY semantics |
| Process management | Custom fork/exec | iSH's kernel/fork.c, exec.c | Full Linux process model emulation |
| Filesystem | Custom FS | iSH's fs/fake.c | SQLite-backed, supports Linux permissions |
| Build configuration | Custom Makefile | Meson + Xcode | Already working; proven by upstream |

**Key insight:** iSH's core is already modular. The main work is packaging, not rewriting.

## Common Pitfalls

### Pitfall 1: Missing Assembly Gadget Compilation
**What goes wrong:** The asbestos interpreter uses architecture-specific assembly (gadgets-arm64.S for iOS). If not compiled correctly, the emulator won't work on device.

**Why it happens:** Meson selects assembly based on host_machine.cpu_family, but Xcode cross-compilation may need explicit configuration.

**How to avoid:** Verify Meson's host machine detection for arm64; use `meson configure` to check gadget path.

**Warning signs:** Build succeeds but emulator crashes on first instruction.

### Pitfall 2: SQLite Thread Safety
**What goes wrong:** iSH's fakefs uses SQLite, which requires thread-safe configuration when used from multiple pthreads.

**Why it happens:** iOS app and emulated Linux processes run in different threads.

**How to avoid:** Ensure SQLite is compiled with SQLITE_THREADSAFE=1 (default for system SQLite).

**Warning signs:** Database corruption under load.

### Pitfall 3: Signal Handling Conflicts
**What goes wrong:** iOS signal handlers may conflict with iSH's emulated signal handling.

**Why it happens:** iSH needs to intercept signals for Linux emulation; iOS also uses signals.

**How to avoid:** iSH already handles this via its signal.c implementation; don't add custom signal handlers in framework consumer.

**Warning signs:** Random crashes on signal delivery.

### Pitfall 4: Missing Public Header Exports
**What goes wrong:** Framework builds but consumers can't find headers.

**Why it happens:** Xcode framework targets need explicit header visibility settings.

**How to avoid:** Create a public umbrella header (libiSH.h) that includes only the public API headers.

**Warning signs:** "Header not found" errors when linking framework.

## Code Examples

### Initialization Sequence (from xX_main_Xx.h)
```c
// This is the core initialization that the framework must expose
int mount_root(const struct fs_ops *fs, const char *source);
int become_first_process(void);
int create_stdio(const char *file, int major, int minor);
int create_piped_stdio(void);

// Example usage:
int err = mount_root(&fakefs, root_path);
if (err < 0) return err;

err = become_first_process();
if (err < 0) return err;

err = create_stdio("/dev/console", TTY_CONSOLE_MAJOR, 1);
if (err < 0) return err;

// Execute a process
err = do_execve("/bin/sh", argc, argv, envp);
```

### PTY Creation (from fs/pty.c)
```c
// Create a pseudo-terminal
int ptmx_open(struct fd *fd);

// Or create a fake PTY with custom driver
struct tty *pty_open_fake(struct tty_driver *driver);

// TTY input/output
ssize_t tty_input(struct tty *tty, const char *input, size_t len, bool blocking);
void tty_set_winsize(struct tty *tty, struct winsize_ winsize);
void tty_hangup(struct tty *tty);
```

### Proposed Framework Public API
```objc
// libiSH.h - Proposed public header
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface iSHTerminal : NSObject
@property (nonatomic, readonly) NSUUID *uuid;
@property (nonatomic, readonly) int columns;
@property (nonatomic, readonly) int rows;

- (int)sendOutput:(const void *)buf length:(int)len;
- (void)sendInput:(NSData *)input;
- (void)setSize:(int)cols rows:(int)rows;
- (void)destroy;
@end

@interface iSHSession : NSObject
@property (nonatomic, readonly) iSHTerminal *terminal;
@property (nonatomic, copy, nullable) void (^onExit)(int code);

- (instancetype)initWithRootfsPath:(NSString *)path;
- (int)executeCommand:(NSString *)command withArgs:(NSArray<NSString *> *)args;
- (void)kill;
- (void)suspend;
@end

void iSHInitialize(void);  // Call once at app launch

NS_ASSUME_NONNULL_END
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single monolithic library | Three separate libs | Original design | Clean separation of concerns |
| Manual Makefile | Meson build system | Original design | Cross-platform support, dependency management |
| In-app rootfs download | Bundled rootfs (for Blink integration) | This project | Works offline, simpler UX |

**Deprecated/outdated:**
- Direct xcode-meson.sh script: Should be replaced with proper Xcode build phases
- ROOTFS_URL xcconfig setting: Will use bundled rootfs instead

## Open Questions

1. **Framework vs Static Library**
   - What we know: iSH already produces .a files; XCFramework is Apple's recommended distribution format
   - What's unclear: Whether Blink prefers XCFramework or would accept static library linking
   - Recommendation: Start with static library for simplicity; convert to XCFramework in Phase 4

2. **Thread Model**
   - What we know: iSH uses pthreads internally; Blink sessions also use pthreads
   - What's unclear: Exact integration point between iSH's thread and Blink's Session pthread
   - Recommendation: Research in Phase 3; for now, assume iSH runs in its own thread

3. **Memory Pressure on iOS**
   - What we know: x86 emulation is memory-intensive; iOS has strict limits
   - What's unclear: Whether rootfs size affects memory usage significantly
   - Recommendation: Test with minimal Debian rootfs; may need to optimize in Phase 2

## Sources

### Primary (HIGH confidence)
- iSH source code analysis (meson.build, kernel/init.h, fs/tty.h, kernel/calls.h)
- Blink Shell source code analysis (Sessions/Session.h, Sessions/Session.m, xcfs/Package.swift)
- Xcode project analysis (iSH.xcodeproj/project.pbxproj)

### Secondary (MEDIUM confidence)
- iSH README.md - Build instructions verified against source
- Blink blinkCommandsDictionary.plist - Command registration pattern

### Tertiary (LOW confidence)
- None - all findings verified against source code

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Based on direct source code analysis
- Architecture: HIGH - Verified by reading actual implementation files
- Pitfalls: MEDIUM - Based on code understanding, needs runtime verification

**Research date:** 2026-02-21
**Valid until:** 6 months (iOS tooling stable; iSH actively maintained)

---

## Appendix: Key Files Analyzed

### iSH Core Libraries (to be extracted)
| Path | Purpose | Lines |
|------|---------|-------|
| meson.build | Build configuration | 219 |
| kernel/init.h | Initialization API | 14 |
| kernel/init.c | Initialization impl | ~100 |
| kernel/calls.h | Syscall declarations | 260 |
| kernel/task.h | Task/process model | 201 |
| fs/tty.h | TTY/PTY interface | 170 |
| fs/pty.c | PTY implementation | 327 |
| emu/cpu.h | CPU state | ~200 |
| asbestos/asbestos.c | Interpreter engine | ~500 |

### iSH App Layer (to exclude)
| Path | Purpose |
|------|---------|
| app/AppDelegate.m | iOS app lifecycle |
| app/Terminal.m | iOS terminal view |
| app/TerminalView.m | UIKit integration |
| app/iOSFS.m | iOS filesystem bridge |

### Blink Integration Points
| Path | Purpose |
|------|---------|
| Sessions/Session.h | Base session class |
| Sessions/Session.m | Session implementation |
| Sessions/SSHSession.h | Example session subclass |
| Resources/blinkCommandsDictionary.plist | Command registration |
| xcfs/Package.swift | Framework dependencies |
