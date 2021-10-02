--[[
    Parser Util
    HawDevelopment
    02/10/2021
--]]

local Node = require("Generator.Util.Node")

local ParserUtil = {}
ParserUtil.__index = ParserUtil

local SKIP_WHITESPACE = true

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
    while self.Head:Next() and ValueInTable(operators, self.Head:Next().Value) do
        local op = self:Get(1, true)
        if not op or not op:Is("Operator") then
            break
        end
        self.Head:GoNext()
        self.Head:GoNext()
        
        local right = func(...)
        if not right then
            error("Unexpected token: Expected a term or expression after operator at " .. self.Pos.Counter)
        end
        left = Node.new("BinOp", {op, left, right}, "BinOp", self.Pos.Counter)
    end
    
    return left
end

function ParserUtil:GetLiteral(_type)
    local token = self:Get(0, false, "Expected Literal got nil")
    if not token then
        return nil
    end
    
    local correct = false
    if type(_type) == "string" then
        correct = token:Is(_type)
    elseif type(_type) == "table" then
        correct = ValueInTable(_type, token.Name) or ValueInTable(_type, token.Type)
    end
    
    if correct then
        return Node.new("Literal", token.Value, "Literal", self.Pos.Counter)
    end
    return nil
end

local TERM_OPERATORS = {"*", "/", "%", "^"}
function ParserUtil:GetTerm()
    return self:GetBinOp(TERM_OPERATORS, self.GetLiteral, self, "Number")
end

local EXPR_OPERATORS = {"+", "-"}
function ParserUtil:GetExpr()
    return self:GetBinOp(EXPR_OPERATORS, self.GetTerm, self)
end

--#endregion

function ParserUtil:Destroy()
    for key, _ in pairs(self) do
        self[key] = nil
    end
end


return ParserUtil