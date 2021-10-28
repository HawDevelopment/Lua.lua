--[[
    Visitor head class
    HawDevelopment
    28/09/2021
--]]


local VisitorHead = {}
VisitorHead.__index = VisitorHead

function VisitorHead.new(statements)
    local self = setmetatable({
        Stats = statements,
        Pos = 0
    }, VisitorHead)
    
    return self
end

function VisitorHead:Next()
    return self.Stats[self.Pos + 1]
end

function VisitorHead:GoNext()
    self.Pos = self.Pos + 1
    return self.Stats[self.Pos]
end

function VisitorHead:Current()
    return self.Stats[self.Pos]
end

-- DANGER Will not check if its negativ!!
function VisitorHead:Last()
    return self.Stats[self.Pos - 1]
end

-- DANGER Will not check if its negativ!!
function VisitorHead:GoLast()
    self.Pos = self.Pos - 1
    return self.Stats[self.Pos]
end

return VisitorHead