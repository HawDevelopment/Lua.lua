--[[
    Basics
    HawDevelopment
    10/10/2021
--]]

local test = require("test.test")

local function MakeCallStatement(base, args)
    return { Name = "CallStatement", Value = { "CallExpression", Value = {
        base = base,
        args = args,
    }, Type = "Expression" }, Type = "Statement"}
end

return {
    test("print()", nil, {
        MakeCallStatement(
            { Name = "print", Value = "print", Type = "Identifier" },
            {}
        )
    }),
    
    test("print(tab)", nil, {
        MakeCallStatement(
            { Name = "print", Value = "print", Type = "Identifier" },
            {
                { Name = "tab", Value = "tab", Type = "Identifier" }
            }
        )
    }),
}