local ElementNode = require("htmlparser.ElementNode")
local voidelements = require("htmlparser.voidelements")

local HtmlParser = {}

local function parse(text)
  local index = 0
  local root = ElementNode:new(index, text)

  local node, descend, tpos, opentags = root, true, 1, {}
  while true do
    local openstart, name
    openstart, tpos, name = string.find(root._text, 
      "<" ..     -- an uncaptured starting "<"
      "(%w+)" .. -- name = the first word, directly following the "<"
      "[^>]*>",  -- include, but not capture everything up to the next ">"
    tpos)
    if not name then break end
    index = index + 1
    local tag = ElementNode:new(index, name, node, descend, openstart, tpos)
    node = tag

    local tagst, apos = tag:gettext(), 1
    while true do
      local start, k, eq, quote, v
      start, apos, k, eq, quote = string.find(tagst, 
        "%s+" ..       -- some uncaptured space
        "([^%s=/>]+)" .. -- k = an unspaced string up to an optional "=" or the "/" or ">"
        "(=?)" ..      -- eq = the optional; "=", else ""
        "(['\"]?)",    -- quote = an optional "'" or '"' following the "=", or ""
      apos)
      if not k or k == "/>" or k == ">" then break end
      if eq == "=" then
        local pattern = "=([^%s>]*)"
        if quote ~= "" then
          pattern = quote .. "([^" .. quote .. "]*)" .. quote
        end
        start, apos, v = string.find(tagst, pattern, apos)
      end
      tag:addattribute(k, v or "")
    end

    if voidelements[string.lower(tag.name)] then
      descend = false
      tag:close()
    else
      opentags[tag.name] = opentags[tag.name] or {}
      table.insert(opentags[tag.name], tag)
    end

    local closeend = tpos
    while true do
      local closestart, closing, closename
      closestart, closeend, closing, closename = string.find(root._text, "[^<]*<(/?)(%w+)", closeend)
      if not closing or closing == "" then break end
      tag = table.remove(opentags[closename])
      closestart = string.find(root._text, "<", closestart)
      tag:close(closestart, closeend + 1)
      node = tag.parent
      descend = true
    end
  end

  return root
end
HtmlParser.parse = parse

return HtmlParser

