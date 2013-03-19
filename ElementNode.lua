local Set = require "Set"

local ElementNode = {}
ElementNode.mt = {__index = ElementNode}
function ElementNode:new(nameortext, node, descend, openstart, openend)
  local instance = {
    name = nameortext,
    level = 0,
    parent = nil,
    root = nil,
    nodes = {},
    _openstart = openstart, _openend = openend,
    _closestart = openstart, _closeend = openend,
    attributes = {},
    id = nil,
    classes = {},
    deepernodes = Set:new(),
    deeperelements = {}, deeperattributes = {}, deeperids = {}, deeperclasses = {}
  }
  if not node then
    instance.name = "root"
    instance.root = instance
    instance._text = nameortext
    local length = string.len(nameortext)
    instance._openstart, instance._openend = 1, length
    instance._closestart, instance._closeend = 1, length
  elseif descend then
    instance.root = node.root
    instance.parent = node
    instance.level = node.level + 1
    table.insert(node.nodes, instance)
  else
    instance.root = node.root
    instance.parent = node.parent
    instance.level = node.level
    table.insert(node.parent.nodes, instance)
  end
  return setmetatable(instance, ElementNode.mt)
end

function ElementNode:gettext()
  return string.sub(self.root._text, self._openstart, self._closeend)
end

function ElementNode:getcontent()
  return string.sub(self.root._text, self._openend + 1, self._closestart - 1)
end

function ElementNode:addattribute(k, v)
  self.attributes[k] = v
  if string.lower(k) == "id" then
    self.id = v
  end
  -- class attribute contains "space-separated tokens", each of which we'd like quick access to
  if string.lower(k) == "class" then
    for class in string.gmatch(v, "%S+") do
      table.insert(self.classes, class)
    end
  end
end

local function insert(list, name, node)
  if not list[name] then
    list[name] = Set:new()
  end
  list[name]:add(node)
end

function ElementNode:close(closestart, closeend)
  if closestart and closeend then
    self._closestart, self._closeend = closestart, closeend
  end
  -- inform hihger level nodes about this element's existence in their branches
  local node = self
  while true do
    node = node.parent
    if not node then break end
    node.deepernodes:add(self)
    insert(node.deeperelements, self.name, self)
    for k in pairs(self.attributes) do
      insert(node.deeperattributes, k, self)
    end
    if self.id then
      insert(node.deeperids, self.id, self)
    end
    for _,v in ipairs(self.classes) do
      insert(node.deeperclasses, v, self)
    end
  end
end

function ElementNode:select(s)
  if not s or type(s) ~= "string" then return {} end
  local subjects = Set:new({self})
  local resultset
  local childrenonly
  for part in string.gmatch(s, "%S+") do
    if part == ">" then childrenonly = true goto nextpart end
    resultset = Set:new()
    for subject in pairs(subjects) do
      local init = subject.deepernodes
      if childrenonly then init = Set:new(subject.nodes) childrenonly = false end
      resultset = resultset + init
    end
    if part == "*" then goto nextpart end
    for t, w in string.gmatch(part, "([%[#%.]?)([^%[%]#%.]+)") do
      if t == "" then resultset = resultset * self.deeperelements[w]
      elseif t == "[" then resultset = resultset * self.deeperattributes[w]
      elseif t == "#" then resultset = resultset * self.deeperids[w]
      elseif t == "." then resultset = resultset * self.deeperclasses[w]
      end
    end
    subjects = Set:new(resultset)
    ::nextpart::
  end
  return resultset:tolist()
end

return ElementNode