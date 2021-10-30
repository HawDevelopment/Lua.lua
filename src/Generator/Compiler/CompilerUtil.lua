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
    return ("\t" .. str .. ":\n")
end

function CompilerUtil:AdvLabel(str)
    return self:Label(str) .. "\tpush ebp\n\tmov ebp, esp\n"
end


return CompilerUtil