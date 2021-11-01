--[[
    Parser class
    HawDevelopment
    09/10/2021
--]]

local ALLOW_SELF_MATH = true -- Allow math to be alone (not being in a statement)

local ParserClass = {}
ParserClass.__index = ParserClass

function ParserClass.new(tokens, head)
    local self = setmetatable({}, ParserClass)
    
    self.Tokens = tokens
    self.Head = head
    
    return self
end

function ParserClass:ParseChunk()
    
    local body = self:ParseBody()
    if self.Head:Next() then
        error("Unexpected token: " .. self.Head:Next().Type)
    end
    return { Name = "Chunk", Value = body, Type = "Chunk", Pos = { Line = 0, Colum = 0, Pos = 0 } }
end

local function IsBodyCloser(token)
    if not token then
        return true
    elseif not (token.Type == "Keyword" or token.Type == "Identifier") then
        return false
    end
    if token.Name == "else" or token.Name == "elseif" or token.Name == "end" or token.Name == "until" then
        return true
    end
    return false
end

function ParserClass:ParseBody()
    local body, statement = {}, nil
    while not IsBodyCloser(self.Head:Current()) do
        local cur = self.Head:Current()
        if cur and (cur.Value == "return" or cur.Value == "break") and cur.Type == "Keyword" then
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
    
    if cur.Type == "Keyword" then
        
        local index = KeywordToFunction[cur.Name]
        if index then
            return self[index](self, cur)
        else
            error("Unexpected token " .. cur:rep())
        end
    elseif ALLOW_SELF_MATH and (cur.Type == "Number" or cur.Type == "Operator") then
        return self:GetExpression(0)
    end
    
    -- If its not a keyword it then it must be assignment or call
    return self:ParseAssignmentOrCallStatement(cur)
end

-- Statements

-- Function
function ParserClass:ParseFunctionStatement(cur)
    local name = self:GetFunctionName(self.Head:GoNext())
    return self:GetFunctionDefinition(name, false, cur.Position)
end

-- Break
function ParserClass:ParseBreakStatement(cur)
    self.Head:GoNext()
    return { Name = "BreakStatement", Value = cur.Value, Type = "Statement", Position = cur.Position }
end

-- Do
function ParserClass:ParseDoStatement(cur)
    self.Head:GoNext()
    local body = self:ParseBody()
    self.Head:Expect("end", "Expected end after do body!")
    
    return { Name = "DoStatement", Value = body, Type = "Statement", Position = cur.Position }
end

-- While
function ParserClass:ParseWhileStatement(cur)
    self.Head:GoNext()
    local con = self:GetExpectedExpression()
    self.Head:Expect("do", "Expected do after while condition!")
    local body = self:ParseBody()
    self.Head:Expect("end", "Expected end after while!")
    
    return { Name = "WhileStatement", Value = {
        con = con,
        body = body
    }, Type = "Statement", Position = cur.Position }
end

-- Repeat
function ParserClass:ParseRepeatStatement(cur)
    self.Head:GoNext()
    local body = self:ParseBody()
    self.Head:Expect("until", "Expected until after repear!")
    local con = self:GetExpectedExpression()
    
    return { Name = "RepearStatement", Value = {
        con = con,
        body = body
    }, Type = "Statement", Position = cur.Position }
end

-- Return
function ParserClass:ParseReturnStatement(cur)
    cur = cur or self.Head:Current()
    
    local expressions = {}
    if self.Head:Next() and self.Head:Next().Name ~= "end" then
        self.Head:GoNext()
        while true do
            local expression = self:GetExpectedExpression()
            if not expression then
                error("Expected expression")
            end
            table.insert(expressions, #expressions + 1, expression)
            
            if not self.Head:Consume(",") then
                break
            end
        end
    else
        self.Head:GoNext()
    end
    
    return { Name = "ReturnStatement", Value = expressions, Type = "Statement", Position = cur.Position }
end

function ParserClass:ParseIfStatement(cur)
    local statements = {}
    
    -- Parse the if statement
    self.Head:GoNext()
    local condition = self:GetExpectedExpression()
    self.Head:Expect("then", "Expected then after if condition!")
    local body = self:ParseBody()
    
    table.insert(statements, #statements + 1, { Name = "IfStatement", Value = {
        condition = condition,
        body = body
    }, Type = "Statement", Position = cur.Position })
    
    -- Elseif
    while true do
        local token = self.Head:Current()
        if token.Name ~= "elseif" then
            break
        end
        
        condition = self:GetExpectedExpression()
        self.Head:Expect("then", "Expected then after elseif condition!")
        body = self:ParseBody()
        
        table.insert(statements, #statements + 1, { Name = "ElseIfStatement", Value = {
            condition = condition,
            body = body
        }, Type = "Statement", Position = token.Position })
    end
    
    -- Else
    local token = self.Head:Current()
    if token.Name == "else" then
        
        self.Head:GoNext()
        body = self:ParseBody()
        
        table.insert(statements, #statements + 1, { Name = "ElseStatement", Value = {
            body = body
        }, Type = "Statement", Position = token.Position })
    end
    self.Head:Expect("end", "Expected end after if!")
    
    return { Name = "IfStatement", Value = {
        statements = statements
    }, Type = "Statement", Position = cur.Position }
end

function ParserClass:ParseForStatement(cur)
    local var = self:GetIdentifier(self.Head:GoNext())
    
    -- Normal number for loop
    if self.Head:Current().Value == "=" then
        self.Head:GoNext()
        local start, stop, iter
        
        start = self:GetExpectedExpression()
        self.Head:Expect(",", "Expected , after for start!")
        stop = self:GetExpectedExpression()
        
        if self.Head:Consume(",") then
            iter = self:GetExpectedExpression()
        end
        
        self.Head:Expect("do", "Expected do after for!")
        local body = self:ParseBody()
        self.Head:Expect("end", "Expected end after for!")
        
        return { Name = "NumericForStatement", Value = {
            var = var,
            start = start,
            stop = stop,
            iter = iter,
            body = body
        }, Type = "Statement", Position = cur.Position }
    else
        -- Other type
        
        local vars = {var}
        while self.Head:Consume(",") do
            table.insert(vars, #vars + 1, self:GetIdentifier())
        end
        
        self.Head:Expect("in", "Expected in after for!")
        local iters = {}
        while true do
            table.insert(iters, nil, self:GetExpectedExpression())
            self.Head:GoNext()
            if not self.Head:Consume(",") then
                break
            end
        end
        self.Head:Expect("do", "Expected do after for!")
        local body = self:ParseBody()
        self.Head:GoNextAndExpect("end", "Expected end after for!")
        
        return { Name = "GenericForStatement", Value = {
            vars = vars,
            iters = iters,
            body = body
        }, Type = "Statement", Position = cur.Position }
    end
end

-- Local
function ParserClass:ParseLocalStatement(cur)
    local name = self.Head:GoNext()
    
    if name.Type == "Identifier" then
        -- Typical local
        
        local vars, init = { name }, nil
        while self.Head:Consume(",") do
            table.insert(vars, #vars + 1, self:GetIdentifier())
        end
        self.Head:GoNext()
        
        -- Init values
        if self.Head:Consume("=") then
            init = { self:GetExpectedExpression() }
            while self.Head:Consume(",") do
                table.insert(init, #init + 1, self:GetExpectedExpression())
            end
        end
        
        return { Name = "LocalStatement", Value = {
            idens = vars,
            inits = init
        }, Type = "Statement", Position = cur.Position }
    elseif name.Name == "function" then
        -- Local function
        name = self:GetIdentifier(self.Head:GoNext())
        return self:GetFunctionDefinition(name, true, cur.Position)
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

function ParserClass:ParseAssignmentOrCallStatement(start)
    local cur = start or self.Head:Current()
    
    -- Get all identifiers or expressions
    local names, base, isassignment = {}, nil, nil
    while true do
        
        -- Find identifier
        if cur.Type == "Identifier" then
            base = self:GetIdentifier()
            isassignment = true -- We check if it could be a call later
        elseif cur.Value == "(" then
            self.Head:GoNext()
            base = self:GetExpectedExpression()
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
            elseif cur.Type == "Symbol" then
                
                local val = AssignmentOrCallStatementTab[cur.Value]
                if val == 1 then
                    isassignment = true
                elseif val == 2 then
                    isassignment = nil -- (, :, { can be used in function calls
                else
                    break
                end
            elseif cur.Type == "String" then
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
        return { Name = "CallStatement", Value = names[1], Type = "Statement", Position = start.Position }
    elseif not isassignment then
        -- We found to names but it is not a call?
        return error("Unexpected token")
    end
    
    -- If its not a call statement then it must be an assignment
    self.Head:Expect("=")
    
    local expressions = {}
    while true do
        table.insert(expressions, #expressions + 1, self:GetExpectedExpression())
        if not self.Head:Consume(",") then
            break
        end
    end
    
    return { Name = "AssignmentStatement", Value = {
        idens = names,
        values = expressions
    }, Type = "Statement", Position = start.Position }
end

-- UTIL

-- Get identifier
function ParserClass:GetIdentifier(cur)
    cur = cur or self.Head:Current()
    if cur.Type == "Identifier" then
        self.Head:GoNext()
        return cur
    end
    error("Expected identifier!")
end

-- Get function body
function ParserClass:GetFunctionDefinition(name, islocal, pos)
    pos = pos or error("Expected a position!")
    if islocal == nil then
        islocal = false
    end
    
    self.Head:Expect("(", "Expected ( after function")
    local params = {}
    
    if not self.Head:Consume(")") then
        -- There are some params
        while true do
            local cur = self.Head:Current()
            if cur.Name == "VarArgLiteral" then
                table.insert(params, #params + 1, cur)
                break -- Vararg is the last param
            elseif cur.Type == "Identifier" and self.Head:Next() then
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
    
    return { Name = "FunctionStatement", Value = {
        name = name,
        params = params,
        body = body,
        islocal = islocal
    }, Type = "Statement", Position = pos }
end

-- Get function name
local function CreateMembership(base, index, name)
    return { Name = "MembershipExpression", Value = {
        base = base,
        index = index,
        name = name
    }, Type = "Expression", Position = base.Position }
    
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

function ParserClass:GetTableContructor(cur)
    self.Head:GoNext() -- We expect that previous token was "{"
    local values, value, key = {}, nil, nil
    
    while true do
        local token = self.Head:Current()
        if token:IsType("Symbol") and token.Value == "[" then
            self.Head:GoNext()
            key = self:GetExpectedExpression()
            self.Head:Expect("]", "Expected ] after table key!")
            self.Head:Expected("=", "Expected = after table key!")
            value = self:GetExpectedExpression()
            table.insert(values, #values + 1, { Name = "TableConstructorPair", Value = {
                key = key,
                value = value
            }, Type = "TableConstructor", Position = token.Position })
        elseif token:IsType("Indentifier") then
            
            if self.Head:Next().Value == "=" then
                key = self:GetIdentifier(token)
                self.Head:GoNext() -- We known that this is "="
                value = self:GetExpectedExpression()
                table.insert(values, #values + 1, { Name = "TableConstructorPair", Value = {
                    key = key,
                    value = value
                }, Type = "TableConstructor", Position = token.Position })
            else
                value = self:GetExpectedExpression()
                table.insert(values, #values + 1, { Name = "TableConstructorValue", Value = value, Type = "TableConstructor", Position = token.Position })
            end
        else
            value = self:GetExpression(0)
            if not value then
                break
            end
            table.insert(values, #values + 1, { Name = "TableConstructorValue", Value = value, Type = "TableConstructor", Position = token.Position })
        end
        
        -- Seperator
        token = self.Head:Current()
        if token.Value == "," or token == ";" then
            self.Head:GoNext()
        else
            break
        end
    end
    self.Head:Expect("}", "Expected } after table constructor!")
    return { Name = "TableConstructor", Value = values, Type = "Expression", Position = cur.Position }
end

function ParserClass:GetExpectedExpression()
    local expr = self:GetExpression(0)
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
function ParserClass:GetExpression(minprec)
    local op, expr = self.Head:Current(), nil
    
    if IsUnary(op.Value) then
        -- Unary expr
        self.Head:GoNext()
        -- 7 is the precedence of unary
        local subexpr = self:GetExpression(7)
        if not subexpr then
            error("Expected expression after unary operator!")
        end
        expr = { Name = "UnaryExpression", Value = {
            op = op,
            expr = subexpr
        }, Type = "Expression", Position = op.Position }
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
        
        local subexpr = self:GetExpression(precedence)
        if not subexpr then
            self.Head:GoNext()
            break
        end
        expr = { Name = "BinaryExpression", Value = {
            op = op,
            left = expr,
            right = subexpr
        }, Type = "Expression", Position = expr.Position }
    end
    return expr
end

function ParserClass:GetPrefixExpressionBase(base, cur)
    cur = cur or self.Head:Current()
    if not cur then
        return nil
    end
    
    if cur.Type == "Symbol" then
        if cur.Value == "." then
            self.Head:GoNext()
            return CreateMembership(base, ".", self:GetIdentifier())
        elseif cur.Value == "[" then
            self.Head:GoNext()
            local index = self:GetExpectedExpression()
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
    elseif cur.Type == "String" then
        return self:GetCallExpression(base)
    end
end

function ParserClass:GetPrefixExpression(cur)
    cur = cur or self.Head:Current()
    local name, base
    
    if cur.Type == "Identifier" then
        name = cur.Value
        base = self:GetIdentifier(cur)
    elseif self.Head:Consume("(") then
        base = self:GetExpectedExpression()
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
    
    if cur.Type == "Symbol" then
        
        if cur.Value == "(" then
            local exprs = {}
            
            if self.Head:GoNext() and self.Head:Current().Value ~= ")" then
                local expr = self:GetExpression(0)
                if expr then
                    table.insert(exprs, #exprs + 1, expr)
                end
                
                while self.Head:Consume(",") do
                    table.insert(exprs, #exprs + 1, self:GetExpectedExpression())
                end
            end
            
            self.Head:Expect(")", "Expected ) after expression!")
            return { Name = "CallExpression", Value = {
                base = base,
                args = exprs
            }, Type = "Expression", Position = base.Position }
        elseif cur.Value == "{" then
            self.Head:GoNext()
            local tab = self:ParseTableConstructor()
            return { Name = "TableCallExpression", Value = {
                base = base,
                arg = tab
            }, Type = "Expression", Position = base.Position }
        end
    
    elseif cur.Type == "String" then
        return { Name = "StringCallExpression", Value = {
            base = base,
            arg = self:GetLiteral(cur),
        }, Type = "Expression", Position = base.Position }
    end
    error("Unexpected function argument")
end

function ParserClass:GetLiteral(cur)
    cur = cur or self.Head:Current()
    
    if cur.Type == "String" or cur.Type == "Number" or cur.Type == "Boolean" or cur.Name == "VarArgLiteral" or cur.Name == "NilLiteral" then
        self.Head:GoNext()
        return cur
    elseif cur.Name == "function" then
        self.Head:GoNext()
        return self:GetFunctionDefinition(nil, false)
    elseif self.Head:Consume("{") then
        return self:ParseTableConstructor()
    end
end

return ParserClass