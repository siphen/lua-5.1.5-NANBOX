local M = {}

function M.eq(a, b, msg)
  if a ~= b then error((msg or "assert eq failed") .. string.format("; got=%s expected=%s", tostring(a), tostring(b)), 2) end
end

function M.truthy(v, msg)
  if not v then error(msg or "assert truthy failed", 2) end
end

function M.falsy(v, msg)
  if v then error(msg or "assert falsy failed", 2) end
end

return M

