--[[
    Base error class
    HawDevelopment
    28/09/2021
--]]

local Error = require("Generator.Util.Error")

local BaseError = {}
BaseError.__index = BaseError

function BaseError.new(name, message)
    local self = setmetatable({}, BaseError)
    
    self.Name = name
    self.Message = message
    
    return self
end

function BaseError:Format(pos, ...)
    return Error.new(self.Name, string.format(self.Message, ...), pos)
end

function BaseError:rep()
    return "BaseError(" .. self.Name .. ": " .. self.Message .. ")"
end

return setmetatable(BaseError, {
    __call = function (_, ...)
        return BaseError.new(...)
    end
})