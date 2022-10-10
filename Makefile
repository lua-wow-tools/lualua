## Top-level targets

.PHONY: all clean test test-lua.5.1.5 test-elune

all: build/env/lua-5.1.5/lib/lua/5.1/lualua.so build/env/elune/lib/lua/5.1/lualua.so

clean:
	rm -rf build lualua.o lualua.so

test: test-lua.5.1.5 test-elune

test-lua.5.1.5: build/env/lua-5.1.5/bin/busted build/env/lua-5.1.5/lib/lua/5.1/lualua.so
	build/env/lua-5.1.5/bin/busted

test-elune: build/env/elune/bin/busted build/env/elune/lib/lua/5.1/lualua.so
	build/env/elune/bin/busted

## lua-5.1.5

build/deps/lua-5.1.5.tgz:
	mkdir -p build/deps
	wget -Obuild/deps/lua-5.1.5.tmp https://www.lua.org/ftp/lua-5.1.5.tar.gz
	mv build/deps/lua-5.1.5.tmp build/deps/lua-5.1.5.tgz

build/env/lua-5.1.5/bin/lua: build/deps/lua-5.1.5.tgz
	rm -rf build/src/lua-5.1.5
	mkdir -p build/src/lua-5.1.5
	tar zxf build/deps/lua-5.1.5.tgz -C build/src/lua-5.1.5 --strip-components=1
	$(MAKE) -C build/src/lua-5.1.5 CFLAGS="-O2 -Wall -DLUA_USE_POSIX -DLUA_USE_APICHECK -DLUA_USE_DLOPEN" linux
	$(MAKE) -C build/src/lua-5.1.5 INSTALL_TOP=../../../env/lua-5.1.5 install

build/env/lua-5.1.5/bin/luarocks: build/deps/luarocks.tgz build/env/lua-5.1.5/bin/lua
	rm -rf build/src/luarocks-lua-5.1.5
	mkdir -p build/src/luarocks-lua-5.1.5
	tar zxf build/deps/luarocks.tgz -C build/src/luarocks-lua-5.1.5 --strip-components=1
	(cd build/src/luarocks-lua-5.1.5 && ./configure --with-lua=../../env/lua-5.1.5 --prefix=../../env/lua-5.1.5)
	make -C build/src/luarocks-lua-5.1.5
	make -C build/src/luarocks-lua-5.1.5 install

build/env/lua-5.1.5/bin/busted: build/env/lua-5.1.5/bin/luarocks
	build/env/lua-5.1.5/bin/luarocks install busted

build/env/lua-5.1.5/lib/lua/5.1/lualua.so: lualua.c lualua-scm-0.rockspec build/env/lua-5.1.5/bin/luarocks
	build/env/lua-5.1.5/bin/luarocks build

## Elune

build/deps/elune.tgz:
	mkdir -p build/deps
	wget -Obuild/deps/elune.tmp https://github.com/meorawr/elune/archive/main.tar.gz
	mv build/deps/elune.tmp build/deps/elune.tgz

build/env/elune/bin/lua5.1: build/deps/elune.tgz
	rm -rf build/src/elune
	mkdir -p build/src/elune
	tar zxf build/deps/elune.tgz -C build/src/elune --strip-components=1
	(cd build/src/elune && cmake --preset linux)
	(cd build/src/elune && cmake --build --preset linux)
	(cd build/src/elune && cmake --install build/linux --prefix ../../env/elune)

build/env/elune/bin/luarocks: build/deps/luarocks.tgz build/env/elune/bin/lua5.1
	rm -rf build/src/luarocks-elune
	mkdir -p build/src/luarocks-elune
	tar zxf build/deps/luarocks.tgz -C build/src/luarocks-elune --strip-components=1
	(cd build/src/luarocks-elune && ./configure --with-lua=../../env/elune --prefix=../../env/elune)
	make -C build/src/luarocks-elune
	make -C build/src/luarocks-elune install

build/env/elune/bin/busted: build/env/elune/bin/luarocks
	build/env/elune/bin/luarocks install busted

build/env/elune/lib/lua/5.1/lualua.so: lualua.c lualua-scm-0.rockspec build/env/elune/bin/luarocks
	build/env/elune/bin/luarocks build

## Luarocks source (compiled for each Lua)

build/deps/luarocks.tgz:
	mkdir -p build/deps
	wget -Obuild/deps/luarocks.tmp https://luarocks.org/releases/luarocks-3.8.0.tar.gz
	mv build/deps/luarocks.tmp build/deps/luarocks.tgz
