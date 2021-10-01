--[[
    Parser
    HawDevelopment
    29/09/2021
--]]

local Node = require("Generator.Util.Node")
local Type = require("Generator.Util.Type")
local LexerHead = require("Generator.Util.LexerHead")
local Position = require("Generator.Util.Position")

local IGNORE_WHITESPACE = true

local function BinOp(op, left, right)
    return Node("BinOp", {op, left, right}, Type("BinOp"))
end

local function LiteralExpr(value)
    return Node("LiteralExpr", value, Type("LiteralExpr"))
end

return function(tokens, version)
    version = require("Versions.Lua51")
    
    local nodes = {}
    local pos = Position(0)
    local head = LexerHead.new(tokens, pos)
    
    local function GetOrError(delta, msg)
        msg = msg or "Unexpected token"
        local token, err = nil, delta
        repeat
            token, err = tokens[pos.Counter + err], err + (delta > 0 and 1 or -1)
        until not token or not token:Is("WhiteSpace")
        
        if not token then
            error(msg .. " at " .. pos.Counter + delta)
        end
        return token
    end
    
    local function GetType(delta, _type, msg)
        msg = msg or "Unexpected token type"
        local token = GetOrError(delta, "Unexpected nil value")
        if type(_type) == "string" and not token:Is(_type) then
            error(msg .. " at " .. pos.Counter + delta)
        elseif type(_type) == "table" then
            for _, t in pairs(_type) do
                if token:Is(t) then
                    return token
                end
            end
            error(msg .. " at " .. pos.Counter + delta)
        end
        
        return token
    end
    
    local function GetBinOp(type, tofind, ...)
        local left = tofind(...)
        while head:Next() do
            local op = GetType(1, type, "Invalid token")
            if not op then
                break
            end
            head:GoNext()
            head:GoNext()
            
            local right = tofind(...)
            left = BinOp(op, left, right)
        end
        
        return left
    end
    
    while head:GoNext() do
        if head:Current():Is("Number") then
            nodes[#nodes+1] = GetBinOp("Operator", GetType, 0, {"BinOp", "Number"})
        end
    end
    
    return nodes
end