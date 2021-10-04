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
    
    local function AddToken(token)
        
        local past = tokens[#tokens]
        if past and past:IsType(token) and (token.Type == "String" or token.Type == "Number") then
            past.Value = past.Value .. token.Value
        else
            tokens[#tokens + 1] = token
        end
    end
    
    local function TrimWhitespaces()
        if not version.INDENTATION[head:Current()] or head:Current() ~= "\n" then
            return
        end
        
        local start, stop = pos.Counter, pos.Counter
        while true do
            local char = head:Current()
            
            if char == "\n" then
                AddToken(Token.new("WhiteSpace", source:sub(start, stop), "WhiteSpace"))
            elseif version.INDENTATION[char] then
                stop = stop + 1
            else
                break
            end
            head:GoNext()
        end
        AddToken(Token.new("WhiteSpace", source:sub(start, stop), "WhiteSpace"))
    end
    
    
    while head:GoNext() do
        TrimWhitespaces()
        local char = head:Current()
        
        if char == "" then
            break
        elseif char == "\"" or char == "\'" then
            --TODO: Implement escape characters
            
            AddToken(Token("String", char, "String"))
            local value, last = "", nil
            while head:GoNext() ~= "" do
                char = head:Current()
                if char == "\"" or char == "\'" then
                    last = char
                    break
                else
                    value = value .. char
                end
            end
            AddToken(Token("StringLiteral", value, "String"))
            AddToken(Token("String", last, "String"))
        
        elseif version.IDEN[char] then
            --TODO: Should this check for keywords?
            
            local value = char
            while version.IDEN[head:Next()] do
                head:GoNext()
                value = value .. head:Current()
            end
            
            if version.KEYWORDS[value] then
                AddToken(Token("Keyword", value, "Keyword"))
            else
                AddToken(Token("Identifier", value, "Identifier"))
            end
        
        elseif version.NUM[char] or (char == "." and version.NUM[head:Next()]) then
            
            ---TODO: Support for hexadecimal numbers
            local value, isdot = char, false
            while version.NUM[head:Next()] or head:Next() == "." or head:Next():lower() == "e" do
                head:GoNext()
                local new = head:Current()
                if new == "." then
                    if isdot then
                        return error("Invalid number")
                    end
                    isdot = true
                elseif new:lower() == "e" then
                    if head:Next() == "-" then
                        value = value .. head:GoNext()
                    end
                else
                    value = value .. new
                end
            end
            
            AddToken(Token("NumberLiteral", value, "Number"))
        elseif char == "." then
            
            local value = char
            for _ = 1, 2 do
                if head:Next() == "." then
                    value = value .. head:GoNext()
                else
                    break
                end
            end
            
            if #value == 3 then
                AddToken(Token("Vararg", value, "Symbol"))
            else
                AddToken(Token("Symbol", value, "Symbol"))
            end
            
        elseif version.EQUALITY[char] then
            
            if version.EQUALITY[head:Next()] then
                char = char .. head:GoNext()
            end
            AddToken(Token("Symbol", char, "Symbol"))
            
        elseif version.SYMBOLS[char] then
            if version.OPERATORS[char] then
                AddToken(Token("Operator", char, "Operator"))
            else
                AddToken(Token("Symbol", char, "Symbol"))
            end
        end
    end
    
    return tokens
end


---@param Source string
return function(Source)
    
    return GenerateTokens(Source, require("Versions.Lua51"))
end