--[[
    Table head class
    HawDevelopment
    28/09/2021
--]]


local TableHead = {}
TableHead.__index = TableHead

function TableHead.new(tab)
    local self = setmetatable({
        Table = tab,
        Pos = 0
    }, TableHead)
    
    return self
end

function TableHead:Next()
    return self.Table[self.Pos + 1]
end

function TableHead:GoNext()
    self.Pos = self.Pos + 1
    return self.Table[self.Pos]
end

function TableHead:Current()
    return self.Table[self.Pos]
end

-- DANGER Will not check if its negativ!!
function TableHead:Last()
    return self.Table[self.Pos - 1]
end

-- DANGER Will not check if its negativ!!
function TableHead:GoLast()
    self.Pos = self.Pos - 1
    return self.Table[self.Pos]
end

return TableHead