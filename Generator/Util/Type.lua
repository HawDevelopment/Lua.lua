--[[
    Type class
    HawDevelopment
    28/09/2021
--]]

---@alias Type {Type: string}

local Type = {}
Type.__index = Type

local Types = {}

---@param name string
function Type.new(name)
    local self = setmetatable({}, Type)
    
    self.Type = name
    
    if not Types[name] then
        Types[name] = self
    end
    return self
end

function Type.Get(name)
    return Types[name] or error("No type with name: " .. name)
end

function Type:Is(other)
    if type(other) == "string" then
        return self.Type == other
    elseif type(other) == "table" then
        return self.Type == other.Type
    end
end

function Type:rep()
    return "Type(" .. self.Type .. ")"
end

return setmetatable(Type, {
    __call = function (_, ...)
        return Type.new(...)
    end
})