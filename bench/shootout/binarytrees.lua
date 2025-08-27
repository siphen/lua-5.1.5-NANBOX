-- binarytrees.lua (adapted) -- measures tree allocations and checks
-- Usage: lua binarytrees.lua [N]

local N = tonumber(arg[1] or "14")

local function Node(left, right)
  return { left = left, right = right }
end

local function bottomUpTree(depth)
  if depth <= 0 then
    return Node(nil, nil)
  else
    depth = depth - 1
    return Node(bottomUpTree(depth), bottomUpTree(depth))
  end
end

local function itemCheck(t)
  if not t.left then return 1 end
  return 1 + itemCheck(t.left) + itemCheck(t.right)
end

local function run()
  local minDepth = 4
  local maxDepth = math.max(minDepth + 2, N)
  local stretchDepth = maxDepth + 1

  local stretch = bottomUpTree(stretchDepth)
  local check = itemCheck(stretch)
  stretch = nil

  local longLivedTree = bottomUpTree(maxDepth)

  local sum = 0
  for depth = minDepth, maxDepth, 2 do
    local iters = 2 ^ (maxDepth - depth + minDepth)
    for i = 1, iters do
      local t = bottomUpTree(depth)
      sum = sum + itemCheck(t)
    end
  end
  sum = sum + itemCheck(longLivedTree)
  return sum
end

local peak = 0
local function sample() local m=collectgarbage("count"); if m>peak then peak=m end end
collectgarbage(); collectgarbage(); local m0 = collectgarbage("count"); peak=m0
local t0 = os.clock()
local r = run()
local t1 = os.clock()
local mem_no = collectgarbage("count"); collectgarbage("collect"); local mem_full=collectgarbage("count")
print(string.format("binarytrees N=%d result=%d time=%.3fs mem_no_gc=%.1fKB mem_full_gc=%.1fKB",
  N, r, t1 - t0, mem_no - m0, mem_full - m0))
