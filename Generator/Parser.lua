--[[
    Parser
    HawDevelopment
    29/09/2021
--]]

local Node = require("Generator.Util.Node")
local LexerHead = require("Generator.Util.LexerHead")
local Position = require("Generator.Util.Position")
local ParserUtil = require("Generator.Util.ParserUtil")

return function(tokens, version)
    version = require("Versions.Lua51")
    
    local nodes = {}
    local pos = Position(0)
    local head = LexerHead.new(tokens, pos)
    local util = ParserUtil.new(tokens, head)
    
    while head:GoNext() do
        local token = head:Current()
        
        if token:Is("Keyword") and token.Value == "local" then
            nodes[#nodes + 1] = util:GetVariable()
        elseif token:Is("Identifier") then
            local check = pos.Counter
            while head:Next() and (head:Next():Is("Identifier") or head:Next().Value == ",") do
                head:GoNext()
                check = check + 1
            end
            if head:Next() and head:Next().Value == "=" then
                nodes[#nodes + 1] = util:GetVariable()
            else
                nodes[#nodes + 1] = util:GetExpr()
            end
        elseif token:Is("Number") then
            nodes[#nodes + 1] = util:GetExpr()
        end
    end
    
    return nodes
end