-- vim: ft=lua ts=2

local esc = function(s) return string.gsub(s, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%" .. "%1") end
local str = tostring
local char = string.char
local err = function(s) io.stderr:write(s) end
local out = function(s) io.stdout:write(s) end

local ElementNode = require("htmlparser.ElementNode")
local voidelements = require("htmlparser.voidelements")

local HtmlParser = {}

local tpl_rep={
	-- Replace table for template engines syntax that can confuse us.
	-- Here we're replacing confusing sequences
	-- (things looking like tags, but appearing where tags can't)
	-- with definitelly invalid utf sequence, and later we'll replace them back
	["<%"] = char(208,209),
	["%>"] = char(209,208),
}
local tpl_rep_rev = {}


local function parse(text)
	local text=str(text)

	local limit = limit or htmlparser_looplimit or 1000

	local tpl = false
	for k,v in pairs(tpl_rep) do
		local mtc="("..esc(k)..")"
		if text:match(mtc) then
			tpl=true
			text=text:gsub(mtc,tpl_rep)
			tpl_rep_rev[v]=k;
		end
	end

	local index = 0
	local root = ElementNode:new(index, str(text))

	local node, descend, tpos, opentags = root, true, 1, {}
	while true do
		if index == limit then
			err("[HTMLParser] [ERR] Main loop reached loop limit ("..limit.."). Please, consider increasing it or check the code for errors")
			break
		end

		local openstart, name, textcontent
		openstart, tpos, name = root._text:find(
			"<" ..        -- an uncaptured starting "<"
			"([%w-]+)" .. -- name = the first word, directly following the "<"
			"[^>]*>",     -- include, but not capture everything up to the next ">"
		tpos)

		if not name then break end

		index = index + 1

		local tag = ElementNode:new(index, str(name), node, descend, openstart, tpos)
		node = tag

		local tagloop
		local tagst, apos = tag:gettext(), 1
		while true do
			if tagloop == limit then
				err("[HTMLParser] [ERR] tag parsing loop reached loop limit ("..limit.."). Please, consider increasing it or check the code for errors")
				break
			end

			local start, k, eq, quote, v
			start, apos, k, eq, quote = tagst:find(
				"%s+" ..         -- some uncaptured space
				"([^%s=/>]+)" .. -- k = an unspaced string up to an optional "=" or the "/" or ">"
				"(=?)" ..        -- eq = the optional; "=", else ""
				"(['\"]?)",      -- quote = an optional "'" or '"' following the "=", or ""
			apos)

			if not k or k == "/>" or k == ">" then break end

			if eq == "=" then
				local pattern = "=([^%s>]*)"
				if quote ~= "" then
					pattern = quote .. "([^" .. quote .. "]*)" .. quote
				end
				start, apos, v = tagst:find(pattern, apos)
			end

			v=v or ""

			if tpl then
				for rk,rv in pairs(tpl_rep_rev) do
					local mtc="("..esc(rk)..")"
					if text:match(mtc) then
						v = v:gsub(mtc,tpl_rep_rev)
					end
				end
			end

			tag:addattribute(k, v)
			tagloop = (tagloop or 0) + 1
		end

		if voidelements[tag.name:lower()] then
			descend = false
			tag:close()
		else
			opentags[tag.name] = opentags[tag.name] or {}
			table.insert(opentags[tag.name], tag)
			descend = true
		end

		local closeend = tpos
		local textend  = tpos
		local closingloop
		while true do
			if closingloop == limit then
				err("[HTMLParser] [ERR] tag closing loop reached loop limit ("..limit.."). Please, consider increasing it or check the code for errors")
				break
			end

			local closestart, closing, closename
			closestart, closeend, closing, closename = root._text:find("[^<]*<(/?)([%w-]+)", closeend)

			-- Feature: Wrap a text node in to current or parent node
			-- 新特征: 封装一个纯文本到一个当前或者父节点里
			-- TODO: &nbsp;... et. not handle yet, create a ElementNode function to handle them?
			-- TODO: 一些特殊字符还没有处理, 考虑创建一个ElementNode实例方法处理特殊字符?
			do
				local textstart
				textstart , textend, textcontent = root._text:find(">([^<]*)", closestart)
				textcontent = string.gsub(textcontent, "[\r\n%s]*", '')
				textcontent = string.gsub(textcontent, "&nbsp;", '')
				if textcontent ~= '' then
					index = index + 1
					local textTag = ElementNode:new(index, 'text', node, descend, textstart+1, textend)
					textTag:close()
				end
			end

			if not closing or closing == "" then break end

			tag = table.remove(opentags[closename] or {}) or tag -- kludges for the cases of closing void or non-opened tags
			closestart = root._text:find("<", closestart)
			tag:close(closestart, closeend + 1)
			node = tag.parent
			descend = true
			closingloop = (closingloop or 0) + 1
		end
	end

	if tpl then
		for k,v in pairs(tpl_rep_rev) do
			local mtc="("..esc(k)..")"
			if text:match(mtc) then
				root._text = root._text:gsub(mtc,tpl_rep_rev)
			end
		end
	end

	return root
end
HtmlParser.parse = parse

return HtmlParser

