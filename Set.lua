local Set = {}
Set.mt = {__index = Set}
function Set:new(t)
  local instance = {}
  if type(t) == "table" then
    if #t > 0 then
      for _,v in ipairs(t) do
        instance[v] = true
      end
    else
      for k in pairs(t) do
        instance[k] = true
      end
    end
  else
    instance = {t}
  end
  return setmetatable(instance, Set.mt)
end

function Set:add(e)
  self[e] = true
end

function Set:remove(e)
  self[e] = nil
end

-- Union
Set.mt.__add = function (a, b)
  local res = Set:new()
  if getmetatable(a) ~= Set.mt then a = Set:new(a) end
  if getmetatable(b) ~= Set.mt then b = Set:new(b) end
  for k in pairs(a) do res[k] = true end
  for k in pairs(b) do res[k] = true end
  return res
end

-- Subtraction
Set.mt.__sub = function (a, b)
  local res = Set:new()
  if getmetatable(a) ~= Set.mt then a = Set:new(a) end
  if getmetatable(b) ~= Set.mt then b = Set:new(b) end
  for k in pairs(a) do res[k] = true end
  for k in pairs(b) do res[k] = nil end
  return res
end

-- Intersection
Set.mt.__mul = function (a, b)
  local res = Set:new()
  if getmetatable(a) ~= Set.mt then a = Set:new(a) end
  if getmetatable(b) ~= Set.mt then b = Set:new(b) end
  for k in pairs(a) do
    res[k] = b[k]
  end
  return res
end

-- String representation
Set.mt.__tostring = function (set)
  local s = "{"
  local sep = ""
  for k in pairs(set) do
    s = s .. sep .. k
    sep = ", "
  end
  return s .. "}"
end

function Set:len()
  local num = 0
  for _ in pairs(self) do
    num = num + 1
  end
  return num
end

function Set:tolist()
  local res = {}
  for k in pairs(self) do
    table.insert(res, k)
  end
  return res
end

return Set