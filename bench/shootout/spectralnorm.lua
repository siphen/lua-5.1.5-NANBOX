-- spectralnorm.lua (adapted)
-- Usage: lua spectralnorm.lua [N]

local N = tonumber(arg[1] or "100")

local function A(i, j)
  return 1.0 / (((i + j) * (i + j + 1) / 2 + i + 1))
end

local function Av(x, y)
  for i=1,N do
    local s = 0
    for j=1,N do s = s + A(i-1, j-1) * x[j] end
    y[i] = s
  end
end

local function Atv(x, y)
  for i=1,N do
    local s = 0
    for j=1,N do s = s + A(j-1, i-1) * x[j] end
    y[i] = s
  end
end

local function AtAv(x, y)
  local t = {}
  Av(x, t)
  Atv(t, y)
end

local function run()
  local u, v = {}, {}
  for i=1,N do u[i] = 1 end
  for i=1,10 do
    AtAv(u, v)
    AtAv(v, u)
  end
  local vBv, vv = 0, 0
  for i=1,N do
    vBv = vBv + u[i] * v[i]
    vv = vv + v[i] * v[i]
  end
  return math.sqrt(vBv / vv)
end

local peak=0; local function sample() local m=collectgarbage("count"); if m>peak then peak=m end end
collectgarbage(); collectgarbage(); local m0 = collectgarbage("count"); peak=m0
local t0 = os.clock()
local r = run(); sample()
local t1 = os.clock()
local mem_no = collectgarbage("count"); collectgarbage("collect"); local mem_full=collectgarbage("count")
print(string.format("spectralnorm N=%d result=%.9f time=%.3fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB",
  N, r, t1 - t0, mem_no - m0, mem_full - m0))
