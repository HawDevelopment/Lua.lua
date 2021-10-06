--[[
    Parser Util
    HawDevelopment
    02/10/2021
--]]

local Node = require("Generator.Util.Node")
local TakeTime = require("Generator.Debug.TakeTime")

local TAKETIME = true


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
    
    self.TakeTime = TakeTime.new()
    
    return self
end

function ParserUtil:Start()
    if TAKETIME then
        self.TakeTime:Start()
    end
end

function ParserUtil:Stop(name)
    if TAKETIME then
        self.TakeTime:Stop(name)
    end
end

--#region Util

function IsUnaryToken(token)
    return (token:IsType("Keyword") and token.Value == "not") or (token:Is("Operator") and ValueInTable(UNARY_OPERATORS, token.Value))
end

function ParserUtil:GetSeperated(tofind, comma, ...)
    self:Start()
    if comma == nil then
        comma = true
    end
    
    local idens = {}
    while true do
        local cur = self.Head:Current()
        
        if type(tofind) == "table" then
            if not ValueInTable(tofind, cur.Name) or ValueInTable(tofind, cur.Type) then
                break
            end
        elseif type(tofind) == "string" then
            if not (cur.Name == tofind or cur.Type == tofind) then
                break
            end
            self.Head:GoNext()
        elseif type(tofind) == "function" then
            cur = tofind(...)
        end
        
        table.insert(idens, cur)
        if comma and self.Head:Current() and self.Head:Current().Value == "," then
            self.Head:GoNext()
        else
            break
        end
    end
    
    self:Stop("GetSeperated")
    return idens
end

--#endregion

--#region Getting tokens

function ParserUtil:GetBinOp(operators, func, ...)
    self:Start()
    local left = func(...)
    while self.Head:Current() and self.Head:Current():Is("Operator") and ValueInTable(operators, self.Head:Current().Value) do
        local op = self.Head:Current()
        self.Head:GoNext()
        
        local right = func(...)
        if not right then
            self:Stop("GetBinOp")
            error("Unexpected token: Expected a term or expression after operator at " .. self.Pos.Counter)
        end
        left = Node.new("BinaryExpression", {op, left, right}, "Expression", self.Pos.Counter)
    end
    self:Stop("GetBinOp")
    return left
end

function ParserUtil:GetLiteral()
    self:Start()
    local token = self.Head:Current()
    if not token then
        self:Stop("GetLiteral")
        return nil
    end
    self.Head:GoNext()
    
    if token:Is("Identifier") then
        self:Stop("GetLiteral")
        return Node.new("Identifier", token.Value, "Identifier", self.Pos.Counter)
    elseif token:IsType("Number") or token:IsType("String") then
        self:Stop("GetLiteral")
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
                self:Stop("GetLiteral")
                return expr
            end
        end
    end
    self.Head:GoLast()
    self:Stop("GetLiteral")
    return nil
end

-- Math
do
    function ParserUtil:GetUnary()
        self:Start()
        local token = self.Head:Current()
        if not token then
            self:Stop("GetUnary")
            return nil
        end
        
        if IsUnaryToken(token) then
            self.Head:GoNext()
            local num = self:GetLiteral()
            if not num then
                self:Stop("GetUnary")
                error("Expected a number after unary operator at " .. self.Pos.Counter)
            end
            self:Stop("GetUnary")
            return Node.new("Unary", {token, num}, "Unary", self.Pos.Counter)
        end
        self:Stop("GetUnary")
        return nil 
    end
    
    function ParserUtil:GetPower()
        self:Start()
        self:Stop("GetPower")
        return self:GetBinOp({"^"}, self.GetLiteral, self)
    end
    
    function ParserUtil:GetFactor()
        self:Start()
        local cur = self.Head:Current()
        if not cur then
            self:Stop("GetFactor")
            return nil
        end
        
        if IsUnaryToken(cur) then
            self:Stop("GetFactor")
            return self:GetUnary()
        end
        self:Stop("GetFactor")
        return self:GetPower()
    end
    
    function ParserUtil:GetTerm()
        self:Start()
        self:Stop("GetTerm")
        return self:GetBinOp(TERM_OPERATORS, self.GetFactor, self)
    end
    
    function ParserUtil:GetExpr()
        self:Start()
        self:Stop("GetExpr")
        return self:GetBinOp(EXPR_OPERATORS, self.GetTerm, self)
    end
end

--#region Variables

function ParserUtil:GetVariable()
    self:Start()
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
            self:Stop("GetVariable")
            error("Expected an identifier after \"local\" at " .. self.Pos.Counter)
        elseif self.Head:Next().Value == "=" then
            self:Stop("GetVariable")
            error("Expected an identifier in variable at " .. self.Pos.Counter)
        else
            self:Stop("GetVariable")
            return
        end
    end
    
    self.Head:GoNext()
    
    -- Get expr
    local init
    if self.Head:Current() and self.Head:Current().Value == "=" then
        init = self:GetSeperated(self.GetLiteral, true, self)
        if #init == 0 then
            self:Stop("GetVariable")
            error("Expected an expression after \"=\" at " .. self.Pos.Counter)
        end
    end
    
    self:Stop("GetVariable")
    return Node.new(islocal and "LocalStatement" or "AssignmentStatement", {idens, init}, "Variable", self.Pos.Counter)
end

--#endregion

--#region Functions

function ParserUtil:GetArguments()
    self:Start()
    self:Stop("GetArguments")
    return self:GetSeperated(self.GetExpr, true, self)
end

function ParserUtil:GetCallStatement()
    self:Start()
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
        
        -- We dont go next, because the parent caller will do that
        if not self.Head:Current().Value == ")" then
            self:Stop("GetCallStatement")
            error("Expected \")\" after arguments at " .. self.Pos.Counter)
        end
        
        self:Stop("GetCallStatement")
        return Node.new("CallStatement", {cur, args}, "Statement", self.Pos.Counter)
    end
    self:Stop("GetCallStatement")
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