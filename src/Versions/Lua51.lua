--[[
    Lua 5.1
    HawDevelopment
    28/09/2021
--]]

local Token = require("src.Generator.Util.Token")
local ToTable = require("src.Versions.Util.ToTable")

local INDENTATION = ToTable("   ")
local IDEN = ToTable("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
local NUM = ToTable("0123456789")
local NEW_LINE = Token("NewLine", "\n", "NewLine")
local HEX = ToTable("0123456789abcdefABCDEF")

local SYMBOLS = ToTable("+-*/^#%,(){}[]")
local OPERATORS = ToTable("+-*/^#%")
local EQUALITY = ToTable("=><~")

local KEYWORDS = ToTable("and break do else elseif end false for function if in local nil not or repeat return then true until while", nil, "[^%s]+")

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