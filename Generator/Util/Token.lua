--[[
    Token class
    HawDevelopment
    28/09/2021
--]]

---@alias Token {Name: string, Type: string | nil, Value: any, Pos: Position}

local Token = {}
Token.__index = Token

---@param name string
---@param value any
---@param type integer
---@param pos Position
---@return Token
function Token.new(name, value, type, pos)
    local self = setmetatable({}, Token)
    
    self.Name = name
    self.Value = value
    self.Type = type
    self.Pos = pos
    
    return self
end

---@param other string | Token
function Token:Is(other)
    if type(other) == "string" then
        return self.Name == other
    elseif type(other) == "table" and other.Name then
        return self.Name == other.Name
    end
end

---@param other string | Type | Token
function Token:IsType(other)
    if type(other) == "string" then
        return self.Type == other
    elseif type(other) == "table" then
        return self.Type == other.Type
    end
end

function Token:Copy()
    return Token.new(self.Name, self.Value, self.Type, self.Copy and self.Pos:Copy() or nil)
end

function Token:rep()
    return "Token(" .. self.Name .. ":" .. tostring(self.Value) .. ")" 
end

return setmetatable(Token, {
    __call = function (_, ...)
        return Token.new(...)
    end
})