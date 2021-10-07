--[[
    Parser
    HawDevelopment
    29/09/2021
--]]

local Node = require("src.Generator.Util.Node")
local LexerHead = require("src.Generator.Util.LexerHead")
local Position = require("src.Generator.Util.Position")
local ParserUtil = require("src.Generator.Util.ParserUtil")

return function(tokens, version)
    version = require("src.Versions.Lua51")
    
    local nodes = {}
    local pos = Position(0)
    local head = LexerHead.new(tokens, pos)
    local util = ParserUtil.new(tokens, head)
    
    while head:GoNext() do
        local token = head:Current()
        
        if token:Is("Keyword") and token.Value == "local" then
            nodes[#nodes + 1] = util:GetVariable()
        elseif token:Is("Identifier") then
            
            if head:Next().Value == "(" then
                -- Call expresion?
                
                nodes[#nodes + 1] = util:GetCallStatement()
            elseif head:Next().Value == "=" then
                
                nodes[#nodes + 1] = util:GetVariable()
            end
        else
            nodes[#nodes + 1] = util:GetExpr()
        end
    end
    
    return nodes
end