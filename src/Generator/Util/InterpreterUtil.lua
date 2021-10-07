--[[
    Interpreter Util
    HawDevelopment
    02/10/2021
--]]

local InterpreterUtil = {}
InterpreterUtil.__index = InterpreterUtil


function InterpreterUtil.new(nodes, head)
    local self = setmetatable({}, InterpreterUtil)
    
    self.Nodes = nodes
    self.Head = head
    self.Pos = head.Pos
    
    return self
end

function InterpreterUtil:GetNextNode()
    
end

function InterpreterUtil:Destroy()
    for key, _ in pairs(self) do
        self[key] = nil
    end
end


return InterpreterUtil