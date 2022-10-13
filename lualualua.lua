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
  return index > 0 or index < 0 and -index <= s:gettop()
end

local function checkboolean(s, index)
  assert(s:isboolean(index))
  return s:toboolean(index)
end

local function checkstring(s, index)
  assert(s:isstring(index))
  return s:tostring(index)
end

local function checkacceptableindex(s, index, ss)
  local n = s:checknumber(index)
  assert(isacceptableindex(ss, n), 'invalid index')
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
  concat = function(s)
    local ss = checkstate(s, 1)
    local n = s:checknumber(2)
    ss:concat(n)
    return 0
  end,
  equal = function(s)
    local ss = checkstate(s, 1)
    local index1 = checkacceptableindex(s, 2, ss)
    local index2 = checkacceptableindex(s, 3, ss)
    s:pushboolean(ss:equal(index1, index2))
    return 1
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
  isnil = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:isnil(index))
    return 1
  end,
  istable = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    s:pushboolean(ss:istable(index))
    return 1
  end,
  loadstring = function(s)
    local ss = checkstate(s, 1)
    local str = checkstring(s, 2)
    ss:loadstring(str)
    return 1
  end,
  newtable = function(s)
    local ss = checkstate(s, 1)
    ss:newtable()
    return 0
  end,
  pop = function(s)
    local ss = checkstate(s, 1)
    local n = s:checknumber(2)
    ss:pop(n)
    return 0
  end,
  pushboolean = function(s)
    local ss = checkstate(s, 1)
    local b = checkboolean(s, 2)
    ss:pushboolean(b)
    return 0
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
    local str = checkstring(s, 2)
    ss:pushstring(str)
    return 0
  end,
  pushvalue = function(s)
    local ss = checkstate(s, 1)
    local index = checkacceptableindex(s, 2, ss)
    ss:pushvalue(index)
    return 1
  end,
  setglobal = function(s)
    local ss = checkstate(s, 1)
    local name = checkstring(s, 2)
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
