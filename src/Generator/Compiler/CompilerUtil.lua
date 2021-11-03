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
CompilerUtil.Edx = { Name = "Register", Value = "ecx"}

function CompilerUtil:Push(cur)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Push", value = cur }
end

function CompilerUtil:Pop(cur)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Pop", value = cur }
end

function CompilerUtil:Jmp(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Jmp", value = { cur, cur2 } }
end

function CompilerUtil:Mov(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Mov", value = { cur, cur2 } }
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
    return { Name = "Negate", Value = cur}
end

function CompilerUtil:Cmp(cur, cur2)
    assert(type(cur) == "table", "Expected table, got " .. type(cur))
    return { Name = "Compate", Value = { cur, cur2 }}
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
    local name = "[ebp - " .. pointer .. "]"
    return self:Mov(self:_local(name), self.Eax)
end

function CompilerUtil:Text(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return { Name = "Text", Value = str }
end

return CompilerUtil