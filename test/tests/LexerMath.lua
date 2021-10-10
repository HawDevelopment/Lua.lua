--[[
    Basics
    HawDevelopment
    09/10/2021
--]]

local test = require("test.test")
local Token = require("src.Generator.Util.Token")

return {
    test("1 + 1", {
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Operator", "+", "Operator"),
        Token.new("IntegerLiteral", "1", "Number")
    }),
    
    test("1 + 1 + 1", {
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Operator", "+", "Operator"),
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Operator", "+", "Operator"),
        Token.new("IntegerLiteral", "1", "Number")
    }),
    
    test("1 * 1", {
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Operator", "*", "Operator"),
        Token.new("IntegerLiteral", "1", "Number")
    }),
    
    test("1 * (1 + 1)", {
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Operator", "*", "Operator"),
        Token.new("Symbol", "(", "Symbol"),
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Operator", "+", "Operator"),
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Symbol", ")", "Symbol")
    }),
}