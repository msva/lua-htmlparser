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

local sel, chapters = root("ol.chapters > li"), {}
for _,v in ipairs(sel.nodes) do
  table.insert(chapters, v:getcontent())
end
print("\nchapters")
for i,v in ipairs(chapters) do
  print(i, v)
end

local sel, contacts = root("ul.contacts > li")("span[class]"), {}
for _,v in ipairs(sel.nodes) do
  local id = v.parent.parent.id -- li > a > span
  contacts[id] = contacts[id] or {}
  contacts[id][v.classes[1]] = v:getcontent()
end
print("\ncontacts")
for k,v in pairs(contacts) do
  print(k)
  for fk,fv in pairs(v) do
    print(fk, fv)
  end
end

print("\nmicrodata")
local sel, scopes = root("[itemscope]"), {}
for i,v in ipairs(sel.nodes) do
  local type = v.attributes["itemtype"]
  if not v.attributes["itemprop"] then
    scopes[type] = scopes[type] or {}
    local item = {}
      local sel = sel("[itemprop]")
      for i,v in ipairs(sel.nodes) do
        -- TODO
        print("prop", v.attributes["itemprop"])
      end
    table.insert(scopes[type], item)
  end
end



