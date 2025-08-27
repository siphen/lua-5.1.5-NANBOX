local A = require('test.spec_assert')

-- Closure captures table; even if outer references are dropped, upvalue keeps it alive.
collectgarbage(); collectgarbage()

local alive = setmetatable({}, {__mode='k'})

local function make()
  local t = {x=123}
  alive[t] = true
  local function f() return t.x end
  return f
end

local f = make()
collectgarbage('collect')

-- t should be alive through upvalue captured by f
A.eq(f(), 123)

local n=0; for _ in pairs(alive) do n=n+1 end
A.eq(n, 1, 'upvalue-kept table must survive')

