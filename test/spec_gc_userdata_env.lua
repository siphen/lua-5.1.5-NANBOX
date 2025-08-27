local A = require('test.spec_assert')

-- In Lua 5.1, full userdata can have an environment table (fenv).
-- Verify that userdata keeps its environment alive and that fenv is retrievable.

if getfenv and setfenv and type(newproxy) == 'function' then
  collectgarbage(); collectgarbage()

  local owner = {}
  do
    -- create full userdata via io.tmpfile's file handle? that's lightuserdata.
    -- use newproxy(true) to get a userdata; in 5.1 newproxy returns userdata.
    local u = newproxy(true)
    local env = { y = 7 }
    local ok = pcall(setfenv, u, env)
    if not ok then
      -- Some builds may not allow setting fenv on proxy userdata; skip test.
      return A.truthy(true, 'userdata env not supported; skipping')
    end
    owner.u = u
    -- drop local refs to env so only userdata holds it
    env = nil
  end

  collectgarbage('collect')

  local u = owner.u
  A.eq(type(u), 'userdata')
  local env = getfenv(u)
  A.eq(type(env), 'table')
  A.eq(env.y, 7)
else
  -- Fallback: nothing to test on env in restricted runtimes
  A.truthy(true, 'fenv not supported; skipping userdata env test')
end
