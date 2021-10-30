--[[
    Visitor Class
    HawDevelopment
    21/10/2021
--]]

local TableHead = require("src.Generator.Util.TableHead")

local VisitorClass = {}
VisitorClass.__index = VisitorClass

function VisitorClass.new(ast, head)
    local self = setmetatable({}, VisitorClass)
    
    self.Ast = ast
    self.Out = {}
    self.Head = head or TableHead.new(ast.Value)
    
    return self
end

function VisitorClass:_instruction(name, ...)
    local value = self.Ast.Value
    if ... then
        value = { ... }
    end
    table.insert(self.Out, { Name = name, Value = value , Type = "Instruction" })
end

function VisitorClass:Number(cur)
    self:_instruction("Mov", "eax", cur.Value)
end

function VisitorClass:UnaryExpression(cur)
    self:Walk(cur.Value.expr)
    return cur
end

function VisitorClass:BinaryExpression(cur)
    self:Walk(cur.Value.left)
    self:_instruction("Push", "eax")
    self:Walk(cur.Value.right)
    
    cur.Value = cur.Value.op.Value -- Get the string of the operator
    return cur
end

function VisitorClass:ReturnStatement(cur)
    
    for _, value in pairs(cur.Value) do
        table.insert(self.Out, self:Walk(value))
    end
    return cur
end

function VisitorClass:FunctionStatement(cur)
    
    local body = {}
    for _, value in pairs(cur.Value.body) do
        table.insert(body, self:Walk(value))
    end
    cur.Value.body = body
    
    cur.Value.name = cur.Value.name.Value    
    return cur
end

function VisitorClass:CallStatement(cur)
    for _, value in pairs(cur.Value.Value.args) do
        table.insert(self.Out, self:Walk(value))
        self:_instruction("Push", "eax")
    end
    
    cur.Value = { name = cur.Value.Value.base.Value, args = cur.Value.Value.args }
    return cur
end

-- TODO: Add suport for multiple inits
function VisitorClass:LocalStatement(cur)
    if #cur.Value.inits > 0 then
        self:Walk(cur.Value.inits[1])
    else
        self:_instruction("Mov", "eax", 0) -- If there is no init, set it to 0
    end
    cur.Value = cur.Value.idens[1] -- Get the name of the variable
    return cur
end

function VisitorClass:Identifier(cur)
    cur.Value = cur.Value.Value -- Get the string of the identifier
    return cur
end

local NameToFunction = {
    IntegerLiteral = VisitorClass.Number,
    FloatLiteral = VisitorClass.Number,
    
    UnaryExpression = VisitorClass.UnaryExpression,
    ReturnStatement = VisitorClass.ReturnStatement,
    BinaryExpression = VisitorClass.BinaryExpression,
    FunctionStatement = VisitorClass.FunctionStatement,
    LocalStatement = VisitorClass.LocalStatement,
    CallStatement = VisitorClass.CallStatement
}

local TypeToFunction = {
    Identifier = VisitorClass.Identifier
}

function VisitorClass:Walk(node)        
    if node == nil then
        return
    else
        local tocall = NameToFunction[node.Name] or TypeToFunction[node.Type]
        if not tocall then
            return print("No function for " .. node.Name)
        end
        return tocall(self, node)
    end
end

function VisitorClass:Run()
    while self.Head:GoNext() do
        local ret = self:Walk(self.Head:Current())
        if ret then
            table.insert(self.Out, ret)
        end
    end
    return self.Out
end

return VisitorClass