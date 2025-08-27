local A = require('test.spec_assert')

-- Build a large object graph (chain) and validate collection after unlinking root
collectgarbage('collect')

local N = 10000
local head = {id=1}
local cur = head
local alive = setmetatable({}, {__mode='k'})
alive[head] = true
for i=2,N do
  local node = {id=i}
  alive[node] = true
  cur.next = node
  cur = node
end

-- Count reachable via weak table (should be N)
local n1 = 0; for _ in pairs(alive) do n1 = n1 + 1 end
A.eq(n1, N, 'all nodes alive before unlink')

-- Unlink root
head = nil; cur = nil
collectgarbage('collect')

local n2 = 0; for _ in pairs(alive) do n2 = n2 + 1 end
A.eq(n2, 0, 'all nodes collected after unlink')

