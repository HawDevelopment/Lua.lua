--[[
    Service file
    HawDevelopment
    28/09/2021
--]]

local Lexer = require("src.Generator.Lexer.Lexer")
local Parser = require("src.Generator.Parser.Parser")

local unpack = unpack or table.unpack

local function TakeTime(func, ...)
    local start = os.clock()
    local arg = { func(...) }
    return os.clock() - start, unpack(arg)
end

local function PrintFile(source)
    local starttime = os.clock()
    print("\nLexing:")
    local lextime, tokens = TakeTime(function(...)
        return Lexer(...)
    end, source)
    print("Lexing took: ", lextime .. "s")
    print("\nParsing:")
    local parsetime, parsed = TakeTime(function(...)
        return Parser(...)
    end, tokens)
    print("Parsing took: ", parsetime .. "s")
    print("Total real time: ", (os.clock() - starttime) .. "s")
    print("Total time: ", (parsetime + lextime) .. "s")
    return tokens, parsed
end

function RunFile(source)
    local succes, tokens = pcall(function()
        return Lexer(source)
    end)
    if not succes then
        print("Lexing failed: ", tokens)
    end
    local succes, parsed = pcall(function()
        return Parser(tokens)
    end)
    if not succes then
        print("Parsing failed: ", parsed)
    end
    return tokens, parsed
end

return function(source, shouldprint)
    source = source or ""
    if shouldprint == nil then
        shouldprint = true
    end
    
    local lexed, parsed
    if shouldprint then
        lexed, parsed = PrintFile(source)
    else
        lexed, parsed = RunFile(source)
    end
    
    return lexed, parsed
end