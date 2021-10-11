--[[
    Basics
    HawDevelopment
    09/10/2021
--]]

local test = require("test.test")
local Node = require("src.Generator.Util.Node")
local Token = require("src.Generator.Util.Token")


return {
    test("1 + 1", nil, {
        Node.new("BinaryOperation", {
            op = "+",
            left = Token.new("IntegerLiteral", "1", "Number"),
            right = Token.new("IntegerLiteral", "1", "Number")
        }, "Operation")
    }),
    
    test("1 + 1 + 1", nil, {
        Node.new("BinaryOperation", {
            op = "+",
            left = Node.new("BinaryOperation", {
                op = "+",
                left = Token.new("IntegerLiteral", "1", "Number"),
                right = Token.new("IntegerLiteral", "1", "Number")
            }),
            right = Token.new("IntegerLiteral", "1", "Number"),
        }, "Operation")
    }),
    
    test("1 * 1", nil, {
        Node.new("BinaryOperation", {
            op = "*",
            left = Token.new("IntegerLiteral", "1", "Number"),
            right = Token.new("IntegerLiteral", "1", "Number")
        }, "Operation")
    }),
    
    test("1 * 1 ^ 1", nil, {
        Node.new("BinaryOperation", {
            op = "*",
            left = Token.new("IntegerLiteral", "1", "Number"),
            right = Node.new("BinaryOperation", {
                op = "^",
                left = Token.new("IntegerLiteral", "1", "Number"),
                right = Token.new("IntegerLiteral", "1", "Number")
            })
        }, "Operation")
    }),
    
    test("1 + 1 - 1 * 1 / 1 + (1 + 1) ^ 1", nil, {
        Node.new("BinaryOperation", {
            op = "+",
            left = Node.new("BinaryOperation", {
                op = "-",
                left = Node.new("BinaryOperation", {
                    op = "+",
                    left = Token.new("IntegerLiteral", "1", "Number"),
                    right = Token.new("IntegerLiteral", "1", "Number")
                }, "Operation"),
                right = Node.new("BinaryOperation", {
                    op = "/",
                    left = Node.new("BinaryOperation", {
                        op = "*",
                        left = Token.new("IntegerLiteral", "1", "Number"),
                        right = Token.new("IntegerLiteral", "1", "Number")
                    }, "Operation"),
                    right = Token.new("IntegerLiteral", "1", "Number")
                }, "Operation")
            }),
            right = Node.new("BinaryOperation", {
                op = "^",
                left = Node.new("BinaryOperation", {
                    op = "+",
                    left = Token.new("IntegerLiteral", "1", "Number"),
                    right = Token.new("IntegerLiteral", "1", "Number")
                }, "Operation"),
                right = Token.new("IntegerLiteral", "1", "Number"),
            }, "Operation")
        }, "Operation")
    }),
}