--[[
    Visitor Class
    HawDevelopment
    21/10/2021
--]]

local LexerHead = require("src.Generator.Util.LexerHead")
local Position = require("src.Generator.Util.Position")
local Node = require("src.Generator.Util.Node")

local VisitorClass = {}
VisitorClass.__index = VisitorClass

function VisitorClass.new(ast, head)
    local self = setmetatable({}, VisitorClass)
    
    self.Ast = ast
    self.Out = {}
    self.Pos = head and head.Pos or Position.new(0)
    self.Head = head or LexerHead.new(ast.Value, self.Pos)
    
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
    table.insert(self.Out, cur)
    self:Walk(cur.Value.right)
end

function VisitorClass:ReturnStatement(cur)
    
    for _, value in pairs(cur.Value) do
        self:Walk(value)
    end
    table.insert(self.Out, cur)
end

function VisitorClass:FunctionStatement(cur)
    table.insert(self.Out, cur)
    for _, value in pairs(cur.body) do
        self:Walk(value)
    end
    table.insert(self.Out, Node.new("FunctionStatementEnd", cur.name, "Statement"))
end

-- TODO: Add suport for multiple inits
function VisitorClass:LocalStatement(cur)
    if #cur.Value.inits > 0 then
        self:Walk(cur.Value.inits[1])
    else
        self:Number(Node.new("IntegerLiteral", 0, "Number"))
    end
    table.insert(self.Out, Node.new("LocalStatement", "a", "Statement"))
end

local NameToFunction = {
    IntegerLiteral = VisitorClass.Number,
    FloatLiteral = VisitorClass.Number,
    UnaryExpression = VisitorClass.UnaryExpression,
    ReturnStatement = VisitorClass.ReturnStatement,
    BinaryExpression = VisitorClass.BinaryExpression,
    FunctionStatement = VisitorClass.FunctionStatement,
    LocalStatement = VisitorClass.LocalStatement,
}

function VisitorClass:Walk(node)        
    if node == nil then
        return
    else
        local tocall = NameToFunction[node.Name]
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