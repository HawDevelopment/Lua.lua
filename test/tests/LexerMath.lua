--[[
    Basics
    HawDevelopment
    09/10/2021
--]]

local test = require("test.test")

return {
    test("1 + 1", {
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Operator", Value = "+", Type = "Operator" },
        { Name = "IntegerLiteral", Value = "1", Type = "Number" }
    }),
    
    test("1 + 1 + 1", {
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Operator", Value = "+", Type = "Operator" },
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Operator", Value = "+", Type = "Operator" },
        { Name = "IntegerLiteral", Value = "1", Type = "Number" }
    }),
    
    test("1 * 1", {
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Operator", Value = "*", Type = "Operator" },
        { Name = "IntegerLiteral", Value = "1", Type = "Number" }
    }),
    
    test("1 * (1 + 1)", {
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Operator", Value = "*", Type = "Operator" },
        { Name = "Symbol", Value = "(", Type = "Symbol" },
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Operator", Value = "+", Type = "Operator" },
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Symbol", Value = ")", Type = "Symbol" }
    }),
}