# Copyright (c) 2026 Christiaan (chris@boreddev.nl)
# Lua Standalone Makefile

CC = x86_64-boredos-gcc
LD = x86_64-boredos-ld

ifneq ($(BOREDOS_SDK),)
  ifeq ($(wildcard $(BOREDOS_SDK)/lib/libc.a),)
    BOOTSTRAP_SDK = $(BOREDOS_SDK)
    SDK_PATH      = $(BOREDOS_SDK)
  else
    SDK_PATH      = $(BOREDOS_SDK)
  endif
endif

ifeq ($(SDK_PATH),)
  SDK_PATH = $(abspath build/sdk)
  ifeq ($(wildcard $(SDK_PATH)/lib/libc.a),)
    BOOTSTRAP_SDK = $(SDK_PATH)
  endif
endif

DESTDIR ?= $(abspath build/dist)

LUA_CFLAGS = -std=gnu11 -ffreestanding -O2 -fno-stack-protector -fno-stack-check \
             -fno-lto -fno-pie -m64 -march=x86-64 -mno-red-zone \
             -isystem src/sysinclude -I. -I$(SDK_PATH)/include -Isrc -DLUA_USE_C89 \
             -Wno-conversion -Wno-sign-conversion -Wno-double-promotion \
             -Wno-unused-parameter -Wno-missing-declarations -Wno-shadow -Wno-undef \
             -Wno-redundant-decls -Wno-old-style-definition -Wno-missing-prototypes \
             -Wno-implicit-fallthrough -Wno-type-limits

LDFLAGS = -m elf_x86_64 -nostdlib -static -no-pie -Ttext=0x40000000 \
          --no-dynamic-linker -z text -z max-page-size=0x1000 -e _start \
          -L$(SDK_PATH)/lib

APPS    = lua.elf

all: $(APPS)

obj/lua_onelua.o: src/boredos_onelua.c
	@mkdir -p obj
	$(CC) $(LUA_CFLAGS) -c $< -o $@

lua.elf: obj/lua_onelua.o
	$(LD) $(LDFLAGS) $(SDK_PATH)/lib/crt0.o $(SDK_PATH)/lib/crti.o $< -lc $(SDK_PATH)/lib/crtn.o -o $@

install: all
	mkdir -p $(DESTDIR)/bin
	cp $(APPS) $(DESTDIR)/bin/

.PHONY: bup
bup: all
	rm -rf build/package
	mkdir -p build/package/bin
	cp lua.elf build/package/bin/
	@echo 'name = "lua"' > build/package/MANIFEST.toml
	@echo 'version = "5.4.4"' >> build/package/MANIFEST.toml
	@echo '[install]' >> build/package/MANIFEST.toml
	@echo 'bin = "/bin"' >> build/package/MANIFEST.toml
	x86_64-boredos-strip --strip-unneeded build/package/bin/*.elf 2>/dev/null || true
	tar -cf build/lua.tar -C build/package MANIFEST.toml bin
	lz4 -f build/lua.tar build/lua.bup
	rm -f build/lua.tar
	rm -rf build/package

clean:
	rm -rf obj build $(APPS)
