--[[
    LexerClass
    HawDevelopment
    09/10/2021
--]]

local LexerClass = {}
LexerClass.__index = LexerClass

local HEX_NUMBER = "[%da-fA-F]"
local EXPONENT = "[eE]?[%+%-]?%d*"
local HEX_EXPONENT = "[pP][%+%-]?%d*"

function LexerClass.new(source, head, version)
    local self = setmetatable({}, LexerClass)
    
    self.Head = head
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
        return string.match(self.Source, "[%a_][%a%d_]*", self.Head.Pos)
    end
    
    function LexerClass:GetMultiline()
        return string.match(self.Source, "%[=*%[[.%s%p%a]*%]=*%]", self.Head.Pos)
    end
    
    function LexerClass:GetToLineEnd()
        -- We add an extra line so it neven fails
        return string.match(self.Source .. "\n", "[.%s%p%a]-\n", self.Head.Pos)
    end
end

function LexerClass:LexString(char)
    --TODO: Implement escape characters
    --TODO: Implement multi line strings
    
    local value = string.match(self.Source, char .. ".-" .. char, self.Pos.Counter)
    if not value then
        error("Unterminated string literal")
    end
    self.Tokens[#self.Tokens + 1] = { Name = "String",
        Value = value,
        Type = "String",
        Position = self.Head:CopyPos()
    }
    for i = 1, #value - 1 do
        self.Head:GoNext()
    end
end

function LexerClass:LexIdentifier()
    local name = self:GetName()
    if not name then
        error("Invalid identifier")
    end
    for _ = 1, #name - 1 do
        self.Head:GoNext()
    end
    
    if self.Version.KEYWORDS[name] then
        if self.Version.BOOLEAN[name] then
            self.Tokens[#self.Tokens + 1] = { Name = "BooleanLiteral", Value = name, Type = "Boolean", Position = self.Head:CopyPos() }
        elseif name == "nil" then
            self.Tokens[#self.Tokens + 1] = { Name = "NilLiteral", Value = name, Type = "Boolean", Position = self.Head:CopyPos() }
        else
            self.Tokens[#self.Tokens + 1] = { Name = name, Value = name, Type = "Keyword", Position = self.Head:CopyPos() }
        end
    else
        self.Tokens[#self.Tokens + 1] = { Name = name, Value = name, Type = "Identifier", Position = self.Head:CopyPos() }
    end
end

function LexerClass:LexOperator(char)
    self.Tokens[#self.Tokens + 1] = { Name = "Operator", Value = char, Type = "Operator", Position = self.Head:CopyPos() }
end

function LexerClass:LexSymbol(char)
    self.Tokens[#self.Tokens + 1] = { Name = "Symbol", Value = char, Type = "Symbol", Position = self.Head:CopyPos() }
end

function LexerClass:LexDot(char)
    
    if self.Head:GoNext() == "." then
        char = char .. self.Head:Current()
        if self.Head:GoNext() == "." then
            -- Var arg
            self.Tokens[#self.Tokens+1] = { Name = "VarArgLiteral", Value = "...", Type = "Symbol", Position = self.Head:CopyPos() }
            return
        end
    end
    self.Tokens[#self.Tokens+1] = { Name = "Symbol", Value = char, Type = "Symbol", Position = self.Head:CopyPos() }
end

-- Comment
function LexerClass:TrimComment()
    self.Head:GoNext()
    
    local islong = false
    if self.Head:GoNext() == "[" and self.Head:Next() == "[" then
        local multi = self:GetMultiline()
        if multi then
            islong = true
            for _ = 1, #multi - 1 do
                self.Head:GoNext()
            end
        end
    end
    
    if not islong then
        local multi = self:GetToLineEnd()
        if multi then
            for _ = 1, #multi - 1 do
                self.Head:GoNext()
            end
        end
    end
end

-- Number
do
    function LexerClass:GetInt()
        local value = string.match(self.Source, "[%d]+", self.Head.Pos)
        return value
    end
    
    local Float1 = "[%d]*[%.][%d]+" .. EXPONENT
    local Float2 = "[%d]+" .. EXPONENT
    function LexerClass:GetFloat()
        return string.match(self.Source, Float1, self.Head.Pos) or
            string.match(self.Source, Float2, self.Head.Pos)
    end
    
    local Hex = "0[xX]%.?" .. HEX_NUMBER .. "*%.?" .. HEX_NUMBER .. "*" .. HEX_EXPONENT
    function LexerClass:GetHex()
        return string.match(self.Source, Hex, self.Head.Pos)
    end
    
    function LexerClass:LexNumber()
        local cur, next = self.Head:Current(), self.Head:Next()
        if cur == "0" and next == "x" or next == "X" then
            -- Hexadecimal
            local hex = self:GetHex()
            if hex then
                self.Tokens[#self.Tokens + 1] = { Name = "HexadecimalLiteral", Value = hex, Type = "Number", Position = self.Head:CopyPos() }
                for i = 1, #hex - 1 do
                    self.Head:GoNext()
                end
                return
            else
                error("Invalid hexadecimal")
            end
        end
        
        -- Decimal
        local number = self:GetInt()
        local length = self.Head.Pos + #number
        if number and self.Source:sub(length, length) == "." then
            -- Float
            number = self:GetFloat()
            self.Tokens[#self.Tokens+1] = { Name = "FloatLiteral", Value = number, Type = "Number", Position = self.Head:CopyPos() }
            for i = 1, #number - 1 do
                self.Head:GoNext()
            end
        elseif number then
            -- Int
            self.Tokens[#self.Tokens+1] = { Name = "IntegerLiteral", Value = number, Type = "Number", Position = self.Head:CopyPos() }
            for i = 1, #number - 1 do
                self.Head:GoNext()
            end
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
            self.Tokens[#self.Tokens + 1] = { Name = "Symbol", Value = char, Type = "Symbol" }
        end
    end
end


return LexerClass