The Lua C API, in Lua. Provides a mechanism for creating and manipulating
_sandbox_ Lua states separate from the _host_ Lua state.

Install via luarocks. Requires a lua 5.1 installation.

```sh
luarocks install lualua
```

Example usage:

```lua
local sandbox = require('lualua').newstate()
sandbox:loadstring('local a, b = ...; return a + b')
sandbox:pushnumber(12)
sandbox:pushnumber(34)
sandbox:call(2, 1)
assert(sandbox:tonumber(-1) == 46)
```

`lualua` is still under active development; its API is not yet stable.

A few things of note:

* `pushlfunction` provides a mechanism for the sandbox to call back into the host.
* `newuserdata` provides a userdata to the sandbox backed by a table in the host.
* Misuse of the API throws errors in the host Lua and resets the sandbox stack.
