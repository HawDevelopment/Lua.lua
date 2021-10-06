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
    print("Lexing:")
    local lextime, tokens = TakeTime(function(...)
        return lexer(...)
    end, source)
    --PrintTokens(tokens)
    print("Lexing took: ", lextime .. "s")
    print("Parsing:")
    local parsetime, parsed = TakeTime(function(...)
        return parser(...)
    end, tokens)
    -- PrintTokens(parsed)
    print("Parsing took: ", parsetime .. "s")
    -- print("Interpreting:")
    -- interpreter(parsed)
    print("Total time: ", (parsetime + lextime) .. "s")
    return parsed
end

if DO_CLI then
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
    
    local dodebug = ValueInTable(opt, "debug")
    local lexer = dodebug and require("Generator.Debug.LexerDebug") or Lexer
    local parser = dodebug and require("Generator.Debug.ParserDebug") or Parser
    
    if args[1] == "run" then
        local file = io.open(args[2], "r")
        if not file then
            return print("File not found")
        end
        
        local source = file:read("*a")
        file:close()
        local parsed = RunFile(source, lexer, parser)
        if ValueInTable(opt, "print") then
            PrintTokens(parsed)
        end
        
    elseif args[1] == "sim" then
        
        while true do
            io.write("> ")
            local inp = io.read("*l")
            if inp == "exit" or not inp then
                return
            end
            
            local parsed = RunFile(inp, lexer, parser)
            if ValueInTable(opt, "print") then
                PrintTokens(parsed)
            end
        end
    end
end