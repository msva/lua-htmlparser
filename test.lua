local HtmlParser = require("HtmlParser")

local io = require("io")
local file = io.input("./test.html")
local text = io.read("*a") file:close()

local root = HtmlParser.parse(text)

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
  for i,t in ipairs(tags) do
    print(t.name)
  end
  print(# tags)
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

local sel, chapters = root:select("ol.chapters > li"), {}
for i,v in ipairs(sel) do
  table.insert(chapters, v:getcontent())
end
print("\nchapters")
for i,v in ipairs(chapters) do
  print(i, v)
end

local sel, contacts = root:select("ul.contacts > li"), {}
for i,v in ipairs(sel) do
  local c = {}
  for fi,fv in ipairs(v:select("span[class]")) do
    c[fv.classes[1]] = fv:getcontent()
  end
  contacts[v.id] = c
end
print("\ncontacts")
for k,v in pairs(contacts) do
  print(k)
  for fk,fv in pairs(v) do
    print(fk, fv)
  end
end
