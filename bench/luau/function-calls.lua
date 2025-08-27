-- function-calls.lua (Luau-style microbench: calls/closures)
-- Usage: lua function-calls.lua [N]

local N = tonumber(arg[1] or "2000000")

local function inc(x) return x + 1 end
local function run()
  local s = 0
  for i=1,N do s = inc(s) end
  local function add(a,b) return a+b end
  for i=1,N,2 do s = add(s, 2) end
  return s
end

local peak=0; local function sample() local m=collectgarbage("count"); if m>peak then peak=m end end
collectgarbage(); collectgarbage(); local m0 = collectgarbage("count"); peak=m0
local t0 = os.clock()
local r = run(); sample()
local t1 = os.clock()
local mem_no = collectgarbage("count"); collectgarbage("collect"); local mem_full=collectgarbage("count")
print(string.format("luau:function-calls N=%d res=%d time=%.3fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB",
  N, r, t1 - t0, mem_no - m0, mem_full - m0))
