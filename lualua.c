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

static struct luaL_Reg lualua_state_index[] = {
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
