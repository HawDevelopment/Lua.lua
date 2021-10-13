--[[
    Lexer head class
    HawDevelopment
    28/09/2021
--]]

local function ToTable(str)
    local tab = {}
    for i = 1, #str do
        tab[#tab+1] = str:sub(i, i)
    end
    return tab
end


local LexerHead = {}
LexerHead.__index = LexerHead

---@param tab string | table
---@param pos Position
function LexerHead.new(tab, pos)
    local self = setmetatable({
        Thing = tab,
        Pos = pos
    }, LexerHead)
    
    if type(tab) == "string" then
        self.Thing = ToTable(tab)
    end
    
    return self
end

function LexerHead:Next()
    return self.Thing[self.Pos.Counter + 1]
end

function LexerHead:GoNext()
    return self.Thing[self.Pos:Next()]
end

function LexerHead:Current()
    return self.Thing[self.Pos.Counter]
end

-- DANGER Will not check if its negativ!!
function LexerHead:Last()
    return self.Thing[self.Pos.Counter - 1]
end

-- DANGER Will not check if its negativ!!
function LexerHead:GoLast()
    return self.Thing[self.Pos:Last()]
end

function LexerHead:Consume(toconsum)
    local cur, ret = self.Thing[self.Pos.Counter], false
    if type(cur) == "table" then
        ret = cur.Value == toconsum
    else
        ret = cur == toconsum
    end
    if ret then
        self.Pos.Counter = self.Pos.Counter + 1
    end
    return ret
end

function LexerHead:Expect(toexpect, err)
    err = err or "Unexpected char"
    if not LexerHead:Consume(toexpect) then
        error(err)
    end
end

return LexerHead