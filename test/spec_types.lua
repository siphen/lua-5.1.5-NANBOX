local A = require('test.spec_assert')

-- numbers
do
  local n = 123.5
  A.eq(type(n), 'number')
  A.eq(tonumber('42'), 42)
  A.eq(tostring(3.25), '3.25')
end

-- booleans and nil
do
  A.eq(type(true), 'boolean')
  A.eq(type(false), 'boolean')
  A.eq(type(nil), 'nil')
  A.falsy(false)
  A.truthy(true)
end

-- strings
do
  local s = 'a' .. 'b' .. 'c'
  A.eq(type(s), 'string')
  A.eq(#s, 3)
  A.eq(string.sub(s, 2, 3), 'bc')
end

-- tables
do
  local t = {a = 1, [2] = 3}
  A.eq(type(t), 'table')
  A.eq(t.a, 1)
  A.eq(t[2], 3)
  t.a = 5; A.eq(t.a, 5)
end

-- functions
do
  local function f(x) return x + 1 end
  A.eq(type(f), 'function')
  A.eq(f(2), 3)
end

-- coroutine/thread
do
  local sum = 0
  local co = coroutine.create(function(n)
    for i=1,n do sum = sum + i; coroutine.yield() end
  end)
  A.eq(type(co), 'thread')
  for _=1,5 do coroutine.resume(co, 5) end
  A.truthy(sum > 0)
end

-- userdata (from io)
do
  local f = io.tmpfile()
  A.eq(type(f), 'userdata')
  f:write('x')
  f:close()
end

