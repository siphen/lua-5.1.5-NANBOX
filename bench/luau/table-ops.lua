-- table-ops.lua (Luau-style microbench: property/array ops)
-- Usage: lua table-ops.lua [N]

local N = tonumber(arg[1] or "200000")

local function run()
  local t = {}
  for i=1,N do t[i] = i end
  for i=1,N,3 do t[i] = t[i] + 1 end
  local sum = 0
  for i=1,N do sum = sum + (t[i] or 0) end
  local o = {}
  for i=1, N do o.x = i; o.y = i*2; sum = sum + (o.x + o.y) end
  return sum
end

local peak=0; local function sample() local m=collectgarbage("count"); if m>peak then peak=m end end
collectgarbage(); collectgarbage(); local m0 = collectgarbage("count"); peak=m0
local t0 = os.clock()
local r = run(); sample()
local t1 = os.clock()
local mem_no = collectgarbage("count"); collectgarbage("collect"); local mem_full=collectgarbage("count")
print(string.format("luau:table-ops N=%d sum=%d time=%.3fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB",
  N, r, t1 - t0, mem_no - m0, mem_full - m0))
