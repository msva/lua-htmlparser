package = "htmlparser"
version = "0.1.1-1"
source = {
  url = "git://github.com/wscherphof/lua-htmlparser.git",
  branch = "v0.1.1"
}
description = {
  summary = "Parse HTML text into a tree of elements with selectors",
  detailed = [[
    Call parse() to build up a tree of element nodes. Each node in the tree, including the root node that is returned by parse(), supports a basic set of jQuery-like selectors. Or you could walk the tree by hand.
  ]],
  homepage = "http://wscherphof.github.io/lua-htmlparser/",
  license = "MIT"
}
dependencies = {
  "lua >= 5.2",
  "set >= 0.1",
  "lunitx >= 0.6"
}
build = {
  type = "builtin",
  copy_directories = {"doc", "tst"},
  modules = {
    htmlparser = "src/htmlparser.lua",
    ["htmlparser.ElementNode"] = "src/htmlparser/ElementNode.lua",
    ["htmlparser.voidelements"] = "src/htmlparser/voidelements.lua"
  }
}