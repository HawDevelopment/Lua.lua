--[[
    Interpreter
    HawDevelopment
    29/09/2021
--]]

local LexerHead = require("Generator.Util.LexerHead")
local Position = require("Generator.Util.Position")
local Token = require("Generator.Util.Token")
local Node = require("Generator.Util.Node")
local Type = require("Generator.Util.Type")

function EvalBinOp(op, a, b)
    a, b = tonumber(a), tonumber(b)
    local value = 0
    if op == "+" then
        value = a + b
    elseif op == "-" then
        value = a - b
    elseif op == "*" then
        value = a * b
    elseif op == "/" then
        value = a / b
    elseif op == "^" then
        value = a ^ b
    elseif op == "%" then
        value = a % b
    else
        error("Unknown operator: " .. tostring(value:rep()))
    end
    return value
end

return function (tokens)
    
    local head = LexerHead.new(tokens, Position.new(0))
    
    function GetBinOp(token)
        local op, left, right = unpack(token.Value)
        
        if left:Is("BinOp") then
            left = GetBinOp(left)
        end
        if right:Is("BinOp") then
            right = GetBinOp(right)
        end
        return Node.new("LiteralExpr", tostring(EvalBinOp(op.Value, left.Value, right.Value)), Type("LiteralExpr"))
    end
    
    while head:GoNext() ~= nil do
        local token = head:Current()
        
        if token:Is("BinOp") then
            
            local num = GetBinOp(token)
            print(num:rep())
        end
    end
end