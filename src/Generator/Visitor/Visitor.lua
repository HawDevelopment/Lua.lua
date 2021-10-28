--[[
    Visitor
    HawDevelopment
    21/10/2021
--]]

local VisitorClass = require("src.Generator.Visitor.VisitorClass")

return function(ast)
    
    local visitor = VisitorClass.new(ast)
    return visitor:Run()
end