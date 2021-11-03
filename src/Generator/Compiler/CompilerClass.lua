--[[
    Compiler Class
    HawDevelopment
    21/10/2021
--]]

local LOG = false

local TableHead = require("src.Generator.Util.TableHead")
local CompilerUtil = require("src.Generator.Compiler.CompilerUtil")

local CompilerClass = {}
CompilerClass.__index = CompilerClass

function CompilerClass.new(visited, head, version)
    local self = setmetatable({}, CompilerClass)
    
    self.File = {
        Start = { },
        Function = { },
        End = { }
    }
    
    self.Util = CompilerUtil.new(self)
    
    self.GlobalEnv = { ["print"] = "print" }
    self.GlobalDataEnv = { ["print"] = { numargs = 1}}
    
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
    return self.Util:Text("\tpop ebp\n\tret\n")
end

-- TODO: Start support for: "a and b or c"
function CompilerClass:UnaryExpression(cur)
    -- Evaluate the expression
    local op = cur.Value.op.Value
    if op == "-" then
        return self.Util:Neg(self.Util.Eax)
    elseif op == "not" then
        return { self.Util:Cmp(self.Util.Eax, self.Util:Text("0")),
            self.Util:Mov(self.Util.Eax, self.Util:Text("0")),
            self.Util:Text("\tsete al\n")
        }
    else
        print("Unary with name: " .. tostring(op) .. " not found!")
    end
end

-- Binary
do
    function CompilerUtil:_genOps()
        self._optorender = {
            ["+"] = self.Util:Add(self.Util.Eax, self.Util.Ecx),
            ["*"] = self.Util:Mul(self.Util.Eax, self.Util.Ecx),
            ["-"] = { self.Util:Sub(self.Util.Ecx, self.Util.Eax), self.Util:Mov(self.Util.Eax, self.Util.Ecx) },
            ["/"] = self.Util:Div(self.Util.Eax, self.Util.Ecx),
            ["%"] = { self.Util:Div(self.Util.Eax, self.Util.Ecx), self.Util:Mov(self.Util.Eax, self.Util.Edx) },
            ["=="] = "cmove", ["~="] = "cmovne",
            [">"] = "cmovg", [">="] = "cmovge",
            ["<"] = "cmovl", ["<="] = "cmovle",
            ["or"] = self.Util:Or(self.Util.Eax, self.Util.Ecx),
            ["and"] = self.Util:And(self.Util.Eax, self.Util.Ecx)
        }
    end
    
    local LogicalString = "_%d:\n\tpop eax\n\tcmp eax, 0\n\tsetne al\n\tjmp _end%d"
    local EqualString = "\tmov ebx, 0\n\tmov edx, 1\n\tcmp ecx, eax\n\t%s ebx, edx\n\tmov eax, ebx"

    -- TODO: Add suport for more ops
    function CompilerClass:BinaryExpression(cur)
        local op, pos = cur.Value, self.Head.Pos
        local str = assert(self._optorender[op], "The operator: " .. op .. " is not a valid operator!")

        if self.Version.LOGICAL_OPERATORS[op] then
            -- and, or
            return self._optorender[op]
        elseif self.Version.EQUALITY_OPERATORS[op] or self.Version.COMPARISON_OPERATORS[op] then
            -- ==, ~=, >, >=, <, <=
            return self.Util:Equal(self._optorender[op])
        end
        -- Binary
        return self._optorender[op]
    end
end

function CompilerClass:LocalStatement(cur)
    -- We assume that eax holds the value of var
    return self.Util:LocalVariable(cur.Value.Value)
end

function CompilerClass:GetLocalExpression(cur)
    local env = self:GetEnv()
    if not env[cur.Value] then
        error("Attemp to acces local '" .. tostring(cur.Value) .. "' (a nil value)")
    end
    return self.Util:Mov(self.Util.Eax, self.Util:_local("[ebp - " .. env[cur.Value] .. "]"))
end

function CompilerClass:AssignmentStatement(cur)
    -- We expect that eax holds the value
    local env = self:GetEnv()
    if not env[cur.Value.Value] then
        error("Attemp to assign to local '" .. tostring(cur.Value.Value) .. "' (a nil value)")
    end
    return self.Util:Mov(self.Util:_local("[ebp - " .. env[cur.Value] .. "]"), self.Util.Eax)
end


function CompilerClass:FunctionStatement(cur)
    Log("Creating function: " .. cur.Value.name)
    local hash = "_" .. GetHash(cur) -- We add an underscore so nasm doesn't complain
    self:CreateEnv()
    local env = self:GetEnv()
    env._ENV.EndName = hash
    
    self.GlobalDataEnv[cur.Value.name] = { numargs = #cur.Value.params }

    if not cur.Value.islocal then
        Log("Added public function: " .. cur.Value.name)
        self.GlobalEnv[cur.Value.name] = hash
    end
    
    local body = { }
    
    -- Args
    if #cur.Value.params > 0 then
        local parampointer = 8
        for _, value in pairs(cur.Value.params) do
            local pointer = env._ENV.Pointer
            env[value.Value] = pointer
            env._ENV.Pointer = pointer + 4
            table.insert(body, {
                self.Util:Mov(self.Util.Eax, self.Util:_param("[ebp + " .. parampointer .. "]")),
                self.Util:Mov(self.Util:_local("[ebp - " .. pointer .. "]"), self.Util.Eax)
            })
            parampointer = parampointer + 4
        end
    end
    
    for _, value in pairs(cur.Value.body) do
        table.insert(body, self:Walk(value))
    end
    if cur.Value.body[#cur.Value.body].Name ~= "ReturnStatement" then
        error("Function " .. cur.Value.name .. " does not return have a return statement!")
    end
    
    env = self:GetEnv()
    if env._ENV.EndName ~= hash then
        error("Expected 'end'")
    end
    
    self:RemoveEnv()
    if cur.Value.islocal then
        Log("Added local function: " .. cur.Value.name)
        self.GlobalEnv[cur.Value.name] = hash
    end
    self:Function(("global %s\n%s:\n\tpush ebp\n\tmov ebp, esp\n%s"):format(hash, hash, body))
    return "\t; Create " .. cur.Value.name .. " function\n"
end

function CompilerClass:CallExpression(cur)
    -- !THE VISITOR CREATES INSTRUCTIONS TO PUSH THE PARAMETERS!
    
    Log("Calling function: " .. cur.Value.name)
    if not self.GlobalEnv[cur.Value.name] then
        error("Attemp to call function '" .. tostring(cur.Value.name) .. "' (a nil value)")
    end
    local data = self.GlobalDataEnv[cur.Value.name]
    if data and data.numargs and data.numargs ~= cur.Value.argsnum then
        error("Function " .. cur.Value.name .. " expects " .. data.numargs .. " arguments, got " .. cur.Value.argsnum)
    end
    
    return ("\tcall %s ; -- Call function %s\n\tadd esp, %d\n"):format(self.GlobalEnv[cur.Value.name], cur.Value.name, cur.Value.argsnum * 4)
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
        
        for _, value in pairs(tab.body) do
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
                    
                    if not value.body[#value.body].Name ~= "ReturnStatement" then
                        str = str .. self.Util:Jmp("_end" .. name)
                    end
                    
                    if cur.Value[key + 1] then
                        -- Add label for the next statement
                        str = str .. self.Util:Label(endpos)
                    end
                else
                    for _, value in pairs(value.body) do
                        str = str .. self:Walk(value)
                    end
                    if not value.body[#value.body].Name ~= "ReturnStatement" then
                        str = str .. self.Util:Jmp("_end" .. name)
                    end
                end
            end
        else
            str = self:_genifstatement(cur.Value[1], "_end" .. name)
        end
        str = str .. self.Util:Label("_end" .. name)
        return str
    end
end

-- Loop statement
do
    local WhileCompareString = "\tcmp eax, 1\n\tjne %s\n"
    function CompilerClass:WhileStatement(cur)
        local str = ""
        local name = "_" .. GetHash(cur) -- We add an underscore so nasm doesn't complain
        local endpos = "_end" .. name
        
        str = str .. self.Util:Label(name)
        for _, value in pairs(cur.Value.condition) do
            str = str .. self:Walk(value)
        end
        str = str .. WhileCompareString:format(endpos)
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
    
    local ForCompareString = "\tcmp %s, %s\n\tjl %s\n"
    function CompilerClass:NumericForStatement(cur)
        local name = "_" .. GetHash(cur) -- We add an underscore so nasm doesn't complain
        local endpos = "_end" .. name
        local env = self:GetEnv()
        
        local str = ""
        for _, value in pairs(cur.Value.start) do
            str = str .. self:Walk(value)
        end
        str = str .. self.Util:LocalVariable(cur.Value.var.Value)
        for _, value in pairs(cur.Value.stop) do
            str = str .. self:Walk(value)
        end
        str = str .. self.Util:LocalVariable("__iter")
        
        str = str .. self.Util:Label(name)
        
        local varassembly = "[ebp - " .. env[cur.Value.var.Value] .. "]"
        local stopassembly = "[ebp - " .. env["__iter"] .. "]"
        str = str .. self.Util:Mov("eax", varassembly)
        str = str .. self.Util:Mov("ebx", stopassembly)
        str = str .. ForCompareString:format("ebx", "eax", endpos)
        for _, value in pairs(cur.Value.body) do
            if value.Name == "BreakStatement" then
                str = str .. self.Util:Jmp(endpos)
            else
                str = str .. self:Walk(value)
            end
        end
        
        
        str = str .. self.Util:Add(varassembly, "1")
        str = str .. self.Util:Mov(varassembly, "eax")
        
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