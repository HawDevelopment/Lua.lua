--[[
    Main file
    HawDevelopment
    07/10/2021
--]]

local Lua = require("src.service")
local unpack = unpack or table.unpack

local USAGE = [[
    USAGE: Lua.lua [SUBCOMMANDS] [FILES]
    
    SUBCOMMANDS:
        run     Runs a file
        sim     Takes input and interprets it immediately
]]

local function PrintTokens(tokens)
    if tokens.Name and tokens.Name == "Chunk" then
        print(tokens:rep())
    else
        for _, tok in pairs(tokens) do
            print(tok:rep())
        end
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

function RunSource(source, debug)
    local ast, tokens
    if debug then
        -- Taketime
        local alltime, time = os.clock(), nil
        time, tokens = TakeTime(Lua.Lex, source)
        print("Lexing took " .. time .. "s")
        time, ast = TakeTime(Lua.Parse, tokens)
        print("Parsing took " .. time .. "s")
        alltime = os.clock() - alltime
        print("Total time " .. alltime .. "s")
    else
        tokens = Lua.Lex(source)
        ast = Lua.Parse(tokens)
    end
    return tokens, ast
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
    
    if args[1] == "run" then
        local file = io.open(args[2], "r")
        if not file then
            return print("File not found")
        end
        
        local source = file:read("*a")
        file:close()
        local lexed, parsed = RunSource(source, DEBUG)
        
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
            
            local lexed, parsed = RunSource(inp, DEBUG)
            
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

if arg then
    RunCommand()
end
return RunCommand