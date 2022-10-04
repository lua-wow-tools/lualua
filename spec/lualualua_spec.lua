describe('lualualua', function()
  it('loads', function()
    local s = require('lualua').newstate()
    s:loadstring([[
      local lib = ...
      local s = lib.newstate()
      return s:gettop() < lib.MINSTACK
    ]])
    s:pushlfunction(require('lualualua'))
    assert.same(0, s:pcall(0, 1, 0))
    assert.same(0, s:pcall(0, 1, 0))
    assert.same(true, s:toboolean(1))
  end)
end)
