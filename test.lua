local htmlparser = require("htmlparser")

local io = require("io")
local file = io.input("./test.html")
local text = io.read("*a") file:close()

local root = htmlparser.parse(text)

-- print the tree
local function p(n)
  local space = string.rep("  ", n.level)
  local s = space .. n.name
  for i,v in ipairs(n.nodes) do
    s = s .. " nodes[" .. i .. "]=" .. v.name
  end
  for k,v in pairs(n.attributes) do
    s = s .. " " .. k .. "=[" .. v .. "]"
  end
  print(s)
  for i,v in ipairs(n.nodes) do
    p(v)
  end
end
p(root)

local function select( s )
  print ""
  print("->", s)
  local tags = root:select(s)
  for i,t in ipairs(tags.nodes) do
    print(t.name)
  end
  print(# tags.nodes)
end
select("*")
select("link")
select("#/contacts/4711")
select(".chapters")
select("[href]")
select("span.firstname")
select("ul[id]")

select("#/contacts/4711")
select("#/contacts/4711 *")
select("#/contacts/4711 .lastname")
select("body li[id]")

select("ul")
select("ul *")
select("ul > *")
select("body [class]")
select("body > [class]")

print("\nchapters")
local sel, chapters = root("ol.chapters > li"), {}
for _,v in ipairs(sel.nodes) do
  table.insert(chapters, v:getcontent())
end
-- print
for i,v in ipairs(chapters) do
  print(i, v)
end

print("\ncontacts")
local sel, contacts = root("ul.contacts > li")("span[class]"), {}
for _,v in ipairs(sel.nodes) do
  local id = v.parent.parent.id -- li > a > span
  contacts[id] = contacts[id] or {}
  contacts[id][v.classes[1]] = v:getcontent()
end
-- print
for k,v in pairs(contacts) do
  print(k)
  for fk,fv in pairs(v) do
    print(fk, fv)
  end
end

print("\nmicrodata")
local sel, scopes = root("[itemprop]"), {}
for _,prop in ipairs(sel.nodes) do
  if prop.attributes["itemscope"] then goto nextprop end
  local descendantscopes, scope = {}, prop
  while true do
    repeat
      scope = scope.parent
    until scope.attributes["itemscope"]
    if not scope.attributes["itemprop"] then break end
    table.insert(descendantscopes, 1, scope)
  end
  scopes[scope] = scopes[scope] or {}
  local entry = scopes[scope]
  for _,v in ipairs(descendantscopes) do
    entry[v] = entry[v] or {}
    entry = entry[v]
  end
  local k, v = prop.attributes["itemprop"], prop:getcontent()
  entry[k] = v
  ::nextprop::
end
-- print
local function printscope(node, table, level)
  level = level or 1
  local scopeprop = node.attributes["itemprop"] or ""
  print(string.rep("  ", level - 1) .. node.attributes["itemtype"], scopeprop)
  for prop,v in pairs(table) do
    if type(prop) == "table" then
      printscope(prop, v, level + 1)
    else
      print(string.rep("  ", level) .. prop .. "=[" .. v .. "]")
    end
  end
end
for node,table in pairs(scopes) do
  printscope(node, table)
end

local sel = root("[itemscope]:not([itemprop])")
for i,v in ipairs(sel.nodes) do
  print(v.name)
end

local sel = root("[href]:not(a)")
for i,v in ipairs(sel.nodes) do
  print(v.name)
end