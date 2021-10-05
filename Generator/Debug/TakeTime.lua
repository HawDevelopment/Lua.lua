--[[
    Take time class
    HawDevelopment
    05/10/2021
--]]

local TakeTime = {}
TakeTime.__index = TakeTime


function TakeTime.new()
    local self = setmetatable({
        Nodes = {}
    }, TakeTime)
    
    return self
end

function TakeTime:Start()
    self.Start = os.clock()
end

function TakeTime:Stop(name)
    if self.Start then
        
        self:Add(name, os.clock() - self.Start)
        self.Start = nil
    else
        error("Tried to stop, but was never started")
    end
end

function TakeTime:Add(name, time)
    if not self.Nodes[name] then
        self.Nodes[name] = {
            Calls = 0,
            Time = 0
        }
    end
    self.Nodes[name].Calls = self.Nodes[name].Calls + 1
    self.Nodes[name].Time = self.Nodes[name].Time + time
end

function TakeTime:rep()
    local out = ""
    for name, node in pairs(self.Nodes) do
        out = out .. name:upper() .. " = " .. node.Time .. "s" .. " " .. node.Calls .. " calls" .. "\n"
    end
    return out
end

return TakeTime