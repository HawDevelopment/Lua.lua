--[[
    Math
    HawDevelopment
    06/11/2021
--]]

local test = require("test.test")
local util = require("src.Generator.Compiler.CompilerUtil").new()

return {
    test("1 + 1", nil, nil, {
        Start = {
            util:Text("\tsub esp, 0\n"),
            util:Mov(util.Eax, util:Text("1")),
            util:Push(util.Eax),
            util:Mov(util.Eax, util:Text("1")),
            util:Pop(util.Ecx),
            util:Add(util.Eax, util.Ecx),
            util:Text("\tadd esp, 0\n\tpop ebp\n\tret\n")
        }
    }),
    test("1 + 1 + 1", nil, nil, {
        Start = {
            util:Text("\tsub esp, 0\n"),
            util:Mov(util.Eax, util:Text("1")),
            util:Push(util.Eax),
            util:Mov(util.Eax, util:Text("1")),
            util:Pop(util.Ecx),
            util:Add(util.Eax, util.Ecx),
            util:Push(util.Eax),
            util:Mov(util.Eax, util:Text("1")),
            util:Pop(util.Ecx),
            util:Add(util.Eax, util.Ecx),
            util:Text("\tadd esp, 0\n\tpop ebp\n\tret\n")
        }
    }),
    test("1 * 1", nil, nil, {
        Start = {
            util:Text("\tsub esp, 0\n"),
            util:Mov(util.Eax, util:Text("1")),
            util:Push(util.Eax),
            util:Mov(util.Eax, util:Text("1")),
            util:Pop(util.Ecx),
            util:Mul(util.Eax, util.Ecx),
            util:Text("\tadd esp, 0\n\tpop ebp\n\tret\n")
        }
    }),
    test("1 * (1 + 1)", nil, nil, {
        Start = {
            util:Text("\tsub esp, 0\n"),
            util:Mov(util.Eax, util:Text("1")),
            util:Push(util.Eax),
            util:Mov(util.Eax, util:Text("1")),
            util:Push(util.Eax),
            util:Mov(util.Eax, util:Text("1")),
            util:Pop(util.Ecx),
            util:Add(util.Eax, util.Ecx),
            util:Pop(util.Ecx),
            util:Mul(util.Eax, util.Eax),
            util:Text("\tadd esp, 0\n\tpop ebp\n\tret\n")	
        }
    })
}