--[[
    Render class
    HawDevelopment
    11/03/2021
--]]

local TableHead = require("src.Generator.Util.TableHead")

local PrintAssembly = "print:\n\tpush ebp\n\tmov ebp, esp\n\tmov eax, [ebp + 8]\n\tpush eax\n\tpush print_number\n\tcall _printf\n\tpop ebx\n\tpop ebx\n\tpop ebp\n\tret\n"
local StartAssembly = "section .text\nglobal _main\nextern _printf\n" .. PrintAssembly .. "\n_main:\n"
local EndAssembly = "section .data\nprint_number db '%i', 0xA, 0 ; Used for print"

local RenderClass = {}
RenderClass.__index = RenderClass

function RenderClass.new(compiled, head)
    local self = setmetatable({}, RenderClass)
    
    self.File = {
        Start = StartAssembly,
        Function = "",
        End = EndAssembly,
    }
    
    self.Nodes = compiled
    self.Head = head or TableHead.new(compiled)
    
    return self
end

function RenderClass:_add(pos, str)
    self.File[pos] = self.File[pos] .. str
end





function RenderClass:Walk(cur)
    cur = cur or self.Head:GoNext()
    
    if cur == nil then
        return "nil"
    else
        local tocall = self[cur.Name]
        if not tocall then
            error("No function for " .. cur.Name)
        end
        return tocall(self, cur)
    end
end

function RenderClass:Run()
    
    for key, value in pairs(self.Nodes) do
        self.Head = TableHead.new(value)
        while self.Head:GoNext() do
            self.File[key] = self.File[key] .. self:Walk(self.Head:Current())
        end
    end
    
    return (self.File.Start .. "\n" .. self.File.Function .. "\n" .. self.File.End):gsub("\t", "   ")
end

return RenderClass