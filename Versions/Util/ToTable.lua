--[[
    String to table function
    HawDevelopment
    29/09/2021
--]]

local function Split(str, tab, split)
    for token in string.gmatch(str, split) do
        tab[token] = true
    end
    return tab
end

return function(str, tab, split)
    tab = tab or {}
    if split then
        return Split(str, tab, split)
    end
    
    for i = 1, #str do
        tab[str:sub(i, i)] = true
    end
    return tab
end