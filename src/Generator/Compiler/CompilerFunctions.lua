--[[
    Compiler functions
    HawDevelopment
    11/09/2021
--]]

local CompilerFunctions = {}
CompilerFunctions.__index = CompilerFunctions

function CompilerFunctions.new(class, util)
    local self = setmetatable({}, CompilerFunctions)
    
    self.Class = class
    self.Util = util
    
    return self
end

local ToStringText = [[
extern _sprintf
sprintf:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 16]
    push eax
    mov eax, [ebp + 12]
    push eax
    mov eax, [ebp + 8]
    push eax
    call _sprintf
    add esp, 12
    pop ebp
    ret
]]

function CompilerFunctions:sprintf()
    return self.Util:Text(ToStringText), {
        numargs = 3,
    }
end

local PrintText = [[
extern _printf
printf:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 12]
    push eax
    mov eax, [ebp + 8]
    push eax
    call _printf
    add esp, 8
    pop ebp
    ret
]]

function CompilerFunctions:printf()
    return self.Util:Text(PrintText), {
        numargs = 2
    }
end

local BufferText = [[
buffer:
    ; Boiler
    ret
]]

function CompilerFunctions:buffer()
    return self.Util:Text(BufferText), {
        numargs = 0,
        startasm = function ()
            local env = self.Class:GetEnv()
            local pointer = env._ENV.Pointer
            env._ENV.Pointer = pointer + 256
            env._ENV.NumVars = env._ENV.NumVars + 64
            return { 
                self.Util:Text("\t; Created buffer\n"),
                self.Util:Text("\tlea eax, [ebp - " .. tostring(pointer + 256 - 4) .. "]\n")
            }
        end,
    }
end

local StrCpyText = [[
extern _strcpy
strcpy:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 12]
    push eax
    mov eax, [ebp + 8]
    push eax
    call _strcpy
    add esp, 8
    pop ebp
    ret
]]

function CompilerFunctions:strcpy()
    return self.Util:Text(StrCpyText), {
        numargs = 2,
    }
end

local StrCatText = [[
extern _strcat
strcat:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 12]
    push eax
    mov eax, [ebp + 8]
    push eax
    call _strcat
    add esp, 8
    pop ebp
    ret
]]
function CompilerFunctions:strcat()
    return self.Util:Text(StrCatText), {
        numargs = 2,
    }
end

local ScanfText = [[
extern _scanf
scanf:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 12]
    push eax
    mov eax, [ebp + 8]
    push eax
    call _scanf
    add esp, 8
    pop ebp
    ret
]]
function CompilerFunctions:scanf()
    return self.Util:Text(ScanfText), {
        numargs = 2
    }
end

local AddrText = [[
addr:
    ; Boiler
    ret
]]

function CompilerFunctions:addr()
    return self.Util:Text(AddrText), {
        numargs = 0,
        startasm = function (args)
            if not args[1] then
                error("Expected argument, got nil", 2)
            end
            local env = self.Class:GetEnv()
            local pointer = env[args[1].Value]
            args[1] = nil
            -- We dont remove the push instruction
            
            return self.Util:Text("\tlea eax, [ebp - " .. pointer .. "]\n")
        end
    }
end

return CompilerFunctions