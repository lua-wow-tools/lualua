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

    describe('isnil', function()
      it('works', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushnil()
        assert.same(false, nr(1, s:isnil(1)))
        assert.same(true, nr(1, s:isnil(2)))
      end)
    end)

    describe('isnumber', function()
      it('works', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushstring('99')
        s:pushstring('wat')
        s:pushnil()
        assert.same(true, nr(1, s:isnumber(1)))
        assert.same(true, nr(1, s:isnumber(2)))
        assert.same(false, nr(1, s:isnumber(3)))
        assert.same(false, nr(1, s:isnumber(4)))
      end)
    end)

    describe('pop', function()
      it('fails without an argument', function()
        local s = lib.newstate()
        s:pushnumber(42)
        local function fn()
          s:pop()
        end
        assert.False(pcall(fn))
      end)
      it('works', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushnumber(43)
        s:pushnumber(44)
        nr(0, s:pop(2))
        assert.same(1, s:gettop())
        assert.same(42, s:tonumber(-1))
      end)
      it('ignores negative numbers', function()
        local s = lib.newstate()
        s:pushnumber(42)
        nr(0, s:pop(-2))
        assert.same(1, s:gettop())
        assert.same(42, s:tonumber(-1))
      end)
    end)

    describe('pushnil', function()
      it('works', function()
        local s = lib.newstate()
        nr(0, s:pushnil())
        assert.same(1, s:gettop())
        assert.same(true, s:isnil(1))
      end)
    end)

    describe('settop', function()
      it('fails without an argument', function()
        local s = lib.newstate()
        local function fn()
          s:settop()
        end
        assert.False(pcall(fn))
      end)
      it('fills with nil', function()
        local s = lib.newstate()
        nr(0, s:settop(3))
        assert.same(true, s:isnil(1))
        assert.same(true, s:isnil(2))
        assert.same(true, s:isnil(3))
      end)
      it('keeps existing values on stack', function()
        local s = lib.newstate()
        s:pushnumber(3)
        s:pushnumber(4)
        s:pushnumber(5)
        s:pushnumber(6)
        nr(0, s:settop(2))
        assert.same(2, s:gettop())
        assert.same(4, s:tonumber(-1))
        assert.same(3, s:tonumber(-2))
      end)
      it('works with negative numbers', function()
        local s = lib.newstate()
        s:pushnumber(12)
        s:pushnumber(13)
        s:pushnumber(14)
        s:pushnumber(15)
        s:pushnumber(16)
        nr(0, s:settop(-4))
        assert.same(2, s:gettop())
        assert.same(13, s:tonumber(-1))
        assert.same(12, s:tonumber(-2))
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
