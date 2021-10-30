--[[
    Compiler Class
    HawDevelopment
    21/10/2021
--]]

local LOG = false

local TableHead = require("src.Generator.Util.TableHead")

local StartAssembly = "section .text\nglobal _main\nextern _printf\nprint:\n\tpush eax\n\tpush print_number\n\tcall _printf\n\tadd esp, 8\n\tret\n\n_main:"
local FunctionsAssembly = ""
local EndAssembly = "section .data\nprint_number db '%i', 0xA, 0 ; Used for print"

local CompilerClass = {}
CompilerClass.__index = CompilerClass

function CompilerClass.new(visited, head, version)
    local self = setmetatable({}, CompilerClass)
    
    self.File = {
        Start = StartAssembly,
        Function = FunctionsAssembly,
        End = EndAssembly
    }
    
    self.GlobalEnv = { ["print"] = true }
    self.Envoriments = {}
    self.TopEnvoriment = 0
    
    self.Nodes = visited
    self.Head = head or TableHead.new(visited)
    self.Version = version
    
    return self
end

local function Log(...)
    if LOG then
        print(...)
    end
end

-- Util
do
    local function AddToAny(self, index, toadd)
        if toadd then
            self.File[index] = self.File[index] .. toadd .. "\n"
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

-- Intructions
do
    function CompilerClass:PushIntruction(_)
        return "\tpush eax\n"
    end
end

function CompilerClass:IntegerLiteral(cur)
    return "\tmov eax, " .. cur.Value .. " ; Integer\n"
end

function CompilerClass:ReturnStatement(_)
    return "\n\tpop ebp\n\tret ; Return"
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
        ["or"] = "\tpop ecx\n\tpush eax\nmov eax, ecx\n\tcmp eax, 0\n\tje _%d\n\tmov eax, 1\n\tjmp _end%d\n",
        ["and"] = "\tpop ecx\n\tpush eax\nmov eax, ecx\n\tcmp eax, 0\n\tjne _%d\n\tjmp _end%d\n"
    }
    local LogicalString = "_%d:\npop eax\n\tcmp eax, 0\n\tsetne al\n\tjmp _end%d"
    local EqualString = "\tmov ecx, 0\n\tmov edx, 1\n\tcmp ebx, eax\n\t%s ecx, edx\n\tmov eax, ecx"

    -- TODO: Add suport for more ops
    function CompilerClass:BinaryExpression(cur)
        local op, pos = cur.Value.op.Value, self.Head.Pos
        local str = OpToString[op] or error("Not a valid operator! " .. op)

        if self.Version.LOGICAL_OPERATORS[op] then
            -- and, or
            self:Function(LogicalString:format(pos, pos))
            return str:format(pos, pos) .. "\n_end" .. pos .. ":\n"

        elseif self.Version.EQUALITY_OPERATORS[op] or self.Version.COMPARISON_OPERATORS[op] then
            -- ==, ~=, >, >=, <, <=
            str = EqualString:format(str, pos, pos)
            -- return "\tpop ebx\n" .. str .. "\n" -- Same as below
        end
        
        -- Binary
        return "\tpop ecx\n" .. str .. "\n"
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
    return ("\tmov eax, [ebp - %d]\n"):format(self:GetEnv()[cur.Value])
end

local ArgumentLookUp = { "edi", "esi", "edx", "ecx" }

function CompilerClass:FunctionStatement(cur)
    Log("Creating function: " .. cur.Value.name)
    self:CreateEnv()
    local env = self:GetEnv()
    env._ENV.EndName = cur.Value.name
    
    local body = ""
    
    -- Args
    if #cur.Value.params > 0 then
        if #cur.Value.params > 4 then
            error("Too many arguments! (Will be fixed)")
        end
        
        for key, value in pairs(cur.Value.params) do
            local pointer = env._ENV.Pointer
            env[value.Value] = pointer
            env._ENV.Pointer = pointer + 4
            body = body .. ("\tmov [ebp - %d], %s\n"):format(pointer, ArgumentLookUp[key])
        end
    end
    
    for _, value in pairs(cur.Value.body) do
        body = body .. self:Walk(value)
    end
    
    env = self:GetEnv()
    if env._ENV.EndName ~= cur.Value.name then
        error("Expected 'end'")
    end
    
    
    Log("Added function: " .. cur.Value.name)
    self:RemoveEnv()
    self.GlobalEnv[cur.Value.name] = true
    self:Function(("%s:\n\tpush ebp\n\tmov ebp, esp\n%s"):format(cur.Value.name, body))
    return "\t; Create " .. cur.Value.name .. " function\n"
end

function CompilerClass:CallStatement(cur)
    Log("Calling function: " .. cur.Value.name)
    if not self.GlobalEnv[cur.Value.name] then
        for key, value in pairs(self.GlobalEnv) do
            print(key, value)
        end
        error("Attemp to call function '" .. tostring(cur.Value.name) .. "' (a nil value)")
    end
    local body = ""
    for i, _ in pairs(cur.Value.args) do
        body = body .. "\tpop eax\n\tmov " .. ArgumentLookUp[i] .. ", eax\n"
    end
    return ("%s\tcall %s\n"):format(body, cur.Value.name)
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
    self.Pointer = 4
    
    while self.Head:GoNext() do
        self.File.Start = self.File.Start .. "\n" .. self:Walk(self.Head:Current())
    end
    
    return (self.File.Start .. "\n" .. self.File.Function .. "\n" .. self.File.End):gsub("\t", "   ")
end


return CompilerClass