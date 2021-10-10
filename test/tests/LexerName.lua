--[[
    Basics
    HawDevelopment
    10/10/2021
--]]

local test = require("test.test")
local Token = require("src.Generator.Util.Token")

return {
    test("Name", {
        Token.new("Name", "Name", "Identifier")
    }),
    
    test("local", {
        Token.new("local", "local", "Identifier")
    }),
    
    test("print()", {
        Token.new("print", "print", "Identifier"),
        Token.new("Symbol", "(", "Symbol"),
        Token.new("Symbol", ")", "Symbol")
    }),
    
    test("function()\n\t\nend", {
        Token.new("function", "function", "Identifier"),
        Token.new("Symbol", "(", "Symbol"),
        Token.new("Symbol", ")", "Symbol"),
        Token.new("end", "end", "Identifier"),
    }),
    
    test("print(tab)", {
        Token.new("print", "print", "Identifier"),
        Token.new("Symbol", "(", "Symbol"),
        Token.new("tab", "tab", "Identifier"),
        Token.new("Symbol", ")", "Symbol"),
    })
}