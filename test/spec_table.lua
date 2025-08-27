local A = require('test.spec_assert')

-- basic set/get and next termination
do
  local t = {}
  for i=1,1000 do t[i] = i end
  for i=1,1000 do A.eq(t[i], i) end
  -- hash part
  for i=1,500 do t['k'..i] = i end
  -- next traversal must terminate and visit keys
  local count = 0
  local k
  while true do
    local nk, v = next(t, k)
    if nk == nil then break end
    count = count + 1
    k = nk
  end
  A.truthy(count >= 1000)
end

-- rehash and delete
do
  local t = {}
  for i=1,5000 do t[i] = i end
  for i=1,5000,2 do t[i] = nil end
  for i=2,5000,2 do A.eq(t[i], i) end
end

