--[[
    Lexer
    HawDevelopment
    28/09/2021
--]]

local LexerHead = require("Generator.Util.LexerHead")
local Token = require("Generator.Util.Token")
local Type = require("Generator.Util.Type")
local Position = require("Generator.Util.Position")

local function GenerateTokens(source, version)
    
    local tokens, pos = {}, Position.new(0)
    local head = LexerHead.new(source, pos)
    
    while head:GoNext() ~= "" do
        local char = head:Current()
        local token
        
        -- Try to find operator
        for _, value in pairs(version.Operators) do
            if value.Value == char then
                token = Token.new(value.Name, value.Value, value.Type)
                break
            end
        end
        
        if not token then
            -- TODO: Keywors and Functions
        end
        
        if not token then
            -- Find number
            if char:match("%d") then
                local value, indot = char, false
                while head:GoNext() do
                    char = head:Current()
                    if char == "." then
                        if indot then
                            error("Invalid number")
                        end
                        indot = true
                        value = value .. char
                    elseif char:match("%d") then
                        value = value .. char
                    else
                        head:GoLast()
                        break
                    end
                end
                token = Token.new("Number", value, Type.new("Number"))
            end
        end
        
        if not token then
            -- Find string
            -- TODO: Parse string before lexing
            if char == "\"" then
                local value = char
                while head:GoNext() do
                    char = head:Current()
                    if char == "\"" then
                        value = value .. char
                        break
                    else
                        value = value .. char
                    end
                end
                token = Token.new("String", value, Type.new("String"))
            end
        end
        
        if token then
            table.insert(tokens, token)
        elseif not char:match("%s") then
            return nil, version.Errors.UnknownSymbol:Format(pos:Copy(), char)
        end
    end
    
    return tokens
end


---@param Source string
return function(Source)
    
    return GenerateTokens(Source, require("Generator.Versions.Lua51"))
end