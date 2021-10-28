--[[
    LexerClass
    HawDevelopment
    09/10/2021
--]]

local Token = require("src.Generator.Util.Token")

local LexerClass = {}
LexerClass.__index = LexerClass

local HEX_NUMBER = "[%da-fA-F]"
local EXPONENT = "[eE]?[%+%-]?%d*"
local HEX_EXPONENT = "[pP][%+%-]?%d*"

function LexerClass.new(source, head, version)
    local self = setmetatable({}, LexerClass)
    
    self.Head = head
    self.Pos = head.Pos
    self.Source = source
    self.Version = version
    
    self.Tokens = {}
    
    return self
end

-- Util
do
    function LexerClass:TrimWhitespaces(char)
        char = char or self.Head:Current()
        if not self.Version.INDENTATION[char] and char ~= "\n" then
            return char
        end
        while true do
            char = self.Head:GoNext()
            if not char or (not self.Version.INDENTATION[char] and char ~= "\n") then
                break
            end
        end
        return char
    end

    function LexerClass:GetName()
        local value = string.match(self.Source, "[%a_][%a%d_]*", self.Pos.Counter)
        return value, #value - 1
    end
    
    function LexerClass:GetMultiline()
        local value = string.match(self.Source, "%[=*%[[.%s%p%a]*%]=*%]", self.Pos.Counter)
        return value, #value - 1
    end
    
    function LexerClass:GetToLineEnd()
        local value = string.match(self.Source .. "\n", "[.%s%p%a]-\n", self.Pos.Counter)
        return value, #value - 1
    end
end

function LexerClass:LexString(char)
    --TODO: Implement escape characters
    --TODO: Implement multi line strings
    
    local value = string.match(self.Source, char .. ".-" .. char, self.Pos.Counter)
    if not value then
        error("Unterminated string literal")
    end
    self.Tokens[#self.Tokens + 1] = Token.new("String", value, "String")
    self.Pos.Counter = self.Pos.Counter + #value - 1
end

function LexerClass:LexIdentifier()
    local value, length = self:GetName()
    if not value then
        error("Invalid identifier")
    end
    self.Pos.Counter = self.Pos.Counter + length
    
    if self.Version.KEYWORDS[value] then
        if self.Version.BOOLEAN[value] then
            self.Tokens[#self.Tokens + 1] = Token.new("BooleanLiteral", value, "Boolean")
        elseif value == "nil" then
            self.Tokens[#self.Tokens + 1] = Token.new("NilLiteral", value, "Boolean")
        else
            self.Tokens[#self.Tokens + 1] = Token.new(value, value, "Keyword")
        end
    else
        self.Tokens[#self.Tokens + 1] = Token.new(value, value, "Identifier")
    end
end

function LexerClass:LexOperator(char)
    self.Tokens[#self.Tokens + 1] = Token.new("Operator", char, "Operator")
end

function LexerClass:LexSymbol(char)
    self.Tokens[#self.Tokens + 1] = Token.new("Symbol", char, "Symbol")
end

function LexerClass:LexDot(char)
    
    if self.Head:GoNext() == "." then
        char = char .. self.Head:Current()
        if self.Head:GoNext() == "." then
            -- Var arg
            self.Tokens[#self.Tokens+1] = Token.new("VarArgLiteral", "...", "Symbol")
            return
        end
    end
    self.Tokens[#self.Tokens+1] = Token.new("Symbol", char, "Symbol")
end

-- Comment
function LexerClass:TrimComment()
    self.Head:GoNext()
    
    local islong = false
    if self.Head:GoNext() == "[" and self.Head:Next() == "[" then
        local val, len = self:GetMultiline()
        if val then
            islong = true
            self.Pos.Counter = self.Pos.Counter + len
        end
    end
    
    if not islong then
        local val, len = self:GetToLineEnd()
        if val then
            self.Pos.Counter = self.Pos.Counter + len
        end
    end
end

-- Number
do
    function LexerClass:GetInt()
        local value = string.match(self.Source, "[%d]+", self.Pos.Counter)
        return value
    end
    
    local Float1 = "[%d]*[%.][%d]+" .. EXPONENT
    local Float2 = "[%d]+" .. EXPONENT
    function LexerClass:GetFloat()
        local value = string.match(self.Source, Float1, self.Pos.Counter) or
            string.match(self.Source, Float2, self.Pos.Counter)
        return value
    end
    
    local Hex = "0[xX]%.?" .. HEX_NUMBER .. "*%.?" .. HEX_NUMBER .. "*" .. HEX_EXPONENT
    function LexerClass:GetHex()
        local value = string.match(self.Source, Hex, self.Pos.Counter)
        return value
    end
    
    function LexerClass:LexNumber()
        local cur, next = self.Head:Current(), self.Head:Next()
        if cur == "0" and next == "x" or next == "X" then
            -- Hexadecimal
            local value = self:GetHex()
            if value then
                self.Pos.Counter = self.Pos.Counter + #value - 1
                self.Tokens[#self.Tokens + 1] = Token.new("HexadecimalLiteral", value, "Number", self.Pos.Counter)
                return
            else
                error("Invalid hexadecimal")
            end
        end
        
        -- Decimal
        local value = self:GetInt()
        local length = self.Pos.Counter + #value
        if value and self.Source:sub(length, length) == "." then
            -- Float
            value = self:GetFloat()
            self.Pos.Counter = self.Pos.Counter + #value - 1
            self.Tokens[#self.Tokens+1] = Token.new("FloatLiteral", value, "Number", self.Pos.Counter)
        elseif value then
            -- Int
            self.Pos.Counter = length - 1
            self.Tokens[#self.Tokens+1] = Token.new("IntegerLiteral", value, "Number", self.Pos.Counter)
        else
            error("Invalid number")
        end
        
    end
end


function LexerClass:Walk()
    
    while true do
        local char = self:TrimWhitespaces(self.Head:GoNext())
        while char == "-" and self.Head:Next() == "-" do
            self:TrimComment()
            char = self:TrimWhitespaces(self.Head:GoNext())
        end
        local version = self.Version
        
        if char == "" or not char then
            break
        elseif char == "\"" or char == "\'" then
            
            self:LexString(char)
            
        elseif version.IDEN[char] then
            
            self:LexIdentifier()
            
        elseif version.NUM[char] or (char == "." and version.NUM[self.Head:Next()]) then
            
            self:LexNumber()
            
            -- DANGER Operators MUST be checked before symbols
        elseif version.OPERATORS[char] then
            
            self:LexOperator(char)
            
        elseif version.SYMBOLS[char] then
            
            self:LexSymbol(char)
            
        elseif char == "." then
            
            self:LexDot(char)
            
        elseif version.EQUALITY[char] then
            
            if self.Head:Next() == "=" then
                char = char .. self.Head:GoNext()
            end
            self.Tokens[#self.Tokens + 1] = Token("Symbol", char, "Symbol")
        end
    end
end


return LexerClass