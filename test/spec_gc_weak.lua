local A = require('test.spec_assert')

collectgarbage(); collectgarbage()

-- Weak keys: keys should disappear when no strong refs
do
  local Wk = setmetatable({}, {__mode='k'})
  do
    local k1 = {}
    local k2 = {}
    Wk[k1] = 'a'
    Wk[k2] = 'b'
  end
  collectgarbage('collect')
  local n=0; for _ in pairs(Wk) do n=n+1 end
  A.eq(n, 0, 'weak keys collected')
end

-- Weak values: values should disappear when no strong refs
do
  local Wv = setmetatable({}, {__mode='v'})
  local k1, k2 = {}, {}
  do
    local v1 = {}
    local v2 = {}
    Wv[k1] = v1
    Wv[k2] = v2
  end
  collectgarbage('collect')
  local n=0; for _,v in pairs(Wv) do if v then n=n+1 end end
  A.eq(n, 0, 'weak values collected')
end

-- Weak both: both keys and values can vanish
do
  local W = setmetatable({}, {__mode='kv'})
  do
    local k = {}
    local v = {}
    W[k] = v
  end
  collectgarbage('collect')
  local n=0; for _ in pairs(W) do n=n+1 end
  A.eq(n, 0, 'weak kv collected')
end

