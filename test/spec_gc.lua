local A = require('test.spec_assert')

-- Stress GC with many short-lived objects
do
  collectgarbage(); collectgarbage()
  local t = {}
  for r=1,5 do
    for i=1,20000 do t[i] = {i} end
    for i=1,20000 do t[i] = nil end
    collectgarbage('collect')
  end
  A.truthy(true)
end

-- Ensure strings and tables survive GC
do
  local keep = {}
  for i=1,5000 do keep[i] = 's'..i end
  collectgarbage('collect')
  for i=1,5000,500 do A.eq(keep[i], 's'..i) end
end

