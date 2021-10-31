--[[
    Compiler Class
    HawDevelopment
    21/10/2021
--]]

local LOG = false

local TableHead = require("src.Generator.Util.TableHead")
local CompilerUtil = require("src.Generator.Compiler.CompilerUtil")

local StartAssembly = "section .text\nglobal _main\nextern _printf\nprint:\n\tpush edi\n\tpush print_number\n\tcall _printf\n\tadd esp, 8\n\tret\n\n_main:\n\tpush ebp\n\tmov ebp, esp\n"
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
    
    self.Util = CompilerUtil.new(self)
    
    self.GlobalEnv = { ["print"] = "print" }
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

local function GetHash(cur)
    return tostring(cur):sub(8, -1)
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
        self.Envoriments[self.TopEnvoriment] = nil
        self.TopEnvoriment = self.TopEnvoriment - 1
    end
    function CompilerClass:GetEnv()
        return self.Envoriments[self.TopEnvoriment] or error("No env found")
    end
end

function CompilerClass:ReturnStatement(_)
    return self.Util:Pop("ebp") .. "\tret"
end

-- TODO: Start support for: "a and b or c"
function CompilerClass:UnaryExpression(cur)
    -- Evaluate the expression
    local op = cur.Value.op.Value
    if op == "-" then
        return "\tneg eax ; Unary\n"
    elseif op == "not" then
        return "\tcmp eax, 0\n\tmov eax, 0\n\tsete al\n"
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
    local EqualString = "\tmov ebx, 0\n\tmov edx, 1\n\tcmp ecx, eax\n\t%s ebx, edx\n\tmov eax, ebx"

    -- TODO: Add suport for more ops
    function CompilerClass:BinaryExpression(cur)
        local op, pos = cur.Value, self.Head.Pos
        local str = assert(OpToString[op], "The operator: " .. op .. " is not a valid operator!")

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

function CompilerClass:GetLocalExpression(cur)
    local env = self:GetEnv()
    if not env[cur.Value] then
        error("Attemp to acces local '" .. tostring(cur.Value) .. "' (a nil value)")
    end
    return ("\tmov eax, [ebp - %d]\n"):format(self:GetEnv()[cur.Value])
end

function CompilerClass:AssignmentStatement(cur)
    -- We expect that eax holds the value
    local env = self:GetEnv()
    if not env[cur.Value.Value] then
        error("Attemp to assign to local '" .. tostring(cur.Value.Value) .. "' (a nil value)")
    end
    return ("\tmov [ebp - %d], eax\n"):format(env[cur.Value.Value])
end

local ArgumentLookUp = { "edi", "esi", "edx", "ecx" }

function CompilerClass:FunctionStatement(cur)
    Log("Creating function: " .. cur.Value.name)
    local hash = "_" .. GetHash(cur) -- We add an underscore so nasm doesn't complain
    self:CreateEnv()
    local env = self:GetEnv()
    env._ENV.EndName = hash
    
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
    if cur.Value.body[#cur.Value.body].Name ~= "ReturnStatement" then
        error("Function " .. cur.Value.name .. " does not return have a return statement!")
    end
    
    env = self:GetEnv()
    if env._ENV.EndName ~= hash then
        error("Expected 'end'")
    end
    
    Log("Added function: " .. cur.Value.name)
    self:RemoveEnv()
    self.GlobalEnv[cur.Value.name] = hash
    self:Function(("%s:\n\tpush ebp\n\tmov ebp, esp\n%s"):format(hash, body))
    return "\t; Create " .. cur.Value.name .. " function\n"
end

function CompilerClass:CallStatement(cur)
    -- !THE VISITOR CREATES INSTRUCTIONS TO PUSH THE PARAMETERS!
    
    Log("Calling function: " .. cur.Value.name)
    if not self.GlobalEnv[cur.Value.name] then
        error("Attemp to call function '" .. tostring(cur.Value.name) .. "' (a nil value)")
    end
    
    local body = ""
    for i, _ in pairs(cur.Value.args) do
        body = body .. self.Util:Pop("eax") .. self.Util:Mov(ArgumentLookUp[i], "eax")
    end
    return ("\tpush eax\n%s\tcall %s ; -- Call function %s \n\tpop eax\n"):format(body, self.GlobalEnv[cur.Value.name], cur.Value.name)
end

-- If statement
do
    local CompareString = "\tcmp eax, 1\n\tjne %s\n"
    
    function CompilerClass:_genifstatement(tab, endpos)
        local str = ""
        for _, value in pairs(tab.condition) do
            str = str .. self:Walk(value)
        end
        
        str = str .. CompareString:format(endpos)
        
        for key, value in pairs(tab.body) do
            str = str .. self:Walk(value)
        end
        return str
    end
    
    function CompilerClass:IfStatement(cur)
        local name = GetHash(cur)
        local str = ""
        if #cur.Value > 1 then
            -- theres also some elseif or else statements
            for key, value in pairs(cur.Value) do
                if #value.condition > 0 then
                    -- If or elseif
                    local endpos = cur.Value[key + 1] and ("_else" .. name .. "_" .. key + 1) or ("_end" .. name)
                    str = str .. self:_genifstatement(value, endpos)
                    str = str .. self.Util:Jmp("_end" .. name)
                    
                    if cur.Value[key + 1] then
                        -- Add label for the next statement
                        str = str .. self.Util:Label(endpos)
                    end
                else
                    for _, value in pairs(value.body) do
                        str = str .. self:Walk(value)
                    end
                    str = str .. self.Util:Jmp("_end" .. name)
                end
            end
        else
            str = self:_genifstatement(cur.Value[1], "_end" .. name)
        end
        str = str .. self.Util:Label("_end" .. name)
        return str
    end
end

-- While statement
do
    local CompareString = "\tcmp eax, 1\n\tjne %s\n"
    function CompilerClass:WhileStatement(cur)
        local str = ""
        local name = "_" .. GetHash(cur) -- We add an underscore so nasm doesn't complain
        local endpos = "_end" .. name
        
        str = str .. self.Util:Label(name)
        for _, value in pairs(cur.Value.condition) do
            str = str .. self:Walk(value)
        end
        str = str .. CompareString:format(endpos)
        for _, value in pairs(cur.Value.body) do
            if value.Name == "BreakStatement" then
                str = str .. self.Util:Jmp(endpos)
            else
                str = str .. self:Walk(value)
            end
        end
        str = str .. self.Util:Jmp(name)
        str = str .. self.Util:Label(endpos)
        return str
    end
end

function CompilerClass:Walk(cur)
    cur = cur or self.Head:GoNext()
    
    if cur == nil then
        return "nil"
    else
        if cur.Type == "Instruction" then
            local tocall = assert(self.Util[cur.Name], "Could not find intruction with name: " .. tostring(cur.Name))
            if cur.Value then return tocall(self.Util, unpack(cur.Value)) end
            return tocall(self.Util)
        end
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
        self.File.Start = self.File.Start .. self:Walk(self.Head:Current())
    end
    
    return (self.File.Start .. "\n" .. self.File.Function .. "\n" .. self.File.End):gsub("\t", "   ")
end


return CompilerClass