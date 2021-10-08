--[[
    Lexer
    HawDevelopment
    28/09/2021
--]]

local LexerHead = require("src.Generator.Util.LexerHead")
local Token = require("src.Generator.Util.Token")
local Position = require("src.Generator.Util.Position")

local TakeTime = require("src.Generator.Debug.TakeTime")
local TakeTimeCopy = require("src.Generator.Debug.TakeTimeCopy")

local TAKE_TIME = true

---@param source string
---@param version table<string, table<string | number, Token>>
local function GenerateTokens(source, version)
    local timer = TAKE_TIME and TakeTime.new() or TakeTimeCopy
    
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
        
        local time = timer:Start()
        TrimWhitespaces()
        time("Whitespace")
        
        time = timer:Start()
        char = head:Current()
        time("GetNext")
        if char == "" then
            break
        elseif char == "\"" or char == "\'" then
            --TODO: Implement escape characters
            --TODO: Implement multi line strings
            
            time = timer:Start()
            value = string.match(source, char .. ".-" .. char, pos.Counter)
            if not value then
                error("Unterminated string literal")
            end
            tokens[#tokens + 1] = Token.new("String", value, "String")
            pos.Counter = pos.Counter + #value - 1
            time("String")
            
        elseif version.IDEN[char] then
            --TODO: Should this check for keywords?
            
            time = timer:Start()
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
            time("Identifier")
            
        elseif version.NUM[char] or (char == "." and version.NUM[head:Next()]) then
            
            ---TODO: Support for hexadecimal numbers
            time = timer:Start()
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
            time("Number")
            
            -- DANGER Operators MUST be checked before symbols
        elseif version.OPERATORS[char] then
            time = timer:Start()
            tokens[#tokens + 1] = Token("Operator", char, "Operator")
            time("Operator")
            
        elseif version.SYMBOLS[char] then
            local symstarttime = os.clock()
            tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
            timer:Add("Symbol", os.clock() - symstarttime)
            
        elseif char == "." then
            
            time = timer:Start()
            value = char
            if head:Next() == "." then
                value = value .. head:GoNext()
                if head:Next() == "." then
                    value = value .. head:GoNext()
                end
            end
            tokens[#tokens + 1] = Token("Symbol", value, "Symbol")
            time("Dot")
            
        elseif version.EQUALITY[char] then
            
            time = timer:Start()
            if version.EQUALITY[head:Next()] then
                char = char .. head:GoNext()
            end
            tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
            time("Equality")
        end
    end
    
    print("Real Lexer Time: " .. os.clock() - starttime)
    if TAKE_TIME then
        print(timer:rep())
    end
    
    return tokens
end


---@param Source string
return function(Source)
    
    return GenerateTokens(Source, require("src.Versions.Lua51"))
end