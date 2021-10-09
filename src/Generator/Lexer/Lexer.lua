--[[
    Lexer debug
    HawDevelopment
    09/10/2021
--]]

local LexerHead = require("src.Generator.Util.LexerHead")
local Token = require("src.Generator.Util.Token")
local Position = require("src.Generator.Util.Position")
local LexerUtil = require("src.Generator.Lexer.LexerClass")

return function(source, version)
    version = require("src.Versions.Lua51")
    
    local pos = Position(0)
    local head = LexerHead.new(source, pos)
    local util = LexerUtil.new(source, head, version)
    
    util:Walk()
    
    return util.Tokens
end