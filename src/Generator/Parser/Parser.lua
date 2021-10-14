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
    
    
    local pos = Position(1)
    local head = LexerHead.new(tokens, pos)
    local util = ParserUtil.new(tokens, head)
    
    return util:ParseChunk()
end