local A = require('test.spec_assert')

-- __index / __newindex
do
  local base = {x=1}
  local t = {}
  setmetatable(t, { __index = base, __newindex = function(tbl, k, v) rawset(base, k, v*2) end })
  A.eq(t.x, 1)
  t.y = 3
  A.eq(base.y, 6)
end

-- __eq and tostring
do
  local mt = {}
  mt.__eq = function(a, b) return a.v == b.v end
  mt.__tostring = function(a) return 'V'..a.v end
  local a = setmetatable({v=10}, mt)
  local b = setmetatable({v=10}, mt)
  local c = setmetatable({v=11}, mt)
  A.truthy(a == b)
  A.falsy(a == c)
  A.eq(tostring(a), 'V10')
end

