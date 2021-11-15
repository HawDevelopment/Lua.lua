
function Print()
    local a = buffer()
    strcpy(a, "Hello world")
    printf("%s\n", a)
    return
end

for i = 1, 10 do
    Print()
end

return