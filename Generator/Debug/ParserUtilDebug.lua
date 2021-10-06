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
    local starttime = os.clock()
    if comma == nil then
        comma = true
    end
    local idens, cur = {}, nil
    
    while true do
        local callstarttime = os.clock()
        
        cur = self.Head:Current()
        if type(tofind) == "string" then
            if not (cur.Name == tofind) then
                break
            end
        elseif type(tofind) == "function" then
            cur = tofind(...)
        elseif type(tofind) == "table" then
            if not ValueInTable(tofind, cur.Name) then
                break
            end
        end
        if TAKETIME then
            self.TakeTime:Add("SeperateCall", os.clock() - callstarttime)
        end
        
        table.insert(idens, cur)
        cur = self.Head:Next()
        if comma and cur and cur.Value == "," then
            self.Head:GoNext()
        else
            break
        end
    end
    
    if TAKETIME then
        self.TakeTime:Add("GetSeperated", os.clock() - starttime)
    end
    return idens
end

--#endregion

--#region Getting tokens

function ParserUtil:GetBinOp(operators, func, ...)
    local starttime = os.clock()
    local left = func(...)
    while self.Head:Current() and self.Head:Current():Is("Operator") and ValueInTable(operators, self.Head:Current().Value) do
        local op = self.Head:Current()
        self.Head:GoNext()
        
        local right = func(...)
        if not right then
            if TAKETIME then
                self.TakeTime:Add("GetBinOp", os.clock() - starttime) 
            end
            error("Unexpected token: Expected a term or expression after operator at " .. self.Pos.Counter)
        end
        left = Node.new("BinaryExpression", {op, left, right}, "Expression", self.Pos.Counter)
    end
    
    if TAKETIME then
        self.TakeTime:Add("GetBinOp", os.clock() - starttime) 
    end
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
        local starttime = os.clock()
        local ret = self:GetBinOp({"^"}, self.GetLiteral, self)
        
        if TAKETIME then
            self.TakeTime:Add("GetPower", os.clock() - starttime)
        end
        return ret
    end
    
    function ParserUtil:GetFactor()
        local starttime = os.clock()
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
        
        if TAKETIME then
            self.TakeTime:Add("GetFactor", os.clock() - starttime)
        end
        return ret
    end
    
    function ParserUtil:GetTerm()
        local starttime = os.clock()
        local ret = self:GetBinOp(TERM_OPERATORS, self.GetFactor, self)
        if TAKETIME then
            self.TakeTime:Add("GetTerm", os.clock() - starttime)
        end
        return ret
    end
    
    function ParserUtil:GetExpr()
        local starttime = os.clock()
        local ret = self:GetBinOp(EXPR_OPERATORS, self.GetTerm, self)
        if TAKETIME then
            self.TakeTime:Add("GetExpr", os.clock() - starttime)
        end
        return ret
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
        init = self:GetSeperated(self.GetExpr, true, self)
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
    return self:GetSeperated(self.GetExpr, true, self)
end

function ParserUtil:GetCallStatement()
    local starttime = os.clock()
    local cur = self.Head:Current()
    if not (cur and cur:Is("Identifier")) then
        return
    else
        cur = self.Head:GoNext()
    end
    
    -- Is call
    if cur and cur:Is("Symbol") and cur.Value == "(" then
        self.Head:GoNext()
        local args
        local callstarttime = os.clock()
        
        -- Could save performance by not calling GetArguments if there are no arguments or if theres only one
        local next, nextnext = self.Head:Current(), self.Head:Next()
        if (next and next.Value == ")") or (nextnext and nextnext.Value == ")") then
            local perfstarttime = os.clock()
            if next.Value == ")" then
                args = {}
            else
                args = { self:GetExpr() }
            end
            if TAKETIME then
                self.TakeTime:Add("PerfArguments", os.clock() - perfstarttime)
            end
        else
            args = self:GetArguments()
        end
        if TAKETIME then
            self.TakeTime:Add("CallArguments", os.clock() - callstarttime)
        end
        
        -- We dont go next, because the parent caller will do that
        if not self.Head:Current().Value == ")" then
            if TAKETIME then
                self.TakeTime:Add("GetCallStatement", os.clock() - starttime)
            end
            error("Expected \")\" after arguments at " .. self.Pos.Counter)
        end
        
        if TAKETIME then
            self.TakeTime:Add("GetCallStatement", os.clock() - starttime)
        end
        return Node.new("CallStatement", {cur, args}, "Statement", self.Pos.Counter)
    end
    
    if TAKETIME then
        self.TakeTime:Add("GetCallStatement", os.clock() - starttime)
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