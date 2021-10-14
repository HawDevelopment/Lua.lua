--[[
    Basics
    HawDevelopment
    10/10/2021
--]]

local test = require("test.test")
local Token = require("src.Generator.Util.Token")
local Node = require("src.Generator.Util.Node")

local function MakeCallStatement(base, args)
    return Node.new("CallStatement", Node.new("CallExpression", {
        base = base,
        args = args,
    }, "Expression"), "Statement")
end

return {
    test("print()", nil, {
        MakeCallStatement(
            Node.new("Identifier", "print"),
            {}
        )
    }),
    
    test("print(tab)", nil, {
        MakeCallStatement(
            Node.new("Identifier", "print"),
            {
                Node.new("Identifier", "tab", "Identifier")
            }
        )
    }),
}