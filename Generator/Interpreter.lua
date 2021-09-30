--[[
    Interpreter
    HawDevelopment
    29/09/2021
--]]

local LexerHead = require("Generator.Util.LexerHead")
local Position = require("Generator.Util.Position")
local Token = require("Generator.Util.Token")

return function (tokens)
    
    local head = LexerHead.new(tokens, Position.new(0))
    
    while head:GoNext() ~= nil do
        local token = head:Current()
        
        if token:Is("BinOp") then
            local op = token.Value[1]
            local val1, val2 = tonumber(token.Value[2].Value), tonumber(token.Value[3].Value)
            local value
            if op == "+" then
                value = val1 + val2
            elseif op == "-" then
                value = val1 - val2
            elseif op == "*" then
                value = val1 * val2
            elseif op == "/" then
                value = val1 / val2
            elseif op == "^" then
                value = val1 ^ val2
            elseif op == "%" then
                value = val1 % val2
            else
                error("Unknown operator: " .. value)
            end
            print(value)
        end
    end
end