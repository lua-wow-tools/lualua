describe('lualua', function()
  local lib = require('lualua')

  local function nr(k, ...)
    local n = select('#', ...)
    if k ~= n then
      error(('wrong number of return values: expected %d, got %d'):format(k, n), 2)
    end
    return ...
  end

  it('is a table with newstate and constants', function()
    assert.same('table', type(lib))
    assert.Nil(getmetatable(lib))
    assert.Not.Nil(next(lib))
    for k, v in pairs(lib) do
      assert.same('string', type(k))
      assert.same(k == 'newstate' and 'function' or 'number', type(v))
    end
  end)

  it('newstate creates a new state userdata', function()
    local s = nr(1, lib.newstate())
    assert.same('userdata', type(s))
    assert.same('lualua state', getmetatable(s))
    assert.same(0, nr(1, s:gettop()))
    assert.Not.same(s, lib.newstate())
  end)

  describe('api', function()
    describe('gettop', function()
      it('starts at zero', function()
        local s = lib.newstate()
        assert.same(0, nr(1, s:gettop()))
      end)
      it('tracks settop', function()
        local s = lib.newstate()
        s:settop(42)
        assert.same(42, nr(1, s:gettop()))
      end)
    end)
  end)

  it('can do basic stack manipulations', function()
    local s = lib.newstate()
    nr(0, s:pushnumber(42))
    assert.same(1, s:gettop())
    assert.same(42, s:tonumber(1))
    assert.same(42, s:tonumber(-1))
    s:pushstring('abc')
    assert.same(2, s:gettop())
    assert.same(42, s:tonumber(1))
    assert.same('abc', s:tostring(2))
    assert.same('abc', s:tostring(-1))
    assert.same(42, s:tonumber(-2))
    nr(0, s:pop(1))
    assert.same(1, s:gettop())
    assert.same(42, s:tonumber(1))
    assert.same(42, s:tonumber(-1))
  end)

  it('can do basic table manipulations', function()
    local s = lib.newstate()
    nr(0, s:newtable())
    assert.same(1, s:gettop())
    s:pushnumber(42)
    nr(0, s:gettable(-2))
    assert.same(2, s:gettop())
    assert.same('nil', s:typename(2))
    s:pop(1)
    assert.same(1, s:gettop())
    assert.same('table', s:typename(1))
    s:pushnumber(42)
    s:pushstring('value')
    nr(0, s:settable(-3))
    assert.same(1, s:gettop())
    assert.same('table', s:typename(1))
    s:pushnumber(42)
    s:gettable(-2)
    assert.same(2, s:gettop())
    assert.same('string', s:typename(-1))
    assert.same('value', s:tostring(-1))
  end)

  it('has constants', function()
    assert.same('number', type(lib.GLOBALSINDEX))
    assert.same('number', type(lib.REGISTRYINDEX))
    assert.same('number', type(lib.TNIL))
    assert.same('nil', type(lib.nonsense))
  end)

  it('does not panic on error', function()
    local function fn()
      lib.newstate():gettable(42)
    end
    assert.has.errors(fn, 'attempt to index non-table value')
  end)

  it('can load strings', function()
    local s = lib.newstate()
    assert.same(0, nr(1, s:loadstring('local n = ...; return n + 5, "foo"')))
    assert.same(1, s:gettop())
    s:pushnumber(42)
    assert.same(0, nr(1, s:call(1, lib.MULTRET)))
    assert.same(2, s:gettop())
    assert.same(47, s:tonumber(-2))
    assert.same('foo', s:tostring(-1))
  end)

  it('can load C functions', function()
    local s = lib.newstate()
    s:pushcclosure(loadstring, 0)
    s:pushstring('return 42')
    s:call(1, 1)
    s:call(0, 1)
    assert.same(42, s:tonumber(-1))
  end)

  it('does not panic on call', function()
    local s = lib.newstate()
    assert.same(lib.ERRRUN, s:call(0, 0))
  end)
end)
