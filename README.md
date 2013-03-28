#LuaRock "htmlparser"

Parse HTML text into a tree of elements with selectors

##License
MIT; see `./doc/LICENSE`

##Usage
Start off with
```lua
require("luarocks.loader")
local htmlparser = require("htmlparser")
```
Then, parse some html:
```lua
local root = htmlparser.parse(htmlstring)
```
The input to parse may be the contents of a complete html document, or any valid html snippet, as long as all tags are correctly opened and closed.
Now, find specific elements by selecting:
```lua
local elements = root:select(selectorstring)
```
Or in shorthand:
```lua
local elements = root(selectorstring)
```
This wil return a Set of elements, all of which are of the same type as the root element, and thus support selecting as well, if ever needed:
```lua
for e in pairs(elements) do
	print(e.name)
	local subs = e(subselectorstring)
	for sub in pairs(subs) do
		print("", sub.name)
	end
end
```

##Selectors
- `"element"`
- `"#id"`
- `".class"`
- `"[attribute]"`
- `"[attribute=value]"`
- `"[attribute!=value]"`
- `"[attribute|=value]"`
- `"[attribute*=value]"`
- `"[attribute~=value]"`
- `"[attribute^=value]"`
- `"[attribute$=value]"`
- `":not(selector)"`
- `"ancestor descendant"`
- `"parent > child"`

Selectors can be combined; e.g. `".class:not([attribute]) element.class"`

###Limitations
- Attribute values in selectors currently cannot contain any spaces, since space is interpreted as a delimiter between the `ancestor` and `descendant`, `parent` and `>`, or `>` and `child` parts of the selector
- Likewise, for the `parent > child` relation, the spaces before and after the `>` are mandatory

##Examples
See `.doc/smples.lua`

##Element type
All tree elements provide, apart from `:select` and `()`, the following accessors:

###Basic
- `.name` = the element's tagname
- `.attributes` = a table with keys and values for the element's attributes; `{}` if none
- `.id` = the value of the element's id attribute; `nil` if not present
- `.classes` = an array with the classes listed in element's class attribute; `{}` if none
- `:getcontent()` = the raw text between the opening and closing tags of the element; `""` if none
- `.nodes` = an array with the element's child elements, `{}` if none
- `.parent` = the elements that contains this element; `root.parent` is `nil`

###Other
- `:gettext()` = the raw text of the complete element, starting with `"<tagname"` and ending with `"/>"`
- `.level` = how deep the element is in the tree; root level is `0`
- `.root` the root element of the tree; `root.root` is `root`
- `.deepernodes` = a Set containing all elements in the tree beneath this element, including this element's `.nodes`; `{}` if none
- `.deeperelements` = a table with a key for each distinct tagname in `.deepernodes`, containing a Set of all deeper element nodes with that name; `{}` in none
- `.deeperattributes` = as `.deeperelements`, but keyed on attribute name
- `.deeperids` = as `.deeperelements`, but keyed on id value
- `.deeperclasses` = as `.deeperelements`, but keyed on class name
