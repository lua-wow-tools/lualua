# `lualua`

The Lua C API, in Lua. Provides a mechanism for creating and manipulating
_sandbox_ Lua states separate from the _host_ Lua state.

`lualua` is still under active development; its API is not yet stable.

## Installation

Install via luarocks. Requires Lua 5.1.

```sh
luarocks install lualua
```

## Usage

```lua
local sandbox = require('lualua').newstate()
sandbox:loadstring('local a, b = ...; return a + b')
sandbox:pushnumber(12)
sandbox:pushnumber(34)
sandbox:call(2, 1)
assert(sandbox:tonumber(-1) == 46)
```

## Notes

* `pushcfunction` provides a mechanism for the sandbox to call back into the host.
* `newuserdata` provides a userdata to the sandbox backed by a table in the host.
* Misuse of the API throws errors in the host Lua and resets the sandbox stack.

## API Coverage

### Base library

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
| `lua_newstate` | Not supported |
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

### Debug library

| Lua C API | `lualua` equivalent |
| --- | --- |
| `lua_gethook` | Not supported |
| `lua_gethookcount` | Not supported |
| `lua_gethookmask` | Not supported |
| `lua_getinfo` | Not supported |
| `lua_getlocal` | Not supported |
| `lua_getstack` | Not supported |
| `lua_getupvalue` | Not supported |
| `lua_sethook` | Not supported |
| `lua_setlocal` | Not supported |
| `lua_setupvalue` | Not supported |

### Auxiliary library

Note that the C auxiliary library is built on top of the C base library, so
anything labeled "Not supported" can instead be implemented using the `lualua`
base library equivalents.

| Lua C API | `lualua` equivalent |
| --- | --- |
| `luaL_addchar` | Not supported |
| `luaL_addlstring` | Not supported |
| `luaL_addsize` | Not supported |
| `luaL_addstring` | Not supported |
| `luaL_addvalue` | Not supported |
| `luaL_argcheck` | Not supported |
| `luaL_argerror` | Not supported |
| `luaL_buffinit` | Not supported |
| `luaL_callmeta` | Not supported |
| `luaL_checkany` | Not supported |
| `luaL_checkint` | Not supported |
| `luaL_checkinteger` | Not supported |
| `luaL_checklong` | Not supported |
| `luaL_checklstring` | Not supported |
| `luaL_checknumber` | Not supported |
| `luaL_checkoption` | Not supported |
| `luaL_checkstack` | Not supported |
| `luaL_checkstring` | Not supported |
| `luaL_checktype` | Not supported |
| `luaL_checkudata` | Not supported |
| `luaL_dofile` | Not supported |
| `luaL_dostring` | Not supported |
| `luaL_error` | Not supported |
| `luaL_getmetafield` | Not supported |
| `luaL_getmetatable` | Not supported |
| `luaL_gsub` | Not supported |
| `luaL_loadbuffer` | Not supported |
| `luaL_loadfile` | Not supported |
| `luaL_loadstring` | Not supported |
| `luaL_newmetatable` | Not supported |
| `luaL_newstate` | `s = require('lualua').newstate()` |
| `luaL_openlibs` | `s:openlibs()` |
| `luaL_optint` | Not supported |
| `luaL_optinteger` | Not supported |
| `luaL_optlong` | Not supported |
| `luaL_optlstring` | Not supported |
| `luaL_optnumber` | Not supported |
| `luaL_optstring` | Not supported |
| `luaL_prepbuffer` | Not supported |
| `luaL_pushresult` | Not supported |
| `luaL_ref` | `n = s:ref(index)` |
| `luaL_register` | Not supported |
| `luaL_typename` | `str = s:typename(index)` |
| `luaL_typerror` | Not supported |
| `luaL_unref` | Not supported |
| `luaL_where` | Not supported |
