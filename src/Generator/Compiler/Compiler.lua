--[[
    Compiler
    HawDevelopment
    21/10/2021
--]]

local CompilerClass = require("src.Generator.Compiler.CompilerClass")
local Lua51 = require("src.Versions.Lua51")

return function(visited)
    local compiler = CompilerClass.new(visited, nil, Lua51)
    return compiler:Run()
end