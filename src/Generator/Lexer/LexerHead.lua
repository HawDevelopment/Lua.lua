--[[
    Lexer head class
    HawDevelopment
    28/09/2021
--]]

local LexerHead = {}
LexerHead.__index = LexerHead

function LexerHead.new(string)
    local self = setmetatable({
        String = string,
        Line = 1,
        Column = 0,
        Pos = 0
    }, LexerHead)
    
    return self
end

function LexerHead:Next()
    return self.String:sub(self.Pos + 1, self.Pos + 1)
end

function LexerHead:GoNext()
    local toreturn = self.String:sub(self.Pos + 1, self.Pos + 1)
    if toreturn == "\n" then
        self.Line = self.Line + 1
        self.Column = 1
    else
        self.Column = self.Column + 1
    end
    self.Pos = self.Pos + 1
    return toreturn
end

function LexerHead:Current()
    return self.String:sub(self.Pos, self.Pos)
end

-- DANGER Will not check if its negativ!!
function LexerHead:Last()
    return self.String:sub(self.Pos - 1, self.Pos - 1)
end

-- I dont want to support GoLast

function LexerHead:CopyPos()
    return { Line = self.Line, Column = self.Colum, Pos = self.Pos }
end

return LexerHead