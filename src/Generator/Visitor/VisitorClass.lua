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

function VisitorClass:_instruction(toadd, name, ...)
    local value
    if ... then
        value = { ... }
    end
    table.insert(toadd, { Name = name, Value = value , Type = "Instruction" })
end

function VisitorClass:Number(cur, toadd)
    self:_instruction(toadd, "Mov", "eax", cur.Value)
end

function VisitorClass:Boolean(cur, toadd)
    self:_instruction(toadd, "Mov", "eax", cur.Value == "true" and "1" or "0")
end

function VisitorClass:UnaryExpression(cur, toadd)
    self:Walk(cur.Value.expr, toadd)
    table.insert(toadd, cur)
end

function VisitorClass:BinaryExpression(cur, toadd)
    self:Walk(cur.Value.left, toadd)
    self:_instruction(toadd, "Push", "eax")
    self:Walk(cur.Value.right, toadd)
    
    cur.Value = cur.Value.op.Value -- Get the string of the operator
    table.insert(toadd, cur)
end

function VisitorClass:ReturnStatement(cur, toadd)
    
    for _, value in pairs(cur.Value) do
        table.insert(toadd, self:Walk(value))
    end
    table.insert(toadd, cur)
end

function VisitorClass:FunctionStatement(cur, toadd)
    
    local body = {}
    for _, value in pairs(cur.Value.body) do
        self:Walk(value, body)
    end
    cur.Value.body = body
    
    cur.Value.name = cur.Value.name.Value    
    table.insert(toadd, cur)
end

function VisitorClass:CallStatement(cur, toadd)
    for _, value in pairs(cur.Value.Value.args) do
        self:Walk(value, toadd)
        self:_instruction(toadd, "Push", "eax")
    end
    
    cur.Value = { name = cur.Value.Value.base.Value, args = cur.Value.Value.args }
    table.insert(toadd, cur)
end

-- TODO: Add suport for multiple inits
function VisitorClass:LocalStatement(cur, toadd)
    if #cur.Value.inits > 0 then
        self:Walk(cur.Value.inits[1], toadd)
    else
        self:_instruction(toadd, "Mov", "eax", 0) -- If there is no init, set it to 0
    end
    cur.Value = cur.Value.idens[1] -- Get the name of the variable
    table.insert(toadd, cur)
end

-- TODO: Add suport for multiple values
function VisitorClass:AssignmentStatement(cur, toadd)
    self:Walk(cur.Value.values[1], toadd)
    cur.Value = cur.Value.idens[1] -- Get the name of the variable
    table.insert(toadd, cur)
end

function VisitorClass:Identifier(cur, toadd)
    table.insert(toadd, { Name = "GetLocalExpression", Value = cur.Value, Type = "Expression" })
end

function VisitorClass:IfStatement(cur, toadd)
    
    local statements = cur.Value.statements
    local clauses = {}
    for _, value in pairs(statements) do
        local con = {}
        self:Walk(value.Value.condition, con)
        
        local body = {}
        for _, towalk in pairs(value.Value.body) do
            self:Walk(towalk, body)
        end
        table.insert(clauses, { body = body, condition = con })
    end
    cur.Value = clauses
    table.insert(toadd, cur)
end

local NameToFunction = {
    IntegerLiteral = VisitorClass.Number,
    FloatLiteral = VisitorClass.Number,
    BooleanLiteral = VisitorClass.Boolean,
    
    UnaryExpression = VisitorClass.UnaryExpression,
    ReturnStatement = VisitorClass.ReturnStatement,
    BinaryExpression = VisitorClass.BinaryExpression,
    FunctionStatement = VisitorClass.FunctionStatement,
    
    AssignmentStatement = VisitorClass.AssignmentStatement,
    LocalStatement = VisitorClass.LocalStatement,
    CallStatement = VisitorClass.CallStatement,
    
    IfStatement = VisitorClass.IfStatement
}

local TypeToFunction = {
    Identifier = VisitorClass.Identifier
}

function VisitorClass:Walk(node, toadd)
    toadd = toadd or self.Out
            
    if node == nil then
        return
    else
        local tocall = NameToFunction[node.Name] or TypeToFunction[node.Type]
        if not tocall then
            return print("No function for " .. node.Name)
        end
        return tocall(self, node, toadd)
    end
end

function VisitorClass:Run()
    while self.Head:GoNext() do
        self:Walk(self.Head:Current(), self.Out)
    end
    return self.Out
end

return VisitorClass