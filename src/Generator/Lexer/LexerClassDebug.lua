--[[
    LexerClass debug
    HawDevelopment
    09/10/2021
--]]

local Token = require("src.Generator.Util.Token")

local LexerClassDebug = {}
LexerClassDebug.__index = LexerClassDebug

local HEX_NUMBER = "[%da-fA-F]"
local EXPONENT = "[eE][%+%-]?%d+"
local HEX_EXPONENT = "[pP][%+%-]?%d+"

function LexerClassDebug.new(source, head, version)
    local self = setmetatable({}, LexerClassDebug)
    
    self.Head = head
    self.Pos = head.Pos
    self.Source = source
    self.Version = version
    
    self.Tokens = {}
    
    return self
end

-- Util
do
    function LexerClassDebug:TrimWhitespaces(char)
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

    function LexerClassDebug:GetName()
        local value = string.match(self.Source, "[%a_][%a%d_]*", self.Pos.Counter)
        return value, #value - 1
    end
end

function LexerClassDebug:LexString(char)
    --TODO: Implement escape characters
    --TODO: Implement multi line strings
    
    local value = string.match(self.Source, char .. ".-" .. char, self.Pos.Counter)
    if not value then
        error("Unterminated string literal")
    end
    self.Tokens[#self.Tokens + 1] = Token.new("String", value, "String")
    self.Pos.Counter = self.Pos.Counter + #value - 1
end

function LexerClassDebug:LexIdentifier()
    local value, length = self:GetName()
    if not value then
        error("Invalid identifier")
    end
    self.Pos.Counter = self.Pos.Counter + length
    
    if self.Version[value] then
        self.Tokens[#self.Tokens + 1] = Token.new(value, value, "Keyword")
    else
        self.Tokens[#self.Tokens + 1] = Token.new(value, value, "Identifier")
    end
end

function LexerClassDebug:LexOperator(char)
    if self.Version.OPERATORS[char] then
        self.Tokens[#self.Tokens+1] = Token.new("Operator", char, "Operator")
    end
end

function LexerClassDebug:LexSymbol(char)
    if self.Version.SYMBOLS[char] then
        self.Tokens[#self.Tokens+1] = Token.new("Symbol", char, "Symbol")
    end
end

function LexerClassDebug:LexDot(char)
    
    if self.Head:GoNext() == "." then
        char = char .. self.Head:GoNext()
        if self.Head:Next() == "." then
            -- Var arg
            self.Tokens[#self.Tokens+1] = Token.new("VarArgLiteral", "...", "Symbol")
            return
        end
    end
    self.Tokens[#self.Tokens+1] = Token.new("Symbol", char, "Symbol")
end

-- Number
do
    function LexerClassDebug:GetInt()
        local value = string.match(self.Source, "[%d]+", self.Pos.Counter)
        return value, #value
    end
    
    local Float1 = "[%d]*[%.][%d]+" .. EXPONENT
    local Float2 = "[%d]+" .. EXPONENT
    function LexerClassDebug:GetFloat()
        local value = string.match(self.Source, Float1, self.Pos.Counter) or
            string.match(self.Source, Float2, self.Pos.Counter)
        return value, #value
    end
    
    local Hex = "0[xX]%.?" .. HEX_NUMBER .. "*%.?" .. HEX_NUMBER .. "*" .. HEX_EXPONENT
    function LexerClassDebug:GetHex()
        local value = string.match(self.Source, Hex, self.Pos.Counter)
        return value, #value
    end
    
    function LexerClassDebug:LexNumber()
        local cur, next = self.Head:Current(), self.Head:Next()
        if cur == "0" and next == "x" or next == "X" then
            -- Hexadecimal
            local value, length = self:GetHex()
            if value then
                self.Pos.Counter = self.Pos.Counter + length
                self.Tokens[#self.Tokens + 1] = Token.new("HexadecimalLiteral", value, "Number", self.Pos.Counter)
            else
                error("Invalid hexadecimal")
            end
        end
        
        -- Decimal
        local value, length = self:GetInt()
        if value then
            -- Integer
            self.Pos.Counter = self.Pos.Counter + length
            self.Tokens[#self.Tokens+1] = Token.new("IntegerLiteral", value, "Number", self.Pos.Counter)
        else
            -- Float
            value, length = self:GetFloat()
            if value and value ~= "" then
                self.Pos.Counter = self.Pos.Counter + length
                self.Tokens[#self.Tokens+1] = Token.new("FloatLiteral", value, "Number", self.Pos.Counter)
            else
                error("Invalid number")
            end
        end
    end
end


function LexerClassDebug:Walk()
    
    while true do
        local char = self:TrimWhitespaces(self.Head:GoNext())
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


return LexerClassDebug