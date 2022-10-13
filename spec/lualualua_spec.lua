describe('lualualua', function()
  it('runs lualua_spec.lua', function()
    local s = require('lualua').newstate()
    s:openlibs()
    s:loadstring([=[
      local errors = {}
      local path = {}
      local function onerror(s)
        errors[table.concat(path, ' ')] = s
      end
      local function busted(name, fn)
        table.insert(path, name)
        xpcall(fn, onerror)
        table.remove(path)
      end
      assert = require('luassert')
      describe = busted
      it = busted
      return errors
    ]=])
    s:call(0, 1)
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
    s:loadstring(lualuaspec, '@spec/lualua_spec.lua')
    s:call(0, 0)
    s:pushnil()
    local count = 0
    while s:next(-2) do
      print()
      print(s:tostring(-2))
      print(s:tostring(-1))
      s:pop(1)
      count = count + 1
    end
    print()
    print('lualualua errors: ' .. count)
  end)
end)
