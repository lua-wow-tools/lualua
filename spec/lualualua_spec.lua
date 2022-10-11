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
end)
