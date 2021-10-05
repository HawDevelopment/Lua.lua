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

local function TakeTime(func, ...)
    local start = os.clock()
    local arg = { func(...) }
    return os.clock() - start, unpack(arg)
end

local function RunFile(source)
    print("Lexing:")
    local lextime, tokens = TakeTime(function(...)
        return Lexer(...)
    end, source)
    --PrintTokens(tokens)
    print("Lexing took: ", lextime .. "s")
    print("Parsing:")
    local parsetime, parsed = TakeTime(function(...)
        return Parser(...)
    end, tokens)
    -- PrintTokens(parsed)
    print("Parsing took: ", parsetime .. "s")
    -- print("Interpreting:")
    -- Interpreter(parsed)
    print("Total time: ", (parsetime + lextime) * 100 .. "ms")
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
        RunFile(source)
        
    elseif command == "sim" then
        
        while true do
            io.write("> ")
            local inp = io.read("*l")
            if inp == "exit" or not inp then
                return
            end
            
            RunFile(inp)
        end
    end
end