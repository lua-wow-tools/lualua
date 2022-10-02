#include <lauxlib.h>
#include <lua.h>

static const char lualua_state_metatable[] = "lualua state";

static int lualua_newstate(lua_State *L) {
  lua_State **p = lua_newuserdata(L, sizeof(*p));
  luaL_getmetatable(L, lualua_state_metatable);
  lua_setmetatable(L, -2);
  *p = luaL_newstate();
  return 1;
}

static lua_State *lualua_checkstate(lua_State *L, int index) {
  return *(lua_State **)luaL_checkudata(L, index, lualua_state_metatable);
}

static int lualua_state_gc(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  lua_close(S);
  return 0;
}

static int lualua_call(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int nargs = luaL_checkint(L, 2);
  int nresults = luaL_checkint(L, 3);
  if (lua_gettop(S) < nargs + 1) {
    lua_pushstring(L, "lualua call: insufficient elements on stack");
    lua_error(L);
  }
  int value = lua_pcall(S, nargs, nresults, 0);
  lua_pushinteger(L, value);
  return 1;
}

static int lualua_checkstack(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int value = lua_checkstack(S, index);
  lua_pushboolean(L, value);
  return 1;
}

static int lualua_equal(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index1 = luaL_checkint(L, 2);
  int index2 = luaL_checkint(L, 3);
  int value = lua_equal(S, index1, index2);
  lua_pushboolean(L, value);
  return 1;
}

static int lualua_gettable(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  if (lua_type(S, index) != LUA_TTABLE) {
    lua_pushstring(L, "attempt to index non-table value");
    lua_error(L);
  }
  lua_gettable(S, index);
  return 0;
}

static int lualua_gettop(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  lua_pushnumber(L, lua_gettop(S));
  return 1;
}

static int lualua_isboolean(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isboolean(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_iscfunction(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_iscfunction(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isfunction(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isfunction(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_islightuserdata(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_islightuserdata(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnil(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isnil(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnone(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isnone(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnoneornil(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isnoneornil(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isnumber(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isnumber(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isstring(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isstring(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_istable(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_istable(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isthread(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isthread(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_isuserdata(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int result = lua_isuserdata(S, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_loadstring(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  size_t sz;
  const char *buff = luaL_checklstring(L, 2, &sz);
  const char *chunkname = luaL_optstring(L, 3, buff);
  int value = luaL_loadbuffer(S, buff, sz, chunkname);
  lua_pushinteger(L, value);
  return 1;
}

static int lualua_newtable(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  lua_newtable(S);
  return 0;
}

static int lualua_pop(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int n = luaL_checkint(L, 2);
  lua_pop(S, n);
  return 0;
}

static int lualua_pushboolean(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int b = lua_toboolean(L, 2);
  lua_pushboolean(S, b);
  return 0;
}

static int lualua_pushcclosure(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  lua_CFunction fn = lua_tocfunction(L, 2);
  if (fn == NULL) {
    lua_pushfstring(L, "expected c function, got %s",
                    lua_typename(L, lua_type(L, 2)));
    lua_error(L);
  }
  int n = luaL_checkint(L, 3);
  lua_pushcclosure(S, fn, n);
  return 0;
}

static int lualua_pushnil(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  lua_pushnil(S);
  return 0;
}

static int lualua_pushnumber(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  lua_Number n = luaL_checknumber(L, 2);
  lua_pushnumber(S, n);
  return 0;
}

static int lualua_pushstring(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  const char *s = luaL_checkstring(L, 2);
  lua_pushstring(S, s);
  return 0;
}

static int lualua_pushvalue(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  lua_pushvalue(S, index);
  return 0;
}

static int lualua_settable(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  lua_settable(S, index);
  return 0;
}

static int lualua_settop(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  lua_settop(S, index);
  return 0;
}

static int lualua_toboolean(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  int b = lua_toboolean(S, index);
  lua_pushboolean(L, b);
  return 1;
}

static int lualua_tonumber(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  lua_Number number = lua_tonumber(S, index);
  lua_pushnumber(L, number);
  return 1;
}

static int lualua_tostring(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  const char *s = lua_tostring(S, index);
  lua_pushstring(L, s);
  return 1;
}

static int lualua_typename(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  const char *s = luaL_typename(S, index);
  lua_pushstring(L, s);
  return 1;
}

static const struct luaL_Reg lualua_state_index[] = {
    {"call", lualua_call},
    {"checkstack", lualua_checkstack},
    {"equal", lualua_equal},
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
    {"pop", lualua_pop},
    {"pushboolean", lualua_pushboolean},
    {"pushcclosure", lualua_pushcclosure},
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

static const lualua_Constant lualua_constants[] = {
    {"ERRERR", LUA_ERRERR},
    {"ERRMEM", LUA_ERRMEM},
    {"ERRRUN", LUA_ERRRUN},
    {"GLOBALSINDEX", LUA_GLOBALSINDEX},
    {"MAXCSTACK", LUAI_MAXCSTACK},
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
