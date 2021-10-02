--[[
    Parser
    HawDevelopment
    29/09/2021
--]]

local Node = require("Generator.Util.Node")
local Type = require("Generator.Util.Type")
local LexerHead = require("Generator.Util.LexerHead")
local Position = require("Generator.Util.Position")
local ParserUtil = require("Generator.Util.ParserUtil")

local IGNORE_WHITESPACE = true

local function BinOp(op, left, right)
    return Node("BinOp", {op, left, right}, Type("BinOp"))
end

local function LiteralExpr(value)
    return Node("LiteralExpr", value, Type("LiteralExpr"))
end

return function(tokens, version)
    version = require("Versions.Lua51")
    
    local nodes = {}
    local pos = Position(0)
    local head = LexerHead.new(tokens, pos)
    local util = ParserUtil.new(tokens, head)
    
    while head:GoNext() do
        if head:Current():Is("Number") then
            nodes[#nodes+1] = util:GetExpr()
        end
    end
    
    return nodes
end