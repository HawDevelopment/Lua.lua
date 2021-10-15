--[[
    Parser class
    HawDevelopment
    09/10/2021
--]]


local Node = require("src.Generator.Util.Node")

local ParserClass = {}
ParserClass.__index = ParserClass

function ParserClass.new(tokens, head)
    local self = setmetatable({}, ParserClass)
    
    self.Tokens = tokens
    self.Head = head
    self.Pos = head.Pos
    
    return self
end

function ParserClass:ParseChunk()
    
    local body = self:ParseBody()
    if self.Head:Next() then
        error("Unexpected token: " .. self.Head:Next().Type)
    end
    return Node.new("Chunk", body, "Chunk", 0)
end

local function IsBodyCloser(token)
    if not token then
        return true
    elseif not (token:IsType("Keyword") or token:IsType("Identifier")) then
        return false
    end
    if token:Is("else") or token:Is("elseif") or token:Is("end") or token:Is("until") then
        return true
    end
    return false
end

function ParserClass:ParseBody()
    local body, statement = {}, nil
    while not IsBodyCloser(self.Head:Current()) do
        local cur = self.Head:Current()
        if cur and cur:Is("return") or cur:Is("break") then
            table.insert(body, #body + 1, self:ParseStatement())
            break
        end
        
        statement = self:ParseStatement()
        if statement then
            table.insert(body, #body + 1, statement)
        end
    end
    return body
end

local KeywordToFunction = {
    ["local"] = "ParseLocalStatement",
    ["if"] = "ParseIfStatement",
    ["return"] = "ParseReturnStatement",
    ["function"] = "ParseFunctionStatement",
    ["while"] = "ParseWhileStatement",
    ["for"] = "ParseForStatement",
    ["repeat"] = "ParseRepearStatement",
    ["break"] = "ParseBreakStatement",
    ["do"] = "ParseDoStatement",
}

function ParserClass:ParseStatement(cur)
    cur = cur or self.Head:Current()
    
    if cur:IsType("Keyword") then
        
        local index = KeywordToFunction[cur.Name]
        if index then
            return self[index](self, cur)
        else
            error("Unexpected token " .. cur:rep())
        end
    end
    
    -- If its not a keyword it then it must be assignment or call
    return self:ParseAssignmentOrCallStatement(cur)
end

-- Statements

-- Break
function ParserClass:ParseBreakStatement(cur)
    self.Head:GoNext()
    return Node.new("BreakStatement", cur.Value, "Statement", self.Pos.Counter - 1)
end

-- Do
function ParserClass:ParseDoStatement()
    self.Head:GoNext()
    local body = self:ParseBody()
    self.Head:Expect("end", "Expected end after do body!")
    
    return Node.new("DoStatement", body, "Statement", self.Pos.Counter - 1)
end

-- While
function ParserClass:ParseWhileStatement()
    self.Head:GoNext()
    local con = self:ParseExpectedExpression()
    self.Head:Expect("do", "Expected do after while condition!")
    local body = self:ParseBody()
    self.Head:Expect("end", "Expected end after while!")
    
    return Node.new("WhileStatement", {
        con = con,
        body = body
    }, "Statement", self.Pos.Counter - 1)
end

-- Repeat
function ParserClass:ParseRepeatStatement()
    self.Head:GoNext()
    local body = self:ParseBody()
    self.Head:Expect("until", "Expected until after repear!")
    local con = self:ParseExpectedExpression()
    
    return Node.new("RepearStatement", {
        con = con,
        body = body
    }, "Statement", self.Pos.Counter - 1)
end

-- Return
function ParserClass:ParseReturnStatement(cur)
    cur = cur or self.Head:Current()
    
    local expressions = {}
    if not cur:Is("end") then
        self.Head:GoNext()
        while true do
            local expression = self:ParseExpectedExpression()
            if not expression then
                error("Expected expression")
            end
            table.insert(expressions, #expressions + 1, expression)
            
            if not self.Head:Consume(",") then
                break
            end
        end
    end
    
    return Node.new("ReturnStatement", expressions, "Statement", self.Pos.Counter - 1)
end

function ParserClass:ParseIfStatement()
    local statements = {}
    
    -- Parse the if statement
    self.Head:GoNext()
    local condition = self:ParseExpectedExpression()
    self.Head:Expect("then", "Expected then after if condition!")
    local body = self:ParseBody()
    
    table.insert(statements, #statements + 1, Node.new("IfStatement", {
        condition = condition,
        body = body
    }, "Statement", self.Pos.Counter - 1))
    
    -- Elseif
    while self.Head:Consume("elseif") do
        
        condition = self:ParseExpectedExpression()
        self.Head:Expect("then", "Expected then after elseif condition!")
        body = self:ParseBody()
        
        table.insert(statements, #statements + 1, Node.new("ElseIfStatement", {
            condition = condition,
            body = body
        }, "Statement", self.Pos.Counter - 1))
    end
    
    -- Else
    if self.Head:Consume("else") then
        
        condition = self:ParseExpectedExpression()
        self.Head:Expect("then", "Expected then after elseif condition!")
        body = self:ParseBody()
        
        table.insert(statements, #statements + 1, Node.new("ElseStatement", {
            condition = condition,
            body = body
        }, "Statement", self.Pos.Counter - 1))
    end
    self.Head:Expect("end", "Expected end after if!")
    
    return Node.new("IfStatement", {
        statements = statements
    }, "Statement", self.Pos.Counter - 1)
end

function ParserClass:ParseForStatement()
    local var = self:GetIdentifier(self.Head:GoNext())
    self.Head:GoNext()
    
    -- Normal number for loop
    if self.Head:Consume("=") then
        
        local start, stop, iter
        start = self:ParseExpectedExpression()
        self.Head:Expect(",", "Expected , after for start!")
        
        stop = self:ParseExpectedExpression()
        self.Head:GoNext()
        if self.Head:Consume(",") then
            iter = self:ParseExpectedExpression()
            self.Head:GoNext()
        end
        
        self.Head:Expect("do", "Expected do after for!")
        local body = self:ParseBody()
        self.Head:GoNextAndExpect("end", "Expected end after for!")
        
        return Node.new("NumericForStatement", {
            var = var,
            start = start,
            stop = stop,
            iter = iter,
            body = body
        }, "Statement", self.Pos.Counter - 1)
    else
        -- Other type
        
        local vars = {var}
        while self.Head:Consume(",") do
            table.insert(vars, #vars + 1, self:GetIdentifier())
        end
        
        self.Head:Expect("in", "Expected in after for!")
        local iters = {}
        while true do
            table.insert(iters, nil, self:ParseExpectedExpression())
            self.Head:GoNext()
            if not self.Head:Consume(",") then
                break
            end
        end
        self.Head:Expect("do", "Expected do after for!")
        local body = self:ParseBody()
        self.Head:GoNextAndExpect("end", "Expected end after for!")
        
        return Node.new("GenericForStatement", {
            vars = vars,
            iters = iters,
            body = body
        }, "Statement", self.Pos.Counter - 1)
    end
end

-- Local
function ParserClass:ParseLocalStatement()
    local name = self.Head:GoNext()
    
    if name:IsType("Identifier") then
        -- Typical local
        
        local vars, init = { name }, nil
        while self.Head:Consume(",") do
            table.insert(vars, #vars + 1, self:GetIdentifier())
        end
        self.Head:GoNext()
        
        -- Init values
        if self.Head:Consume("=") then
            init = { self:ParseExpectedExpression() }
            while self.Head:Consume(",") do
                table.insert(init, #init + 1, self:ParseExpectedExpression())
            end
        end
        
        return Node.new("LocalStatement", {
            idens = vars,
            inits = init
        }, "Statement", self.Pos.Counter - 1)
    elseif name:Is("function") then
        -- Local function
        name = self:GetIdentifier(self.Head:GoNext())
        return self:GetFunctionDefinition(name, true)
    else
        error("Expected identifier or function after local!")
    end
end

local AssignmentOrCallStatementTab = {
    ["."] = 1,
    ["["] = 1,
    ["("] = 2,
    [":"] = 2,
    ["{"] = 2,
}

function ParserClass:ParseAssignmentOrCallStatement(cur)
    cur = cur or self.Head:Current()
    
    -- Get all identifiers or expressions
    local names, base, isassignment = {}, nil, nil
    while true do
        
        -- Find identifier
        if cur:IsType("Identifier") then
            base = self:GetIdentifier()
            isassignment = true -- We check if it could be a call later
        elseif cur.Value == "(" then
            self.Head:GoNext()
            base = self:ParseExpectedExpression()
            self.Head:Expect(")", "Expected ) after expression!")
            isassignment = nil -- Can only be a function call
        else
            error("Expected assignment or call!")
        end
        
        -- Find prefixes, eg. "os.clock"
        while true do
            cur = self.Head:Current()
            if not cur then
                break
            elseif cur:IsType("Symbol") then
                
                local val = AssignmentOrCallStatementTab[cur.Value]
                if val == 1 then
                    isassignment = true
                elseif val == 2 then
                    isassignment = nil -- (, :, { can be used in function calls
                else
                    break
                end
            elseif cur:IsType("String") then
                isassignment = nil -- String cant be used as an assignment name
            else
                break
            end
            base = self:GetPrefixExpressionBase(base, cur)
        end
        
        table.insert(names, #names + 1, base)
        if not self.Head:Consume(",") then
            break
        elseif not isassignment then
            return error("Unexpected statement")
        end
        
        cur = self.Head:GoNext()
    end
    
    -- Call statement
    if #names == 1 and isassignment == nil then
        return Node.new("CallStatement", names[1], "Statement", self.Pos.Counter - 1)
    elseif not isassignment then
        -- We found to names but it is not a call?
        return error("Unexpected token")
    end
    
    -- If its not a call statement then it must be an assignment
    self.Head:Expect("=")
    
    local expressions = {}
    while true do
        table.insert(expressions, #expressions + 1, self:ParseExpectedExpression())
        if not self.Head:Consume(",") then
            break
        end
    end
    
    return Node.new("AssignmentStatement", {
        idens = names,
        values = expressions
    }, "Statement", self.Pos.Counter - 1)
end

-- UTIL

-- Get identifier
function ParserClass:GetIdentifier(cur)
    cur = cur or self.Head:Current()
    if cur:IsType("Identifier") then
        self.Head:GoNext()
        return Node.new("Identifier", cur.Value, "Identifier", self.Pos.Counter - 1)
    end
    error("Expected identifier!")
end

-- Get function body
function ParserClass:GetFunctionDefinition(name, islocal)
    if islocal == nil then
        islocal = false
    end
    
    self.Head:Expect("(", "Expected ( after function")
    local params = {}
    
    if not self.Head:Consume(")") then
        -- There are some params
        while true do
            local cur = self.Head:Current()
            if cur:Is("VarArgLiteral") then
                table.insert(params, #params + 1, cur)
                break -- Vararg is the last param
            elseif cur:IsType("Identifier") and self.Head:Next() then
                table.insert(params, #params + 1, self:GetIdentifier())
                if not self.Head:Consume(",") then
                    break
                end
            else
                error("Expected identifier or vararg!")
            end
        end
        self.Head:Expect(")", "Expected ) after function parameters!")
    end
    
    local body = self:ParseBody()
    self.Head:Expect("end", "Expected end after function body!")
    
    return Node.new("FunctionStatement", {
        name = name,
        params = params,
        body = body,
        islocal = islocal
    }, "Statement", self.Pos.Counter - 1)
end

-- Get function name
local function CreateMembership(base, index, name)
    return Node.new("MembershipExpression", {
        base = base,
        index = index,
        name = name
    }, "Expression")
    
end

function ParserClass:GetFunctionName(cur)
    cur = cur or self.Head:Current()
    self.Head:GoNext()
    
    while self.Head:Consume(".") do
        cur = CreateMembership(cur, ".", self:GetIdentifier())
    end
    
    if self.Head:Consume(":") then
        cur = CreateMembership(cur, ":", self:GetIdentifier())
    end
    return cur
end

function ParserClass:GetTableContructor()
    self.Head:GoNext() -- We expect that previous token was "{"
    local values, value, key = {}, nil, nil
    
    while true do
        local cur = self.Head:Current()
        if cur:IsType("Symbol") and cur.Value == "[" then
            self.Head:GoNext()
            key = self:ParseExpectedExpression()
            self.Head:Expect("]", "Expected ] after table key!")
            self.Head:Expected("=", "Expected = after table key!")
            value = self:ParseExpectedExpression()
            table.insert(values, #values + 1, Node.new("TableConstructorPair", {
                key = key,
                value = value
            }, "TableConstructor"))
        elseif cur:IsType("Indentifier") then
            
            if self.Head:Next().Value == "=" then
                key = self:GetIdentifier(cur)
                self.Head:GoNext() -- We known that this is "="
                value = self:ParseExpectedExpression()
                table.insert(values, #values + 1, Node.new("TableConstructorPair", {
                    key = key,
                    value = value
                }, "TableConstructor"))
            else
                value = self:ParseExpectedExpression()
                table.insert(values, #values + 1, Node.new("TableConstructorValue", value, "TableConstructor"))
            end
        else
            value = self:GetExpression()
            if not value then
                break
            end
            table.insert(values, #values + 1, Node.new("TableConstructorValue", value, "TableConstructor"))
        end
        
        -- Seperator
        cur = self.Head:Current()
        if cur.Value == "," or cur == ";" then
            self.Head:GoNext()
        else
            break
        end
    end
    self.Head:Expect("}", "Expected } after table constructor!")
    return Node.new("TableConstructor", values, "Expression")
end

function ParserClass:GetExpression()
    return self:GetSubExpression(0)
end

function ParserClass:ParseExpectedExpression()
    local expr = self:GetExpression()
    if not expr then
        error("Expected expression!")
    end
    return expr
end

local Precedens = {
    ["or"] = 1,
    ["and"] = 2,
    ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["~="] = 3, ["=="] = 3,
    [".."] = 4,
    ["+"] = 5, ["-"] = 5,
    ["*"] = 6, ["/"] = 6, ["%"] = 6,
    ["not"] = 7, ["#"] = 7, -- (Unary)
    ["^"] = 8,
}

function ParserClass:GetPrecedence(cur)
    cur = cur or self.Head:Current()
    if not cur then
        return 0
    end
    return Precedens[cur.Value] or 0
end

local Unary = {
    ["not"] = true, ["#"] = true, ["-"] = true
}

local function IsUnary(name)
    return Unary[name]
end

-- Sub expression
function ParserClass:GetSubExpression(minprec)
    local op, expr = self.Head:Current(), nil
    
    if IsUnary(op.Value) then
        -- Unary expr
        self.Head:GoNext()
        -- 7 is the precedence of unary
        local subexpr = self:GetSubExpression(7)
        if not subexpr then
            error("Expected expression after unary operator!")
        end
        expr = Node.new("UnaryExpression", {
            op = op,
            expr = subexpr
        }, "Expression")
    else
        -- Primary
        expr = self:GetLiteral()
        
        -- Prefix
        if not expr then
            expr = self:GetPrefixExpression()
        end
    end
    
    if not expr then
        return nil
    end
    
    -- Binop
    local precedence
    while true do
        op = self.Head:Current()
        precedence = self:GetPrecedence(op)
        
        if precedence == 0 or precedence <= minprec then
            break
        end
        -- Right hand
        if op.Value == "^" or op.Value == ".." then
            precedence = precedence - 1
        end
        self.Head:GoNext()
        
        local subexpr = self:GetSubExpression(precedence)
        if not subexpr then
            self.Head:GoNext()
            break
        end
        expr = Node.new("BinaryExpression", {
            op = op,
            left = expr,
            right = subexpr
        }, "Expression")
    end
    
    return expr
end

function ParserClass:GetPrefixExpressionBase(base, cur)
    cur = cur or self.Head:Current()
    
    if cur:IsType("Symbol") then
        if cur.Value == "." then
            self.Head:GoNext()
            return CreateMembership(base, ".", self:GetIdentifier())
        elseif cur.Value == "[" then
            self.Head:GoNext()
            local index = self:ParseExpectedExpression()
            self.Head:Expect("]", "Expected ] after table index!")
            return CreateMembership(base, "[", index)
        elseif cur.Value == ":" then
            self.Head:GoNext()
            base = CreateMembership(base, ":", self:GetIdentifier())
            
            -- : Can only be once in the last index, so this must be a call expression
            return self:GetCallExpression(base)
        elseif cur.Value == "(" or cur.Value == "{" then
            return self:GetCallExpression(base)
        end
    elseif cur:IsType("String") then
        return self:GetCallExpression(base)
    end
end

function ParserClass:GetPrefixExpression(cur)
    cur = cur or self.Head:Current()
    local name, base
    
    if cur:IsType("Identifier") then
        name = cur.Value
        base = self:GetIdentifier(cur)
    elseif self.Head:Consume("(") then
        base = self:ParseExpectedExpression()
        self.Head:Expect(")", "Expected ) after expression!")
    else
        return nil
    end
    
    -- Suffix
    while true do
        local part = self:GetPrefixExpressionBase(base)
        if not part then
            break
        end
        base = part
    end
    
    return base
end

function ParserClass:GetCallExpression(base, cur)
    cur = cur or self.Head:Current()
    
    if cur:IsType("Symbol") then
        
        if cur.Value == "(" then
            local exprs = {}
            
            self.Head:GoNext()
            if self.Head:Current().Value ~= ")" then
                local expr = self:GetExpression()
                if expr then
                    table.insert(exprs, #exprs + 1, expr)
                end
                
                while self.Head:Consume(",") do
                    table.insert(exprs, #exprs + 1, self:ParseExpectedExpression())
                end
            end
            
            self.Head:Expect(")", "Expected ) after expression!")
            return Node.new("CallExpression", {
                base = base,
                args = exprs
            }, "Expression")
        elseif cur.Value == "{" then
            self.Head:GoNext()
            local tab = self:ParseTableConstructor()
            return Node.new("TableCallExpression", {
                base = base,
                arg = tab
            }, "Expression")
        end
    
    elseif cur:IsType("String") then
        return Node.new("StringCallExpression", {
            base = base,
            arg = self:GetLiteral(cur),
        }, "Expression")
    end
    error("Unexpected function argument")
end

function ParserClass:GetLiteral(cur)
    cur = cur or self.Head:Current()
    
    if cur:IsType("String") or cur:IsType("Number") or cur:IsType("Boolean") or cur:Is("VarArgLiteral") or cur:Is("NilLiteral") then
        self.Head:GoNext()
        return cur
    elseif cur:Is("function") then
        self.Head:GoNext()
        return self:GetFunctionDefinition(nil, false)
    elseif self.Head:Consume("{") then
        return self:ParseTableConstructor()
    end
end

return ParserClass