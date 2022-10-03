#include <lauxlib.h>
#include <lua.h>

typedef struct {
  lua_State *state;
  lua_State *host;
  int stackmax;
  int hostuserdataref;
} lualua_State;

static const char lualua_state_metatable[] = "lualua state";

static int lualua_newstate(lua_State *L) {
  lualua_State *p = lua_newuserdata(L, sizeof(*p));
  luaL_getmetatable(L, lualua_state_metatable);
  lua_setmetatable(L, -2);
  lua_pushvalue(L, -1);
  int ref = luaL_ref(L, LUA_REGISTRYINDEX);
  p->state = luaL_newstate();
  p->host = L;
  p->stackmax = LUA_MINSTACK;
  p->hostuserdataref = ref;
  return 1;
}

static lualua_State *lualua_checkstate(lua_State *L, int index) {
  return luaL_checkudata(L, index, lualua_state_metatable);
}

static int lualua_isacceptableindex(lualua_State *S, int index) {
  return index > 0 && index <= S->stackmax ||
         index < 0 && -index <= lua_gettop(S->state);
}

static int lualua_checkacceptableindex(lua_State *L, int index,
                                       lualua_State *S) {
  int k = luaL_checkint(L, index);
  if (!lualua_isacceptableindex(S, k)) {
    luaL_error(L, "invalid index");
  }
  return k;
}

static void lualua_checkspace(lua_State *L, lualua_State *S, int space) {
  if (S->stackmax - lua_gettop(S->state) < space) {
    luaL_error(L, "stack overflow");
  }
}

static int lualua_state_gc(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lua_close(S->state);
  luaL_unref(L, LUA_REGISTRYINDEX, S->hostuserdataref);
  return 0;
}

static int lualua_checkstack(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int value = lua_checkstack(S->state, index);
  if (value && index > 0) {
    S->stackmax += index;
  }
  lua_pushboolean(L, value);
  return 1;
}

static int lualua_equal(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index1 = lualua_checkacceptableindex(L, 2, S);
  int index2 = lualua_checkacceptableindex(L, 3, S);
  int value = lua_equal(S->state, index1, index2);
  lua_pushboolean(L, value);
  return 1;
}

static int lualua_error(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  if (lua_gettop(S->state) < 1) {
    luaL_error(L, "stack underflow");
  }
  lua_error(S->state);
  return 0;
}

static int lualua_gettable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  if (lua_type(S->state, index) != LUA_TTABLE) {
    luaL_error(L, "attempt to index non-table value");
  }
  lua_gettable(S->state, index);
  return 0;
}

static int lualua_gettop(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lua_pushnumber(L, lua_gettop(S->state));
  return 1;
}

static int lualua_isboolean(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isboolean(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_iscfunction(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_iscfunction(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isfunction(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isfunction(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_islightuserdata(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_islightuserdata(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnil(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isnil(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnone(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isnone(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnoneornil(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isnoneornil(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnumber(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isnumber(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isstring(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isstring(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_istable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_istable(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isthread(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isthread(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isuserdata(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int result = lua_isuserdata(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_loadstring(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  size_t sz;
  const char *buff = luaL_checklstring(L, 2, &sz);
  const char *chunkname = luaL_optstring(L, 3, buff);
  lualua_checkspace(L, S, 1);
  int value = luaL_loadbuffer(S->state, buff, sz, chunkname);
  lua_pushinteger(L, value);
  return 1;
}

static int lualua_newtable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lualua_checkspace(L, S, 1);
  lua_newtable(S->state);
  return 0;
}

static int lualua_pcall(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int nargs = luaL_checkint(L, 2);
  int nresults = luaL_checkint(L, 3);
  int errfunc = luaL_checkint(L, 4);
  if (errfunc != 0 && !lualua_isacceptableindex(S, errfunc)) {
    luaL_error(L, "invalid index");
  }
  if (lua_gettop(S->state) < nargs + 1) {
    luaL_error(L, "stack underflow");
  }
  int value = lua_pcall(S->state, nargs, nresults, errfunc);
  lua_pushinteger(L, value);
  return 1;
}

static int lualua_pop(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int n = luaL_checkint(L, 2);
  /* Analogous to lualua_settop, since pop is defined in terms of settop. */
  if (n != -1 && n != 0 && !lualua_isacceptableindex(S, -n - 1)) {
    luaL_error(L, "stack underflow");
  }
  lua_pop(S->state, n);
  return 0;
}

static int lualua_pushboolean(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int b = lua_toboolean(L, 2);
  lualua_checkspace(L, S, 1);
  lua_pushboolean(S->state, b);
  return 0;
}

static int lualua_invokefromhostregistry(lua_State *SS) {
  lualua_State *S = lua_touserdata(SS, lua_upvalueindex(1));
  int hostfunref = lua_tonumber(SS, lua_upvalueindex(2));
  lua_State *L = S->host;
  lua_checkstack(L, 2);
  lua_rawgeti(L, LUA_REGISTRYINDEX, hostfunref);
  lua_rawgeti(L, LUA_REGISTRYINDEX, S->hostuserdataref);
  int value = lua_pcall(L, 1, 1, 0);
  if (value != 0) {
    lua_error(L);
  }
  return lua_tonumber(L, -1);
}

static int lualua_pushlfunction(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  luaL_argcheck(L, lua_isfunction(L, 2), 2, "function expected");
  lualua_checkspace(L, S, 2);
  int hostfunref = luaL_ref(L, LUA_REGISTRYINDEX); /* TODO unref */
  lua_pushlightuserdata(S->state, S);
  lua_pushnumber(S->state, hostfunref);
  lua_pushcclosure(S->state, lualua_invokefromhostregistry, 2);
  return 0;
}

static int lualua_pushnil(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lualua_checkspace(L, S, 1);
  lua_pushnil(S->state);
  return 0;
}

static int lualua_pushnumber(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lua_Number n = luaL_checknumber(L, 2);
  lualua_checkspace(L, S, 1);
  lua_pushnumber(S->state, n);
  return 0;
}

static int lualua_pushstring(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  const char *s = luaL_checkstring(L, 2);
  lualua_checkspace(L, S, 1);
  lua_pushstring(S->state, s);
  return 0;
}

static int lualua_pushvalue(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_checkspace(L, S, 1);
  lua_pushvalue(S->state, index);
  return 0;
}

static int lualua_settable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  if (lua_type(S->state, index) != LUA_TTABLE) {
    luaL_error(L, "attempt to index non-table value");
  }
  if (lua_gettop(S->state) < 2) {
    luaL_error(L, "not enough elements on stack");
  }
  lua_settable(S->state, index);
  return 0;
}

static int lualua_settop(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  if (index != 0 && index != -1 && !lualua_isacceptableindex(S, index)) {
    luaL_error(L, "invalid settop index");
  }
  lua_settop(S->state, index);
  return 0;
}

static int lualua_toboolean(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int b = lua_toboolean(S->state, index);
  lua_pushboolean(L, b);
  return 1;
}

static int lualua_tonumber(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lua_Number number = lua_tonumber(S->state, index);
  lua_pushnumber(L, number);
  return 1;
}

static int lualua_tostring(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  const char *s = lua_tostring(S->state, index);
  lua_pushstring(L, s);
  return 1;
}

static int lualua_typename(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  const char *s = luaL_typename(S->state, index);
  lua_pushstring(L, s);
  return 1;
}

static const struct luaL_Reg lualua_state_index[] = {
    {"checkstack", lualua_checkstack},
    {"equal", lualua_equal},
    {"error", lualua_error},
    {"gettable", lualua_gettable},
    {"gettop", lualua_gettop},
    {"isboolean", lualua_isboolean},
    {"iscfunction", lualua_iscfunction},
    {"isfunction", lualua_isfunction},
    {"islightuserdata", lualua_islightuserdata},
    {"isnil", lualua_isnil},
    {"isnone", lualua_isnone},
    {"isnoneornil", lualua_isnoneornil},
    {"isnumber", lualua_isnumber},
    {"isstring", lualua_isstring},
    {"istable", lualua_istable},
    {"isthread", lualua_isthread},
    {"isuserdata", lualua_isuserdata},
    {"loadstring", lualua_loadstring},
    {"newtable", lualua_newtable},
    {"pcall", lualua_pcall},
    {"pop", lualua_pop},
    {"pushboolean", lualua_pushboolean},
    {"pushlfunction", lualua_pushlfunction},
    {"pushnil", lualua_pushnil},
    {"pushnumber", lualua_pushnumber},
    {"pushstring", lualua_pushstring},
    {"pushvalue", lualua_pushvalue},
    {"settable", lualua_settable},
    {"settop", lualua_settop},
    {"toboolean", lualua_toboolean},
    {"tonumber", lualua_tonumber},
    {"tostring", lualua_tostring},
    {"typename", lualua_typename},
    {NULL, NULL},
};

static const struct luaL_Reg lualua_index[] = {
    {"newstate", lualua_newstate},
    {NULL, NULL},
};

typedef struct {
  const char *name;
  int value;
} lualua_Constant;

/*
 * MAXSTACK exists in PUC Lua llimits.h but is not exposed in the public API.
 * Elune exposes the value as LUAI_MAXSTACK.
 * We default to the default value in PUC Lua and hope it's not overridden.
 */
#ifndef LUAI_MAXSTACK
#define LUAI_MAXSTACK 250
#endif

static const lualua_Constant lualua_constants[] = {
    {"ENVIRONINDEX", LUA_ENVIRONINDEX},
    {"ERRERR", LUA_ERRERR},
    {"ERRMEM", LUA_ERRMEM},
    {"ERRRUN", LUA_ERRRUN},
    {"ERRSYNTAX", LUA_ERRSYNTAX},
    {"GLOBALSINDEX", LUA_GLOBALSINDEX},
    {"MAXCSTACK", LUAI_MAXCSTACK},
    {"MAXSTACK", LUAI_MAXSTACK},
    {"MINSTACK", LUA_MINSTACK},
    {"MULTRET", LUA_MULTRET},
    {"REGISTRYINDEX", LUA_REGISTRYINDEX},
    {"TBOOLEAN", LUA_TBOOLEAN},
    {"TLIGHTUSERDATA", LUA_TLIGHTUSERDATA},
    {"TFUNCTION", LUA_TFUNCTION},
    {"TNIL", LUA_TNIL},
    {"TNUMBER", LUA_TNUMBER},
    {"TSTRING", LUA_TSTRING},
    {"TTABLE", LUA_TTABLE},
    {"TTHREAD", LUA_TTHREAD},
    {"TUSERDATA", LUA_TUSERDATA},
    {NULL, 0},
};

int luaopen_lualua(lua_State *L) {
  if (luaL_newmetatable(L, lualua_state_metatable)) {
    lua_pushstring(L, "__index");
    lua_newtable(L);
    luaL_register(L, NULL, lualua_state_index);
    lua_settable(L, -3);
    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, lualua_state_gc);
    lua_settable(L, -3);
    lua_pushstring(L, "__metatable");
    lua_pushstring(L, lualua_state_metatable);
    lua_settable(L, -3);
  }
  lua_pop(L, 1);
  lua_newtable(L);
  luaL_register(L, NULL, lualua_index);
  for (const lualua_Constant *c = lualua_constants; c->name != NULL; ++c) {
    lua_pushstring(L, c->name);
    lua_pushinteger(L, c->value);
    lua_settable(L, -3);
  }
  return 1;
}
