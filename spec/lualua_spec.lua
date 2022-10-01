describe('lualua', function()
  local lib = require('lualua')

  local function nr(k, ...)
    assert.same(k, select('#', ...))
    return ...
  end

  it('creates an empty state', function()
    local state = lib.newstate()
    assert.same('userdata', type(state))
    assert.same(0, nr(1, state:gettop()))
  end)

  it('can do basic stack manipulations', function()
    local state = lib.newstate()
    nr(0, state:pushnumber(42))
    assert.same(1, state:gettop())
    assert.same(42, state:tonumber(1))
    assert.same(42, state:tonumber(-1))
    state:pushstring('abc')
    assert.same(2, state:gettop())
    assert.same(42, state:tonumber(1))
    assert.same('abc', state:tostring(2))
    assert.same('abc', state:tostring(-1))
    assert.same(42, state:tonumber(-2))
  end)
end)
