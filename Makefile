.PHONY: all clean test
all: lualua.so
clean:
	rm -rf build lualua.o lualua.so
test: lualua.so build/elune/build/linux/bin/Release/lua5.1
	busted
	busted --lua build/elune/build/linux/bin/Release/lua5.1
build/deps/elune.tgz:
	mkdir -p build/deps
	wget -Obuild/deps/elune.tmp https://github.com/meorawr/elune/archive/`cat elune.txt`.tar.gz
	mv build/deps/elune.tmp build/deps/elune.tgz
build/elune/build/linux/bin/Release/lua5.1: build/deps/elune.tgz
	rm -rf build/elune
	mkdir -p build/elune
	tar zxf build/deps/elune.tgz -C build/elune --strip-components=1
	(cd build/elune && cmake --preset linux)
	(cd build/elune && cmake --build --preset linux)
lualua.so: lualua.c lualua-scm-0.rockspec
	luarocks build --no-install
