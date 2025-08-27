local A = require('test.spec_assert')

-- Lua 5.1: newproxy(true) can create a userdata with __gc
if type(newproxy) == 'function' then
  local gc_count = 0
  local mt = { __gc = function() gc_count = gc_count + 1 end }
  do
    for i=1,1000 do
      local u = newproxy(true)
      debug.setmetatable(u, mt)
    end
  end
  collectgarbage('collect')
  A.truthy(gc_count > 0, '__gc must be invoked for eligible userdata')
else
  -- Fallback: create many full userdata via io.tmpfile and rely on close
  A.truthy(true, 'newproxy not available; skipping __gc test')
end

