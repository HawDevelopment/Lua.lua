--[[
    Service file
    HawDevelopment
    28/09/2021
--]]

local PRINT_ARG = false
local DEBUG = false

local USAGE = [[
    USAGE: Lua.lua [SUBCOMMANDS] [FILES]
    
    SUBCOMMANDS:
        run     Runs a file
        sim     Takes input and interprets it immediately
]]

local Lexer = require("src.Generator.Lexer.init")
local LexerDebug = require("src.Generator.Lexer.LexerDebug")
local Parser = require("src.Generator.Parser.init")
local ParserDebug = require("src.Generator.Parser.ParserDebug")

local unpack = unpack or table.unpack

local function PrintTokens(tokens)
    for _, tok in pairs(tokens) do
        print(tok:rep())
    end
end

local function ValueInTable(tab, value)
    for _, val in pairs(tab) do
        if val == value then
            return true
        end
    end
    return false
end

local function TakeTime(func, ...)
    local start = os.clock()
    local arg = { func(...) }
    return os.clock() - start, unpack(arg)
end

local function RunFile(source, lexer, parser, interpreter)
    local starttime = os.clock()
    print("\nLexing:")
    local lextime, tokens = TakeTime(function(...)
        return lexer(...)
    end, source)
    if PRINT_ARG then
        PrintTokens(tokens)
    end
    print("Lexing took: ", lextime .. "s")
    print("\nParsing:")
    local parsetime, parsed = TakeTime(function(...)
        return parser(...)
    end, tokens)
    if PRINT_ARG then
        PrintTokens(parsed)
    end
    print("Parsing took: ", parsetime .. "s")
    print("Total real time: ", (os.clock() - starttime) .. "s")
    print("Total time: ", (parsetime + lextime) .. "s")
    return parsed
end

return function(arg)
    if #arg == 0 then
        print(USAGE)
        return
    end
    
    -- Parse the command
    local opt, args = {}, {}
    for _, value in pairs(arg) do
        if string.match(value, "^%-%-") ~= nil then
            opt[#opt+1] = value:sub(3)
        else
            args[#args+1] = value
        end
    end
    
    DEBUG = ValueInTable(opt, "debug")
    PRINT_ARG = ValueInTable(opt, "print")
    local lexer = DEBUG and LexerDebug or Lexer
    local parser = DEBUG and ParserDebug or Parser
    
    if args[1] == "run" then
        local file = io.open(args[2], "r")
        if not file then
            return print("File not found")
        end
        
        local source = file:read("*a")
        file:close()
        local parsed = RunFile(source, lexer, parser)
        
    elseif args[1] == "sim" then
        
        while true do
            io.write("> ")
            local inp = io.read("*l")
            if inp == "exit" or not inp then
                return
            end
            
            local parsed = RunFile(inp, lexer, parser)
        end
    end
end