--[[
    Service file
    HawDevelopment
    28/09/2021
--]]

local Lexer = require("src.Generator.Lexer.Lexer")
local Parser = require("src.Generator.Parser.Parser")

return {
    Lex = Lexer,
    Parse = Parser
}