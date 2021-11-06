--[[
    Basics
    HawDevelopment
    10/10/2021
--]]

local test = require("test.test")

return {
    test("Name", {
        { Name = "Name", Value = "Name", Type = "Identifier" }
    }),
    
    test("local", {
        { Name = "local", Value = "local", Type = "Identifier" }
    }),
    
    test("print()", {
        { Name = "print", Value = "print", Type = "Identifier" },
        { Name = "Symbol", Value = "(", Type = "Symbol" },
        { Name = "Symbol", Value = ")", Type = "Symbol" }
    }),
    
    test("function()\n\t\nend", {
        { Name = "function", Value = "function", Type = "Identifier" },
        { Name = "Symbol", Value = "(", Type = "Symbol" },
        { Name = "Symbol", Value = ")", Type = "Symbol" },
        { Name = "end", Value = "end", Type = "Identifier" },
    }),
    
    test("print(tab)", {
        { Name = "print", Value = "print", Type = "Identifier" },
        { Name = "Symbol", Value = "(", Type = "Symbol" },
        { Name = "tab", Value = "tab", Type = "Identifier" },
        { Name = "Symbol", Value = ")", Type = "Symbol" },
    })
}