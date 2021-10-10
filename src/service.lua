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

local function PrintFile(source, lexer, parser, interpreter)
    local starttime = os.clock()
    print("\nLexing:")
    local lextime, tokens = TakeTime(function(...)
        return lexer(...)
    end, source)
    print("Lexing took: ", lextime .. "s")
    print("\nParsing:")
    local parsetime, parsed = TakeTime(function(...)
        return parser(...)
    end, tokens)
    print("Parsing took: ", parsetime .. "s")
    print("Total real time: ", (os.clock() - starttime) .. "s")
    print("Total time: ", (parsetime + lextime) .. "s")
    return tokens, parsed
end

function RunFile(source, lexer, parser)
    local succes, tokens = pcall(function()
        return lexer(source)
    end)
    if not succes then
        print("Lexing failed: ", tokens)
    end
    local succes, parsed = pcall(function()
        return parser(tokens)
    end)
    if not succes then
        print("Parsing failed: ", parsed)
    end
    return tokens, parsed
end

return function(source, lexer, parser, interpreter, shouldprint)
    source = source or ""
    lexer = lexer or Lexer
    parser = parser or Parser
    if shouldprint == nil then
        shouldprint = true
    end
    
    local lexed, parsed
    if shouldprint then
        lexed, parsed = PrintFile(source, lexer, parser, interpreter)
    else
        lexed, parsed = RunFile(source, lexer, parser)
    end
    
    return lexed, parsed
end