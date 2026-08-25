# Copyright (c) 2026 Christiaan (chris@boreddev.nl)
# Lua Standalone Makefile

CC = x86_64-boredos-gcc

DESTDIR ?= $(abspath build/dist)

LUA_CFLAGS = -std=gnu11 -O2 -fno-stack-protector -fno-stack-check \
             -m64 -march=x86-64 \
             -isystem src/sysinclude -I. -Isrc -DLUA_USE_C89 \
             -Wno-conversion -Wno-sign-conversion -Wno-double-promotion \
             -Wno-unused-parameter -Wno-missing-declarations -Wno-shadow -Wno-undef \
             -Wno-redundant-decls -Wno-old-style-definition -Wno-missing-prototypes \
             -Wno-implicit-fallthrough -Wno-type-limits

LDFLAGS = -Wl,-z,max-page-size=0x1000 -Wl,-dynamic-linker,/usr/lib/ld.so -Wl,-rpath,/usr/lib:/lib -lm

APPS    = lua.elf

all: $(APPS)

obj/lua_onelua.o: src/boredos_onelua.c
	@mkdir -p obj
	$(CC) $(LUA_CFLAGS) -c $< -o $@

lua.elf: obj/lua_onelua.o
	$(CC) $< $(LDFLAGS) -o $@

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
