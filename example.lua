
function Fib(n)
    local toret = 1
    if n < 2 then
        toret = n
    else
        local a = Fib(n - 1)
        local b = Fib(n - 2)
        toret = a + b
    end
    return toret
end

local a = Fib(10)
print(a)

return