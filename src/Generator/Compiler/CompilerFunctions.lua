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
tostring:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    push eax
    push tostring_format
    mov eax, [ebp + 12]
    push eax
    call _sprintf
    add esp, 12
    pop ebp
    ret
]]

function CompilerFunctions:tostring()
    return self.Util:Text(ToStringText), {
        numargs = 1,
        startasm = function ()
            return {
                self.Util:Text("\tsub esp, 260\n"),
                self.Util:Mov(self.Util.Eax, self.Util.Esp),
                self.Util:Mov(self.Util:Text("[esp + 256]"), self.Util.Eax),
                self.Util:Push(self.Util.Eax),
            }
        end,
        endasm = function ()
            local env = self.Class:GetEnv()
            return {
                self.Util:Pop(self.Util.Eax),
            }
        end,
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

local ConcatText = [[
extern _sprintf
concat:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 12]
    push eax
    mov eax, [ebp + 8]
    push eax
    push concat_format
    mov eax, [ebp + 16]
    push eax
    call _sprintf
    add esp, 16
    pop ebp
    ret
]]
function CompilerFunctions:concat()
    return self.Util:Text(ConcatText), {
        numargs = 2,
        startasm = function ()
            return {
                self.Util:Text("\tsub esp, 260\n"),
                self.Util:Mov(self.Util.Eax, self.Util.Esp),
                self.Util:Mov(self.Util:Text("[esp + 256]"), self.Util.Eax),
                self.Util:Push(self.Util.Eax),
            }
        end,
        endasm = function ()
            local env = self.Class:GetEnv()
            return {
                self.Util:Pop(self.Util.Eax),
            }
        end,
    }
end

return CompilerFunctions