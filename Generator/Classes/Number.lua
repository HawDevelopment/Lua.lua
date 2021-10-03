--[[
    Number class
    HawDevelopment
    02/10/2021
--]]

local Number = {}
Number.__index = Number

Number.OPERATOR_TO_METHOD = {
    ["+"] = "Add",
    ["-"] = "Subtract",
    ["*"] = "Multiply",
    ["/"] = "Divide",
    ["^"] = "Power",
    ["%"] = "Modulo",
}

function Number.new(value, pos)
    local self = setmetatable({}, Number)
    
    self.Value = value
    self.Pos = pos
    
    return self
end

function Number:Handle(other, method)
    if other:Is("Number") then
        local result = self[method](self, other.Value)
        return Number.new(result, self.Pos)
    end
    return error("Expected number")
end

--#region Methods

function Number:Add(other)
    return self.Value + other
end

function Number:Subtract(other)
    return self.Value - other
end

function Number:Divide(other)
    return self.Value / other
end

function Number:Multiply(other)
    return self.Value * other
end

function Number:Power(other)
    return self.Value ^ other
end

function Number:Modulo(other)
    return self.Value % other
end

--#endregion

return Number