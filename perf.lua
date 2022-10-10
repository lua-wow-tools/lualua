local lib = require('lualua')
local n = arg[1] or 1000000

local checks = {
  ['lualua pcall'] = function()
    local s = lib.newstate()
    s:loadstring('return')
    for _ = 1, n do
      s:pushvalue(-1)
      s:pcall(0, 0, 0)
    end
  end,
  ['lua pcall'] = function()
    local function f() end
    for _ = 1, n do
      pcall(f)
    end
  end,
  ['lualua call'] = function()
    local s = lib.newstate()
    s:loadstring('return')
    for _ = 1, n do
      s:pushvalue(-1)
      s:call(0, 0)
    end
  end,
  ['lua call'] = function()
    local function f() end
    for _ = 1, n do
      f()
    end
  end,
}

for k, v in require('pl.tablex').sort(checks) do
  local t = os.clock()
  v()
  print(('%s: %.4f'):format(k, os.clock() - t))
end
