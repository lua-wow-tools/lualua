local lualua = require('lualua')

-- Compare to luaL_newmetatable.
local function newmetatable(s, tname)
  s:getfield(lualua.REGISTRYINDEX, tname)
  if not s:isnil(-1) then
    return false
  end
  s:pop(1)
  s:newtable()
  s:pushvalue(-1)
  s:setfield(lualua.REGISTRYINDEX, tname)
  return true
end

-- Compare to lualua_checkstate.
local function checkstate(s, index)
  assert(s:isuserdata(index))
  assert(s:getmetatable(index))
  s:getfield(lualua.REGISTRYINDEX, 'lualua state')
  assert(s:equal(-1, -2))
  s:pop(2)
  return s:touserdata(index).state
end

local function isacceptableindex(s, index)
  return index > 0
    or index < 0 and -index <= s:gettop()
    or index == lualua.REGISTRYINDEX
    or index == lualua.GLOBALSINDEX
    or index == lualua.ENVIRONINDEX
    or index == lualua.ERRORHANDLERINDEX
end

local function checkacceptableindex(s, index, ss)
  local n = s:checknumber(index)
  if not isacceptableindex(ss, n) then
    s:pushstring('invalid index')
    s:error()
  end
  return n
end

local function register(s, t)
  for k, v in pairs(t) do
    s:pushstring(k)
    s:pushcfunction(v)
    s:settable(-3)
  end
end

local stateindex = {
  call = function(s)
    local ss = checkstate(s, 1)
    local nargs = s:checknumber(2)
    local nresults = s:checknumber(3)
    ss:call(nargs, nresults)
    return 0
  end,
  checkstack = function(s)
    local ss = checkstate(s, 1)
    local n = s:checknumber(2)
    s:pushboolean(ss:checkstack(n))
    return 1
  end,
  concat = function(s)
    local ss = checkstate(s, 1)
    local n = s:checknumber(2)
    ss:concat(n)
    return 0
  end,
  createtable = function(s)
    local ss = checkstate(s, 1)
    local narr = s:checknumber(2)
    local nrec = s:checknumber(3)
    ss:createtable(narr, nrec)
    return 0
  end,
  equal = function(s)
    local ss = checkstate(s, 1)
    local index1 = checkacceptableindex(s, 2, ss)
    local index2 = checkacceptableindex(s, 3, ss)
    s:pushboolean(ss:equal(index1, index2))
    return 1
  end,
  error = function(s)
    local ss = checkstate(s, 1)
    ss:error()
  end,
  getfenv = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:getfenv(index)
    return 0
  end,
  getfield = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    local name = s:checkstring(3)
    ss:getfield(index, name)
    return 0
  end,
  getglobal = function(s)
    local ss = checkstate(s, 1)
    local name = s:checkstring(2)
    ss:getglobal(name)
    return 0
  end,
  getmetatable = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:getmetatable(index))
    return 1
  end,
  gettable = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:gettable(index)
    return 0
  end,
  gettop = function(s)
    local ss = checkstate(s, 1)
    s:pushnumber(ss:gettop())
    return 1
  end,
  insert = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:insert(index)
    return 0
  end,
  isfunction = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:isfunction(index))
    return 1
  end,
  isnil = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:isnil(index))
    return 1
  end,
  isnumber = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:isnumber(index))
    return 1
  end,
  isstring = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:isstring(index))
    return 1
  end,
  istable = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:istable(index))
    return 1
  end,
  lessthan = function(s)
    local ss = checkstate(s, 1)
    local index1 = checkacceptableindex(s, 2, ss)
    local index2 = checkacceptableindex(s, 3, ss)
    s:pushboolean(ss:lessthan(index1, index2))
    return 1
  end,
  loadstring = function(s)
    local ss = checkstate(s, 1)
    local str = s:checkstring(2)
    s:pushnumber(ss:loadstring(str))
    return 1
  end,
  newtable = function(s)
    local ss = checkstate(s, 1)
    ss:newtable()
    return 0
  end,
  newuserdata = function()
    error('newuserdata not implemented')
  end,
  next = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:next(index))
    return 1
  end,
  objlen = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushnumber(ss:objlen(index))
    return 1
  end,
  openlibs = function(s)
    local ss = checkstate(s, 1)
    ss:openlibs()
    return 0
  end,
  pcall = function(s)
    local ss = checkstate(s, 1)
    local nargs = s:checknumber(2)
    local nresults = s:checknumber(3)
    local errfunc = s:checknumber(4)
    assert(errfunc == 0 or isacceptableindex(ss, errfunc), 'invalid index')
    s:pushnumber(ss:pcall(nargs, nresults, errfunc))
    return 1
  end,
  pop = function(s)
    local ss = checkstate(s, 1)
    local n = s:checknumber(2)
    ss:pop(n)
    return 0
  end,
  pushboolean = function(s)
    local ss = checkstate(s, 1)
    local b = s:toboolean(2)
    ss:pushboolean(b)
    return 0
  end,
  pushcfunction = function()
    error('pushcfunction not implemented')
  end,
  pushnil = function(s)
    local ss = checkstate(s, 1)
    ss:pushnil()
    return 0
  end,
  pushnumber = function(s)
    local ss = checkstate(s, 1)
    local n = s:checknumber(2)
    ss:pushnumber(n)
    return 0
  end,
  pushstring = function(s)
    local ss = checkstate(s, 1)
    local str = s:checkstring(2)
    ss:pushstring(str)
    return 0
  end,
  pushvalue = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:pushvalue(index)
    return 0
  end,
  rawequal = function(s)
    local ss = checkstate(s, 1)
    local index1 = checkacceptableindex(s, 2, ss)
    local index2 = checkacceptableindex(s, 3, ss)
    s:pushboolean(ss:rawequal(index1, index2))
    return 1
  end,
  rawget = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:rawget(index)
    return 0
  end,
  rawgeti = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    local n = s:checknumber(3)
    ss:rawgeti(index, n)
    return 0
  end,
  rawset = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:rawset(index)
    return 0
  end,
  rawseti = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    local n = s:checknumber(3)
    ss:rawseti(index, n)
    return 0
  end,
  ref = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushnumber(ss:ref(index))
    return 1
  end,
  register = function()
    error('register not implemented')
  end,
  remove = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:remove(index)
    return 0
  end,
  replace = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:replace(index)
    return 0
  end,
  setfenv = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:setfenv(index))
    return 1
  end,
  setfield = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    local name = s:checkstring(3)
    ss:setfield(index, name)
    return 0
  end,
  setglobal = function(s)
    local ss = checkstate(s, 1)
    local name = s:checkstring(2)
    ss:setglobal(name)
    return 0
  end,
  setmetatable = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:setmetatable(index))
    return 1
  end,
  settable = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:settable(index)
    return 0
  end,
  settop = function(s)
    local ss = checkstate(s, 1)
    local n = s:checknumber(2) -- TODO check valid
    ss:settop(n)
    return 0
  end,
  toboolean = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:toboolean(index))
    return 1
  end,
  tonumber = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushnumber(ss:tonumber(index))
    return 1
  end,
  tostring = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    -- Work around how lualua is strict about the argument to pushstring
    local str = ss:tostring(index)
    if str then
      s:pushstring(str)
    else
      s:pushnil()
    end
    return 1
  end,
  typename = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushstring(ss:typename(index))
    return 1
  end,
}

local libindex = {
  newstate = function(s)
    local t = s:newuserdata()
    t.state = lualua.newstate()
    s:getfield(lualua.REGISTRYINDEX, 'lualua state')
    s:setmetatable(-2)
    return 1
  end,
}

local constants = {}
for k, v in pairs(lualua) do
  if type(v) == 'number' then
    constants[k] = v
  end
end

local function load(s)
  if newmetatable(s, 'lualua state') then
    s:pushstring('__index')
    s:newtable()
    register(s, stateindex)
    s:settable(-3)
    s:pushstring('__metatable')
    s:pushstring('lualua state')
    s:settable(-3)
  end
  s:pop(1)
  s:newtable()
  register(s, libindex)
  for k, v in pairs(constants) do
    s:pushstring(k)
    s:pushnumber(v)
    s:settable(-3)
  end
  return 1
end

return load
