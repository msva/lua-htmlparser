require("luarocks.loader")
-- Omit next line in actual module clients; it's only to support development of the module itself
package.path = "../src/?.lua;" .. package.path

local lunitx = require("lunitx")
module("html", lunitx.testcase, package.seeall)

local htmlparser = require("htmlparser")
local tree, sel

function test_void()
	tree = htmlparser.parse([[
		<p>
			<br>
			<br/>
			<br >
			<br />
		</p>
		<br>
		<br/>
		<br >
		<br />
	]])
	assert_equal(5, #tree.nodes, "top level")
	for _,n in ipairs(tree.nodes) do
		if n.name == "p" then
			assert_equal(4, #n.nodes, "deeper level")
		else
			assert_equal("br", n.name, "name")
			assert_equal(0, #n.attributes, "attributes")
			assert_equal("", n:getcontent(), "content")
		end
	end
end

function test_descendants()
	tree = htmlparser.parse([[
		<parent>1
			<child>1</child>
			<child>2
				<child>3</child>
			</child>
			<arbitrary>
				<child>4</child>
			</arbitrary>
		</parent>
		<parent>2
			<child>5</child>
			<child>6
				<child>7</child>
			</child>
			<arbitrary>
				<child>8</child>
			</arbitrary>
		</parent>
	]])
	sel = tree("parent child")
	assert_equal(8, sel:len(), 'parent child')
end

function test_children()
	tree = htmlparser.parse([[
		<parent>1
			<child>1</child>
			<child>2
				<child>not</child>
			</child>
			<arbitrary>
				<child>not</child>
			</arbitrary>
		</parent>
		<parent>2
			<child>3</child>
			<child>4
				<child>not</child>
			</child>
			<arbitrary>
				<child>not</child>
			</arbitrary>
		</parent>
	]])
	sel = tree("parent > child")
	assert_equal(4, sel:len(), 'parent > child')
end