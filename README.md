# Lua interpreter

This repository packages the programming language compiler and interpreter for Lua on BoredOS.

## Decoupled Building

This repository is designed to compile **either within the main BoredOS tree OR completely standalone**.

### 1. Integrated Build (Within BoredOS)
If built from the BoredOS root tree, the build system passes `BOREDOS_SDK` to the Makefile. It immediately compiles Lua against the shared pre-built SDK:
```bash
make BOREDOS_SDK=/path/to/shared/sdk
```

### 2. Standalone Build (Isolated Clone)
If cloned completely separately in isolation, running `make` will **automatically bootstrap the SDK**:
```bash
make
```
If `build/sdk` is missing, the Makefile automatically clones the pure standard library dependency from `https://github.com/boredos/libc.git`, compiles it, installs it to `build/sdk`, and builds `lua` standalone!

## Staging Installation
To stage the Lua executable into your target initrd root filesystem directory:
```bash
make DESTDIR=/path/to/initrd/root install
```
- Binary is routed to `/bin/lua`
