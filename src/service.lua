--[[
    Service file
    HawDevelopment
    28/09/2021
--]]

local Lexer = require("src.Generator.Lexer.Lexer")
local Parser = require("src.Generator.Parser.Parser")
local Visitor = require("src.Generator.Visitor.Visitor")
local Compiler = require("src.Generator.Compiler.Compiler")
local Render = require("src.Generator.Render.Render")


return {
    Lex = Lexer,
    Parse = Parser,
    Visit = Visitor,
    Compile = Compiler,
    Render = Render,
}