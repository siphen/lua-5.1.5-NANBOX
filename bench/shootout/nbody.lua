-- nbody.lua (adapted) -- simulates bodies, reports energy
-- Usage: lua nbody.lua [STEPS]

local STEPS = tonumber(arg[1] or "200000")

local pi = math.pi
local sqrt = math.sqrt

local bodies = {
  { x=0, y=0, z=0, vx=0, vy=0, vz=0, mass=4*pi*pi },
  { x=4.84143144246472090e+00, y=-1.16032004402742839e+00, z=-1.03622044471123109e-01,
    vx=1.66007664274403694e-03*365.24, vy=7.69901118419740425e-03*365.24, vz=-6.90460016972063023e-05*365.24, mass=9.54791938424326609e-04*4*pi*pi },
  { x=8.34336671824457987e+00, y=4.12479856412430479e+00, z=-4.03523417114321381e-01,
    vx=-2.76742510726862411e-03*365.24, vy=4.99852801234917238e-03*365.24, vz=2.30417297573763929e-05*365.24, mass=2.85885980666130812e-04*4*pi*pi },
  { x=1.28943695621391310e+01, y=-1.51111514016986312e+01, z=-2.23307578892655734e-01,
    vx=2.96460137564761618e-03*365.24, vy=2.37847173959480950e-03*365.24, vz=-2.96589568540237556e-05*365.24, mass=4.36624404335156298e-05*4*pi*pi },
  { x=1.53796971148509165e+01, y=-2.59193146099879641e+01, z=1.79258772950371181e-01,
    vx=2.68067772490389322e-03*365.24, vy=1.62824170038242295e-03*365.24, vz=-9.51592254519715870e-05*365.24, mass=5.15138902046611451e-05*4*pi*pi },
}

local function advance(dt)
  for i=1,#bodies do
    local bi = bodies[i]
    for j=i+1,#bodies do
      local bj = bodies[j]
      local dx = bi.x - bj.x
      local dy = bi.y - bj.y
      local dz = bi.z - bj.z
      local d2 = dx*dx + dy*dy + dz*dz
      local dist = sqrt(d2)
      local mag = dt / (d2 * dist)
      local mix = dx * mag
      local miy = dy * mag
      local miz = dz * mag
      bi.vx = bi.vx - mix * bj.mass
      bi.vy = bi.vy - miy * bj.mass
      bi.vz = bi.vz - miz * bj.mass
      bj.vx = bj.vx + mix * bi.mass
      bj.vy = bj.vy + miy * bi.mass
      bj.vz = bj.vz + miz * bi.mass
    end
  end
  for i=1,#bodies do
    local b = bodies[i]
    b.x = b.x + dt * b.vx
    b.y = b.y + dt * b.vy
    b.z = b.z + dt * b.vz
  end
end

local function energy()
  local e = 0.0
  for i=1,#bodies do
    local b = bodies[i]
    e = e + 0.5 * b.mass * (b.vx*b.vx + b.vy*b.vy + b.vz*b.vz)
    for j=i+1,#bodies do
      local c = bodies[j]
      local dx = b.x - c.x
      local dy = b.y - c.y
      local dz = b.z - c.z
      e = e - (b.mass * c.mass) / sqrt(dx*dx + dy*dy + dz*dz)
    end
  end
  return e
end

local function run()
  local e0 = energy()
  for i=1,STEPS do advance(0.01) end
  local e1 = energy()
  return e0, e1
end

local peak=0; local function sample() local m=collectgarbage("count"); if m>peak then peak=m end end
collectgarbage(); collectgarbage(); local m0 = collectgarbage("count"); peak=m0
local t0 = os.clock()
local e0, e1 = run(); sample()
local t1 = os.clock()
local mem_no = collectgarbage("count"); collectgarbage("collect"); local mem_full=collectgarbage("count")
print(string.format("nbody steps=%d e0=%.9f e1=%.9f time=%.3fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB",
  STEPS, e0, e1, t1 - t0, mem_no - m0, mem_full - m0))
