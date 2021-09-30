--[[
    Main
    HawDevelopment
    28/09/2021
--]]

local DO_CLI = true

local USAGE = [[
    USAGE: Lua.lua [SUBCOMMANDS] [FILES]
    
    SUBCOMMANDS:
        run     Runs a file
        sim     Takes input and interprets it immediately
]]

local Lexer = require("Generator.Lexer")
local Interpreter = require("Generator.Interpreter")
local Parser = require("Generator.Parser")

local function PrintTokens(tokens)
    for _, tok in pairs(tokens) do
        print(tok:rep())
    end
end

if DO_CLI then
    if #arg == 0 then
        print(USAGE)
        return
    end
    
    local command = arg[1]
    if command == "run" then
        local file = io.open(arg[2], "r")
        if not file then
            return print("File not found")
        end
        
        local source = file:read("*a")
        file:close()
        
        print("Lexing:")
        local tokens = Lexer(source)
        PrintTokens(tokens)
        print("Parsing:")
        local parsed = Parser(tokens)
        PrintTokens(parsed)
        print("Interpreting:")
        Interpreter(parsed)
        
    elseif command == "sim" then
        
        while true do
            io.write("> ")
            local inp = io.read("*l")
            if inp == "exit" or not inp then
                return
            end
            
            print("Lexing:")
            local tokens = Lexer(inp)
            PrintTokens(tokens)
            print("Parsing:")
            local parsed = Parser(tokens)
            PrintTokens(parsed)
            print("Interpreting:")
            Interpreter(parsed)
        end
    end
end