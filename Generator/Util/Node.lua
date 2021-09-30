--[[
    Node class
    HawDevelopment
    29/09/2021
--]]


---@alias Node {Name: string, Value: table<any, any>, Type: Type, Pos: Position}

local Node = {}
Node.__index = Node

---@param name string
---@param value any
---@param type Type
---@param pos Position
---@return Node
function Node.new(name, value, type, pos)
    local self = setmetatable({}, Node)
    
    self.Name = name
    self.Value = value
    self.Type = type
    self.Pos = pos
    
    return self
end

---@param other string | Node
function Node:Is(other)
    if type(other) == "string" then
        return self.Name == other
    elseif type(other) == "table" and other.Name then
        return self.Name == other.Name
    end
end

---@param other string | Type | Node
function Node:IsType(other)
    if type(other) == "string" then
        return self.Type == other
    elseif type(other) == "table" then
        return self.Type == other.Type
    end
end

function Node:Copy()
    return Node.new(self.Name, self.Value, self.Type, self.Copy and self.Pos:Copy() or nil)
end

function Node:rep()
    return "Node(" .. self.Name .. ":" .. tostring(self.Type) .. ")" 
end

return setmetatable(Node, {
    __call = function (_, ...)
        return Node.new(...)
    end
})