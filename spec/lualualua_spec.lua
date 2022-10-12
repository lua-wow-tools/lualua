describe('lualualua', function()
  it('loads', function()
    local s = require('lualua').newstate()
    s:loadstring([[
      local lib = ...
      local s = lib.newstate()
      s:pushnumber(42)
      s:pushstring(',')
      s:pushnumber(99)
      s:concat(3)
      return s:tostring(1)
    ]])
    s:pushcfunction(require('lualualua'))
    if s:pcall(0, 1, 0) ~= 0 then
      error(s:tostring(-1))
    end
    if s:pcall(1, 1, 0) ~= 0 then
      error(s:tostring(-1))
    end
    assert.same('42,99', s:tostring(1))
  end)
  it('runs lualua_spec.lua', function()
    local lualuaspec = require('pl.file').read('spec/lualua_spec.lua')
    local s = require('lualua').newstate()
    s:loadstring('assert=require("luassert")')
    s:call(0, 0)
    s:loadstring(lualuaspec)
    -- Emulate the busted environment in lualua.
    s:pushcfunction(function(ss)
      print('describe: ' .. ss:tostring(1))
      ss:settop(2)
      if ss:pcall(0, 0, 0) ~= 0 then
        print('error:' .. ss:tostring(-1))
      end
    end)
    s:setglobal('describe')
    s:pushcfunction(function(ss)
      print('it: ', ss:tostring(1))
      ss:settop(2)
      if ss:pcall(0, 0, 0) ~= 0 then
        print('error:' .. ss:tostring(-1))
      end
    end)
    s:setglobal('it')
    s:call(0, 0)
  end)
end)
