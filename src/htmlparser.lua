-- vim: ft=lua ts=2 sw=2

local esc = function(s) return string.gsub(s, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%" .. "%1") end
local str = tostring
local char = string.char
local err = function(s) io.stderr:write(s) end
local out = function(s) io.stdout:write(s) end

local ElementNode = require("htmlparser.ElementNode")
local voidelements = require("htmlparser.voidelements")

local HtmlParser = {}

local tpr = {
	-- Here we're replacing confusing sequences
	-- (things looking like tags, but appearing where tags can't)
	-- with definitelly invalid utf sequence, and later we'll replace them back
	["<"] = char(208,209,208,209),
	[">"] = char(209,208,209,208),
}

local function parse(text,limit)
	local text=str(text)

	local limit = limit or htmlparser_looplimit or 1000

	local tpl = false

	local function g(id,...)
		local arg={...}
		arg[id]=tpr[arg[id]]
		tpl=true
		return table.concat(arg)
	end

	text = text
		:gsub(
			"(<)"..
			"([^>]-)"..
			"(<)",
			function(...)return g(3,...)end
		):gsub(
			"("..tpr["<"]..")"..
			"([^%w%s])"..
			"([^%2]-)"..
			"(%2)"..
			"(>)"..
			"([^>]-)"..
			"(>)",
			function(...)return g(5,...)end
		):gsub(
			[=[(['"])]=]..
			[=[([^'">%s]-)]=]..
			"(>)"..
			[=[([^'">%s]-)]=]..
			[=[(['"])]=],
			function(...)return g(3,...)end
		)

	local index = 0
	local root = ElementNode:new(index, str(text))

	local node, descend, tpos, opentags = root, true, 1, {}
	while true do
		if index == limit then
			err("[HTMLParser] [ERR] Main loop reached loop limit ("..limit.."). Please, consider increasing it or check the code for errors")
			break
		end

		local openstart, name
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
				pattern = "=([^%s>]*)"
				if quote ~= "" then
					pattern = quote .. "([^" .. quote .. "]*)" .. quote
				end
				start, apos, v = tagst:find(pattern, apos)
			end

			v=v or ""

			if tpl then
				for rk,rv in pairs(tpr) do
						v = v:gsub(rv,rk)
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
		end

		local closeend = tpos
		local closingloop
		while true do
			if closingloop == limit then
				err("[HTMLParser] [ERR] tag closing loop reached loop limit ("..limit.."). Please, consider increasing it or check the code for errors")
				break
			end

			local closestart, closing, closename
			closestart, closeend, closing, closename = root._text:find("[^<]*<(/?)([%w-]+)", closeend)

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
		for k,v in pairs(tpr) do
			root._text = root._text:gsub(v,k)
		end
	end

	return root
end
HtmlParser.parse = parse

return HtmlParser

