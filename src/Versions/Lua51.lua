--[[
    Lua 5.1
    HawDevelopment
    28/09/2021
--]]

local ToTable = require("src.Versions.Util.ToTable")

local INDENTATION = ToTable("   ")
local IDEN = ToTable("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
local NUM = ToTable("0123456789")
local HEX = ToTable("0123456789abcdefABCDEF")

local SYMBOLS = ToTable("+-*/^#%,(){}[]")
local OPERATORS = ToTable("+-*/^#%")
local EQUALITY = ToTable("=><~")

local EQUALITY_OPERATORS = ToTable("== ~=", nil, "[^%s]+")
local COMPARISON_OPERATORS = ToTable("< > <= >=", nil, "[^%s]+")
local LOGICAL_OPERATORS = ToTable("and or", nil, "[^%s]+")

local KEYWORDS = ToTable("and break do else elseif end false for function if in local nil not or repeat return then true until while", nil, "[^%s]+")
local BOOLEAN = ToTable("true false", nil, "[^%s]+")

return {
    SYMBOLS = SYMBOLS,
    OPERATORS = OPERATORS,
    EQUALITY = EQUALITY,
    KEYWORDS = KEYWORDS,
    BOOLEAN = BOOLEAN,
    INDENTATION = INDENTATION,
    NUM = NUM,
    IDEN = IDEN,
    HEX = HEX,
    
    EQUALITY_OPERATORS = EQUALITY_OPERATORS,
    COMPARISON_OPERATORS = COMPARISON_OPERATORS,
    LOGICAL_OPERATORS = LOGICAL_OPERATORS
}