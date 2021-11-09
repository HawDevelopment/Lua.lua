--[[
    Compiler functions
    HawDevelopment
    11/09/2021
--]]

local Functions = {}

Functions["tostring"] = { [[
tostring:
    push ebp
    mov ebp, esp
    
    pop ebp
]], { NumArgs = 1 } }

Functions["print"] = { [[
extern _printf
print:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    push eax
    push print_number
    call _printf
    add esp, 8
    pop ebp
    ret
]], { NumArgs = 1 }}
Functions["puts"] = { [[
extern _puts
puts:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    push eax
    call _puts
    add esp, 4
    pop ebp
    ret
]], { NumArgs = 1 }}

return function (name)
    return Functions[name]
end