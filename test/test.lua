--[[
    Test module
    HawDevelopment
    09/10/2021
--]]

local function ToString(v, indent)
    if type(v) == "table" and v.Name and v.Type then
        return v:rep(indent)
    elseif type(v) == "table" then
        return TableToString(v)
    else
        return tostring(v)
    end
end
function TableToString(tab, indent)
    local str, stop = "{", (indent or "") .. "}"
    indent = indent and indent .. "\t" or "\t"
    if next(tab) then
        str = str .. "\n"
        for i, v in pairs(tab) do
            str = str .. indent .. i .. " = " .. ToString(v, indent) .. ",\n"
        end
    end
    
    return str .. stop
end

function CheckDeep(tab1, tab2)
    for key, value in pairs(tab1) do
        if type(value) == "table" then
            local ret, out = CheckDeep(value, tab2[key])
            if not ret then
                return false, key .. ":\n" .. out .. "\n" .. TableToString(value) .. " ~= " .. TableToString(tab2[key])
            end
        else
            local typecheck
            if type(value) ~= type(tab2[key]) then
                typecheck = ("The key \"%s\" with value \"%s\" of type \"%s\" isnt type \"%s\"!\n"):format(key, value, type(value), type(tab2[key]))
            end
            
            if value ~= tab2[key] then
                return false, typecheck or (key .. ":" .. ToString(value) .. " ~= " .. ToString(tab2[key]))
            end
        end
    end
    return true
end

local function test(program, outlexed, outparsed)
    
    return function (service, _, _)
        
        local lexed, parsed = service(program, nil, nil, nil, false)
        
        if outlexed and lexed then
            return CheckDeep(outlexed ,lexed)
        end
        if outparsed and parsed then
            return CheckDeep(outparsed, parsed)
        end
        return false
    end
end

return test