--[[
    Comments
    HawDevelopment
    10/12/2021
--]]


local test = require("test.test")
local Token = require("src.Generator.Util.Token")

return {
    test("-- Hello", {}),
    
    test("1 + 1 -- Adds one and one", {
        Token.new("IntegerLiteral", "1", "Number"),
        Token.new("Operator", "+", "Operator"),
        Token.new("IntegerLiteral", "1", "Number")
    }),
    
    test("--[[ Hello, this is multiline!\n Or at least it should be! ]]", {}),
}