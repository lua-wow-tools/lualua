#include <lua.h>
#include <lauxlib.h>

static const char lualua_state_metatable[] = "lualua";

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

static int lualua_gettop(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  lua_pushnumber(L, lua_gettop(S));
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

static int lualua_settop(lua_State *L) {
  lua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  lua_settop(S, index);
  return 0;
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

static struct luaL_Reg lualua_state_index[] = {
  {"gettop", lualua_gettop},
  {"isnumber", lualua_isnumber},
  {"isstring", lualua_isstring},
  {"pushnumber", lualua_pushnumber},
  {"pushstring", lualua_pushstring},
  {"settop", lualua_settop},
  {"tonumber", lualua_tonumber},
  {"tostring", lualua_tostring},
  {NULL, NULL},
};

static struct luaL_Reg lualua_index[] = {
  {"newstate", lualua_newstate},
  {NULL, NULL},
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
  return 1;
}
