local A = require('test.spec_assert')

-- Goal: verify write barrier keeps newly-linked objects alive when referenced
-- from an old (long-lived) table.

collectgarbage(); collectgarbage()

-- Make an old table by surviving a collection
local t = {}
collectgarbage('collect')

-- Create a weak table to detect collection of child
local alive = setmetatable({}, {__mode='k'})

-- Link a fresh table into old table and drop strong ref
local c = {}
t.child = c
alive[c] = true
c = nil

-- If barrier works, child should survive because it's reachable from t
collectgarbage('collect')
local survived = 0
for k in pairs(alive) do survived = survived + 1 end
A.eq(survived, 1, 'barrier must keep child alive via old table link')

-- Now remove reference and child should be collected
t.child = nil
collectgarbage('collect')
local remained = 0
for k in pairs(alive) do remained = remained + 1 end
A.eq(remained, 0, 'child should be collectable after unlink')

