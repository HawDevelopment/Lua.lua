--[[
    Take time class
    HawDevelopment
    05/10/2021
--]]

local TakeTime = {}
TakeTime.__index = TakeTime

local INDENT = true

local INDENTS = {
    NAME = 16,
    TIME = 6,
    CALLS = 12,
    AVG = 13,
}

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

local function Round(num, div)
    local match = tostring(num * div):match("(%d-%.%d%d%d)%d*")
    return match
end

function TakeTime:rep()
    local out = ""
    for name, node in pairs(self.Nodes) do
        local time, calls, avg = tostring(node.Time) .. "s", tostring(node.Calls) .. " calls", Round(node.Time / node.Calls, 1000000) .. "us avrg"
        if INDENT then
            name = name .. string.rep(" ", math.max(INDENTS.NAME - #name, 0))
            time = time .. string.rep(" ", math.max(INDENTS.TIME - #time, 0))
            calls = calls .. string.rep(" ", math.max(INDENTS.CALLS - #calls, 0))
            avg = avg .. string.rep(" ", math.max(INDENTS.AVG - #avg, 0))
            
        end
        out = out .. string.format("%s = %s %s %s\n", name, time, calls, avg)
    end
    return out
end

return TakeTime