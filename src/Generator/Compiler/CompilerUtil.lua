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

function CompilerUtil:Push(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return ("\tpush " .. str .. "\n")
end

function CompilerUtil:Pop(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return ("\tpop " .. str .. "\n")
end

function CompilerUtil:Jmp(str, str2)
    assert(type(str) == "string", "Expected string, got " .. type(str) .. " and " .. type(str2))
    return ("\t" .. (str2 or "jmp") .. " " .. str .. "\n")
end

function CompilerUtil:Mov(str, str2)
    assert(type(str) == "string" and type(str2) == "string", "Expected string, got " .. type(str) .. " and " .. type(str2))
    return ("\tmov " .. str .. " , " .. str2 .. "\n")
end

function CompilerUtil:Label(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return (str .. ":\n")
end

function CompilerUtil:AdvLabel(str)
    return self:Label(str) .. "\tpush ebp\n\tmov ebp, esp\n"
end

function CompilerUtil:Add(str, str2)
    return ("\tmov eax, %s\n\tmov ecx, %s\n\tadd eax, ecx\n"):format(str, str2)
end

function CompilerUtil:LocalVariable(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    local env = self.Class:GetEnv()
    local pointer = env._ENV.Pointer
    env[str] = pointer
    env._ENV.Pointer = pointer + 4
    return ("\tmov [ebp - %d], eax\n"):format(pointer)
end


return CompilerUtil