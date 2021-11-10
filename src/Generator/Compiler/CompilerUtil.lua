--[[
    Compiler util
    HawDevelopment
    30/10/2021
--]]


local CompilerUtil = {}
CompilerUtil.__index = CompilerUtil

function CompilerUtil.new(class)
    local self = setmetatable({}, CompilerUtil)
    
    self.Class = class
    
    return self
end

CompilerUtil.Eax = { Name = "Register", Value = "eax"}
CompilerUtil.Ebx = { Name = "Register", Value = "ebx"}
CompilerUtil.Ecx = { Name = "Register", Value = "ecx"}
CompilerUtil.Edx = { Name = "Register", Value = "edx"}
CompilerUtil.Esp = { Name = "Register", Value = "esp"}
CompilerUtil.Ebp = { Name = "Register", Value = "ebp"}


function CompilerUtil:Push(cur)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Push", Value = cur }
end

function CompilerUtil:Pop(cur)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Pop", Value = cur }
end

function CompilerUtil:Jmp(cur)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Jmp", Value = cur }
end

function CompilerUtil:Mov(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. tostring(cur))
    return { Name = "Mov", Value = { cur, cur2 } }
end

function CompilerUtil:Label(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return { Name = "Text", Value = (str .. ":\n") }
end

function CompilerUtil:AdvLabel(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return { Name = "Text", Value = str .. ":\n\tpush ebp\n\tmov ebp, esp\n" }
end

function CompilerUtil:Add(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Add", Value = { cur, cur2 } }
end

function CompilerUtil:Sub(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Sub", Value = { cur, cur2 } }
end

function CompilerUtil:Mul(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Multiply", Value = { cur, cur2 } }
end

function CompilerUtil:Div(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Divide", Value = { cur, cur2 } }
end

function CompilerUtil:Neg(cur)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Negate", Value = cur }
end

function CompilerUtil:Or(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Or", Value = { cur, cur2 } }
end
function CompilerUtil:And(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "And", Value = {cur, cur2}}
end

function CompilerUtil:Cmp(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Compare", Value = { cur, cur2 }}
end

function CompilerUtil:Equal(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return {
        self:Mov(self.Edx, self:Text("1")),
        self:Cmp(self.Ecx, self.Eax),
        self:Text("\t" .. str .. " al\n"),
        self:Text("\tmovzx eax, al\n")
    }
end

function CompilerUtil:_param(str)
    return { Name = "Param", Value = str }
end

function CompilerUtil:_local(str)
    return { Name = "Local", Value = str }
end

function CompilerUtil:LocalVariable(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    local env = self.Class:GetEnv()
    local pointer = env._ENV.Pointer
    env[str] = pointer
    env._ENV.Pointer = pointer + 4
    env._ENV.NumVars = env._ENV.NumVars + 1
    local name = "[ebp - " .. pointer .. "]"
    return self:Mov(self:_local(name), self.Eax)
end

local Limiters = {
    ["ReturnStatement"] = 1;
    ["CallExpression"] = 2;
}

function CompilerUtil:LimitBuffer(size)
    assert(type(size) == "number", "Expected number, got " .. type(size))
    
    -- Since its limited we want to free it up
    local index, cur = self.Class.Head.Pos, nil
    repeat
        index = index + 1
        cur = self.Class.Head.Table[index]
        if index > #self.Class.Head.Table then
            cur = nil
            break
        end
    until Limiters[cur.Name]
    if cur then
        local limit, pos = Limiters[cur.Name], index + 1
        if limit == 1 then
            pos = index
        end
        table.insert(self.Class.Head.Table, pos, {
            Name = "Instruction",
            Value = {
                self:Text("\tadd esp, " .. size .. "\n"),
            }
        })
    end
    
    
    return {
        self:Text("\tsub esp, " .. size .. "\n"),
        self:Mov(self.Eax, self.Esp),
        self:Mov(self:Text("[esp + " .. size -  4 .. "]"), self.Eax),
        self:LocalVariable("__buffer")
    }
end

function CompilerUtil:Text(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return { Name = "Text", Value = str }
end

function CompilerUtil:DefineByte(...)
    return { Name = "DefineByte", Value = { ... } }
end

return CompilerUtil