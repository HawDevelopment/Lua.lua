--[[
    Main file
    HawDevelopment
    07/10/2021
--]]

local Service = require("src.service")

local Lexer = require("src.Generator.Lexer.Lexer")
local LexerDebug = require("src.Generator.Lexer.LexerDebug")
local Parser = require("src.Generator.Parser.Parser")
local ParserDebug = require("src.Generator.Parser.ParserDebug")

local USAGE = [[
    USAGE: Lua.lua [SUBCOMMANDS] [FILES]
    
    SUBCOMMANDS:
        run     Runs a file
        sim     Takes input and interprets it immediately
]]

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

function RunCommand()
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
        local lexed, parsed = Service(source, lexer, parser, nil, DEBUG)
        if PRINT_ARG then
            if type(lexed) == "table" then
                print("Lexed tokens:")
                PrintTokens(lexed)
            end
            if type(parsed) == "table" then
                print("Parsed tokens:")
                PrintTokens(parsed)
            end
        end
        
    elseif args[1] == "sim" then
        
        while true do
            io.write("> ")
            local inp = io.read("*l")
            if inp == "exit" or not inp then
                return
            end
            
            local lexed, parsed = Service(inp, lexer, parser, nil, DEBUG)
            if PRINT_ARG then
                if type(lexed) == "table" then
                    print("Lexed tokens:")
                    PrintTokens(lexed)
                end
                if type(parsed) == "table" then
                    print("Parsed tokens:")
                    PrintTokens(parsed)
                end
            end
        end
    end
end

RunCommand()