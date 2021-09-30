--[[
    String to table function
    HawDevelopment
    29/09/2021
--]]

return function(str, tab)
    tab = tab or {}
    for i = 1, #str do
        tab[str:sub(i, i)] = true
    end
    return tab
end