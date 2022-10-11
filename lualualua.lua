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

local function checknumber(s, index)
  assert(s:isnumber(index))
  return s:tonumber(index)
end

local function checkstring(s, index)
  assert(s:isstring(index))
  return s:tostring(index)
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
    local n = checknumber(s, 2)
    ss:concat(n)
    return 0
  end,
  gettop = function(s)
    local ss = checkstate(s, 1)
    s:pushnumber(ss:gettop())
    return 1
  end,
  pushnumber = function(s)
    local ss = checkstate(s, 1)
    local n = checknumber(s, 2)
    ss:pushnumber(n)
    return 0
  end,
  pushstring = function(s)
    local ss = checkstate(s, 1)
    local str = checkstring(s, 2)
    ss:pushstring(str)
    return 0
  end,
  tostring = function(s)
    local ss = checkstate(s, 1)
    local index = s:tonumber(2) -- TODO checkacceptableindex
    s:pushstring(ss:tostring(index))
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
