--[[
    Parser Util
    HawDevelopment
    02/10/2021
--]]

local Node = require("src.Generator.Util.Node")

local ParserUtil = {}
ParserUtil.__index = ParserUtil

local SKIP_WHITESPACE = true

local UNARY_OPERATORS = { "-", "+" }
local TERM_OPERATORS = {"*", "/", "%"}
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

function IsUnaryToken(token)
    return (token:IsType("Keyword") and token.Value == "not") or (token:Is("Operator") and ValueInTable(UNARY_OPERATORS, token.Value))
end

function ParserUtil:GetSeperated(tofind, comma, ...)
    if comma == nil then
        comma = true
    end
    
    local idens, cur = {}, nil
    
    while true do
        cur = self.Head:Current()
        if type(tofind) == "string" then
            if not (cur.Name == tofind) then
                break
            end
            self.Head:GoNext()
        elseif type(tofind) == "function" then
            cur = tofind(...)
        elseif type(tofind) == "table" then
            if not ValueInTable(tofind, cur.Name) then
                break
            end
            self.Head:GoNext()
        end
        
        table.insert(idens, cur)
        cur = self.Head:Current()
        if comma and cur and cur.Value == "," then
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
    while self.Head:Current() and self.Head:Current():Is("Operator") and ValueInTable(operators, self.Head:Current().Value) do
        local op = self.Head:Current()
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
    local token = self.Head:Current()
    if not token then
        return nil
    end
    self.Head:GoNext()
    
    if token:Is("Identifier") then
        
        return Node.new("Identifier", token.Value, "Identifier", self.Pos.Counter)
    elseif token:IsType("Number") or token:IsType("String") then
        
        if token:IsType("Number") then
            return Node.new("NumberLiteral", token.Value, "Literal", self.Pos.Counter)
        elseif token:IsType("String") then
            return Node.new("StringLiteral", token.Value, "Literal", self.Pos.Counter)
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
    self.Head:GoLast()
    return nil
end

-- Math
do
    function ParserUtil:GetUnary()
        local token = self.Head:Current()
        if not token then
            return nil
        end
        
        if IsUnaryToken(token) then
            self.Head:GoNext()
            local num = self:GetLiteral()
            if not num then
                error("Expected a number after unary operator at " .. self.Pos.Counter)
            end
            return Node.new("Unary", {token, num}, "Unary", self.Pos.Counter)
        end
        return nil 
    end
    
    function ParserUtil:GetPower()
        return self:GetBinOp({"^"}, self.GetLiteral, self)
    end
    
    function ParserUtil:GetFactor()
        local cur = self.Head:Current()
        if not cur then
            return nil
        end
        
        if IsUnaryToken(cur) then
            return self:GetUnary()
        end
        return self:GetPower()
    end
    
    function ParserUtil:GetTerm()
        return self:GetBinOp(TERM_OPERATORS, self.GetFactor, self)
    end
    
    function ParserUtil:GetExpr()
        return self:GetBinOp(EXPR_OPERATORS, self.GetTerm, self)
    end
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
    if #idens == 0 then
        if islocal then
            error("Expected an identifier after \"local\" at " .. self.Pos.Counter)
        elseif self.Head:Next().Value == "=" then
            error("Expected an identifier in variable at " .. self.Pos.Counter)
        else
            return
        end
    end
    
    -- Get expr
    local init
    if self.Head:Current() and self.Head:Current().Value == "=" then
        self.Head:GoNext()
        init = self:GetSeperated(self.GetExpr, true, self)
        if #init == 0 then
            error("Expected an expression after \"=\" at " .. self.Pos.Counter)
        end
    end
    
    return Node.new(islocal and "LocalStatement" or "AssignmentStatement", {idens, init}, "Variable", self.Pos.Counter)
end

--#endregion

--#region Functions

function ParserUtil:GetArguments()
    return self:GetSeperated(self.GetExpr, true, self)
end

function ParserUtil:GetCallStatement()
    local cur = self.Head:Current()
    if not (cur and cur:Is("Identifier")) then
        return
    end
    
    -- Is call
    local parantheses = self.Head:GoNext()
    if parantheses and parantheses:Is("Symbol") and parantheses.Value == "(" then
        self.Head:GoNext()
        local args
        
        -- Could save performance by not calling GetArguments if there are no arguments or if theres only one
        local next, nextnext = self.Head:Current(), self.Head:Next()
        if (next and next.Value == ")") or (nextnext and nextnext.Value == ")") then
            if next.Value == ")" then
                args = {}
            else
                args = { self:GetExpr() }
            end
        else
            args = self:GetArguments()
        end
        
        -- We dont go next, because the parent caller will do that
        if not self.Head:Current().Value == ")" then
            error("Expected \")\" after arguments at " .. self.Pos.Counter)
        end

        return Node.new("CallStatement", {cur, args}, "Statement", self.Pos.Counter)
    end
    return
end

--#endregion

--#endregion

function ParserUtil:Destroy()
    for key, _ in pairs(self) do
        self[key] = nil
    end
end

return ParserUtil