
function Fib(m)
    if m < 2 then
        return m
    else
        return Fib(m - 1) + Fib(m - 2)
    end
end
print(Fib(10))

return