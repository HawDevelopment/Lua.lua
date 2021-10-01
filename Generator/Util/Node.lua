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

local function ToString(v, indent)
    if type(v) == "table" and v.Name and v.Type then
        return v:rep(indent)
    elseif type(v) == "table" then
        return TableToString(v)
    else
        return tostring(v)
    end
end

function TableToString(tab, indent)
    local str, stop = "{", (indent or "") .. "}"
    indent = indent and indent .. "\t" or "\t"
    if next(tab, 2) then
        str = str .. "\n"
        
        for k, v in ipairs(tab) do
            str = str .. indent .. k .. " = " .. ToString(v, indent) .. ",\n"
        end
    else
        local index, value = next(tab)
        str = str .. " " .. index .. " = " .. ToString(value, indent) .. " "
    end
    
    return str .. stop
end

function Node:rep(indent)
    return "Node(" .. self.Name .. ":"
        .. (type(self.Value) == "table" and TableToString(self.Value or {}, indent) or self.Value)
        .. ")" 
end

return setmetatable(Node, {
    __call = function (_, ...)
        return Node.new(...)
    end
})