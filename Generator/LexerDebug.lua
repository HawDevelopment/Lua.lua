--[[
    Lexer
    HawDevelopment
    28/09/2021
--]]

local LexerHead = require("Generator.Util.LexerHead")
local Token = require("Generator.Util.Token")
local Position = require("Generator.Util.Position")

local TakeTime = require("Generator.Debug.TakeTime")

local TAKETIME = true

local timer
local function Start()
    if TAKETIME then
        timer:Start()
    end
end

local function Stop(name)
    if TAKETIME then
        timer:Stop(name)
    end
end


---@param source string
---@param version table<string, table<string | number, Token | BaseError>>
local function GenerateTokens(source, version)
    timer = TakeTime.new()
    
    local tokens, pos = {}, Position.new(0)
    local head = LexerHead.new(source, pos)
    
    local function TrimWhitespaces()
        if not version.INDENTATION[head:Current()] or head:Current() ~= "\n" then
            return
        end
        
        local start = pos.Counter
        while true do
            local char = head:Current()
            
            if char == "\n" then
                --AddToken(Token.new("WhiteSpace", source:sub(start, pos.Counter), "WhiteSpace"))
                start = pos.Counter + 1
            elseif version.INDENTATION[char] then
                break
            end
            head:GoNext()
        end
        if start ~= pos.Counter then
            --AddToken(Token.new("WhiteSpace", source:sub(start, pos.Counter), "WhiteSpace"))
        end
    end
    
    local starttime = os.clock()
    
    local value, cur, char = "", nil, nil
    while head:GoNext() do
        Start()
        if version.INDENTATION[head:Current()] or head:Current() == "\n" then
            TrimWhitespaces()
        end
        Stop("Whitespace")
        
        Start()
        char = head:Current()
        Stop("GetNext")
        
        if char == "" then
            break
        elseif char == "\"" or char == "\'" then
            --TODO: Implement escape characters
            --TODO: Implement multi line strings
            
            Start()
            value = string.match(source, char .. ".-" .. char, pos.Counter)
            if not value then
                error("Unterminated string literal")
            end
            tokens[#tokens + 1] = Token.new("String", value, "String")
            pos.Counter = pos.Counter + #value - 1
            Stop("String")
            
        elseif version.IDEN[char] then
            --TODO: Should this check for keywords?
            
            Start()
            value = char
            while true do
                char = head:GoNext()
                if not version.IDEN[char] then
                    head:GoLast()
                    break
                end
                value = value .. char
            end
            
            if version.KEYWORDS[value] then
                tokens[#tokens + 1] = Token("Keyword", value, "Keyword")
            else
                tokens[#tokens + 1] = Token("Identifier", value, "Identifier")
            end
            Stop("Identifier")
            
        elseif version.NUM[char] or (char == "." and version.NUM[head:Next()]) then
            
            ---TODO: Support for hexadecimal numbers
            Start()
            value = char
            while version.NUM[head:Next()] do
                value = value .. head:GoNext()
            end
            
            if head:Next() == "." then
                value = value .. head:GoNext()
                while version.NUM[head:Next()] do
                    value = value .. head:GoNext()
                end
            end
            if head:Next() == "e" then
                value = value .. head:GoNext()
                if head:Next() == "+" or head:Next() == "-" then
                    value = value .. head:GoNext()
                end
                while version.NUM[head:Next()] do
                    value = value .. head:GoNext()
                end
            end
            
            tokens[#tokens + 1] = Token("NumberLiteral", value, "Number")
            Stop("Number")
            
        elseif version.SYMBOLS[char] then
            
            Start()
            if version.OPERATORS[char] then
                tokens[#tokens + 1] = Token("Operator", char, "Operator")
            else
                tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
            end
            Stop("Symbol")
            
        elseif char == "." then
            
            Start()
            value = char
            if head:Next() == "." then
                value = value .. head:GoNext()
                if head:Next() == "." then
                    value = value .. head:GoNext()
                end
            end
            tokens[#tokens + 1] = Token("Symbol", value, "Symbol")
            Stop("Dot")
            
        elseif version.EQUALITY[char] then
            
            Start()
            if version.EQUALITY[head:Next()] then
                char = char .. head:GoNext()
            end
            tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
            Stop("Equality")
        end
    end
    
    if TAKETIME then
        print("Real Lexer Time: " .. os.clock() - starttime)
        print(timer:rep())
    end
    
    return tokens
end


---@param Source string
return function(Source)
    
    return GenerateTokens(Source, require("Versions.Lua51"))
end