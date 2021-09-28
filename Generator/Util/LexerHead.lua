--[[
    Lexer head class
    HawDevelopment
    28/09/2021
--]]

local LexerHead = {}
LexerHead.__index = LexerHead

---@param thing any
---@param pos Position
function LexerHead.new(thing, pos)
    local self = setmetatable({}, LexerHead)
    
    self.Thing = thing
    self.Pos = pos
    self.GetAtPos = function(pos)
        if type(self.Thing) == "table" then
            return self.Thing[pos]
        elseif type(self.Thing) == "string" then
            return self.Thing:sub(pos, pos)
        end
    end
    
    return self
end

function LexerHead:Next()
    return self.GetAtPos(self.Pos:GetNext())
end

function LexerHead:GoNext()
    local to_ret = self:Next()
    self.Pos:Next()
    return to_ret
end

function LexerHead:Current()
    return self.GetAtPos(self.Pos:GetCurrent())
end

function LexerHead:Last()
    return self.GetAtPos(self.Pos:GetLast())
end

function LexerHead:GoLast()
    local to_ret = self:Last()
    self.Pos:Last()
    return to_ret
end

return LexerHead