describe('lualua', function()
  local lib = require('lualua')

  local function nr(k, ...)
    local n = select('#', ...)
    if k ~= n then
      error(('wrong number of return values: expected %d, got %d'):format(k, n), 2)
    end
    return ...
  end

  describe('library', function()
    it('is a table with newstate and constants', function()
      assert.same('table', type(lib))
      assert.Nil(getmetatable(lib))
      assert.Not.Nil(lib.newstate)
      for k, v in pairs(lib) do
        assert.same('string', type(k))
        assert.same(k == 'newstate' and 'function' or 'number', type(v))
      end
    end)

    it('has some specific constants', function()
      assert.same('number', type(lib.GLOBALSINDEX))
      assert.same('number', type(lib.REGISTRYINDEX))
      assert.same('number', type(lib.TNIL))
      assert.same('nil', type(lib.nonsense))
    end)
  end)

  describe('newstate', function()
    it('creates state userdata', function()
      local s = nr(1, lib.newstate())
      assert.same('userdata', type(s))
      assert.same('lualua state', getmetatable(s))
      assert.Not.same(s, lib.newstate())
    end)
    it('starts with an empty stack', function()
      local s = nr(1, lib.newstate())
      assert.same(0, nr(1, s:gettop()))
    end)
    it('creates new states every time', function()
      local s1 = nr(1, lib.newstate())
      local s2 = nr(1, lib.newstate())
      local s3 = nr(1, lib.newstate())
      assert.Not.same(s1, s2)
      assert.Not.same(s1, s3)
      assert.Not.same(s2, s3)
    end)
  end)

  describe('state api', function()
    describe('checkstack', function()
      it('works with zero', function()
        local s = lib.newstate()
        assert.same(true, nr(1, s:checkstack(0)))
      end)
      it('makes room for pushing', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          s:pushnil()
        end
        assert.same(true, nr(1, s:checkstack(2)))
        s:pushnil()
        s:pushnil()
        assert.False(pcall(function()
          s:pushnil()
        end))
      end)
      it('works at limit', function()
        local s = lib.newstate()
        assert.same(true, nr(1, s:checkstack(lib.MAXCSTACK)))
      end)
      it('fails beyond limit', function()
        local s = lib.newstate()
        assert.same(false, nr(1, s:checkstack(lib.MAXCSTACK + 1)))
      end)
      it('works with nonempty stack', function()
        local s = lib.newstate()
        s:pushnil()
        s:pushnil()
        assert.same(true, nr(1, s:checkstack(lib.MAXCSTACK - 2)))
        assert.same(false, nr(1, s:checkstack(lib.MAXCSTACK - 1)))
      end)
      it('negative numbers are ignored', function()
        local s = lib.newstate()
        assert.same(true, nr(1, s:checkstack(-100)))
        assert.same(true, nr(1, s:checkstack(-lib.MAXCSTACK * 2)))
      end)
    end)

    describe('equal', function()
      it('works with numbers', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushnumber(99)
        s:pushnumber(42)
        assert.same(true, nr(1, s:equal(1, 3)))
        assert.same(false, nr(1, s:equal(2, 3)))
      end)
      it('works with strings', function()
        local s = lib.newstate()
        s:pushstring('foo')
        s:pushstring('bar')
        s:pushstring('foo')
        assert.same(true, nr(1, s:equal(1, 3)))
        assert.same(false, nr(1, s:equal(2, 3)))
      end)
      it('works with tables', function()
        local s = lib.newstate()
        s:newtable()
        s:newtable()
        s:pushvalue(1)
        assert.same(true, nr(1, s:equal(1, 3)))
        assert.same(false, nr(1, s:equal(2, 3)))
      end)
    end)

    describe('error', function()
      it('fails on empty stack', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:error()
        end))
      end)
      it('works outside pushlfunction, by failing', function()
        local s = lib.newstate()
        s:pushstring('womp womp')
        local function fn()
          s:error()
        end
        assert.errors(fn, 'womp womp')
      end)
      it('works in pushlfunction', function()
        local s = lib.newstate()
        s:pushlfunction(function(ss)
          ss:pushstring('womp womp')
          ss:error()
        end)
        assert.same(lib.ERRRUN, s:pcall(0, 0, 0))
        assert.same(1, s:gettop())
        assert.same('womp womp', s:tostring(1))
      end)
    end)

    describe('getfield', function()
      it('fails on invalid index', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:getfield(0, 'foo')
        end))
        assert.same(0, s:gettop())
      end)
      it('fails on non-table', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.False(pcall(function()
          s:getfield(1, 'foo')
        end))
      end)
      it('pushes nil on missing field', function()
        local s = lib.newstate()
        s:newtable()
        nr(0, s:getfield(-1, 'foo'))
        assert.same(2, s:gettop())
        assert.same(true, s:istable(1))
        assert.same(true, s:isnil(2))
      end)
      it('pushes value on present field', function()
        local s = lib.newstate()
        s:newtable()
        s:pushstring('foo')
        s:pushstring('bar')
        s:settable(-3)
        nr(0, s:getfield(-1, 'foo'))
        assert.same(2, s:gettop())
        assert.same(true, s:istable(1))
        assert.same('bar', s:tostring(2))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        s:newtable()
        for _ = 2, lib.MINSTACK do
          s:pushnil()
        end
        assert.False(pcall(function()
          s:getfield(1, 'foo')
        end))
      end)
    end)

    describe('getmetatable', function()
      it('fails on empty stack', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:getmetatable(-1)
        end))
        assert.same(0, s:gettop())
      end)
      it('returns false on numbers', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.same(false, nr(1, s:getmetatable(-1)))
      end)
      it('returns false on tables without a metatable', function()
        local s = lib.newstate()
        s:newtable()
        assert.same(false, nr(1, s:getmetatable(-1)))
      end)
      it('works on userdata', function()
        local s = lib.newstate()
        s:newuserdata()
        s:newtable()
        s:setmetatable(-2)
        assert.same(true, nr(1, s:getmetatable(-1)))
      end)
      it('success on almost full stack', function()
        local s = lib.newstate()
        s:newtable()
        s:newtable()
        s:setmetatable(1)
        for _ = 2, lib.MINSTACK - 1 do
          s:pushnil()
        end
        assert.same(true, nr(1, s:getmetatable(1)))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        s:newtable()
        s:newtable()
        s:setmetatable(1)
        for _ = 2, lib.MINSTACK do
          s:pushnil()
        end
        assert.False(pcall(function()
          s:getmetatable(1)
        end))
      end)
    end)

    describe('gettable', function()
      it('fails on empty stack', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:gettable(-1)
        end))
        assert.same(0, s:gettop())
      end)
      it('works getting itself', function()
        local s = lib.newstate()
        s:newtable()
        nr(0, s:gettable(-1))
        assert.same(1, s:gettop())
        assert.same(true, s:isnil(1))
      end)
      it('fails on non-table', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.False(pcall(function()
          s:gettable(-1)
        end))
        assert.same(1, s:gettop())
        assert.same(42, s:tonumber(1))
      end)
    end)

    describe('gettop', function()
      it('starts at zero', function()
        local s = lib.newstate()
        assert.same(0, nr(1, s:gettop()))
      end)
      it('tracks settop', function()
        local s = lib.newstate()
        s:settop(15)
        assert.same(15, nr(1, s:gettop()))
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

    describe('isstring', function()
      it('works', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushstring('99')
        s:pushstring('wat')
        s:pushnil()
        assert.same(true, nr(1, s:isstring(1)))
        assert.same(true, nr(1, s:isstring(2)))
        assert.same(true, nr(1, s:isstring(3)))
        assert.same(false, nr(1, s:isstring(4)))
      end)
    end)

    describe('istable', function()
      it('works', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushstring('wat')
        s:newtable()
        s:pushnil()
        assert.same(false, nr(1, s:istable(1)))
        assert.same(false, nr(1, s:istable(2)))
        assert.same(true, nr(1, s:istable(3)))
        assert.same(false, nr(1, s:istable(4)))
      end)
    end)

    describe('loadstring', function()
      it('requires an argument', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:loadstring()
        end))
      end)
      it('pushes a function and returns zero on success', function()
        local s = lib.newstate()
        assert.same(0, nr(1, s:loadstring('return 42')))
        assert.same(1, s:gettop())
        assert.same(true, s:isfunction(1))
      end)
      it('pushes an error message and returns ERRSYNTAX on parse failure', function()
        local s = lib.newstate()
        assert.same(lib.ERRSYNTAX, nr(1, s:loadstring('not a valid lua function body')))
        assert.same(1, s:gettop())
        assert.same(true, s:isstring(1))
      end)
      it('success with MAXSTACK-1 returns', function()
        local s = lib.newstate()
        local t = {}
        for i = 1, lib.MAXSTACK - 1 do
          table.insert(t, i)
        end
        assert.same(0, nr(1, s:loadstring('return ' .. table.concat(t, ','))))
      end)
      it('failure with MAXSTACK returns', function()
        local s = lib.newstate()
        local t = {}
        for i = 1, lib.MAXSTACK do
          table.insert(t, i)
        end
        assert.same(lib.ERRSYNTAX, nr(1, s:loadstring('return ' .. table.concat(t, ','))))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          s:pushnil()
        end
        assert.False(pcall(function()
          s:loadstring('return 42')
        end))
        assert.same(lib.MINSTACK, s:gettop())
      end)
    end)

    describe('newtable', function()
      it('works', function()
        local s = lib.newstate()
        nr(0, s:newtable())
        assert.same(1, s:gettop())
        assert.same(true, s:istable(1))
        nr(0, s:newtable())
        assert.same(2, s:gettop())
        assert.same(true, s:istable(2))
        assert.same(false, s:equal(1, 2))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          nr(0, s:newtable())
        end
        assert.False(pcall(function()
          s:newtable()
        end))
      end)
    end)

    describe('newuserdata', function()
      it('works', function()
        local s = lib.newstate()
        local t = nr(1, s:newuserdata())
        assert.same('table', type(t))
        assert.Nil(getmetatable(t))
        assert.same(1, s:gettop())
        assert.same(true, s:isuserdata(1))
        assert.equal(t, s:touserdata(1))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          s:pushnil()
        end
        assert.False(pcall(function()
          s:newuserdata()
        end))
      end)
    end)

    describe('pcall', function()
      it('fails on empty stack', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:pcall(0, 0, 0)
        end))
      end)
      it('returns ERRRUN on non-function', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.same(lib.ERRRUN, nr(1, s:pcall(0, 0, 0)))
      end)
      it('returns ERRRUN on function that errors', function()
        local s = lib.newstate()
        s:loadstring('unknown()')
        assert.same(lib.ERRRUN, nr(1, s:pcall(0, 0, 0)))
        assert.same(1, s:gettop())
        assert.same(true, s:isstring(1))
      end)
      it('works', function()
        local s = lib.newstate()
        s:loadstring('local a, b, c = ...; return a + 5, "foo", ...')
        s:pushnumber(42)
        s:pushboolean(false)
        assert.same(0, nr(1, s:pcall(2, lib.MULTRET, 0)))
        assert.same(4, s:gettop())
        assert.same(47, s:tonumber(1))
        assert.same('foo', s:tostring(2))
        assert.same(42, s:tonumber(3))
        assert.same(false, s:toboolean(4))
      end)
      it('fails on invalid errfunc index', function()
        local s = lib.newstate()
        s:loadstring('unknown()')
        assert.False(pcall(function()
          s:pcall(0, 0, -2)
        end))
      end)
      it('returns ERRERR on erroring function that is also its errfunc', function()
        local s = lib.newstate()
        assert.same(0, s:loadstring('unknown()'))
        assert.same(lib.ERRERR, nr(1, s:pcall(0, 0, -1)))
      end)
      it('returns ERRERR if errfunc is not a function', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.same(0, s:loadstring('unknown()'))
        assert.same(lib.ERRERR, nr(1, s:pcall(0, 0, -2)))
      end)
      it('properly invokes errfunc, only preserves first result', function()
        local s = lib.newstate()
        assert.same(0, s:loadstring('local x = ...; return "moo: " .. x, 42'))
        assert.same(0, s:loadstring('unknown()'))
        assert.same(lib.ERRRUN, nr(1, s:pcall(0, 0, -2)))
        assert.same(2, s:gettop())
        assert.same(true, s:isfunction(1))
        assert.same('string', s:typename(2))
        assert.same('moo: ', s:tostring(2):sub(1, 5))
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
      it('works with zero', function()
        local s = lib.newstate()
        nr(0, s:pop(0))
      end)
      it('works going to empty', function()
        local s = lib.newstate()
        s:pushnumber(42)
        nr(0, s:pop(1))
        assert.same(0, s:gettop())
      end)
      it('fails when popping beyond end', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.False(pcall(function()
          s:pop(2)
        end))
        assert.same(1, s:gettop())
        assert.same(42, s:tonumber(-1))
      end)
      it('negatives confined to stack size', function()
        local s = lib.newstate()
        nr(0, s:pop(-1))
        nr(0, s:pop(-lib.MINSTACK))
        assert.False(pcall(function()
          s:pop(-lib.MINSTACK - 1)
        end))
      end)
    end)

    describe('pushboolean', function()
      it('no argument is false', function()
        local s = lib.newstate()
        nr(0, s:pushboolean())
        assert.same(false, s:toboolean(-1))
      end)
      it('works with true', function()
        local s = lib.newstate()
        nr(0, s:pushboolean(true))
        assert.same(true, s:toboolean(-1))
      end)
      it('works with false', function()
        local s = lib.newstate()
        nr(0, s:pushboolean(false))
        assert.same(false, s:toboolean(-1))
      end)
      it('nil is false', function()
        local s = lib.newstate()
        nr(0, s:pushboolean(nil))
        assert.same(false, s:toboolean(-1))
      end)
      it('nonzero is true', function()
        local s = lib.newstate()
        nr(0, s:pushboolean(1))
        assert.same(true, s:toboolean(-1))
      end)
      it('zero is true', function()
        local s = lib.newstate()
        nr(0, s:pushboolean(0))
        assert.same(true, s:toboolean(-1))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          nr(0, s:pushboolean(true))
        end
        assert.False(pcall(function()
          s:pushboolean(true)
        end))
      end)
    end)

    describe('pushlfunction', function()
      it('works', function()
        local s = lib.newstate()
        s:pushlfunction(function(ss)
          assert.same(s, ss)
          assert.same(2, ss:gettop())
          assert.same(42, ss:tonumber(1))
          assert.same('foo', ss:tostring(2))
          ss:pushstring('bar')
          ss:pushnumber(99)
          ss:pushnil()
          return 3
        end)
        s:pushnumber(42)
        s:pushstring('foo')
        assert.same(0, s:pcall(2, lib.MULTRET, 0))
        assert.same(3, s:gettop())
        assert.same('bar', s:tostring(1))
        assert.same(99, s:tonumber(2))
        assert.same(true, s:isnil(3))
      end)
      it('fails gracefully', function()
        local s = lib.newstate()
        s:pushlfunction(function()
          _G.missingfunction()
        end)
        assert.same(lib.ERRRUN, s:pcall(0, 0, 0))
        assert.same(1, s:gettop())
        assert.Not.Nil(s:tostring(1):find('attempt to call field \'missingfunction\''))
      end)
    end)

    describe('pushnil', function()
      it('works', function()
        local s = lib.newstate()
        nr(0, s:pushnil())
        assert.same(1, s:gettop())
        assert.same(true, s:isnil(1))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          nr(0, s:pushnil())
        end
        assert.False(pcall(function()
          s:pushnil()
        end))
      end)
    end)

    describe('pushnumber', function()
      it('requires an argument', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:pushnumber()
        end))
      end)
      it('works', function()
        local s = lib.newstate()
        nr(0, s:pushnumber(42))
        assert.same(42, s:tonumber(-1))
      end)
      it('works on number string', function()
        local s = lib.newstate()
        nr(0, s:pushnumber('42'))
        assert.same(42, s:tonumber(-1))
      end)
      it('fails on non-number string', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:pushnumber('wat')
        end))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          nr(0, s:pushnumber(42))
        end
        assert.False(pcall(function()
          s:pushnumber(42)
        end))
      end)
    end)

    describe('pushstring', function()
      it('requires an argument', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:pushstring()
        end))
      end)
      it('works', function()
        local s = lib.newstate()
        nr(0, s:pushstring('wat'))
        assert.same('wat', s:tostring(-1))
      end)
      it('works with numbers', function()
        local s = lib.newstate()
        nr(0, s:pushstring(42))
        assert.same('42', s:tostring(-1))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        for _ = 1, lib.MINSTACK do
          nr(0, s:pushstring('foo'))
        end
        assert.False(pcall(function()
          s:pushstring('foo')
        end))
      end)
    end)

    describe('pushvalue', function()
      it('requires an argument', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:pushvalue()
        end))
      end)
      it('works with strings', function()
        local s = lib.newstate()
        s:pushstring('wat')
        nr(0, s:pushvalue(-1))
        assert.same(2, s:gettop())
        assert.same('wat', s:tostring(-1))
      end)
      it('works with nil', function()
        local s = lib.newstate()
        s:pushnil()
        nr(0, s:pushvalue(-1))
        assert.same(2, s:gettop())
        assert.same(true, s:isnil(-1))
      end)
      it('fails on full stack', function()
        local s = lib.newstate()
        s:pushnil()
        for _ = 2, lib.MINSTACK do
          nr(0, s:pushvalue(-1))
        end
        assert.False(pcall(function()
          s:pushvalue(-1)
        end))
      end)
    end)

    describe('setfield', function()
      it('fails on invalid index', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:setfield(0, 'foo')
        end))
        assert.same(0, s:gettop())
      end)
      it('fails on non-table', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushnumber(99)
        assert.False(pcall(function()
          s:setfield(1, 'foo')
        end))
      end)
      it('works', function()
        local s = lib.newstate()
        s:newtable()
        s:pushnumber(99)
        nr(0, s:setfield(-2, 'foo'))
        assert.same(1, s:gettop())
        assert.same(true, s:istable(1))
        s:pushstring('foo')
        s:gettable(-2)
        assert.same(99, s:tonumber(2))
      end)
      it('can set table as value and pops table', function()
        local s = lib.newstate()
        s:newtable()
        s:pushvalue(-1)
        nr(0, s:setfield(-2, 'foo'))
        assert.same(1, s:gettop())
        assert.same(true, s:istable(1))
        s:pushstring('foo')
        s:gettable(-2)
        assert.same(true, s:equal(1, 2))
      end)
      it('succeeds on full stack', function()
        local s = lib.newstate()
        s:newtable()
        for _ = 2, lib.MINSTACK - 1 do
          s:pushnil()
        end
        s:pushnumber(99)
        nr(0, s:setfield(1, 'foo'))
        assert.same(lib.MINSTACK - 1, s:gettop())
      end)
    end)

    describe('setmetatable', function()
      it('fails on empty stack', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:setmetatable(-1)
        end))
        assert.same(0, s:gettop())
      end)
      it('fails on numbers', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.False(pcall(function()
          s:setmetatable(-1)
        end))
        assert.same(1, s:gettop())
        assert.same(42, s:tonumber(1))
      end)
      it('works', function()
        local s = lib.newstate()
        s:newtable()
        s:newtable()
        s:pushstring('__metatable')
        s:pushstring('hi there i am a metatable')
        s:settable(-3)
        assert.same(true, nr(1, s:setmetatable(-2)))
        assert.same(1, s:gettop())
        assert.same(true, s:getmetatable(-1))
        s:pushstring('__metatable')
        s:gettable(-2)
        assert.same('hi there i am a metatable', s:tostring(-1))
      end)
      it('works on userdata', function()
        local s = lib.newstate()
        s:newuserdata()
        s:newtable()
        s:pushvalue(-1)
        assert.same(true, nr(1, s:setmetatable(-3)))
        assert.same(true, s:getmetatable(-2))
        assert.same(true, s:equal(-1, -2))
      end)
      it('can set a table\'s metatable to itself, and also pops it', function()
        local s = lib.newstate()
        s:newtable()
        s:pushvalue(-1)
        assert.same(true, nr(1, s:setmetatable(-1)))
        assert.same(1, s:gettop())
        assert.same(true, s:getmetatable(-1))
        assert.same(true, s:equal(1, 2))
      end)
      it('success on full stack', function()
        local s = lib.newstate()
        s:newtable()
        for _ = 2, lib.MINSTACK - 1 do
          s:pushnil()
        end
        s:newtable()
        assert.same(true, nr(1, s:setmetatable(1)))
      end)
    end)

    describe('settable', function()
      it('fails on empty stack', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:settable(-1)
        end))
        assert.same(0, s:gettop())
      end)
      it('fails just setting itself', function()
        local s = lib.newstate()
        s:newtable()
        assert.False(pcall(function()
          s:settable(-1)
        end))
        assert.same(1, s:gettop())
        assert.same(true, s:istable(1))
      end)
      it('fails on non-table', function()
        local s = lib.newstate()
        s:pushnumber(42)
        assert.False(pcall(function()
          s:settable(-1)
        end))
        assert.same(1, s:gettop())
        assert.same(42, s:tonumber(1))
      end)
      it('works in simple case', function()
        local s = lib.newstate()
        s:newtable()
        s:pushstring('foo')
        s:pushstring('bar')
        nr(0, s:settable(-3))
        assert.same(1, s:gettop())
        assert.same(true, s:istable(1))
        s:pushstring('foo')
        s:gettable(-2)
        assert.same(2, s:gettop())
        assert.same(true, s:istable(1))
        assert.same('bar', s:tostring(2))
      end)
      it('table can be its own key', function()
        local s = lib.newstate()
        s:newtable()
        s:pushnil()
        s:pushvalue(-2)
        s:pushstring('bar')
        nr(0, s:settable(-2))
        assert.same(2, s:gettop())
        assert.same(true, s:istable(1))
        assert.same(true, s:isnil(2))
        s:pushvalue(-2)
        s:gettable(-3)
        assert.same(3, s:gettop())
        assert.same(true, s:istable(1))
        assert.same(true, s:isnil(2))
        assert.same('bar', s:tostring(3))
      end)
      it('table can be its own value', function()
        local s = lib.newstate()
        s:newtable()
        s:pushnil()
        s:pushstring('foo')
        s:pushvalue(-3)
        nr(0, s:settable(-1))
        assert.same(2, s:gettop())
        assert.same(true, s:istable(1))
        assert.same(true, s:isnil(2))
        s:pushstring('foo')
        s:gettable(-3)
        assert.same(3, s:gettop())
        assert.same(true, s:istable(1))
        assert.same(true, s:isnil(2))
        assert.same(true, s:equal(1, 3))
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
      it('succeeds on 0', function()
        local s = lib.newstate()
        nr(0, s:settop(0))
        assert.same(0, s:gettop())
      end)
      it('does not fail on -1 even on empty stack', function()
        local s = lib.newstate()
        nr(0, s:settop(-1))
        assert.same(0, s:gettop())
      end)
      it('fails on negatives past the end', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:settop(-2)
        end))
      end)
      it('succeeds up to end of allocation', function()
        local s = lib.newstate()
        nr(0, s:settop(lib.MINSTACK))
        assert.same(lib.MINSTACK, s:gettop())
      end)
      it('fails past end of allocation', function()
        local s = lib.newstate()
        assert.False(pcall(function()
          s:settop(lib.MINSTACK + 1)
        end))
        assert.same(0, s:gettop())
      end)
    end)

    describe('toboolean', function()
      it('works', function()
        local s = lib.newstate()
        s:pushstring('abc')
        s:pushnumber(42)
        s:pushnumber(0)
        s:pushnil()
        s:pushboolean(true)
        s:pushboolean(false)
        assert.same(true, nr(1, s:toboolean(1)))
        assert.same(true, nr(1, s:toboolean(2)))
        assert.same(true, nr(1, s:toboolean(3)))
        assert.same(false, nr(1, s:toboolean(4)))
        assert.same(true, nr(1, s:toboolean(5)))
        assert.same(false, nr(1, s:toboolean(6)))
      end)
    end)

    describe('tonumber', function()
      it('works', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushstring('42')
        s:pushstring('wat')
        s:pushboolean(true)
        s:pushnil()
        assert.same(42, nr(1, s:tonumber(1)))
        assert.same(42, nr(1, s:tonumber(2)))
        assert.same(0, nr(1, s:tonumber(3)))
        assert.same(0, nr(1, s:tonumber(4)))
        assert.same(0, nr(1, s:tonumber(5)))
      end)
    end)

    describe('tostring', function()
      it('works', function()
        local s = lib.newstate()
        s:pushnumber(42)
        s:pushstring('42')
        s:pushstring('wat')
        s:pushboolean(true)
        s:pushnil()
        assert.same('42', nr(1, s:tostring(1)))
        assert.same('42', nr(1, s:tostring(2)))
        assert.same('wat', nr(1, s:tostring(3)))
        assert.same(nil, nr(1, s:tostring(4)))
        assert.same(nil, nr(1, s:tostring(5)))
      end)
    end)
  end)
end)
