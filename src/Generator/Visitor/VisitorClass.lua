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

function VisitorClass:Number(cur)
    table.insert(self.Out, cur)
end

function VisitorClass:UnaryExpression(cur)
    self:Walk(cur.Value.expr)
    table.insert(self.Out, cur)
end

function VisitorClass:BinaryExpression(cur)
    self:Walk(cur.Value.left)
    table.insert(self.Out, { Name = "PushIntruction", Type = "Instruction", Position = cur.Position })
    self:Walk(cur.Value.right)
    table.insert(self.Out, cur)
end

function VisitorClass:ReturnStatement(cur)
    
    for _, value in pairs(cur.Value) do
        self:Walk(value)
    end
    table.insert(self.Out, cur)
end

function VisitorClass:FunctionStatement(cur)
    
    local oldout = self.Out
    self.Out = {}
    for _, value in pairs(cur.Value.body) do
        self:Walk(value)
    end
    cur.Value.body = self.Out
    self.Out = oldout
    
    table.insert(self.Out, { Name = "FunctionStatement", Value = {
        name = cur.Value.name.Value,
        body = cur.Value.body,
        params = cur.Value.params,
    }, Type = "Statement", Position = cur.Position})
end

function VisitorClass:CallStatement(cur)
    for _, value in pairs(cur.Value.Value.args) do
        self:Walk(value)
        table.insert(self.Out, { Name = "PushIntruction", Type = "Instruction", Position = value.Position })
    end
    
    table.insert(self.Out, { Name = "CallStatement", Value = { name = cur.Value.Value.base.Value, args = cur.Value.Value.args }, Type = "Statement", Position = cur.Position })
end

-- TODO: Add suport for multiple inits
function VisitorClass:LocalStatement(cur)
    if #cur.Value.inits > 0 then
        self:Walk(cur.Value.inits[1])
    else
        self:Number({ Name = "IntegerLiteral", Value = 0, Type = "Number", Position = cur.Position })
    end
    table.insert(self.Out, { Name = "LocalStatement", Value = cur.Value.idens[1], Type = "Statement", Position = cur.Position })
end

function VisitorClass:Identifier(cur)
    table.insert(self.Out, { Name = "GetLocalStatement", Value = cur.Value, Type = "Statement", Position = cur.Position })
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
        tocall(self, node)
    end
end

function VisitorClass:Run()
    while self.Head:GoNext() do
        self:Walk(self.Head:Current())
    end
    return self.Out
end

return VisitorClass