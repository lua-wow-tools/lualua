describe('lualualua', function()
  it('loads', function()
    local s = require('lualua').newstate()
    s:loadstring([[
      local lib = ...
      local s = lib.newstate()
      return s:gettop() < lib.MINSTACK
    ]])
    s:pushlfunction(require('lualualua'))
    if s:pcall(0, 1, 0) ~= 0 then
      error(s:tostring(-1))
    end
    if s:pcall(1, 1, 0) ~= 0 then
      error(s:tostring(-1))
    end
    assert.same(true, s:toboolean(1))
  end)
end)
