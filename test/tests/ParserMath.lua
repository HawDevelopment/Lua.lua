--[[
    Basics
    HawDevelopment
    09/10/2021
--]]

local test = require("test.test")
local Node = require("src.Generator.Util.Node")
local Token = require("src.Generator.Util.Token")

local function MakeCallStatement(base, args)
    return Node.new("CallStatement", Node.new("CallExpression", {
        base = base,
        args = args,
    }, "Expression"), "Statement")
end

local function MakeBinary(op, left, right)
    return Node.new("BinaryExpression", {
        op = op,
        left = left,
        right = right
    }, "Expression")
end

return {
    test("print(1 + 1)", nil, {
        MakeCallStatement(
            Node.new("Identifier", "print"),
            {
                MakeBinary(
                    Token.new("Operator", "+"),
                    Token.new("IntegerLiteral", "1", "Number"),
                    Token.new("IntegerLiteral", "1", "Number")
                )
            }
        )
    }),
    
    test("print(1 + 1 + 1)", nil, {
        MakeCallStatement(
            Node.new("Identifier", "print"),
            {
                MakeBinary(
                    Token.new("Operator", "+"),
                    MakeBinary(
                        Token.new("Operator", "+"),
                        Token.new("IntegerLiteral", "1", "Number"),
                        Token.new("IntegerLiteral", "1", "Number")
                    ),
                    Token.new("IntegerLiteral", "1", "Number")
                )
            }
        )
    }),
    
    test("print(1 * 1)", nil, {
        MakeCallStatement(
            Node.new("Identifier", "print"),
            {
                MakeBinary(
                    Token.new("Operator", "*"),
                    Token.new("IntegerLiteral", "1", "Number"),
                    Token.new("IntegerLiteral", "1", "Number")
                )
            }
        )
    }),
    
    test("print(1 * 1 ^ 1)", nil, {
        MakeCallStatement(
            Node.new("Identifier", "print"),
            {
                MakeBinary(
                    Token.new("Operator", "*"),
                    Token.new("IntegerLiteral", "1", "Number"),
                    MakeBinary(
                        Token.new("Operator", "^"),
                        Token.new("IntegerLiteral", "1", "Number"),
                        Token.new("IntegerLiteral", "1", "Number")
                    )
                )
            }
        )
    }),
    
    test("print(1 + 1 - 1 * 1 / 1 + (1 + 1) ^ 1)", nil, {
        MakeCallStatement(
            Node.new("Identifier", "print"),
            {
                MakeBinary(
                    Token.new("Operator", "+"),
                    MakeBinary(
                        Token.new("Operator", "-"),
                        MakeBinary(
                            Token.new("Operator", "+"),
                            Token.new("IntegerLiteral", "1", "Number"),
                            Token.new("IntegerLiteral", "1", "Number")
                        ),
                        MakeBinary(
                            Token.new("Operator", "/"),
                            MakeBinary(
                                Token.new("Operator", "*"),
                                Token.new("IntegerLiteral", "1", "Number"),
                                Token.new("IntegerLiteral", "1", "Number")
                            ),
                            Token.new("IntegerLiteral", "1", "Number")
                        )
                    ),
                    MakeBinary(
                        Token.new("Operator", "^"),
                        MakeBinary(
                            Token.new("Operator", "+"),
                            Token.new("IntegerLiteral", "1", "Number"),
                            Token.new("IntegerLiteral", "1", "Number")
                        ),
                        Token.new("IntegerLiteral", "1", "Number")
                    )
                )
            }
        )
    }),
}