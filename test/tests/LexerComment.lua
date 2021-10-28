--[[
    Comments
    HawDevelopment
    10/12/2021
--]]


local test = require("test.test")

return {
    test("-- Hello", {}),
    
    test("1 + 1 -- Adds one and one", {
        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
        { Name = "Operator", Value = "+", Type = "Operator" },
        { Name = "IntegerLiteral", Value = "1", Type = "Number" }
    }),
    
    test("--[[ Hello, this is multiline!\n Or at least it should be! ]]", {}),
}