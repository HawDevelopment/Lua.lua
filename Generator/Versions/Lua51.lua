--[[
    Lua 5.1
    HawDevelopment
    28/09/2021
--]]

local Token = require("Generator.Util.Token")
local Type = require("Generator.Util.Type")

-- Note: This is base error!
local Error = require("Generator.Util.BaseError")

local Operator = Type("Operator")

local Operators = {
    Token("Add", "+", Operator),
    Token("Subtract", "-", Operator),
    Token("Multiply", "*", Operator),
    Token("Divide", "/", Operator),
    Token("Modulus", "%", Operator),
    Token("Power", "^", Operator),
}

local Errors = {
    UnknownSymbol = Error("UnknownSymbol", "Unknown symbol \"%s\""),
}

return {
    Operators = Operators,
    Errors = Errors,
}