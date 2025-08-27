-- fannkuchredux.lua (adapted)
-- Usage: lua fannkuchredux.lua [N]

local N = tonumber(arg[1] or "10")

local function run()
  local p, q, s, sign = {}, {}, {}, 1
  for i=1,N do p[i]=i; q[i]=i; s[i]=i end
  local maxflips, checksum = 0, 0
  while true do
    local q1 = p[1]
    if q1 ~= 1 then
      for i=1,N do q[i]=p[i] end
      local flips = 0
      while q1 > 1 do
        local qq = {}
        for i=1,q1 do qq[i]=q[q1+1-i] end
        for i=1,q1 do q[i]=qq[i] end
        q1 = q[1]
        flips = flips + 1
      end
      if flips > maxflips then maxflips = flips end
      checksum = checksum + sign*flips
    end
    if sign == 1 then
      p[1], p[2] = p[2], p[1]
      sign = -1
    else
      p[2], p[3] = p[3], p[2]
      sign = 1
      for i=3,N do
        local sx = s[i]
        if sx ~= 1 then s[i]=sx-1; break end
        if i == N then
          return checksum, maxflips
        end
        s[i]=i
        local t = p[1]
        for j=1,i do p[j]=p[j+1] end
        p[i+1]=t
      end
    end
  end
end

local peak=0; local function sample() local m=collectgarbage("count"); if m>peak then peak=m end end
collectgarbage(); collectgarbage(); local m0 = collectgarbage("count"); peak=m0
local t0 = os.clock()
local checksum, maxflips = run(); sample()
local t1 = os.clock()
local mem_no = collectgarbage("count"); collectgarbage("collect"); local mem_full=collectgarbage("count")
print(string.format("fannkuchredux N=%d checksum=%d maxflips=%d time=%.3fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB",
  N, checksum, maxflips, t1 - t0, mem_no - m0, mem_full - m0))
