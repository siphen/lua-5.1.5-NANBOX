-- mandelbrot.lua (adapted from common LuaJIT benchmark)
-- Usage: lua mandelbrot.lua [N]

local N = tonumber(arg[1] or "1000")

local function run()
  local sum = 0
  local Cr = {}
  for i = 0, N-1 do
    Cr[i] = (2*i/N - 1.5)
  end
  for y = 0, N-1 do
    local Ci = (2*y/N - 1.0)
    for x = 0, N-1 do
      local Zr, Zi, Zr2, Zi2 = 0.0, 0.0, 0.0, 0.0
      local c = Cr[x]
      local i = 50
      repeat
        Zi = 2*Zr*Zi + Ci
        Zr = Zr2 - Zi2 + c
        Zr2 = Zr*Zr
        Zi2 = Zi*Zi
        i = i - 1
      until Zr2 + Zi2 > 4.0 or i == 0
      if i == 0 then sum = sum + 1 end
    end
  end
  return sum
end

local peak=0; local function sample() local m=collectgarbage("count"); if m>peak then peak=m end end
collectgarbage(); collectgarbage(); local m0 = collectgarbage("count"); peak=m0
local t0 = os.clock()
local r = run(); sample()
local t1 = os.clock()
local mem_no = collectgarbage("count"); collectgarbage("collect"); local mem_full=collectgarbage("count")
print(string.format("mandelbrot N=%d in_set=%d time=%.3fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB",
  N, r, t1 - t0, mem_no - m0, mem_full - m0))
