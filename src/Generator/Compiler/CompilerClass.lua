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
    
    self.Start = StartAssembly
    self.Function = FunctionsAssembly
    self.End = EndAssembly
    
    self.Envoriments = {}
    self.TopEnvoriment = 0
    
    self.Nodes = visited
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
    function CompilerClass:Start(...)
        AddToAny(self, "Start", ...)
    end
    function CompilerClass:End(...)
        AddToAny(self, "End", ...)
    end
    function CompilerClass:Function(...)
        AddToAny(self, "Function", ...)
    end
    
    function CompilerClass:CreateEnv()
        self.TopEnvoriment = self.TopEnvoriment + 1
        self.Envoriments[self.TopEnvoriment] = { _ENV = { Pointer = 4 } }
    end
    function CompilerClass:RemoveEnv()
        self.Envoriments[self.TopEnvoriment - 1] = nil
        self.TopEnvoriment = self.TopEnvoriment - 1
    end
    function CompilerClass:GetEnv()
        return self.Envoriments[self.TopEnvoriment] or error("No env found")
    end
end

function CompilerClass:IntegerLiteral(cur)
    return "\tmov eax, " .. cur.Value .. " ; Integer"
end

function CompilerClass:ReturnStatement(_)
    return "\tpop ebp\n\tpush eax\n\tpush print_number\n\tcall _printf\n\tadd esp, 8\n\tret ; Return"
end

-- TODO: Start support for: "a and b or c"
function CompilerClass:UnaryExpression(cur)
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

-- Binary
do
    local OpToString = {
        ["+"] = "\tadd eax, ecx",
        ["*"] = "\timul eax, ecx",
        ["-"] = "\tsub ecx, eax\n\tmov eax, ecx\n",
        ["/"] = "\tmov ebx, eax\n\tmov eax, ecx\n\tmov ecx, ebx\n\tcdq\n\tidiv ecx\n",
        ["%"] = "\tmov ebx, eax\n\tmov eax, ecx\n\tmov ecx, ebx\n\tcdq\n\tidiv ecx\n\tmov eax, edx\n",
        ["=="] = "cmove", ["~="] = "cmovne",
        [">"] = "cmovg", [">="] = "cmovge",
        ["<"] = "cmovl", ["<="] = "cmovle",
        ["or"] = "\tcmp eax, 0\n\tje _%d\n\tmov eax, 1\n\tjmp _end%d\n",
        ["and"] = "\tcmp eax, 0\n\tjne _%d\n\tjmp _end%d\n"
    }
    local LogicalString = "_%d:\n%s\n\tcmp eax, 0\n\tsetne al\n\tjmp _end%d"
    local EqualString = "\tmov ecx, 0\n\tmov edx, 1\n\tcmp ebx, eax\n\t%s ecx, edx\n\tmov eax, ecx"

    -- TODO: Add suport for more ops
    function CompilerClass:BinaryExpression(cur)
        local op, pos = cur.Value.op.Value, self.Head.Pos
        local str = OpToString[op] or error("Not a valid operator! " .. op)

        if self.Version.LOGICAL_OPERATORS[op] then
            -- and, or
            self:Function(LogicalString:format(pos, self:Walk(self.Head:GoNext()), pos), "")
            return str:format(pos, pos) .. "\n_end" .. pos .. ":\n"

        elseif self.Version.EQUALITY_OPERATORS[op] or self.Version.COMPARISON_OPERATORS[op] then
            -- ==, ~=, >, >=, <, <=
            str = EqualString:format(str, pos, pos)
            return string.format("\tpush eax\n%s\n\tpop ebx\n", self:Walk(self.Head:GoNext())) .. str
        end
        
        -- Binary
        return "\tpush eax\n" .. self:Walk(self.Head:GoNext()) .. "\n\tpop ecx\n" .. str
    end
end

function CompilerClass:LocalStatement(cur)
    -- We assume that eax holds the value of var
    local env = self:GetEnv()
    local pointer = env._ENV.Pointer
    env[cur.Value.Value] = pointer
    env._ENV.Pointer = pointer + 4
    return ("\tmov [ebp - %d], eax\n"):format(pointer)
end

function CompilerClass:GetLocalStatement(cur)
    local env = self:GetEnv()
    if not env[cur.Value] then
        error("Attemp to acces local '" .. tostring(cur.Value) .. "' (a nil value)")
    end
    return ("\tmov eax, [ebp - %d]"):format(self:GetEnv()[cur.Value])
end

function CompilerClass:FunctionStart(cur)
    self:CreateEnv()
    local env = self:GetEnv()
    env._ENV.EndName = cur.Value
    
    self.FunctionName[cur.Value] = self.Head.Pos
    return ("\tjmp _end%d\n\n%s:\n\tpush ebp\n\tmov ebp, esp\n"):format(self.Head.Pos, cur.Value)
end
function CompilerClass:FunctionStatementEnd(cur)
    local env = self:GetEnv()
    if env._ENV[cur.Value] == nil then
        error("Expected 'end'")
    end
    self:RemoveEnv()
    return ("\n_end%d:\n"):format(self.FunctionName[cur.Value])
end

function CompilerClass:CallStatement(cur)
    return ("\tcall %s\n"):format(cur.Value.Value.base.Value)
end

function CompilerClass:Walk(cur)
    cur = cur or self.Head:GoNext()
    
    if cur == nil then
        return "nil"
    else
        local tocall = self[cur.Name]
        if not tocall then
            error("No function for " .. cur.Name)
        end
        return tocall(self, cur)
    end
end

function CompilerClass:Run()
    self:CreateEnv()
    self.FunctionName = {}
    self.Pointer = 4
    
    while self.Head:GoNext() do
        self.Start = self.Start .. "\n" .. self:Walk(self.Head:Current())
    end
    
    return (self.Start .. "\n" .. self.Function .. "\n" .. self.End):gsub("\t", "   ")
end


return CompilerClass