-- table_stress.lua: stress table array/hash usage to expose layout benefits
-- Usage: lua table_stress.lua [N] [R]
-- N: element count (default 200000)
-- R: random lookups (default 200000)

local N = tonumber(arg[1] or "200000")
local R = tonumber(arg[2] or "200000")

local function gc_sweep()
  collectgarbage()
  collectgarbage()
end

local function mem_kb()
  return collectgarbage("count") -- in KB
end

local peak = 0
local function sample()
  local m = mem_kb(); if m > peak then peak = m end
end

gc_sweep()
local m0 = mem_kb(); peak = m0

local t = {}

-- Build array part
for i=1,N do t[i] = i; if (i % 5000)==0 then sample() end end

-- Build hash part with mixed keys
for i=1,N do t["k"..i] = i; if (i % 5000)==0 then sample() end end

local m1 = mem_kb()

-- Random access workload
math.randomseed(12345)
local sum = 0
for i=1,R do
  local k = math.random(N)
  sum = sum + (t[k] or 0) + (t["k"..k] or 0)
  if (i % 10000)==0 then sample() end
end

-- Delete some keys
for i=1, N, 3 do t[i] = nil end
for i=2, N, 4 do t["k"..i] = nil end

gc_sweep()
local m2 = mem_kb()

local t0 = os.clock()
-- Compact + further ops to exercise rehash
for i=1,N,5 do t[i] = i; if (i % 5000)==0 then sample() end end
for i=1,N,7 do t["k"..i] = i; if (i % 5000)==0 then sample() end end
for i=1,R do
  local k = math.random(N)
  sum = sum + (t[k] or 0)
  if (i % 10000)==0 then sample() end
end
local t1 = os.clock()

gc_sweep()
local m3 = mem_kb()

local mem_no = mem_kb()
collectgarbage("collect")
local mem_full = mem_kb()
print(string.format(
  "table_stress time=%.6fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB mem_peak=%.1fKB sum=%d N=%d R=%d",
  t1 - t0, mem_no - m0, mem_full - m0, peak - m0, sum, N, R))
