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
            token = tokens[pos.Counter + delta]
            err = err + (delta > 0 and 1 or -1)
        until token and not token:IsType("WhiteSpace")
        
        if not token then
            error(msg .. " at " .. pos.Counter + delta)
        end
        return token
    end
    
    local function GetType(delta, _type, msg)
        msg = msg or "Unexpected token type"
        local token = GetOrError(delta, "Unexpected nil value")
        if type(_type) == "string" then
            if not token:Is(_type) then
                error(msg .. " at " .. pos.Counter + delta)
            end
        elseif type(_type) == "table" then
            local found = false
            for _, t in pairs(_type) do
                if token:Is(t) then
                    found = true
                    break
                end
            end
            if not found then
                error(msg .. " at " .. pos.Counter + delta)
            end
        end
        
        return token
    end
    
    local function GetBinOp(type, tofind, ...)
        local left = tofind(...)
        repeat
            local op = GetType(1, type, "Invalid token")
            if not op then
                break
            end
            head:GoNext()
            head:GoNext()
            
            local right = tofind(...)
            left = BinOp(op, left, right)
        until not left or not right or not op
        
        return left
    end
    
    while head:Next() do
        local token = head:GoNext()
        table.insert(nodes, GetBinOp("Operator", GetType , 0, "Number"))
    end
    
    print("Returtning")
    return nodes
end