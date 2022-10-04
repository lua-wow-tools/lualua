local lualua = require('lualua')

-- Compare to the implementation of luaL_newmetatable.
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

local function register(s, t)
  for k, v in pairs(t) do
    s:pushstring(k)
    s:pushlfunction(v)
    s:settable(-3)
  end
end

local stateindex = {
  gettop = function(s)
    -- TODO implement
    s:pushnumber(0)
    return 1
  end,
}

local libindex = {
  newstate = function(s)
    local t = s:newuserdata()
    s:getfield(lualua.REGISTRYINDEX, 'lualua state')
    s:setmetatable(-2)
    s:pushvalue(-1)
    t.ref = s:ref(lualua.REGISTRYINDEX)
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
