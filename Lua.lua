--[[
    Main file
    HawDevelopment
    07/10/2021
--]]

local Lua = require("src.service")
local unpack = unpack or table.unpack

-- (AUTO_COMPILE only supports windows for now!)
local AUTO_COMPILE = true -- Allow Lua.lua to run nasm and gcc automatically
local AUTO_RUN = true -- Allow Lua.lua to run the compiled binary automatically

local USAGE = [[
    USAGE: Lua.lua [SUBCOMMANDS] [FILES]
    
    SUBCOMMANDS:
        run     Runs a file
        sim     Takes input and interprets it immediately
]]

local PrintTokens
do
    local TableToString, ToReturn
    local function ToString(v, indent)
        if type(v) == "table" and v.Name and v.Type then
            return ToReturn(v, indent)
        elseif type(v) == "table" then
            return TableToString(v, indent)
        else
            return tostring(v)
        end
    end

    TableToString = function(tab, indent)
        local str, stop = "{", (indent or "") .. "}"
        indent = indent and indent .. "\t" or "\t"
        if next(tab) then
            str = str .. "\n"
            for i, v in pairs(tab) do
                str = str .. indent .. i .. " = " .. ToString(v, indent) .. ",\n"
            end
        end
        
        return str .. stop
    end

    ToReturn = function(self, indent)
        return "(" .. self.Name .. ":"
            .. (type(self.Value) == "table" and TableToString(self.Value or {}, indent) or self.Value)
            .. ")"
    end

    function PrintTokens(tokens)
        if tokens.Name and tokens.Name == "Chunk" then
            PrintTokens(tokens.Value)
        else
            for _, tok in pairs(tokens) do
                print(ToReturn(tok))
            end
        end
    end
end

local function ValueInTable(tab, value)
    for i, val in pairs(tab) do
        if val == value then
            return true
        end
    end
    return false
end
local function FindInTable(tab, value)
    for i, val in pairs(tab) do
        if val == value then
            return i
        end
    end
    return nil
end

local function TakeTime(func, ...)
    local start = os.clock()
    local arg = { func(...) }
    return os.clock() - start, unpack(arg)
end

PRINT_VISIT = nil

function RunSource(source, settings)
    local ast, tokens, visited
    if settings.Debug then
        -- Taketime
        local alltime, time = os.clock(), nil
        time, tokens = TakeTime(Lua.Lex, source)
        print("Lexing took " .. time .. "s")
        time, ast = TakeTime(Lua.Parse, tokens)
        print("Parsing took " .. time .. "s")
        if settings.Compile then
            time, visited = TakeTime(Lua.Visit, ast)
            print("Visiting took " .. time .. "s")
        end
        alltime = os.clock() - alltime
        print("Total time " .. alltime .. "s")
    else
        tokens = Lua.Lex(source)
        ast = Lua.Parse(tokens)
        visited = Lua.Visit(ast)
    end
    
    return tokens, ast, visited
end

local function Run(lexed, parsed, visited, settings)
    if settings.Print then
        if lexed then
            print("Lexed: \n")
            PrintTokens(lexed)
        end
        if parsed then
            print("Parsed: \n")
            PrintTokens(parsed)
        end
    end
    if visited and settings.PrintVisited then
        print("Visited: \n")
        PrintTokens(visited)
    end
    if settings.Compile then
        local out = Lua.Compile(visited)
        if settings.Output then
            local file = io.open(settings.Output .. ".asm", "w")
            file:write(out)
            file:close()
            if AUTO_COMPILE then
                
                os.execute("nasm -f win32 " .. settings.Output .. ".asm")
                os.execute("gcc -m32 -o " .. settings.Output .. " " .. settings.Output .. ".obj")
                if AUTO_RUN then
                    os.execute(settings.Output)
                end
            end
        else
            print(out)
        end
    end
end


function RunCommand()
    if #arg == 0 then
        print(USAGE)
        return
    end
    
    local Settings = {
        PrintVisited = ValueInTable(arg, "--visit"),
        Debug = ValueInTable(arg, "--debug") or ValueInTable(arg, "-d"),
        Print = ValueInTable(arg, "--print") or ValueInTable(arg, "-p"),
        Compile = ValueInTable(arg, "--com") or ValueInTable(arg, "-c"),
    }
    -- Output
    local outpos = FindInTable(arg, "--out") or FindInTable(arg, "--output") or FindInTable(arg, "-o")
    if outpos then
        Settings.Output = arg[outpos + 1]
    end
    
    if arg[#arg - 1] == "run" then
        local file = io.open(arg[#arg], "r")
        if not file then
            return print("File not found")
        end
        
        local source = file:read("*a")
        file:close()
        local lexed, parsed, visited = RunSource(source, Settings)
        Run(lexed, parsed, visited, Settings)
        
    elseif arg[#arg] == "sim" then
        
        while true do
            io.write("> ")
            local inp = io.read("*l")
            if inp == "exit" or not inp then
                return
            end
            inp = inp:gsub("\\n", "\n")
            
            local lexed, parsed, visited = RunSource(inp, Settings)
            Run(lexed, parsed, visited, Settings)
        end
    end
end

if arg then
    RunCommand()
end
return RunCommand