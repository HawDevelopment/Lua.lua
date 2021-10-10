--[[
    ParserClass debug
    HawDevelopment
    09/10/2021
--]]

local Node = require("src.Generator.Util.Node")

local TakeTime = require("src.Generator.Debug.TakeTime")
local TakeTimeCopy = require("src.Generator.Debug.TakeTimeCopy")

local TAKE_TIME = true

local ParserClassDebug = {}
ParserClassDebug.__index = ParserClassDebug

local UNARY_OPERATORS = {"+", "-"}
local NUMBER_OPERATORS = {"+", "-", "*", "/", "%", "^"}
local NUMBER_OPERATORS_PRECEDENCE = {
    ["+"] = 1,
    ["-"] = 1,
    ["*"] = 2,
    ["/"] = 2,
    ["%"] = 2,
    ["^"] = 3
}

function ParserClassDebug.new(tokens, head)
    local self = setmetatable({}, ParserClassDebug)
    
    self.Tokens = tokens
    self.Head = head
    self.Pos = head.Pos
    
    self.Timer = TAKE_TIME and TakeTime.new() or TakeTimeCopy
    return self
end

-- UTIL

local function ValueInTable(tab, value)
    for _, val in pairs(tab) do
        if val == value then
            return true
        end
    end
    return false
end

do
    function ParserClassDebug:IsUnary(token)
        return (token:IsType("Keyword") and token.Value == "not") or (token:Is("Operator") and ValueInTable(UNARY_OPERATORS, token.Value))
    end
    
    function ParserClassDebug:PostfixNotation(operators, precedens)
        
        -- Parse
        local out, ops = {}, {}
        while true do
            local token = self.Head:Current()
            if not token then
                break
            elseif token:IsType("Number") then
                out[#out + 1] = token
                self.Head:GoNext()
            elseif token:Is("Symbol") and token.Value == "(" then
                self.Head:GoNext()
                local parent = self:PostfixNotation(operators, precedens)
                for i = 1, #parent do
                    out[#out + 1] = parent[i]
                end
                if self.Head:Current().Value == ")" then
                    self.Head:GoNext()
                else
                    error("Expected ')'")
                end
                
            elseif token:Is("Operator") and ValueInTable(operators, token.Value) then
                while ops[#ops] and precedens[ops[#ops].Value] > precedens[token.Value] do
                    out[#out + 1] = ops[#ops]
                    ops[#ops] = nil
                end
                
                ops[#ops + 1] = token
                self.Head:GoNext()
            else
                break
            end
        end
        for i = #ops, 1, -1 do
            out[#out + 1] = ops[i]
            ops[i] = nil
        end
        return out
    end
    
    function ParserClassDebug:GetBinOp(operators, precedens)
        local out, change = self:PostfixNotation(operators, precedens), false
        local left, right, lefti, righti
        while true do
            change = false
            left, right, lefti, righti = nil, nil, nil, nil
            
            for i, token in pairs(out) do
                if token:Is("Operator") then
                    if left and right then
                        
                        local node = Node.new("BinaryOperation", {op = out[i].Value, left = left, right = right}, "Operation", self.Pos.Counter)
                        out[i] = node
                        left, right, out[lefti], out[righti] = nil, nil, nil, nil
                        change = true
                        break
                    else
                        error("Expected operands")
                    end
                else
                    if not left then
                        left, lefti = token, i
                    elseif not right then
                        right, righti = token, i
                    else
                        left, lefti = right, righti
                        right, righti = token, i
                    end
                end
            end
            if not change then
                break
            end
        end
        local _, val = next(out)
        return val or error("Expected binop")
    end
end

function ParserClassDebug:Walk()
    local token = self.Head:Current()
    local next = self.Head:Next()
    
    if token:IsType("Symbol") and token.Value == "(" and next then
        if next:IsType("Symbol") and next.Value == ")" then
            self.Head:GoNext()
            self.Head:GoNext()
            return self:Walk()
        end
        return self:GetBinOp(NUMBER_OPERATORS)
    end
    if token:IsType("Number") then
        
        local next = self.Head:Next()
        if next and next:Is("Operator") then
            return self:GetBinOp(NUMBER_OPERATORS, NUMBER_OPERATORS_PRECEDENCE)
        end
        
        return Node.new("NumberLiteral", token.Value, "Number", token.Pos)
    end
    if token:IsType("String") then
        return Node.new("StringLiteral", token.Value, "String", token.Pos)
    end
    if token:IsType("Keyword") then
        if token.Value == "true" then
            return Node.new("BooleanLiteral", true, "Boolean", token.Pos)
        elseif token.Value == "false" then
            return Node.new("BooleanLiteral", false, "Boolean", token.Pos)
        elseif token.Value == "nil" then
            return Node.new("NilLiteral", nil, "Nil", token.Pos)
        else
            return Node.new("Keyword", token.Value, "Keyword", token.Pos)
        end
    end
    
    if token:IsType("Identifier") then
        if next and next.Value == "(" then
            self.Head:GoNext()
            self.Head:GoNext()
            local args = {}
            while true do
                local found = self.Head:Current()
                if found and found.Value ~= ")" then
                    local node = self:Walk()
                    if not node then break end
                    
                    self.Head:GoNext()
                    table.insert(args, node)
                    if not (self.Head:Next() and self.Head:Next().Value == ",") or not self.Head:Next() then
                        break
                    end
                    self.Head:GoNext()
                else
                    break
                end
            end
            
            if self.Head:Current().Value ~= ")" then
                error("Expected )")
            end
            
            return Node.new("CallExpression", {
                name = token.Value,
                args = args,
            }, "Expression", token.Pos)
        end
        
        return Node.new("Identifier", token.Value, "Identifier", token.Pos)
    end
    
end

return ParserClassDebug