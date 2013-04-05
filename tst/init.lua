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
		end
	end
end

function test_id()
	local tree = htmlparser.parse([[
		<n id="4711">
			<m id="1174"></m>
		</n>
	]])
	assert_equal(1, #tree.nodes, "top level")
	assert_equal("n", tree("#4711"):tolist()[1].name, "#4711")
	assert_equal("m", tree("#1174"):tolist()[1].name, "#1174")
end

function test_class()
	local tree = htmlparser.parse([[
		<n class="one">
			<n class="two">
				<n class="three"></n>
			</n>
		</n>
		<n class="two three"></n>
		<n ssalc="four"></n>
	]])
	assert_equal(3, #tree.nodes, "top level")
	assert_equal(1, tree(".one"):len(), ".one")
	assert_equal(2, tree(".two"):len(), ".two")
	assert_equal(2, tree(".three"):len(), ".three")
	assert_equal(1, tree(".two.three"):len(), ".two.three")
	assert_equal(0, tree(".four"):len(), ".four")
end

function test_attr()
	local tree = htmlparser.parse([[
		<n a1 a2= a3='' a4=""
			a5='a"5"' a6="a'6'" a7='#.[] :()' a8='|*+-=?$^%&/'
			a9=a9
		a10></n>
	]])
	assert_equal(1, #tree.nodes, "top level")
	local n = tree.nodes[1]
	assert(tree("[a1]")[n], "a1")
	assert(tree("[a2]")[n], "a2")
	assert(tree("[a3]")[n], "a3")
	assert(tree("[a4]")[n], "a4")
	assert(tree("[a5]")[n], "a5")
	assert(tree("[a6]")[n], "a6")
	assert(tree("[a7]")[n], "a7")
	assert(tree("[a8]")[n], "a8")
	assert(tree("[a9]")[n], "a9")
	assert(tree("[a10]")[n], "a10")
end

function test_attr_equal()
	local tree = htmlparser.parse([[
		<n a1 a2= a3='' a4=""
			a5='a"5"' a6="a'6'" a7='#.[] :()' a8='|*+-=?$^%&/'
			a9=a9
		a10></n>
	]])
	assert_equal(1, #tree.nodes, "top level")
	local n = tree.nodes[1]
	assert(tree("[a1='']")[n], "a1=''")
	assert(tree("[a2='']")[n], "a2=''")
	assert(tree("[a3='']")[n], "a3=''")
	assert(tree("[a4='']")[n], "a4=''")
	assert(tree("[a5='a\"5\"']")[n], "a5='a\"5\"'")
	assert(tree("[a6=\"a'6'\"]")[n], "a6=\"a'6'\"")
	-- not these characters
	-- (because these have a special meaning as id, class, or attribute selector, hierarchy separator, or filter command)
	-- they can occur in the HTML, but not in a selector string
	-- assert(tree("[a7='#.[] :()']")[n], "a7='#.[] :()'")
	assert(tree("[a8='|*+-=?$^%&/']")[n], "a8='|*+-=?$^%&/'")
	assert(tree("[a9='a9']")[n], "a9='a9'")
	assert(tree("[a10='']")[n], "a10=''")
	assert(tree("[a10=]")[n], "a10=")
end

function test_attr_notequal()
	local tree = htmlparser.parse([[
		<n a1="a1"></n>
		<n a1="a2"></n>
		<n a1></n>
		<n></n>
	]])
	assert_equal(4, #tree.nodes, "top level")
	assert_equal(3, tree("[a1!='a1']"):len(), "a1!='a1'")
	assert_equal(4, tree("[a1!='b1']"):len(), "a1!='b1'")
	assert_equal(3, tree("[a1!='']"):len(), "a1!=''")
	assert_equal(3, tree("[a1!=]"):len(), "a1!=")
end

function test_attr_prefix_start_end()
	local tree = htmlparser.parse([[
		<n a1="en-gb"></n>
		<n a1="en-us"></n>
		<n a1="en"></n>
		<n a1="enen"></n>
		<n></n>
	]])
	assert_equal(5, #tree.nodes, "top level")
	assert_equal(3, tree("[a1|='en']"):len(), "a1|='en'")
	assert_equal(4, tree("[a1^='en']"):len(), "a1^='en'")
	assert_equal(2, tree("[a1$='en']"):len(), "a1$='en'")
end

function test_attr_word()
	local tree = htmlparser.parse([[
		<n a1="one two three"></n>
		<n a1="three four five"></n>
		<n a1></n>
		<n></n>
	]])
	assert_equal(4, #tree.nodes, "top level")
	assert_equal(1, tree("[a1~='two']"):len(), "a1~='two'")
	assert_equal(2, tree("[a1~='three']"):len(), "a1~='three'")
	assert_equal(1, tree("[a1~='four']"):len(), "a1~='four'")
end

function test_attr_contains()
	local tree = htmlparser.parse([[
		<n a1="one"></n>
		<n a1="one two three"></n>
		<n a1="three four five"></n>
		<n a1=""></n>
		<n a1></n>
		<n></n>
	]])
	assert_equal(6, #tree.nodes, "top level")
	assert_equal(2, tree("[a1*='one']"):len(), "a1*='one'")
	assert_equal(2, tree("[a1*='t']"):len(), "a1*='t'")
	assert_equal(1, tree("[a1*='f']"):len(), "a1*='f'")
	assert_equal(5, tree("[a1*='']"):len(), "a1*=''")
	assert_equal(5, tree("[a1*=]"):len(), "a1*=")
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
	assert_equal(8, tree("parent child"):len(), 'parent child')
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
	assert_equal(4, tree("parent > child"):len(), 'parent > child')
end

function test_not()
	local tree = htmlparser.parse([[
		<n a1="1" a2>
			<m a1="1"></m>
		</n>
		<n a2></n>
	]])
	assert_equal(2, #tree.nodes, "top level")
	assert_equal(1, tree(":not([a1=1])"):len(), ":not([a1=1])")
	assert_equal(1, tree(":not([a2])"):len(), ":not([a2])")
	assert_equal(1, tree(":not(n)"):len(), ":not(n)")
	assert_equal(2, tree(":not(m)"):len(), ":not(m)")
end

function test_combine()
	local tree = htmlparser.parse([[
		<e class="a b c" a="2-two">
			<n b="123"></n>
			<n id="123" b="321">
				<n b="222"></n>
				<n class="c" b="345"></n>
			</n>
		</e>
		<n b="222"></n>
	]])
	assert_equal(2, #tree.nodes, "top level")
	assert_equal(2, tree("e.c:not([a|='1']) > n[b*='2']"):len(), "e.c:not([a|='1']) > n[b*='2']")
	assert_equal(3, tree("e.c:not([a|='1'])   n[b*='2']"):len(), "e.c:not([a|='1'])   n[b*='2']")
	assert_equal(1, tree("#123 .c[b]"):len(), "#123 .c[b]")
end
