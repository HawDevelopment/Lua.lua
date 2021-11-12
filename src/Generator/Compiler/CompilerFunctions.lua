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
extern _puts
print:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    push eax
    call _puts
    add esp, 4
    pop ebp
    ret
]]

function CompilerFunctions:print()
    return self.Util:Text(PrintText), {
        numargs = 1
    }
end

local BufferText = [[
buffer:
    pop ecx
    add esp, 256
    mov eax, esp
    mov [esp - 256], eax
    push ecx
    ret
]]

function CompilerFunctions:buffer()
    return self.Util:Text(BufferText), {
        numargs = 0,
        startasm = function ()
            return self.Util:Text("\t; Created buffer\n")
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

return CompilerFunctions