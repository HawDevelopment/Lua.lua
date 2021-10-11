--[[
    Basics
    HawDevelopment
    10/10/2021
--]]

local test = require("test.test")
local Token = require("src.Generator.Util.Token")
local Node = require("src.Generator.Util.Node")

return {
    test("Name", nil, {
        Node.new("Identifier", "Name", "Identifier")
    }),
    
    test("print()", nil, {
        Node.new("CallExpression", {
            name = "print",
            args = { }
        }, "Expression")
    }),
    
    test("print(1 + 1)", nil, {
        Node.new("CallExpression", {
            name = "print",
            args = {
                Node.new("BinaryOperation", {
                    op = "+",
                    left = Token.new("IntegerLiteral", "1", "Number"),
                    right = Token.new("IntegerLiteral", "1", "Number")
                    
                })
            }
        })
    }),
    
    test("print(tab)", nil, {
        Node.new("CallExpression", {
            name = "print",
            args = {
                Node.new("Identifier", "tab", "Identifier")
            }
        }, "Expression")
    }),
}