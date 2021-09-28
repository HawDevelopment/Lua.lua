--[[
    Keyword class
    HawDevelopment
    28/09/2021
--]]

local Keyword = {}
Keyword.__index = Keyword

local Keywords = {}

function Keyword.new(name, type)
    local self = setmetatable({}, Keyword)
    
    self.Name = name
    self.Type = type or ""
    
    if not Keywords[name] then
        Keywords[name] = self
    end
    return self
end

function Keyword:Is(other)
    if type(other) == "string" then
        return self.Name == other
    elseif type(other) == "table" then
        return self.Name == other.Name
    end
end

function Keyword:IsType(other)
    if type(other) == "string" then
        return self.Type == other
    elseif type(other) == "table" then
        return self.Type == other.Name
    end
end

return setmetatable(Keyword, {
    __call = function (_, ...)
        return Keyword.new(...)
    end
})