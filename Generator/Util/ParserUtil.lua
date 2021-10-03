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

function ParserUtil:GetIdentifiers(comma)
    if comma == nil then
        comma = true
    end
    
    local idens = {}
    while self.Head:Current() and self.Head:Current():Is("Identifier") do
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

local function ValueInTable(tab, value)
    for _, val in pairs(tab) do
        if val == value then
            return true
        end
    end
    return false
end

function ParserUtil:GetBinOp(operators, func, ...)
    local left = func(...)
    
    while self.Head:Next() and self.Head:Next():Is("Operator") and ValueInTable(operators, self.Head:Next().Value) do
        local op = self.Head:GoNext()
        self.Head:GoNext()
        
        local right = func(...)
        if not right then
            error("Unexpected token: Expected a term or expression after operator at " .. self.Pos.Counter)
        end
        left = Node.new("BinaryExpression", {op, left, right}, "Expression", self.Pos.Counter)
    end
    
    return left
end

function ParserUtil:GetLiteral()
    local token = self:Get(0, false)
    if not token then
        return nil
    end
    
    if token:Is("Identifier") then
        return Node.new("Identifier", token.Value, "Identifier", self.Pos.Counter)
    elseif token:Is("Operator") then
        -- Unary operator
        local unary = self:GetUnary()
        if unary then
            return unary
        end
        error(ERR_TERM_OR_EXPR:format(token.Value, self.Pos.Counter))
        
    elseif token:Is("Symbol") then
        -- Parantheses
        if token.Value == "(" then
            self.Head:GoNext()
            local expr = self:GetExpr()
            if expr and self.Head:GoNext().Value == ")" then
                return expr
            end
        end
    else
        if token:IsType("Number") then
            return Node.new("NumericLiteral", token.Value, "Literal", self.Pos.Counter)
        elseif token:IsType("String") then
            return Node.new("StringLiteral", token.Value, "Literal", self.Pos.Counter)
        end
        return nil
    end
end

function ParserUtil:GetUnary()
    local token = self:Get(0, false, "Expected Unary got nil")
    if not token then
        return nil
    end
    
    if token:Is("Operator") and ValueInTable(UNARY_OPERATORS, token.Value) then
        self.Head:GoNext()
        local num = self:GetLiteral("Number")
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
    local idens = self:GetIdentifiers()
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
    local expr = self:GetLiteral()
    if not expr then
        error("Expected an expression after \"=\" at " .. self.Pos.Counter)
    end
    
    if islocal then
        return Node.new("LocalStatement", {idens, expr}, "Variable", self.Pos.Counter)
    else
        return Node.new("AssignmentStatement", {idens, expr}, "Variable", self.Pos.Counter)
    end
end

--#endregion

--#region Functions

function ParserUtil:GetArguments()
    return self:GetIdentifiers(true)
end

function ParserUtil:GetCallStatement()
    
    local cur = self:Get(0, true)
    if not (self.Head:Current() and self.Head:Current():Is("Identifier")) then
        return
    end
    
    -- Is call
    local start = self:Get(1, true)
    if start:Is("Symbol") and start.Value == "(" then
        self.Head:GoNext()
        self.Head:GoNext()
        
        local args = self:GetArguments()
        
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