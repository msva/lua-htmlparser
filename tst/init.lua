require("luarocks.loader")
-- Omit next line in actual module clients; it's only to support development of the module itself
package.path = "../src/?.lua;" .. package.path

local lunitx = require("lunitx")
module("html", lunitx.testcase, package.seeall)

local htmlparser = require("htmlparser")

function test_void()
	local tree = htmlparser.parse([[
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
			assert_equal("", n:getcontent(), "content")
			for _ in pairs(n.attributes) do
				fail("should not have attributes")
			end
		end
	end
end

function test_attr()
	local tree = htmlparser.parse([[
		<n a1 a2= a3='' a4=""
			a5='a"5"' a6="a'6'" a7='a 7' a8='a=8'
			a9='en-gb' a10='enen'
			a11='one two three'
		></n>
		<m a9="en-us" a10></m>
		<l a9="enen" a11="three four five"></l>
	]])
	assert_equal(3, #tree.nodes, "top level")
	local n
	for _,v in ipairs(tree.nodes) do
		if v.name == "n" then n = v break end
	end
	assert(tree("[a1]")[n], "a1")
	assert(tree("[a2]")[n], "a2")
	assert(tree("[a3]")[n], "a3")
	assert(tree("[a4]")[n], "a4")
	assert(tree("[a5]")[n], "a5")
	assert(tree("[a6]")[n], "a6")
	assert(tree("[a7]")[n], "a7")
	assert(tree("[a8]")[n], "a8")
	assert(tree("[a1='']")[n], "a1=''")
	assert(tree("[a2='']")[n], "a2=''")
	assert(tree("[a3='']")[n], "a3=''")
	assert(tree("[a4='']")[n], "a4=''")
	assert(tree("[a5='a\"5\"']")[n], "a5='a\"5\"'")
	assert(tree("[a6=\"a'6'\"]")[n], "a6=\"a'6'\"")
	assert(tree("[a8='a=8']")[n], "a8='a=8'")
	assert_equal(1, tree("[a10=]"):len(), "a10=")
	assert_equal(1, tree("[a10='']"):len(), "a10=''")
	assert_equal(2, tree("[a10!='enen']"):len(), "a10!='enen'")
	assert_equal(2, tree("[a10!='']"):len(), "a10!=''")
	assert_equal(3, tree("[a0!='']"):len(), "a0!=''")
	assert_equal(0, tree("[a0='']"):len(), "a0=''")
	assert_equal(2, tree("[a9|='en']"):len(), "a9|='en'")
	assert_equal(3, tree("[a9^='en']"):len(), "a9^='en'")
	assert_equal(1, tree("[a9$='en']"):len(), "a9$='en'")
	assert_equal(1, tree("[a11~='two']"):len(), "a1~='two'")
	assert_equal(2, tree("[a11~='three']"):len(), "a1~='three'")
	assert_equal(1, tree("[a11~='four']"):len(), "a1~='four'")
	assert_equal(1, tree("[a7*='7']"):len(), "a7*='7'")
	assert_equal(1, tree("[a11*='f']"):len(), "a11*='f'")
end

function test_descendants()
	local tree = htmlparser.parse([[
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
		<arbitrary>
			<child>not</child>
		</arbitrary>
	]])
	local sel = tree("parent child")
	assert_equal(8, sel:len(), 'parent child')
end

function test_children()
	local tree = htmlparser.parse([[
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
		<arbitrary>
			<child>not</child>
		</arbitrary>
	]])
	local sel = tree("parent > child")
	assert_equal(4, sel:len(), 'parent > child')
end