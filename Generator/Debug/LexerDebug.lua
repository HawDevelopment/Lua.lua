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

local function Add(name, time)
    if TAKETIME then
        timer:Add(name, time)
    end
end


---@param source string
---@param version table<string, table<string | number, Token | BaseError>>
local function GenerateTokens(source, version)
    timer = TakeTime.new()
    
    local tokens, pos = {}, Position.new(0)
    local head = LexerHead.new(source, pos)
    
    local value, cur, char = "", nil, nil
    local function TrimWhitespaces()
        if not version.INDENTATION[head:Current()] or head:Current() ~= "\n" then
            return
        end
        while true do
            char = head:GoNext()
            if not char or (not version.INDENTATION[char] and char ~= "\n") then
                break
            end
        end
    end
    
    local starttime = os.clock()
    
    while head:GoNext() do
        Start()
        TrimWhitespaces()
        Stop("Whitespace")
        
        Start()
        char = head:Current()
        Stop("GetNext")
        
        if char == "" then
            break
        elseif char == "\"" or char == "\'" then
            --TODO: Implement escape characters
            --TODO: Implement multi line strings
            
            local strstarttime = os.clock()
            value = string.match(source, char .. ".-" .. char, pos.Counter)
            if not value then
                error("Unterminated string literal")
            end
            tokens[#tokens + 1] = Token.new("String", value, "String")
            pos.Counter = pos.Counter + #value - 1
            Add("String", os.clock() - strstarttime)
            
        elseif version.IDEN[char] then
            --TODO: Should this check for keywords?
            
            local idenstarttime = os.clock()
            value = string.match(source, "[%a%d_]+", pos.Counter)
            if not value then
                error("Invalid identifier")
            end
            
            if version.KEYWORDS[value] then
                tokens[#tokens + 1] = Token("Keyword", value, "Keyword")
            else
                tokens[#tokens + 1] = Token("Identifier", value, "Identifier")
            end
            pos.Counter = pos.Counter + #value - 1
            Add("Identifier", os.clock() - idenstarttime)
            
        elseif version.NUM[char] or (char == "." and version.NUM[head:Next()]) then
            
            ---TODO: Support for hexadecimal numbers
            local numstarttime = os.clock()
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
            Add("Number", os.clock() - numstarttime)
            
            -- DANGER Operators MUST be checked before symbols
        elseif version.OPERATORS[char] then
            
            local opstarttime = os.clock()
            Token("Operator", char, "Operator")
            timer:Add("Operator", os.clock() - opstarttime)
            
        elseif version.SYMBOLS[char] then
            
            local symstarttime = os.clock()
            tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
            timer:Add("Symbol", os.clock() - symstarttime)
            
        elseif char == "." then
            
            local dotstarttime = os.clock()
            value = char
            if head:Next() == "." then
                value = value .. head:GoNext()
                if head:Next() == "." then
                    value = value .. head:GoNext()
                end
            end
            tokens[#tokens + 1] = Token("Symbol", value, "Symbol")
            Add("Dot", os.clock() - dotstarttime)
            
        elseif version.EQUALITY[char] then
            
            local equalstarttime = os.clock()
            if version.EQUALITY[head:Next()] then
                char = char .. head:GoNext()
            end
            tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
            Add("Equality", os.clock() - equalstarttime)
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