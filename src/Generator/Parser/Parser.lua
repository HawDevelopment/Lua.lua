--[[
    Parser
    HawDevelopment
    29/09/2021
--]]

local ParserHead = require("src.Generator.Parser.ParserHead")
local ParserUtil = require("src.Generator.Parser.ParserClass")

return function(tokens, version)
    version = require("src.Versions.Lua51")
    
    local head = ParserHead.new(tokens)
    local util = ParserUtil.new(tokens, head)
    
    return util:ParseChunk()
end