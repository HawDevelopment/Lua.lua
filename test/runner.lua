--[[
    Test runner
    HawDevelopment
    09/10/2021
--]]

local tests = require("test.tests.init")
local Service = require("src.service")
local Lexer = require("src.Generator.Lexer.Lexer")
local Parser = require("src.Generator.Parser.Parser")

local total, failed, passed = 0, 0, 0
function RunTest(torun, name, indent)
    if not indent then
        indent = ""
    else
        indent = indent .. "    "
    end
    
    if type(torun) == "function" then
        total = total + 1
        local succes, result, out = pcall(torun, Service, Lexer, Parser)
        if succes then
            if not result then
                print("\n" .. indent .. "[-]: " .. name)
                print(indent .. "\t" .. (out or "") .. "\n")
                failed = failed + 1
            else
                print(indent .. "[+]: " .. name)
                passed = passed + 1
            end
        else
            print("\n" .. indent .. "[-]: " .. name)
            print(indent .. "\t" .. result .. "\n")
            failed = failed + 1
        end
        
    
    elseif type(torun) == "table" then
        print("\n" .. name .. ":")
        for i, v in pairs(torun) do
            RunTest(v, i, "")
        end
    end
end
for name, torun in pairs(tests) do
    RunTest(torun, name)
end
print("\nTotal tests: " .. total)
print("Passed: " .. passed)
print("Failed: " .. failed)
