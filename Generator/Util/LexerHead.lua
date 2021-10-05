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
    
    if type(self.Thing) == "string" then
        self.GetAtPos = function(pos)
            return self.Thing:sub(pos, pos)
        end
    elseif type(self.Thing) == "table" then
        self.GetAtPos = function(pos)
            return self.Thing[pos]
        end
    end
    
    return self
end

function LexerHead:Next()
    return self.GetAtPos(self.Pos.Counter + 1)
end

function LexerHead:GoNext()
    return self.GetAtPos(self.Pos:Next())
end

function LexerHead:Current()
    return self.GetAtPos(self.Pos.Counter)
end

-- DANGER Will not check if its negativ!!
function LexerHead:Last()
    return self.GetAtPos(self.Pos.Counter - 1)
end

-- DANGER Will not check if its negativ!!
function LexerHead:GoLast()
    return self.GetAtPos(self.Pos:Last())
end

return LexerHead