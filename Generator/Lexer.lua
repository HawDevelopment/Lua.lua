--[[
    Lexer
    HawDevelopment
    28/09/2021
--]]

local LexerHead = require("Generator.Util.LexerHead")
local Token = require("Generator.Util.Token")
local Position = require("Generator.Util.Position")

---@param source string
---@param version table<string, table<string | number, Token | BaseError>>
local function GenerateTokens(source, version)
    
    local tokens, pos = {}, Position.new(0)
    local head = LexerHead.new(source, pos)
    
    local function TrimWhitespaces()
        if not version.INDENTATION[head:Current()] or head:Current() ~= "\n" then
            return
        end
        
        while true do
            char = head:GoNext()
            if not char then
                break
            elseif not version.INDENTATION[char] and char ~= "\n" then
                break
            end
        end
    end
    
    local value, cur, char = "", nil, nil
    while head:GoNext() do
        TrimWhitespaces()
        char = head:Current()
        
        if char == "" then
            break
        elseif char == "\"" or char == "\'" then
            --TODO: Implement escape characters
            --TODO: Implement multi line strings
            
            value = string.match(source, char .. ".-" .. char, pos.Counter)
            if not value then
                error("Unterminated string literal")
            end
            tokens[#tokens + 1] = Token.new("String", value, "String")
            pos.Counter = pos.Counter + #value - 1
        
        elseif version.IDEN[char] then
            --TODO: Should this check for keywords?
            
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
            
        elseif version.NUM[char] or (char == "." and version.NUM[head:Next()]) then
            
            ---TODO: Support for hexadecimal numbers
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
            
        elseif version.SYMBOLS[char] then
            
            if version.OPERATORS[char] then
                tokens[#tokens + 1] = Token("Operator", char, "Operator")
            else
                tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
            end
            
        elseif char == "." then
            
            value = char
            if head:Next() == "." then
                value = value .. head:GoNext()
                if head:Next() == "." then
                    value = value .. head:GoNext()
                end
            end
            tokens[#tokens + 1] = Token("Symbol", value, "Symbol")
            
        elseif version.EQUALITY[char] then
            
            if version.EQUALITY[head:Next()] then
                char = char .. head:GoNext()
            end
            tokens[#tokens + 1] = Token("Symbol", char, "Symbol")
        end
    end
    
    return tokens
end


---@param Source string
return function(Source)
    
    return GenerateTokens(Source, require("Versions.Lua51"))
end