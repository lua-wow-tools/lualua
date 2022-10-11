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

* `pushcfunction` provides a mechanism for the sandbox to call back into the host.
* `newuserdata` provides a userdata to the sandbox backed by a table in the host.
* Misuse of the API throws errors in the host Lua and resets the sandbox stack.

API coverage:

| Lua C API | `lualua` equivalent |
| --- | --- |
| `lua_atpanic` | Not supported |
| `lua_call` | `s:call(nargs, nresults)` |
| `lua_checkstack` | `b = s:checkstack(extra)` |
| `lua_close` | Implicitly called when sandbox is GCed |
| `lua_concat` | `s:concat(n)` |
| `lua_cpcall` | Not supported |
| `lua_createtable` | `s:createtable(narr, nrec)` |
| `lua_dump` | Not supported |
| `lua_equal` | `b = s:equal(index1, index2)` |
| `lua_error` | `s:error()` |
| `lua_gc` | Not supported |
| `lua_getallocf` | Not supported |
| `lua_getfenv` | `s:getfenv(index)` |
| `lua_getfield` | `s:getfield(index, k)` |
| `lua_getglobal` | `s:getglobal(name)` |
| `lua_getmetatable` | `b = s:getmetatable(index)` |
| `lua_gettable` | `s:gettable(index)` |
| `lua_gettop` | `n = s:gettop()` |
| `lua_insert` | `s:insert(index)` |
| `lua_isboolean` | `b = s:isboolean(index)` |
| `lua_iscfunction` | `b = s:iscfunction(index)` |
| `lua_isfunction` | `b = s:isfunction(index)` |
| `lua_islightuserdata` | `b = s:islightuserdata(index)` |
| `lua_isnil` | `b = s:isnil(index)` |
| `lua_isnone` | `b = s:isnone(index)` |
| `lua_isnoneornil` | `b = s:isnoneornil(index)` |
| `lua_isnumber` | `b = s:isnumber(index)` |
| `lua_isstring` | `b = s:isstring(index)` |
| `lua_istable` | `b = s:istable(index)` |
| `lua_isthread` | `b = s:isthread(index)` |
| `lua_isuserdata` | `b = s:isuserdata(index)` |
| `lua_lessthan` | `b = s:lessthan(index1, index2)` |
| `lua_load` | Not supported |
| `lua_newstate` | `require('lualua').newstate()` |
| `lua_newtable` | `s:newtable()` |
| `lua_newthread` | Not supported |
| `lua_newuserdata` | `t = s:newuserdata()` |
| `lua_next` | `b = s:next(index)` |
| `lua_objlen` | `n = s:objlen(index)` |
| `lua_pcall` | `n = s:pcall(nargs, nresults, errfunc)` |
| `lua_pop` | `s:pop(n)` |
| `lua_pushboolean` | `s:pushboolean(b)` |
| `lua_pushcclosure` | Not supported |
| `lua_pushcfunction` | `s:pushcfunction(fn)` |
| `lua_pushfstring` | Not supported |
| `lua_pushinteger` | Not supported |
| `lua_pushlightuserdata` | Not supported |
| `lua_pushliteral` | Not supported |
| `lua_pushlstring` | Not supported |
| `lua_pushnil` | `s:pushnil()` |
| `lua_pushnumber` | `s:pushnumber(n)` |
| `lua_pushstring` | `s:pushstring(str)` |
| `lua_pushthread` | Not supported |
| `lua_pushvalue` | `s:pushvalue(index)` |
| `lua_pushvfstring` | Not supported |
| `lua_rawequal` | `b = s:rawequal(index1, index2)` |
| `lua_rawget` | `s:rawget(index)` |
| `lua_rawgeti` | `s:rawgeti(index, n)` |
| `lua_rawset` | `s:rawset(index)` |
| `lua_rawseti` | `s:rawseti(index, n)` |
| `lua_register` | `s:register(name, fn)` |
| `lua_remove` | `s:remove(index)` |
| `lua_replace` | `s:replace(index)` |
| `lua_resume` | Not supported |
| `lua_setallocf` | Not supported |
| `lua_setfenv` | `b = s:setfenv(index)` |
| `lua_setfield` | `s:setfield(index, k)` |
| `lua_setglobal` | `s:setglobal(name)` |
| `lua_setmetatable` | `b = s:setmetatable(index)` |
| `lua_settable` | `s:settable(index)` |
| `lua_settop` | `s:settop(index)` |
| `lua_status` | Not supported |
| `lua_toboolean` | `b = s:toboolean(index)` |
| `lua_tocfunction` | Not supported |
| `lua_tointeger` | Not supported |
| `lua_tolstring` | Not supported |
| `lua_tonumber` | `n = s:tonumber(index)` |
| `lua_topointer` | Not supported |
| `lua_tostring` | `str = s:tostring(index)` |
| `lua_tothread` | Not supported |
| `lua_touserdata` | `t = s:touserdata(index)` |
| `lua_type` | Not supported |
| `lua_typename` | Not supported |
| `lua_xmove` | Not supported |
| `lua_yield` | Not supported |
