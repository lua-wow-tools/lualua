.PHONY: clean test

test:
	/opt/lua-5.1.5/bin/luarocks build --no-install
	/opt/lua-5.1.5/bin/luarocks test
	/opt/elune/bin/luarocks build --no-install
	/opt/elune/bin/luarocks test
	/opt/luajit-2.1.0-beta3/bin/luarocks build --no-install
	/opt/luajit-2.1.0-beta3/bin/luarocks test

clean:
	$(RM) lualua.o lualua.so
