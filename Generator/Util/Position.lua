--[[
    Position class
    HawDevelopment
    28/09/2021
--]]

---@alias Position {Counter: number}

local Position = {}
Position.__index = Position

---@param counter number
function Position.new(counter)
    local self = setmetatable({}, Position)
    
    self.Counter = counter
    
    return self
end

function Position:GetNext()
    return self.Counter + 1
end

function Position:Next()
    self.Counter = self.Counter + 1
    return self.Counter
end

function Position:GetCurrent()
    return self.Counter
end

function Position:GetLast()
    return math.max(self.Counter - 1, 1)
end

function Position:Last()
    self.Counter = self.Counter - 1
    return self.Counter
end

function Position:Copy()
    return Position.new(self.Counter)
end

function Position:rep()
    return "Position(" .. self.Counter .. ")" 
end

return setmetatable(Position, {
    __call = function (_, ...)
        return Position.new(...)
    end
})