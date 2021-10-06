--[[
    Parser debug
    HawDevelopment
    29/09/2021
--]]

local Node = require("Generator.Util.Node")
local LexerHead = require("Generator.Util.LexerHead")
local Position = require("Generator.Util.Position")
local ParserUtil = require("Generator.Debug.ParserUtilDebug")

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
    
    print(util.TakeTime:rep())
    
    return nodes
end