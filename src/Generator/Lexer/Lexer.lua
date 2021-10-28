--[[
    Lexer debug
    HawDevelopment
    09/10/2021
--]]

local LexerHead = require("src.Generator.Lexer.LexerHead")
local LexerUtil = require("src.Generator.Lexer.LexerClass")

return function(source, version)
    version = require("src.Versions.Lua51")
    
    local head = LexerHead.new(source)
    local util = LexerUtil.new(source, head, version)
    
    util:Walk()
    
    return util.Tokens
end