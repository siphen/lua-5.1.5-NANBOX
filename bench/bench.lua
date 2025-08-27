-- Simple Lua 5.1 microbench harness (portable, no deps)
-- Measures runtime via os.clock() and memory via collectgarbage("count").

local function bench(name, fn, iters)
  iters = iters or 1
  collectgarbage()
  collectgarbage()
  local m0 = collectgarbage("count")
  local t0 = os.clock()
  for _ = 1, iters do fn() end
  local t1 = os.clock()
  local m1 = collectgarbage("count")
  return {name=name, time=t1 - t0, mem=m1 - m0}
end

local cases = {}

table.insert(cases, { name = "table_insert_lookup", iters=200, run = function()
  local t = {}
  for i=1,2000 do t[i] = i end
  local s = 0
  for i=1,2000 do s = s + (t[i] or 0) end
  assert(s > 0)
end})

table.insert(cases, { name = "string_concat", iters=100, run = function()
  local s = ""
  for i=1,2000 do s = s .. "x" end
  assert(#s == 2000)
end})

table.insert(cases, { name = "coroutine_switch", iters=2000, run = function()
  local sum = 0
  local co = coroutine.create(function(n)
    for i=1,n do sum = sum + i; coroutine.yield() end
  end)
  for _=1,10 do coroutine.resume(co, 10) end
  assert(sum > 0)
end})

table.insert(cases, { name = "arith_loop", iters=10, run = function()
  local x = 0
  for i=1,2e6 do x = x + math.sin(i) end
  assert(x ~= 0)
end})

local results = {}
for _, c in ipairs(cases) do
  local r = bench(c.name, c.run, c.iters)
  table.insert(results, r)
end

for _, r in ipairs(results) do
  print(string.format("%-20s time=%.6fs mem=%.1fKB", r.name, r.time, r.mem))
end

