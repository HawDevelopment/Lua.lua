--[[
    Parser head class
    HawDevelopment
    28/09/2021
--]]


local ParserHead = {}
ParserHead.__index = ParserHead

function ParserHead.new(tokens)
    local self = setmetatable({
        Tokens = tokens,
        Pos = 1
    }, ParserHead)
    
    return self
end

function ParserHead:Next()
    return self.Tokens[self.Pos + 1]
end

function ParserHead:GoNext()
    self.Pos = self.Pos + 1
    return self.Tokens[self.Pos]
end

function ParserHead:Current()
    return self.Tokens[self.Pos]
end

-- DANGER Will not check if its negativ!!
function ParserHead:Last()
    return self.Tokens[self.Pos - 1]
end

-- DANGER Will not check if its negativ!!
function ParserHead:GoLast()
    self.Pos = self.Pos - 1
    return self.Tokens[self.Pos]
end

function ParserHead:Consume(toconsum)
    local cur = self.Tokens[self.Pos]
    if cur and cur.Value == toconsum then
        self.Pos = self.Pos + 1
        return true
    end
    return false
end

function ParserHead:Expect(toexpect, err)
    err = err or "Unexpected char"
    if not self:Consume(toexpect) then
        error(err, 2)
    end
end

function ParserHead:GoNextAndConsume(toconsum)
    self:GoNext()
    local ret = self:Consume(toconsum)
    return ret
end

function ParserHead:GoNextAndExpect(toexpect, err)
    self:GoNext()
    self:Expect(toexpect, err)
end

return ParserHead