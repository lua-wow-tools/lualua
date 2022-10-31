#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

#ifdef ELUNE_VERSION
#define LUALUA_IS_ELUNE
#endif

typedef struct {
  lua_State *state;
  int stackmax;
  int stateowner;
} lualua_State;

static const char lualua_host_refname[] =
    "github.com/lua-wow-tools/lualua/host";
static const char lualua_sandbox_refname[] =
    "github.com/lua-wow-tools/lualua/sandbox";
static const char lualua_state_metatable[] = "lualua state";
static const char lualua_gctoken_metatable[] = "lualua gctoken";

static int lualua_gctoken_gc(lua_State *SS) {
  int ref = *(int *)lua_touserdata(SS, 1);
  lua_getfield(SS, LUA_REGISTRYINDEX, lualua_sandbox_refname);
  lua_getfield(SS, -1, "host");
  lua_State *L = lua_touserdata(SS, -1);
  lua_getfield(L, LUA_REGISTRYINDEX, lualua_host_refname);
  luaL_unref(L, -1, ref);
  lua_pop(L, 1);
  return 0;
}

static int lualua_newstate(lua_State *L) {
  lualua_State *p = lua_newuserdata(L, sizeof(*p));
  luaL_getmetatable(L, lualua_state_metatable);
  lua_setmetatable(L, -2);
  lua_State *SS = luaL_newstate();
  lua_newtable(SS);
  lua_pushlightuserdata(SS, L);
  lua_setfield(SS, -2, "host");
  lua_newtable(SS);
  lua_newtable(SS);
  lua_pushstring(SS, "k");
  lua_setfield(SS, -2, "__mode");
  lua_setmetatable(SS, -2);
  lua_setfield(SS, -2, "gctokens");
  lua_newtable(SS);
  lua_pushstring(SS, "__gc");
  lua_pushcfunction(SS, lualua_gctoken_gc);
  lua_settable(SS, -3);
  lua_pushstring(SS, "__metatable");
  lua_pushstring(SS, lualua_gctoken_metatable);
  lua_settable(SS, -3);
  lua_setfield(SS, -2, "gctokenmt");
  lua_setfield(SS, LUA_REGISTRYINDEX, lualua_sandbox_refname);
  p->state = SS;
  p->stackmax = LUA_MINSTACK;
  p->stateowner = 1;
  return 1;
}

static lualua_State *lualua_checkstate(lua_State *L, int index) {
  return luaL_checkudata(L, index, lualua_state_metatable);
}

static int lualua_isacceptablestackindex(lualua_State *S, int index) {
  return (index > 0 && index <= S->stackmax) ||
         (index < 0 && -index <= lua_gettop(S->state));
}

static int lualua_ispseudoindex(int index) {
  return index == LUA_GLOBALSINDEX || index == LUA_REGISTRYINDEX ||
#ifdef LUALUA_IS_ELUNE
         index == LUA_ERRORHANDLERINDEX ||
#endif
         index == LUA_ENVIRONINDEX;
}

static int lualua_isacceptableindex(lualua_State *S, int index) {
  return lualua_isacceptablestackindex(S, index) || lualua_ispseudoindex(index);
}

static void lualua_assert(lua_State *L, lualua_State *S, int cond,
                          const char *msg) {
  if (!cond) {
    lua_settop(S->state, 0);
    luaL_error(L, msg);
  }
}

static int lualua_absoluteindex(lualua_State *S, int index) {
  int top = lua_gettop(S->state);
  return (index < 0 && -index <= top) ? (top + index + 1) : index;
}

static int lualua_checkacceptableindex(lua_State *L, int index,
                                       lualua_State *S) {
  int k = luaL_checkint(L, index);
  lualua_assert(L, S, lualua_isacceptableindex(S, k), "invalid index");
  return lualua_absoluteindex(S, k);
}

static int lualua_checkacceptablestackindex(lua_State *L, int index,
                                            lualua_State *S) {
  int k = luaL_checkint(L, index);
  lualua_assert(L, S, lualua_isacceptablestackindex(S, k), "invalid index");
  return lualua_absoluteindex(S, k);
}

static void lualua_checkoverflow(lua_State *L, lualua_State *S, int space) {
  lualua_assert(L, S, S->stackmax - lua_gettop(S->state) >= space,
                "stack overflow");
}

static void lualua_checkunderflow(lua_State *L, lualua_State *S, int space) {
  lualua_assert(L, S, lua_gettop(S->state) >= space, "stack underflow");
}

static int lualua_state_gc(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  if (S->stateowner) {
    lua_close(S->state);
  }
  return 0;
}

static void lualua_safecall(lua_State *L, lualua_State *S, int nargs,
                            int nresults) {
  if (lua_pcall(S->state, nargs, nresults, 0) != 0) {
    lua_pushstring(L, lua_tostring(S->state, -1));
    lua_settop(S->state, 0);
    lua_error(L);
  }
}

static int lualua_call(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int nargs = luaL_checkint(L, 2);
  int nresults = luaL_checkint(L, 3);
  lualua_checkunderflow(L, S, nargs + 1);
  lualua_safecall(L, S, nargs, nresults);
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

static int lualua_doconcat(lua_State *SS) {
  lua_concat(SS, lua_gettop(SS));
  return 1;
}

static int lualua_concat(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int n = luaL_checkint(L, 2);
  if (n >= 0) {
    lualua_checkunderflow(L, S, n);
    lualua_checkoverflow(L, S, 1);
    lua_pushcfunction(S->state, lualua_doconcat);
    lua_insert(S->state, -n - 1);
    lualua_safecall(L, S, n, 1);
  }
  return 0;
}

static int lualua_createtable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int narr = luaL_checkint(L, 2);
  int nrec = luaL_checkint(L, 3);
  lualua_checkoverflow(L, S, 1);
  lua_createtable(S->state, narr, nrec);
  return 0;
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
  lualua_checkunderflow(L, S, 1);
  lua_pushstring(L, lua_tostring(S->state, -1));
  lua_settop(S->state, 0);
  return lua_error(L);
}

static int lualua_getfenv(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_checkoverflow(L, S, 1);
  lua_getfenv(S->state, index);
  return 0;
}

static int lualua_dogetfield(lua_State *SS) {
  const char *k = luaL_checkstring(SS, 2);
  lua_getfield(SS, 1, k);
  return 1;
}

static int lualua_getfield(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  const char *k = luaL_checkstring(L, 3);
  lualua_checkoverflow(L, S, 3);
  lua_pushvalue(S->state, index);
  lua_pushcfunction(S->state, lualua_dogetfield);
  lua_insert(S->state, -2);
  lua_pushstring(S->state, k);
  lualua_safecall(L, S, 2, 1);
  return 0;
}

static int lualua_getglobal(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  const char *k = luaL_checkstring(L, 2);
  lualua_checkoverflow(L, S, 1);
  lua_getglobal(S->state, k);
  return 0;
}

static int lualua_getmetatable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_checkoverflow(L, S, 1);
  int result = lua_getmetatable(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_dogettable(lua_State *SS) {
  lua_gettable(SS, -2);
  return 1;
}

static int lualua_gettable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_checkoverflow(L, S, 2);
  lua_pushvalue(S->state, index);
  lua_pushcfunction(S->state, lualua_dogettable);
  lua_insert(S->state, -3);
  lua_insert(S->state, -2);
  lualua_safecall(L, S, 2, 1);
  return 0;
}

static int lualua_gettop(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lua_pushnumber(L, lua_gettop(S->state));
  return 1;
}

static int lualua_insert(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptablestackindex(L, 2, S);
  lua_insert(S->state, index);
  return 0;
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

static int lualua_dolessthan(lua_State *SS) {
  lua_pushboolean(SS, lua_lessthan(SS, -2, -1));
  return 1;
}

static int lualua_lessthan(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index1 = lualua_checkacceptableindex(L, 2, S);
  int index2 = lualua_checkacceptableindex(L, 3, S);
  lualua_checkoverflow(L, S, 3);
  lua_pushcfunction(S->state, lualua_dolessthan);
  lua_pushvalue(S->state, index1);
  lua_pushvalue(S->state, index2);
  lualua_safecall(L, S, 2, 1);
  lua_pushboolean(L, lua_toboolean(S->state, -1));
  return 1;
}

static int lualua_loadstring(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  size_t sz;
  const char *buff = luaL_checklstring(L, 2, &sz);
  const char *chunkname = luaL_optstring(L, 3, buff);
  lualua_checkoverflow(L, S, 1);
  int value = luaL_loadbuffer(S->state, buff, sz, chunkname);
  lua_pushinteger(L, value);
  return 1;
}

static int lualua_newtable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lualua_checkoverflow(L, S, 1);
  lua_newtable(S->state);
  return 0;
}

static void lualua_gctokenize(lua_State *SS, int ref) {
  lua_getfield(SS, LUA_REGISTRYINDEX, lualua_sandbox_refname);
  lua_getfield(SS, -1, "gctokens");
  lua_pushvalue(SS, -3);
  int *token = lua_newuserdata(SS, sizeof(int));
  *token = ref;
  lua_getfield(SS, -4, "gctokenmt");
  lua_setmetatable(SS, -2);
  lua_settable(SS, -3);
  lua_pop(SS, 2);
}

static int lualua_newuserdata(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lualua_checkoverflow(L, S, 6);
  lua_newtable(L);
  lua_getfield(L, LUA_REGISTRYINDEX, lualua_host_refname);
  lua_pushvalue(L, -2);
  int ref = luaL_ref(L, -2);
  lua_pop(L, 1);
  *(int *)lua_newuserdata(S->state, sizeof(int)) = ref;
  lualua_gctokenize(S->state, ref);
  return 1;
}

static int lualua_next(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_assert(L, S, lua_type(S->state, index) == LUA_TTABLE, "type error");
  lualua_checkoverflow(L, S, 1);
  int value = lua_next(S->state, index);
  lua_pushboolean(L, value);
  return 1;
}

static int lualua_objlen(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int value = lua_objlen(S->state, index);
  lua_pushinteger(L, value);
  return 1;
}

static int lualua_openlibs(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  luaL_openlibs(S->state);
  return 0;
}

static int lualua_pcall(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int nargs = luaL_checkint(L, 2);
  int nresults = luaL_checkint(L, 3);
  int errfunc = luaL_checkint(L, 4);
  if (errfunc != 0) {
    lualua_assert(L, S, lualua_isacceptableindex(S, errfunc), "invalid index");
  }
  lualua_checkunderflow(L, S, nargs + 1);
  lualua_checkoverflow(L, S, 1);
  int result = lua_pcall(S->state, nargs, nresults, errfunc);
  lua_pushinteger(L, result);
  return 1;
}

static int lualua_pop(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int n = luaL_checkint(L, 2);
  /* Analogous to lualua_settop, since pop is defined in terms of settop. */
  lualua_assert(L, S, n == -1 || n == 0 || lualua_isacceptableindex(S, -n),
                "stack underflow");
  lua_pop(S->state, n);
  return 0;
}

static int lualua_pushboolean(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int b = lua_toboolean(L, 2);
  lualua_checkoverflow(L, S, 1);
  lua_pushboolean(S->state, b);
  return 0;
}

static int lualua_invokefromhostregistry(lua_State *SS) {
  int hostfunref = lua_tonumber(SS, lua_upvalueindex(1));
  lua_getfield(SS, LUA_REGISTRYINDEX, lualua_sandbox_refname);
  lua_getfield(SS, -1, "host");
  lua_State *L = lua_touserdata(SS, -1);
  lua_pop(SS, 2);
  if (!lua_checkstack(L, 3)) {
    return luaL_error(SS, "host stack overflow");
  }
  lua_getfield(L, LUA_REGISTRYINDEX, lualua_host_refname);
  lua_rawgeti(L, -1, hostfunref);
  lua_remove(L, -2);
  lualua_State *p = lua_newuserdata(L, sizeof(*p));
  luaL_getmetatable(L, lualua_state_metatable);
  lua_setmetatable(L, -2);
  p->state = SS;
  p->stackmax = LUA_MINSTACK;
  p->stateowner = 0;
  int value = lua_pcall(L, 1, 1, 0);
  if (value != 0) {
    lua_pushstring(SS, lua_tostring(L, -1));
    lua_pop(L, 1);
    return lua_error(SS);
  } else {
    int nreturn = lua_tonumber(L, -1);
    lua_pop(L, 1);
    return nreturn;
  }
}

static void lualua_dopushcfunction(lua_State *L, lualua_State *S) {
  lualua_checkoverflow(L, S, 2);
  lua_getfield(L, LUA_REGISTRYINDEX, lualua_host_refname);
  lua_insert(L, -2);
  int hostfunref = luaL_ref(L, -2);
  lua_pushnumber(S->state, hostfunref);
  lua_pushcclosure(S->state, lualua_invokefromhostregistry, 1);
  lualua_gctokenize(S->state, hostfunref);
}

static int lualua_pushcfunction(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  luaL_argcheck(L, lua_isfunction(L, 2), 2, "function expected");
  lua_settop(L, 2);
  lualua_dopushcfunction(L, S);
  return 0;
}

static int lualua_pushnil(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lualua_checkoverflow(L, S, 1);
  lua_pushnil(S->state);
  return 0;
}

static int lualua_pushnumber(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  lua_Number n = luaL_checknumber(L, 2);
  lualua_checkoverflow(L, S, 1);
  lua_pushnumber(S->state, n);
  return 0;
}

static int lualua_pushstring(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  const char *s = luaL_checkstring(L, 2);
  lualua_checkoverflow(L, S, 1);
  lua_pushstring(S->state, s);
  return 0;
}

static int lualua_pushvalue(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_checkoverflow(L, S, 1);
  lua_pushvalue(S->state, index);
  return 0;
}

static int lualua_rawequal(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index1 = lualua_checkacceptableindex(L, 2, S);
  int index2 = lualua_checkacceptableindex(L, 3, S);
  int value = lua_rawequal(S->state, index1, index2);
  lua_pushboolean(L, value);
  return 1;
}

static int lualua_rawget(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_assert(L, S, lua_type(S->state, index) == LUA_TTABLE, "type error");
  lua_rawget(S->state, index);
  return 0;
}

static int lualua_rawgeti(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int n = luaL_checkint(L, 3);
  lualua_assert(L, S, lua_type(S->state, index) == LUA_TTABLE, "type error");
  lualua_checkoverflow(L, S, 1);
  lua_rawgeti(S->state, index, n);
  return 0;
}

static int lualua_rawset(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_assert(L, S, lua_type(S->state, index) == LUA_TTABLE, "type error");
  lualua_checkunderflow(L, S, 2);
  lua_rawset(S->state, index);
  return 0;
}

static int lualua_rawseti(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int n = luaL_checkint(L, 3);
  lualua_assert(L, S, lua_type(S->state, index) == LUA_TTABLE, "type error");
  lualua_checkunderflow(L, S, 1);
  lua_rawseti(S->state, index, n);
  return 0;
}

static int lualua_ref(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_assert(L, S, lua_type(S->state, index) == LUA_TTABLE, "type error");
  lualua_checkunderflow(L, S, 1);
  int ref = luaL_ref(S->state, index);
  lua_pushnumber(L, ref);
  return 1;
}

static int lualua_register(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  const char *name = luaL_checkstring(L, 2);
  luaL_argcheck(L, lua_isfunction(L, 3), 3, "function expected");
  lua_settop(L, 3);
  lualua_dopushcfunction(L, S);
  lua_setglobal(S->state, name);
  return 0;
}

static int lualua_remove(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptablestackindex(L, 2, S);
  lua_remove(S->state, index);
  return 0;
}

static int lualua_replace(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptablestackindex(L, 2, S);
  lua_replace(S->state, index);
  return 0;
}

static int lualua_setfenv(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_checkunderflow(L, S, 1);
  lualua_assert(L, S, lua_type(S->state, -1) == LUA_TTABLE, "type error");
  int value = lua_setfenv(S->state, index);
  lua_pushboolean(L, value);
  return 1;
}

static int lualua_setfield(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  const char *k = luaL_checkstring(L, 3);
  lua_setfield(S->state, index, k);
  return 0;
}

static int lualua_setglobal(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  const char *k = luaL_checkstring(L, 2);
  lualua_checkunderflow(L, S, 1);
  lua_setglobal(S->state, k);
  return 0;
}

static int lualua_setmetatable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int type = lua_type(S->state, -1);
  lualua_assert(L, S, type == LUA_TTABLE || type == LUA_TNIL, "type error");
  int result = lua_setmetatable(S->state, index);
  lua_pushboolean(L, result);
  return 1;
}

static int lualua_settable(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  lualua_checkunderflow(L, S, 2);
  lua_settable(S->state, index);
  return 0;
}

static int lualua_settop(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = luaL_checkint(L, 2);
  lualua_assert(L, S,
                index == -1 || index == 0 || lualua_isacceptableindex(S, index),
                "invalid settop index");
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

static int lualua_touserdata(lua_State *L) {
  lualua_State *S = lualua_checkstate(L, 1);
  int index = lualua_checkacceptableindex(L, 2, S);
  int *ref = lua_touserdata(S->state, index);
  if (ref == NULL) {
    lua_pushnil(L);
  } else {
    lua_getfield(L, LUA_REGISTRYINDEX, lualua_host_refname);
    lua_rawgeti(L, -1, *ref);
  }
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
    {"call", lualua_call},
    {"checkstack", lualua_checkstack},
    {"concat", lualua_concat},
    {"createtable", lualua_createtable},
    {"equal", lualua_equal},
    {"error", lualua_error},
    {"getfenv", lualua_getfenv},
    {"getfield", lualua_getfield},
    {"getglobal", lualua_getglobal},
    {"getmetatable", lualua_getmetatable},
    {"gettable", lualua_gettable},
    {"gettop", lualua_gettop},
    {"insert", lualua_insert},
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
    {"lessthan", lualua_lessthan},
    {"loadstring", lualua_loadstring},
    {"newtable", lualua_newtable},
    {"newuserdata", lualua_newuserdata},
    {"next", lualua_next},
    {"objlen", lualua_objlen},
    {"openlibs", lualua_openlibs},
    {"pcall", lualua_pcall},
    {"pop", lualua_pop},
    {"pushboolean", lualua_pushboolean},
    {"pushcfunction", lualua_pushcfunction},
    {"pushnil", lualua_pushnil},
    {"pushnumber", lualua_pushnumber},
    {"pushstring", lualua_pushstring},
    {"pushvalue", lualua_pushvalue},
    {"rawequal", lualua_rawequal},
    {"rawget", lualua_rawget},
    {"rawgeti", lualua_rawgeti},
    {"rawset", lualua_rawset},
    {"rawseti", lualua_rawseti},
    {"ref", lualua_ref},
    {"register", lualua_register},
    {"remove", lualua_remove},
    {"replace", lualua_replace},
    {"setfenv", lualua_setfenv},
    {"setfield", lualua_setfield},
    {"setglobal", lualua_setglobal},
    {"setmetatable", lualua_setmetatable},
    {"settable", lualua_settable},
    {"settop", lualua_settop},
    {"toboolean", lualua_toboolean},
    {"tonumber", lualua_tonumber},
    {"tostring", lualua_tostring},
    {"touserdata", lualua_touserdata},
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
#ifdef LUALUA_IS_ELUNE
    {"ERRORHANDLERINDEX", LUA_ERRORHANDLERINDEX},
#endif
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
  lua_getfield(L, LUA_REGISTRYINDEX, lualua_host_refname);
  if (lua_isnil(L, -1)) {
    lua_newtable(L);
    lua_setfield(L, LUA_REGISTRYINDEX, lualua_host_refname);
  }
  lua_pop(L, 1);
  lua_newtable(L);
  luaL_register(L, NULL, lualua_index);
  for (const lualua_Constant *c = lualua_constants; c->name != NULL; ++c) {
    lua_pushstring(L, c->name);
    lua_pushinteger(L, c->value);
    lua_settable(L, -3);
  }
  lua_pushstring(L, "iselune");
#ifdef LUALUA_IS_ELUNE
  lua_pushboolean(L, 1);
#else
  lua_pushboolean(L, 0);
#endif
  lua_settable(L, -3);
  return 1;
}
