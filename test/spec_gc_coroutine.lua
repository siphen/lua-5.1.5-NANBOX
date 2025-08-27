local A = require('test.spec_assert')

-- Closure captured upvalue passed into coroutine; ensure reachable and correct.
collectgarbage(); collectgarbage()

local function make()
  local t = {v = 31415}
  local function f() return t.v end
  return f
end

local f = make()

local co = coroutine.create(function(fn)
  A.eq(type(fn), 'function')
  A.eq(fn(), 31415)
  coroutine.yield('ok')
  A.eq(fn(), 31415)
end)

local ok, res = coroutine.resume(co, f)
A.truthy(ok and res == 'ok', 'first resume ok')
ok = coroutine.resume(co)
A.truthy(ok, 'second resume ok')

