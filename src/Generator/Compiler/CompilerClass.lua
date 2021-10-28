--[[
    Compiler Class
    HawDevelopment
    21/10/2021
--]]

local TableHead = require("src.Generator.Util.TableHead")

local StartAssembly = "section .text\nglobal _main\nextern _printf\n\n_main:"
local FunctionsAssembly = ""
local EndAssembly = "section .data\nprint_number db '%i', 0xA, 0 ; Used for print"

local CompilerClass = {}
CompilerClass.__index = CompilerClass

function CompilerClass.new(visited, head, version)
    local self = setmetatable({}, CompilerClass)
    
    self.Nodes = visited
    self.Start = StartAssembly
    self.Function = FunctionsAssembly
    self.End = EndAssembly
    self.Head = head or TableHead.new(visited)
    self.Version = version
    
    return self
end

-- Util
do
    local function AddToAny(self, index, toadd, indent)
        indent = indent or "    "
        if toadd then
            self[index] = self[index] .. indent .. toadd .. "\n"
        else
            error("Tried to add nil to index: " .. index)
        end
    end
    function CompilerClass:AddToStart(...)
        AddToAny(self, "Start", ...)
    end
    function CompilerClass:AddToEnd(...)
        AddToAny(self, "End", ...)
    end
    function CompilerClass:AddToFunction(...)
        AddToAny(self, "Function", ...)
    end
end

function CompilerClass:CompileInteger(cur)
    return "\tmov eax, " .. cur.Value .. " ; Integer"
end

-- TODO: AddToStart support for: "a and b or c"
function CompilerClass:CompileUnary(cur)
    -- Evaluate the expression
    local op = cur.Value.op.Value
    if op == "-" then
        return "\tneg eax ; Unary"
    elseif op == "not" then
        return "\tcmp eax, 0\n\tmov eax, 0\n\tsete al"
    else
        print("Unary with name: " .. tostring(op) .. " not found!")
    end
end

function CompilerClass:CompileLocal()
    if not self.Vars then
        self.Vars = {}
    end
    
    local var = self.Head.Value
    -- We assume that eax holds the value of var
    
end

-- Binary
do
    local OpToString = {
        ["+"] = "\tadd eax, ecx",
        ["*"] = "\timul eax, ecx",
        ["-"] = [[  sub ecx, eax
        mov eax, ecx]],
        ["/"] = [[
    mov ebx, eax
    mov eax, ecx
    mov ecx, ebx
    cdq
    idiv ecx]],
        ["%"] = [[
    mov ebx, eax
    mov eax, ecx
    mov ecx, ebx
    cdq
    idiv ecx
    mov eax, edx]],
    ["=="] = "je", ["~="] = "jne",
    [">"] = "jg", [">="] = "jge",
    ["<"] = "jl", ["<="] = "jle",
    
        ["or"] = [[
    cmp eax, 0
    je _%d
    mov eax, 1
    jmp _end%d]],
        ["and"] = [[
    cmp eax, 0
    jne _%d
    jmp _end%d]],
    }
    local LogicalString = "_%d:\n%s\n\tcmp eax, 0\n\tsetne al\n\tjmp _end%d"

    local EqualString = "\tcmp eax, ecx\n\t%s _%d\n\tmov eax, 0\n\tjmp _end%d"
    local EqualStringFunc = "_%d:\n\tmov eax, 1\n\tjmp _end%d"

    -- TODO: Add suport for more ops
    function CompilerClass:CompileBinary(cur)
        local op, pos = cur.Value.op.Value, self.Head.Pos
        local str = OpToString[op] or error("Not a valid operator! " .. op)

        if self.Version.LOGICAL_OPERATORS[op] then
            -- and, or
            self:AddToFunction(LogicalString:format(pos, self:Walk(self.Head:GoNext()), pos), "")
            
            return str:format(pos, pos) .. "\n_end" .. pos .. ":\n"
        end
        
        if self.Version.EQUALITY_OPERATORS[op] or self.Version.COMPARISON_OPERATORS[op] then
            -- ==, ~=, >, >=, <, <=
            str = EqualString:format(str, pos, pos)
            self:AddToFunction(EqualStringFunc:format(pos, pos), "")
            
            return string.format("\tpush eax\n%s\n\tpop ecx\n", self:Walk(self.Head:GoNext())) .. str .. "\n_end" .. pos .. ":\n"
        end
        
        -- Binary
        return "\tpush eax\n" .. self:Walk(self.Head:GoNext()) .. "\n\tpop ecx\n" .. str
    end
end

function CompilerClass:CompileReturn(_)
    return "\tpush eax\n\tpush print_number\n\tcall _printf\n\tadd esp, 8\n\tret ; Return"
end

local NameToFunction = {
    IntegerLiteral = CompilerClass.CompileInteger,
    ReturnStatement = CompilerClass.CompileReturn,
    UnaryExpression = CompilerClass.CompileUnary,
    BinaryExpression = CompilerClass.CompileBinary,
    
    LocalStatement = CompilerClass.CompileLocal,
}

function CompilerClass:Walk(cur)
    cur = cur or self.Head:GoNext()
    
    if cur == nil then
        return "nil"
    else
        local tocall = NameToFunction[cur.Name]
        if not tocall then
            error("No function for " .. cur.Name)
        end
        return tocall(self, cur)
    end
end

function CompilerClass:Run()
    self.Vars = {}
    self.Pointer = 0
    
    while self.Head:GoNext() do
        self.Start = self.Start .. "\n" .. self:Walk(self.Head:Current())
    end
    
    return (self.Start .. "\n" .. self.Function .. "\n" .. self.End):gsub("\t", "   ")
end


return CompilerClass