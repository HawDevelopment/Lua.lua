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
        
        print("Lexing: ")
        local source = file:read("*a")
        file:close()
        
        local tokens, err = Lexer(source)
        if err then
            return print(err:rep())
        end
        
        for _, token in pairs(tokens) do
            print(token:rep())
        end
    elseif command == "sim" then
        
        while true do
            io.write("> ")
            local inp = io.read("*l")
            if inp == "exit" then
                return
            end
            
            print("Lexing: ")
            local tokens, err = Lexer(inp)
            if err then
                return print(err:rep())
            end
            
            for _, token in pairs(tokens) do
                print(token:rep())
            end
        end
    end
end