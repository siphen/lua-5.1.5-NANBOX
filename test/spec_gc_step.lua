local A = require('test.spec_assert')

-- Exercise incremental steps until a cycle finishes.
collectgarbage("collect")
local big = {}
for i=1,50000 do big[i] = {i} end
for i=1,25000 do big[i] = nil end

local finished = false
for _=1,10000 do
  local ok = collectgarbage('step', 50)
  if ok then finished = true; break end
end
A.truthy(finished, 'GC step should finish a cycle eventually')

