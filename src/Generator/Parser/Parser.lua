--[[
    Parser
    HawDevelopment
    29/09/2021
--]]

local Node = require("src.Generator.Util.Node")
local LexerHead = require("src.Generator.Util.LexerHead")
local Position = require("src.Generator.Util.Position")
local ParserUtil = require("src.Generator.Parser.ParserClass")

return function(tokens, version)
    version = require("src.Versions.Lua51")
    
    local nodes = {}
    local pos = Position(0)
    local head = LexerHead.new(tokens, pos)
    local util = ParserUtil.new(tokens, head)
    
    while head:GoNext() do
        nodes[#nodes+1] = util:Walk()
    end
    
    return nodes
end