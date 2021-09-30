--[[
    Error class
    HawDevelopment
    28/09/2021
--]]

---@alias Error {Name: string, Message: string, Pos: Position | nil}

local Error = {}
Error.__index = Error

function Error.new(name, message, pos)
    local self = setmetatable({}, Error)
    
    self.Name = name
    self.Message = message
    self.Pos = pos
    
    return self
end

function Error:rep()
    return self.Name .. ": " .. self.Message .. (self.Pos ~= nil and " at " .. self.Pos.Counter or "")
end

return setmetatable(Error, {
    __call = function (_, ...)
        return Error.new(...)
    end
})