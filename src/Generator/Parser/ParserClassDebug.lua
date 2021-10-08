--[[
    Parser Util
    HawDevelopment
    02/10/2021
--]]

local Node = require("src.Generator.Util.Node")
local TakeTime = require("src.Generator.Debug.TakeTime")
local TakeTimeCopy = require("src.Generator.Debug.TakeTimeCopy")

local TAKE_TIME = true

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
    
    self.Timer = TAKE_TIME and TakeTime.new() or TakeTimeCopy
    
    return self
end

--#region Util

function IsUnaryToken(token)
    return (token:IsType("Keyword") and token.Value == "not") or (token:Is("Operator") and ValueInTable(UNARY_OPERATORS, token.Value))
end

function ParserUtil:GetSeperated(tofind, comma, ...)
    print("Getting seperated")
    local time = self.Timer:Start()
    if comma == nil then
        comma = true
    end
    local idens, cur = {}, nil
    
    while true do
        local calltime = self.Timer:Start()
        
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
        calltime("SeperateCall")
        
        table.insert(idens, cur)
        cur = self.Head:Current()
        if comma and cur and cur.Value == "," then
            self.Head:GoNext()
        else
            break
        end
    end
    
    time("GetSeperated")
    return idens
end

--#endregion

--#region Getting tokens

function ParserUtil:GetBinOp(operators, func, ...)
    local time = self.Timer:Start()
    local left = func(...)
    while self.Head:Current() and self.Head:Current():Is("Operator") and ValueInTable(operators, self.Head:Current().Value) do
        local op = self.Head:Current()
        self.Head:GoNext()
        
        local right = func(...)
        if not right then
            time("GetBinOp") 
            error("Unexpected token: Expected a term or expression after operator at " .. self.Pos.Counter)
        end
        left = Node.new("BinaryExpression", {op, left, right}, "Expression", self.Pos.Counter)
    end
    
    time("GetBinOp") 
    return left
end

function ParserUtil:GetLiteral()
    local time = self.Timer:Start()
    
    local token = self.Head:Current()
    self.Head:GoNext()
    
    if token:Is("Identifier") then
        time("GetLiteral")
        return Node.new("Identifier", token.Value, "Identifier", self.Pos.Counter)
    elseif token:IsType("Number") or token:IsType("String") then
        time("GetLiteral")
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
                time("GetLiteral")
                return expr
            end
        end
    end
    self.Head:GoLast()
    time("GetLiteral")
    return nil
end

-- Math
do
    function ParserUtil:GetUnary()
        local time = self.Timer:Start()
        
        local token = self.Head:Current()
        if not token then
            self:Stop("GetUnary")
            return nil
        end
        
        if IsUnaryToken(token) then
            self.Head:GoNext()
            local num = self:GetLiteral()
            if not num then
                time("GetUnary")
                error("Expected a number after unary operator at " .. self.Pos.Counter)
            end
            return Node.new("Unary", {token, num}, "Unary", self.Pos.Counter)
        end
        
        time("GetUnary")
        return nil 
    end
    
    function ParserUtil:GetPower()
        local time = self.Timer:Start()
        local ret = self:GetBinOp({"^"}, self.GetLiteral, self)
        
        time("GetPower")
        return ret
    end
    
    function ParserUtil:GetFactor()
        local time = self.Timer:Start()
        local cur = self.Head:Current()
        if not cur then
            self:Stop("GetFactor")
            return nil
        end
        
        local ret
        if IsUnaryToken(cur) then
            ret = self:GetUnary()
        else
            ret = self:GetPower()
        end
        
        time("GetFactor")
        return ret
    end
    
    function ParserUtil:GetTerm()
        local time = self.Timer:Start()
        local ret = self:GetBinOp(TERM_OPERATORS, self.GetFactor, self)
        time("GetTerm")
        return ret
    end
    
    function ParserUtil:GetExpr()
        local time = self.Timer:Start()
        local ret = self:GetBinOp(EXPR_OPERATORS, self.GetTerm, self)
        time("GetExpr")
        return ret
    end
end

--#region Variables

function ParserUtil:GetVariable()
    local time = self.Timer:Start()
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
            time("GetVariable")
            error("Expected an identifier after \"local\" at " .. self.Pos.Counter)
        elseif self.Head:Next().Value == "=" then
            time("GetVariable")
            error("Expected an identifier in variable at " .. self.Pos.Counter)
        else
            time("GetVariable")
            return
        end
    end
    
    -- Get expr
    local init
    if self.Head:Current() and self.Head:Current().Value == "=" then
        self.Head:GoNext()
        init = self:GetSeperated(self.GetExpr, true, self)
        if #init == 0 then
            time("GetVariable")
            error("Expected an expression after \"=\" at " .. self.Pos.Counter)
        end
    end
    
    time("GetVariable")
    return Node.new(islocal and "LocalStatement" or "AssignmentStatement", {idens, init}, "Variable", self.Pos.Counter)
end

--#endregion

--#region Functions

function ParserUtil:GetArguments()
    return self:GetSeperated(self.GetExpr, true, self)
end

function ParserUtil:GetCallStatement()
    local time = self.Timer:Start()

    local cur = self.Head:Current()
    if not (cur and cur:Is("Identifier")) then
        return
    end
    
    -- Is call
    local parantheses = self.Head:GoNext()
    if parantheses and parantheses:Is("Symbol") and parantheses.Value == "(" then
        self.Head:GoNext()
        local args
        local calltime = self.Timer:Start()
        
        -- Could save performance by not calling GetArguments if there are no arguments or if theres only one
        local next, nextnext = self.Head:Current(), self.Head:Next()
        if (next and next.Value == ")") or (nextnext and nextnext.Value == ")") then
            
            local perftime = self.Timer:Start()
            if next.Value == ")" then
                args = {}
            else
                args = { self:GetExpr() }
            end
            perftime("PerfArguments")
        else
            args = self:GetArguments()
        end
        calltime("CallArguments")
        
        -- We dont go next, because the parent caller will do that
        if self.Head:Current().Value ~= ")" then
            time("GetCallStatement")
            error("Expected \")\" after arguments at " .. self.Pos.Counter)
        end
        
        time("GetCallStatement")
        return Node.new("CallStatement", {cur, args}, "Statement", self.Pos.Counter)
    end
    
    time("GetCallStatement")
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