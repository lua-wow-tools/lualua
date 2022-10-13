describe('lualualua', function()
  it('runs lualua_spec.lua', function()
    local s = require('lualua').newstate()
    s:openlibs()
    s:loadstring([=[
      assert = require('luassert')
      function describe(name, fn)
        print('describe: ' .. name)
        xpcall(fn, print)
      end
      function it(name, fn)
        print('it: ' .. name)
        xpcall(fn, print)
      end
    ]=])
    s:call(0, 0)
    s:loadstring([=[
      local req, lib = ...
      return function(s)
        return s == 'lualua' and lib or req(s)
      end
    ]=])
    s:getglobal('require')
    s:pushcfunction(require('lualualua'))
    s:call(0, 1)
    s:call(2, 1)
    s:setglobal('require')
    local lualuaspec = require('pl.file').read('spec/lualua_spec.lua')
    s:loadstring(lualuaspec)
    s:call(0, 0)
  end)
end)
