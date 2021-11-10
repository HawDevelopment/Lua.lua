--[[
    Compiler Class
    HawDevelopment
    21/10/2021
--]]

local LOG =  false

local TableHead = require("src.Generator.Util.TableHead")
local CompilerUtil = require("src.Generator.Compiler.CompilerUtil")
local CompilerFunctions = require("src.Generator.Compiler.CompilerFunctions")

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
    self.Functions = CompilerFunctions.new(self, self.Util)
    
    self.GlobalEnv = { }
    self.GlobalDataEnv = { }
    self.GlobalString = { }
    
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
    function CompilerClass:Add(pos, toadd)
        self.File[pos] = toadd
    end
    function CompilerClass:CreateEnv()
        self.TopEnvoriment = self.TopEnvoriment + 1
        self.Envoriments[self.TopEnvoriment] = { _ENV = { Pointer = 4, NumVars = 0 } }
    end
    function CompilerClass:RemoveEnv()
        self.Envoriments[self.TopEnvoriment] = nil
        self.TopEnvoriment = self.TopEnvoriment - 1
    end
    function CompilerClass:GetEnv()
        return self.Envoriments[self.TopEnvoriment] or error("No env found")
    end
end

function CompilerClass:StringLiteral(cur)
    local name
    if self.GlobalString[cur.Value] then
        -- Theres already a string with same value
        Log("Found string: " .. cur.Value)
        name = self.GlobalString[cur.Value]
    else
        Log("Creating string: " .. cur.Value)
        name = GetHash(cur)
        table.insert(self.File.End, self.Util:DefineByte(
            "str_" .. name,
            -- When we define the string we remove the start and end symbols
            ("\'%s\'"):format(cur.Value:sub(2, -2)),
            "0"
        ))
        self.GlobalString[cur.Value] = name
    end
    name = "str_" .. name
    return self.Util:Mov(self.Util.Eax, self.Util:Text(name))
end

function CompilerClass:ReturnStatement(_)
    local env = self:GetEnv()
    return self.Util:Text("\tadd esp, " .. env._ENV.NumVars * 4 .. "\n\tpop ebp\n\tret\n")
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
    function CompilerClass:_genOps()
        -- ! WE SHOULD ALWAYS USE EAX AND ECX !
        self._optorender = {
            ["+"] = self.Util:Add(self.Util.Eax, self.Util.Ecx),
            ["*"] = self.Util:Mul(self.Util.Eax, self.Util.Ecx),
            ["-"] = self.Util:Sub(self.Util.Ecx, self.Util.Eax),
            ["/"] = self.Util:Div(self.Util.Eax, self.Util.Ecx),
            ["%"] = { self.Util:Div(self.Util.Eax, self.Util.Ecx), self.Util:Mov(self.Util.Eax, self.Util.Edx) },
            ["=="] = "sete", ["~="] = "setne",
            [">"] = "setg", [">="] = "setge",
            ["<"] = "setl", ["<="] = "setle",
            ["or"] = self.Util:Or(self.Util.Eax, self.Util.Ecx),
            ["and"] = self.Util:And(self.Util.Eax, self.Util.Ecx),
            [".."] = true, -- Implemented in if
        }
    end

    -- TODO: Add suport for more ops
    function CompilerClass:BinaryExpression(cur)
        local op = cur.Value
        assert(self._optorender[op], "The operator: " .. op .. " is not a valid operator!")

        local toret
        if op == ".." then
            self:_import("concat")
            toret = {
                self.Util:Push(self.Util.Ecx),
                self:Walk({
                    Name = "CallExpression",
                    Value = { name = "concat", args = { }, argsnum = 0 }
                })
            }
            
        elseif self.Version.LOGICAL_OPERATORS[op] then
            -- and, or
            toret = self._optorender[op]
        elseif self.Version.EQUALITY_OPERATORS[op] or self.Version.COMPARISON_OPERATORS[op] then
            -- ==, ~=, >, >=, <, <=
            toret = self.Util:Equal(self._optorender[op])
        else
            -- Binary
            toret = self._optorender[op]
        end
        return toret
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
    return self.Util:Mov(self.Util:_local("[ebp - " .. env[cur.Value.Value] .. "]"), self.Util.Eax)
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
    
    -- Label
    table.insert(body, 1, {
        self.Util:Text("global " .. hash .. "\n"),
        self.Util:AdvLabel(hash)
    })
    
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
            env._ENV.NumVars = env._ENV.NumVars + 1
        end
    end
    
    for _, value in pairs(cur.Value.body) do
        table.insert(body, self:Walk(value))
    end
    
    local vars = env._ENV.NumVars * 4
    table.insert(body, 2, self.Util:Text("\tsub esp, " .. vars .. "\n"))
    
    if cur.Value.body[#cur.Value.body].Name ~= "ReturnStatement" then
        table.insert(body, self:ReturnStatement())
    end
    
    env = self:GetEnv() -- Fetch env again, since it could have changed
    if env._ENV.EndName ~= hash then
        error("Expected 'end'")
    end
    
    self:RemoveEnv()
    if cur.Value.islocal then
        Log("Added local function: " .. cur.Value.name)
        self.GlobalEnv[cur.Value.name] = hash
    end
    
    self:Add("Function", body)
    return self.Util:Text("\t; Created function " .. cur.Value.name .. " \n")
end

function CompilerClass:_import(name)
    local func = self.Functions[name]
    if func and not self.GlobalEnv[name] then
        Log("Importing function: " .. name)
        local body, args = func(self.Functions)
        
        table.insert(self.File.Function, body)
        self.GlobalEnv[name] = name
        
        self.GlobalDataEnv[name] = args or {}
        if args and args.varcost then
            local env = self:GetEnv()
            env._ENV.NumVars = env._ENV.NumVars + args.varcost
        end
    end
end

function CompilerClass:CallExpression(cur)
    local name = assert(cur.Value.name, "Attemted to call unknown function")
    
    -- Check if this could be a global
    self:_import(name)
    
    assert(self.GlobalEnv[name], "Attemp to call function '" .. tostring(name) .. "' (a nil value)")
    local data = self.GlobalDataEnv[name]
    if data and data.numargs and data.numargs ~= cur.Value.argsnum then
        error("Function " .. name .. " expects " .. data.numargs .. " arguments, got " .. cur.Value.argsnum)
    end
    
    Log("Calling function: " .. name)
    local body = { }
    if data.startasm then
        table.insert(body, data.startasm())
    end
    -- Do the args
    for _, value in pairs(cur.Value.args) do
        table.insert(body, self:Walk(value))
    end
    table.insert(body, self.Util:Text(("\tcall %s ; Call function %s\n"):format(self.GlobalEnv[name], name)))
    table.insert(body, self.Util:Add(self.Util.Esp, self.Util:Text(tostring(cur.Value.argsnum * 4))))
    
    if data.endasm then
        table.insert(body, data.endasm())
    end
    return body
end

-- If statement
do
    function CompilerClass:_genifstatement(tab, endpos)
        local body = {}
        for _, value in pairs(tab.condition) do
            table.insert(body, self:Walk(value))
        end
        
        table.insert(body, {
            self.Util:Cmp(self.Util.Eax, self.Util:Text("1")),
            self.Util:Text("\tjne " .. endpos .. "\n")
        })
        
        for _, value in pairs(tab.body) do
            table.insert(body, self:Walk(value))
        end
        return body
    end
    
    function CompilerClass:IfStatement(cur)
        local name = GetHash(cur)
        local body = {}
        
        for key, value in pairs(cur.Value) do
            if #value.condition > 0 then
                -- If or elseif
                local endpos = cur.Value[key + 1] and ("_else" .. name .. "_" .. key + 1) or ("_end" .. name)
                table.insert(body, self:_genifstatement(value, endpos))
                
                if not value.body[#value.body].Name ~= "ReturnStatement" then
                    table.insert(body, self.Util:Jmp(self.Util:Text("_end" .. name)))
                end
                
                if cur.Value[key + 1] then
                    -- Add label for the next statement
                    table.insert(body, self.Util:Label(endpos))
                end
            else
                for _, value in pairs(value.body) do
                    table.insert(body, self:Walk(value))
                end
                if not value.body[#value.body].Name ~= "ReturnStatement" then
                    table.insert(body, self.Util:Jmp(self.Util:Text("_end" .. name)))
                end
            end
        end
        
        table.insert(body, self.Util:Label("_end" .. name))
        return body
    end
end

-- Loop statement
do
    -- local WhileCompareString = "\tcmp eax, 1\n\tjne %s\n"
    function CompilerClass:WhileStatement(cur)
        local name = "_" .. GetHash(cur) -- We add an underscore so nasm doesn't complain
        local endpos = "_end" .. name
        local body = {}
        
        table.insert(body, self.Util:Label(name))
        for _, value in pairs(cur.Value.condition) do
            table.insert(body, self:Walk(value))
        end
        
        -- Compare
        table.insert(body, {
            self.Util:Cmp(self.Util.Eax, self.Util:Text("1")),
            self.Util:Text("\tjne " .. endpos .. "\n")
        })
        for _, value in pairs(cur.Value.body) do
            if value.Name == "BreakStatement" then
                table.insert(body, self.Util:Jmp(self.Util:Text(endpos)))
            else
                table.insert(body, self:Walk(value))
            end
        end
        
        table.insert(body, self.Util:Jmp(self.Util:Text(name)))
        table.insert(body, self.Util:Label(endpos))
        return body
    end
    
    -- local ForCompareString = "\tcmp %s, %s\n\tjl %s\n"
    function CompilerClass:NumericForStatement(cur)
        local name = "_" .. GetHash(cur) -- We add an underscore so nasm doesn't complain
        local endpos = "_end" .. name
        local env = self:GetEnv()
        
        local body = {}
        for _, value in pairs(cur.Value.start) do
            table.insert(body, self:Walk(value))
        end
        table.insert(body, self.Util:LocalVariable(cur.Value.var.Value))
        for _, value in pairs(cur.Value.stop) do
            table.insert(body, self:Walk(value))
        end
        table.insert(body, self.Util:LocalVariable("__iter"))
        table.insert(body,self.Util:Label(name))
        
        local var = self.Util:_local("[ebp - " .. env[cur.Value.var.Value] .. "]")
        local stop = self.Util:_local("[ebp - " .. env["__iter"] .. "]")
        table.insert(body, {
            self.Util:Mov(self.Util.Eax, var),
            self.Util:Mov(self.Util.Ebx, stop),
            
            self.Util:Cmp(self.Util.Ebx, self.Util.Eax),
            self.Util:Text("\tjle " .. endpos .. "\n")
        })
        for _, value in pairs(cur.Value.body) do
            if value.Name == "BreakStatement" then
                table.insert(body, self.Util:Jmp(endpos))
            else
                table.insert(body, self:Walk(value))
            end
        end
        
        table.insert(body, {
            self.Util:Mov(self.Util.Eax, var),
            self.Util:Add(self.Util.Eax, self.Util:Text("1")),
            self.Util:Mov(var, self.Util.Eax)
        })
        
        table.insert(body, self.Util:Jmp(self.Util:Text(name)))
        table.insert(body, self.Util:Label(endpos))
        return body
    end
end

function CompilerClass:Walk(cur)
    cur = cur or self.Head:GoNext()
    
    if cur == nil then
        return "nil"
    else
        if cur.Name == "Instruction" then
            return cur.Value
        end
        local tocall = self[cur.Name]
        if not tocall then
            error("No function for " .. cur.Name)
        end
        return tocall(self, cur)
    end
end

function CompilerClass:Run()
    self:_genOps()
    self:CreateEnv()
    local env = self:GetEnv()
    env.EndName = GetHash(self)
    
    self.Pointer = 4
    
    while self.Head:GoNext() do
        table.insert(self.File.Start, self:Walk(self.Head:Current()))
    end
    
    env = self:GetEnv()
    if env.EndName ~= GetHash(self) then
        error("Expected 'end'")
    end
    
    local vars = env._ENV.NumVars * 4
    table.insert(self.File.Start, 1, self.Util:Text("\tsub esp, " .. vars .. "\n"))
    if self.Head:Last().Name ~= "ReturnStatement" then
        table.insert(self.File.Start, self:ReturnStatement())
    end
    
    
    return self.File
end

return CompilerClass