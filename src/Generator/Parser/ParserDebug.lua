--[[
    Parser debug
    HawDevelopment
    29/09/2021
--]]

local Node = require("src.Generator.Util.Node")
local LexerHead = require("src.Generator.Util.LexerHead")
local Position = require("src.Generator.Util.Position")
local ParserUtil = require("src.Generator.Parser.ParserClassDebug")

return function(tokens, version)
    version = require("src.Versions.Lua51")
    local starttime = os.clock()
    
    local nodes = {}
    local pos = Position(0)
    local head = LexerHead.new(tokens, pos)
    local util = ParserUtil.new(tokens, head)
    
    while head:GoNext() do
        nodes[#nodes+1] = util:Walk()
    end
    
    print("Real Parser Time: " .. os.clock() - starttime)
    print(util.Timer:rep())
    
    return nodes
end