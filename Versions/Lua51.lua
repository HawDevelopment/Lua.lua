--[[
    Lua 5.1
    HawDevelopment
    28/09/2021
--]]

local Token = require("Generator.Util.Token")
local Type = require("Generator.Util.Type")
local ToTable = require("Versions.Util.ToTable")

-- Note: This is base error!
local Error = require("Generator.Util.BaseError")

local Operator = Type("Operator")
local Keyword = Type("Keyword")
local Identifier = Type("Identifier")
local Comma = Type("Comma")
local Dot = Type("Dot")
local Colon = Type("Colon")

local INDENTATION = ToTable("   ")
local IDEN = ToTable("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
local NUM = ToTable("0123456789")
local NEW_LINE = Token("NewLine", "\n", Type("NewLine"))
local HEX = ToTable("0123456789abcdefABCDEF")

local SYMBOLS = ToTable("+-*/^#%,(){}[]")
local OPERATORS = ToTable("+-*/^#%")
local EQUALITY = ToTable("=><~")

local KEYWORDS = {
    Token("If", "if", Keyword),
    Token("Else", "else", Keyword),
    Token("End", "end", Keyword),
    Token("True", "true", Keyword),
    Token("False", "false", Keyword),
}
return {
    SYMBOLS = SYMBOLS,
    OPERATORS = OPERATORS,
    EQUALITY = EQUALITY,
    KEYWORDS = KEYWORDS,
    INDENTATION = INDENTATION,
    NEW_LINE = NEW_LINE,
    NUM = NUM,
    IDEN = IDEN,
    HEX = HEX,
}