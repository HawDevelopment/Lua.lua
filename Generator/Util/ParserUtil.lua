--[[
    Parser Util
    HawDevelopment
    02/10/2021
--]]

local Node = require("Generator.Util.Node")

local ParserUtil = {}
ParserUtil.__index = ParserUtil

local SKIP_WHITESPACE = true

local UNARY_OPERATORS = { "-", "+" }
local TERM_OPERATORS = {"*", "/", "%", "^"}
local EXPR_OPERATORS = {"+", "-"}

local ERR_TERM_OR_EXPR = "Unexpected symbol: Expected a term or expression, got \"%s\" at %s"

local function ValueInTable(tab, value)
    for _, val in pairs(tab) do
        if val == value then
            return true
        end
    end
    return false
end

function ParserUtil.new(tokens, head)
    local self = setmetatable({}, ParserUtil)
    
    self.Tokens = tokens
    self.Head = head
    self.Pos = head.Pos
    
    return self
end

--#region Util

function ParserUtil:Get(delta, doerror, error_message)
    local token, err, toskip = nil, delta, delta > 0 and 1 or -1
    repeat
        token, err = self.Tokens[self.Pos.Counter + err], err + toskip
    until not token or (SKIP_WHITESPACE and not token:Is("WhiteSpace"))
    
    if doerror and not token then
        error_message = error_message or "Unexpected token"
        error(error_message .. " at " .. self.Pos.Counter + delta)
    end
    return token
end

function ParserUtil:GetType(delta, _type, doerror, error_message, nil_message)
    error_message = error_message or "Unexpected token type"
    nil_message = nil_message or "Unexpected nil"
    
    local token = self:Get(delta, doerror, nil_message)
    if type(_type) == "string" then
        if not token:Is(_type) and doerror then
            error(error_message .. " at " .. self.Pos.Counter + delta)
        end
    elseif type(_type) == "table" then
        for _, t in pairs(_type) do
            if token:Is(t) then
                return token
            end
        end
        if doerror then
            error(error_message .. " at " .. self.Pos.Counter + delta)
        end
    end
    
    return token
end

function ParserUtil:GetSeperated(tofind, comma)
    if comma == nil then
        comma = true
    end
    
    local idens = {}
    while
        self.Head:Current() and
        (type(tofind) == "table" and ValueInTable(tofind, self.Head:Current().Name) or self.Head:Current():Is(tofind))
    do
        table.insert(idens, self.Head:Current())
        self.Head:GoNext()
        if comma and self.Head:Current().Value == "," then
            self.Head:GoNext()
        else
            break
        end
    end
    
    return idens
end

--#endregion

--#region Getting tokens

function ParserUtil:GetBinOp(operators, func, ...)
    local left = func(...)
    print(1)
    while self.Head:Current() and self.Head:Current():Is("Operator") and ValueInTable(operators, self.Head:Current().Value) do
        local op = self.Head:Current()
        self.Head:GoNext()
        
        local right = func(...)
        if not right then
            error("Unexpected token: Expected a term or expression after operator at " .. self.Pos.Counter)
        end
        left = Node.new("BinaryExpression", {op, left, right}, "Expression", self.Pos.Counter)
        print(2)
    end
    print(3)
    return left
end

function ParserUtil:GetLiteral()
    local token = self.Head:Current()
    if not token then
        return nil
    end
    self.Head:GoNext()
    print(token.Name)
    
    if token:Is("Identifier") then
        
        return Node.new("Identifier", token.Value, "Identifier", self.Pos.Counter)
    elseif token:IsType("Number") or token:IsType("String") then
        
        if token:IsType("Number") then
            return Node.new("NumberLiteral", token.Value, "Literal", self.Pos.Counter)
        elseif token:IsType("String") then
            return Node.new("StringLiteral", token.Value, "Literal", self.Pos.Counter)
        end
    elseif token:Is("Operator") then
        -- Unary operator
        local unary = self:GetUnary()
        if unary then
            return unary
        end
        
    elseif token:Is("Symbol") then
        -- Parantheses
        if token.Value == "(" then
            local expr = self:GetExpr()
            if expr and self.Head:Current().Value == ")" then
                self.Head:GoNext()
                return expr
            end
        end
    end
    return nil
end

function ParserUtil:GetUnary()
    local token = self:Get(0, false, "Expected Unary got nil")
    if not token then
        return nil
    end
    
    if token:Is("Operator") and ValueInTable(UNARY_OPERATORS, token.Value) then
        self.Head:GoNext()
        local num = self:GetLiteral()
        if not num then
            error("Expected a number after unary operator at " .. self.Pos.Counter)
        end
        return Node.new("Unary", {token, num}, "Unary", self.Pos.Counter)
    end
    return nil 
end

function ParserUtil:GetTerm()
    return self:GetBinOp(TERM_OPERATORS, self.GetLiteral, self)
end

function ParserUtil:GetExpr()
    return self:GetBinOp(EXPR_OPERATORS, self.GetTerm, self)
end

--#region Variables

function ParserUtil:GetVariable()
    --TODO: Add table values
    
    -- Is it local
    local islocal = false
    if self.Head:Current():Is("Keyword") and self.Head:Current().Value == "local" then
        islocal = true
        self.Head:GoNext()
    end
    
    -- Get names
    local idens = self:GetSeperated("Identifier", true)
    if islocal and #idens == 0 then
        error("Expected an identifier after \"local\" at " .. self.Pos.Counter)
    end
    if #idens == 0 then
        if self.Head:Next().Value == "=" then
            error("Expected an identifier in variable at " .. self.Pos.Counter)
        else
            return
        end
    end
    
    self.Head:GoNext()
    
    -- Get expr
    local exprs = {}
    while true do
        if not self.Head:Current() then
            break
        end
        local before = self.Pos.Counter
        local expr = self:GetExpr()
        if not expr then
            self.Pos.Counter = before
            break
        end
        table.insert(exprs, expr)
    end
    if not #exprs == 0 then
        error("Expected an expression after \"=\" at " .. self.Pos.Counter)
    end
    
    if islocal then
        return Node.new("LocalStatement", {idens, exprs}, "Variable", self.Pos.Counter)
    else
        return Node.new("AssignmentStatement", {idens, exprs}, "Variable", self.Pos.Counter)
    end
end

--#endregion

--#region Functions

function ParserUtil:GetArguments()
    return self:GetExpr()
end

function ParserUtil:GetCallStatement()
    
    local cur = self.Head:Current()
    if not (self.Head:Current() and self.Head:Current():Is("Identifier")) then
        return
    else
        self.Head:GoNext()
    end
    
    -- Is call
    local start = self.Head:Current()
    if start and start:Is("Symbol") and start.Value == "(" then
        self.Head:GoNext()
        
        local args = self:GetArguments()
        print(self:Get(-1):rep())
        if self.Head:Current().Value == ")" then
            self.Head:GoNext()
        else
            error("Expected \")\" after arguments at " .. self.Pos.Counter)
        end
        
        return Node.new("CallExpression", {cur, args}, "Expression", self.Pos.Counter)
    else
        return
    end
end

--#endregion

--#endregion

function ParserUtil:Destroy()
    for key, _ in pairs(self) do
        self[key] = nil
    end
end

return ParserUtil