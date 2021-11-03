--[[
    Render
    HawDevelopment
    11/03/2021
--]]

local RenderClass = require("src.Generator.Render.RenderClass")

return function(compiled)
    local compiler = RenderClass.new(compiled)
    return compiler:Run()
end