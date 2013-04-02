require("luarocks.loader")
-- Omit next line in actual module clients; it's only to support development of the module itself
package.path = "../src/?.lua;" .. package.path

local lunitx = require("lunitx")
module("html", lunitx.testcase, package.seeall)

local htmlparser = require("htmlparser")
local tree, sel

function test_descendants()
	tree = htmlparser.parse([[
		<parent>1
			<child>1.1</child>
			<child>1.2
				<child>1.2.1</child>
			</child>
		</parent>
		<parent>2
			<child>2.1</child>
			<child>2.2
				<child>2.2.1</child>
			</child>
		</parent>
	]])
	sel = tree("parent child")
	assert_equal(6, sel:len(), 'parent child')
end

function test_children()
	tree = htmlparser.parse([[
		<parent>1
			<child>1.1</child>
			<child>1.2
				<child>1.2.1</child>
			</child>
		</parent>
		<parent>2
			<child>2.1</child>
			<child>2.2
				<child>2.2.1</child>
			</child>
		</parent>
	]])
	sel = tree("parent > child")
	assert_equal(4, sel:len(), 'parent > child')
end