--[[
    Render class
    HawDevelopment
    11/03/2021
--]]

local TableHead = require("src.Generator.Util.TableHead")

local StartAssembly = "section .text\nglobal _main\n\n_main:\n\tpush ebp\n\tmov ebp, esp\n"
local EndAssembly = "section .data\nprint_number db '%i', 0xA, 0\ntostring_format db '%d', 0\nconcat_format db '%s%s', 0\n"

local RenderClass = {}
RenderClass.__index = RenderClass

function RenderClass.new(compiled, head)
    local self = setmetatable({}, RenderClass)
    
    self.File = {
        Start = StartAssembly,
        Function = "",
        End = EndAssembly,
    }
    
    self.Nodes = compiled
    self.Head = head or TableHead.new(compiled)
    
    return self
end

local function GetHash(cur)
    return tostring(cur):sub(8, -1)
end
function RenderClass:_add(pos, str)
    self.File[pos] = self.File[pos] .. str
end
function RenderClass:_strict(passed, isstrict)
    if passed and isstrict then
        error("Cannot use strict here!", 2)
    end
end

function RenderClass:Text(cur, isstrict)
    self:_strict(isstrict, false)
    return cur.Value
end
function RenderClass:Local(cur, isstrict)
    self:_strict(isstrict, false)
    return cur.Value
end
function RenderClass:Param(cur, isstrict)
    self:_strict(isstrict, false)
    return cur.Value
end
function RenderClass:Register(cur, isstrict)
    self:_strict(isstrict, false)
    return cur.Value
end

function RenderClass:Push(cur, isstrict)
    self:_strict(isstrict, true)
    local topush = assert(self:Walk(cur.Value, true), "Expected a push value")
    return "\tpush " .. topush .. "\n"
end
function RenderClass:Pop(cur, isstrict)
    self:_strict(isstrict, true)
    local topop = assert(self:Walk(cur.Value, true), "Expected a pop value")
    return "\tpop " .. topop .. "\n"
end

function RenderClass:Jmp(cur, isstrict)
    self:_strict(isstrict, true)
    local tojump = assert(self:Walk(cur.Value, true), "Expected a jump position")
    return "\tjmp " .. tojump .. "\n"
end

function RenderClass:Mov(cur, isstrict)
    self:_strict(isstrict, true)
    local tomov1 = assert(self:Walk(cur.Value[1], true), "Expected a mov position")
    local tomov2 = assert(self:Walk(cur.Value[2], true), "Expected a mov value")
    return "\tmov " .. tomov1 .. ", " .. tomov2 .. "\n"
end

function RenderClass:Compare(cur, isstrict)
    self:_strict(isstrict, true)
    local tocmp1 = assert(self:Walk(cur.Value[1], true), "Expected a cmp value")
    local tocmp2 = assert(self:Walk(cur.Value[2], true), "Expected a cmp value")
    return "\tcmp " .. tocmp1 .. ", " .. tocmp2 .. "\n"
end

-- Math
function RenderClass:Add(cur, isstrict)
    self:_strict(isstrict, true)
    local toadd1 = assert(self:Walk(cur.Value[1], true), "Expected an add value")
    local toadd2 = assert(self:Walk(cur.Value[2], true), "Expected an add value")
    return "\tadd " .. toadd1 .. ", " .. toadd2 .. "\n"
end
function RenderClass:Sub(cur, isstrict)
    self:_strict(isstrict, true)
    local toadd1 = assert(self:Walk(cur.Value[1], true), "Expected an add value")
    local toadd2 = assert(self:Walk(cur.Value[2], true), "Expected an add value")
    return ("\tsub %s, %s\n\tmov eax, %s\n"):format(toadd1, toadd2, toadd1)
end
function RenderClass:Mul(cur, isstrict)
    self:_strict(isstrict, true)
    local tomul1 = assert(self:Walk(cur.Value[1], true), "Expected a mul value")
    local tomul2 = assert(self:Walk(cur.Value[2], true), "Expected a mul value")
    return "\tiadd " .. tomul1 .. ", " .. tomul2 .. "\n"
end
function RenderClass:Div(cur, isstrict)
    self:_strict(isstrict, true)
    local todiv1 = assert(self:Walk(cur.Value[1], true), "Expected a div value")
    local todiv2 = assert(self:Walk(cur.Value[2], true), "Expected a div value")
    return ("\tpush %s\n\tmov %s, %s\n\tcdq\n\tdiv %s\n")
        :format(todiv1, todiv1, todiv2, todiv2)
end
function RenderClass:Neg(cur, isstrict)
    self:_strict(isstrict, true)
    local toneg = assert(self:Walk(cur.Value, true), "Expected a neg value")
    return "\tneg " .. toneg .. "\n"
end
function RenderClass:Or(cur, isstrict)
    self:_strict(isstrict, true)
    local toor1 = assert(self:Walk(cur.Value[1], true), "Expected an or value")
    local toor2 = assert(self:Walk(cur.Value[2], true), "Expected an or value")
    local hash = GetHash(cur)
    local start = ("\tcmp %s, 1\n\tje _or%s\n\tcmp %s, 1\n\tje _or%s\n\tmov eax, 0\n\tjmp _end%s\n")
        :format(toor1, hash, toor2, hash, hash)
    local stop = ("_or%s:\n\tmov eax, 1\n\n_end%s:\n")
        :format(hash, hash)
    return start .. stop
end
function RenderClass:And(cur, isstrict)
    self:_strict(isstrict, true)
    local toand1 = assert(self:Walk(cur.Value[1], true), "Expected an and value")
    local toand2 = assert(self:Walk(cur.Value[2], true), "Expected an and value")
    local hash = GetHash(cur)
    local start = ("\tcmp %s, 1\n\tjne _and%s\n\tcmp %s, 1\n\tjne _and%s\n\tmov eax, 1\n\tjmp _end%s\n")
        :format(toand1, hash, toand2, hash, hash)
    local stop = ("_and%s:\n\tmov eax, 0\n\n_end%s:\n")
        :format(hash, hash)
    return start .. stop
end

function RenderClass:DefineByte(cur, isstrict)
    self:_strict(isstrict, true)
    local todb = assert(cur.Value[1], "Expected a db name")
    local str = ""
    for i = 2, #cur.Value do
        str = str .. cur.Value[i] .. (i == #cur.Value and "" or ", ")
    end
    return todb .. " db " .. str .. "\n"
end


function RenderClass:Walk(cur, isstrict)
    cur = cur or self.Head:GoNext()
    
    if cur == nil then
        return "nil"
    elseif not cur.Name then
        local out = ""
        for _, value in pairs(cur) do
            out = out .. self:Walk(value, isstrict)
        end
        return out
    else
        local tocall = self[cur.Name]
        if not tocall then
            error("No function for " .. cur.Name)
        end
        return tocall(self, cur, isstrict)
    end
end

function RenderClass:Run()
    
    for key, value in pairs(self.Nodes) do
        self.Head = TableHead.new(value)
        while self.Head:GoNext() do
            self.File[key] = self.File[key] .. self:Walk(self.Head:Current(), false)
        end
    end
    
    return (self.File.Start .. "\n" .. self.File.Function .. "\n" .. self.File.End):gsub("\t", "   ")
end

return RenderClass