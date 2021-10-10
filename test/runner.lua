--[[
    Test runner
    HawDevelopment
    09/10/2021
--]]

local tests = require("test.tests.init")
local Service = require("src.service")
local Token = require("src.Generator.Util.Token")
local Node = require("src.Generator.Util.Node")

local total, failed, passed = 0, 0, 0
function RunTest(torun, name, indent)
    if not indent then
        indent = ""
    else
        indent = indent .. "    "
    end
    
    if type(torun) == "function" then
        total = total + 1
        local succes, result, out = pcall(torun, Service, Token, Node)
        if succes then
            if not result then
                print("\n" .. indent .. "Test: " .. name .. " failed!")
                print(indent .. (out or ""))
                failed = failed + 1
            else
                print(indent .. "Test: " .. name .. " passed!")
                passed = passed + 1
            end
        else
            print(indent .. "Test: " .. name .. " error!\n" .. result)
            failed = failed + 1
        end
        
    
    elseif type(torun) == "table" then
        print("\nRunning Test: " .. name .. "!")
        for i, v in pairs(torun) do
            RunTest(v, i, "")
        end
        print("Done running: " .. name .. "!")
    end
end
for name, torun in pairs(tests) do
    RunTest(torun, name)
end
print("\nTotal tests: " .. total)
print("Passed: " .. passed)
print("Failed: " .. failed)
