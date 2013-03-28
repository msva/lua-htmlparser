#LuaRock "htmlparser"

Parse HTML text into a tree of elements with selectors

[1]: http://wscherphof.github.com/lua-set/
[2]: http://api.jquery.com/category/selectors/

##License
MIT; see `./doc/LICENSE`

##Install
Htmlparser is a listed [LuaRock](http://luarocks.org/repositories/rocks/). Install using [LuaRocks](http://www.luarocks.org/): `luarocks install htmlparser`

###Dependencies
Htmlparser depends on [Lua 5.2](http://www.lua.org/download.html), and on the ["set"][1] LuaRock, which is installed along automatically

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
Now, find sepcific contained elements by selecting:
```lua
local elements = root:select(selectorstring)
```
Or in shorthand:
```lua
local elements = root(selectorstring)
```
This wil return a [Set][1] of elements, all of which are of the same type as the root element, and thus support selecting as well, if ever needed:
```lua
for e in pairs(elements) do
	print(e.name)
	local subs = e(subselectorstring)
	for sub in pairs(subs) do
		print("", sub.name)
	end
end
```
The root element is a container for the top level elements in the parsed text, i.e. the `<html>` element in a parsed html document would be a child of the returned root element.

##Selectors
Supported selectors are a subset of [jQuery's selectors][2]:

- `"*"` all contained elements
- `"element"` elements with the given tagname
- `"#id"` elements with the given id attribute value
- `".class"` elements with the given classname in the class attribute
- `"[attribute]"` elements with an attribute of the given name
- `"[attribute='value']"` equals: elements with the given value for the attribute with the given name
- `"[attribute!='value']"` not equals: elements without an attribute of the given name, or with that attribute, but with a value that is different from the given value
- `"[attribute|='value']"` prefix: attribute's value is given value, or starts with given value, followed by a hyphen (`-`)
- `"[attribute*='value']"` contains: attribute's value contains given value
- `"[attribute~='value']"` word: attribute's value is a space-separated token, where one of the tokens is the given value
- `"[attribute^='value']"` starts with: attribute's value starts with given value
- `"[attribute$='value']"` ends with: attribute's value ends with given value
- `":not(selectorstring)"` elements not selected by given selector string
- `"ancestor descendant"` elements selected by the `descendant` selector string, that are a descendant of any element selected by the `ancestor` selector string
- `"parent > child"` elements selected by the `child` selector string, that are a child element of any element selected by the `parent` selector string

Selectors can be combined; e.g. `".class:not([attribute]) element.class"`

###Limitations
- Attribute values in selectors currently cannot contain any spaces, since space is interpreted as a delimiter between the `ancestor` and `descendant`, `parent` and `>`, or `>` and `child` parts of the selector
- Likewise, for the `parent > child` relation, the spaces before and after the `>` are mandatory
- `<!` elements are not parsed, including doctype and comments
- Textnodes are not seperate entries in the tree, so the content of `<p>line1<br />line2</p>` is plainly `"line1<br />line2"`

##Examples
See `./doc/samples.lua`

##Element type
All tree elements provide, apart from `:select` and `()`, the following accessors:

###Basic
- `.name` the element's tagname
- `.attributes` a table with keys and values for the element's attributes; `{}` if none
- `.id` the value of the element's id attribute; `nil` if not present
- `.classes` an array with the classes listed in element's class attribute; `{}` if none
- `:getcontent()` the raw text between the opening and closing tags of the element; `""` if none
- `.nodes` an array with the element's child elements, `{}` if none
- `.parent` the elements that contains this element; `root.parent` is `nil`

###Other
- `:gettext()` the raw text of the complete element, starting with `"<tagname"` and ending with `"/>"`
- `.level` how deep the element is in the tree; root level is `0`
- `.root` the root element of the tree; `root.root` is `root`
- `.deepernodes` a [Set][1] containing all elements in the tree beneath this element, including this element's `.nodes`; `{}` if none
- `.deeperelements` a table with a key for each distinct tagname in `.deepernodes`, containing a [Set][1] of all deeper element nodes with that name; `{}` in none
- `.deeperattributes` as `.deeperelements`, but keyed on attribute name
- `.deeperids` as `.deeperelements`, but keyed on id value
- `.deeperclasses` as `.deeperelements`, but keyed on class name
