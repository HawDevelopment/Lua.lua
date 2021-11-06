--[[
    Basics
    HawDevelopment
    09/10/2021
--]]

local test = require("test.test")

local function MakeCallStatement(base, args)
    return { Name = "CallStatement", Value = { "CallExpression", Value = {
        base = base,
        args = args,
    }, Type = "Expression" }, Type = "Statement"}
end

local function MakeBinary(op, left, right)
    return { Name = "BinaryExpression", Value = {
        op = op,
        left = left,
        right = right
    }, Type = "Expression" }
end

return {
    test("print(1 + 1)", nil, {
        MakeCallStatement(
            { Name = "print", Value = "print", Type = "Identifier" },
            {
                MakeBinary(
                    { Name = "Operator", Value = "+", Type = "Operator" },
                    { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                    { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                )
            }
        )
    }),
    
    test("print(1 + 1 + 1)", nil, {
        MakeCallStatement(
            { Name = "print", Value = "print", Type = "Identifier" },
            {
                MakeBinary(
                    { Name = "Operator", Value = "+", Type = "Operator" },
                    MakeBinary(
                        { Name = "Operator", Value = "+", Type = "Operator" },
                        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                        { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                    ),
                    { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                )
            }
        )
    }),
    
    test("print(1 * 1)", nil, {
        MakeCallStatement(
            { Name = "print", Value = "print", Type = "Identifier" },
            {
                MakeBinary(
                    { Name = "Operator", Value = "*", Type = "Operator" },
                    { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                    { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                )
            }
        )
    }),
    
    test("print(1 * 1 ^ 1)", nil, {
        MakeCallStatement(
            { Name = "print", Value = "print", Type = "Identifier" },
            {
                MakeBinary(
                    { Name = "Operator", Value = "*", Type = "Operator" },
                    { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                    MakeBinary(
                        { Name = "Operator", Value = "^", Type = "Operator" },
                        { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                        { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                    )
                )
            }
        )
    }),
    
    test("print(1 + 1 - 1 * 1 / 1 + (1 + 1) ^ 1)", nil, {
        MakeCallStatement(
            { Name = "print", Value = "print", Type = "Identifier" },
            {
                MakeBinary(
                    { Name = "Operator", Value = "+", Type = "Operator" },
                    MakeBinary(
                        { Name = "Operator", Value = "-", Type = "Operator" },
                        MakeBinary(
                            { Name = "Operator", Value = "+", Type = "Operator" },
                            { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                            { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                        ),
                        MakeBinary(
                            { Name = "Operator", Value = "/", Type = "Operator" },
                            MakeBinary(
                                { Name = "Operator", Value = "*", Type = "Operator" },
                                { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                                { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                            ),
                            { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                        )
                    ),
                    MakeBinary(
                        { Name = "Operator", Value = "^", Type = "Operator" },
                        MakeBinary(
                            { Name = "Operator", Value = "+", Type = "Operator" },
                            { Name = "IntegerLiteral", Value = "1", Type = "Number" },
                            { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                        ),
                        { Name = "IntegerLiteral", Value = "1", Type = "Number" }
                    )
                )
            }
        )
    }),
}