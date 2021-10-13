--[[
    Test module
    HawDevelopment
    09/10/2021
--]]

local TableToString
local function ToString(v, indent)
    if type(v) == "table" and (v.Name or v.Type or v.Value) then
        return v:rep(indent)
    elseif type(v) == "table" then
        return TableToString(v, indent)
    else
        return tostring(v)
    end
end

TableToString = function(tab, indent)
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
            if not tab2[key] then
                return false, key .. ": Could not find key in table to check."
            end
            local ret
            if value.Name or value.Type then
                if value:Is(tab2[key]) then
                    if type(value.Value) == "table" then
                        ret = CheckDeep(value.Value, tab2[key].Value)
                    else
                        ret = value.Value == tab2[key].Value
                    end
                else
                    ret = false
                end
                
            else
                ret = CheckDeep(value, tab2[key])
            end
            
            if not ret then
                return false, key .. ": The two table are not the same!\n" .. TableToString(value) .. " ~= " .. TableToString(tab2[key])
            end
        else
            local typecheck
            if type(value) ~= type(tab2[key]) then
                typecheck = ("The key \"%s\" with value \"%s\" of type \"%s\" isnt type \"%s\"!\n"):format(key, value, type(value), type(tab2[key]))
            end
            
            if value and tab2[key] and value ~= tab2[key] then
                return false, typecheck or (key .. ":" .. tostring(value) .. " ~= " .. tostring(tab2[key]))
            end
        end
    end
    return true
end

local function test(program, outlexed, outparsed)
    
    return function (_, lexer, parser)
        local output, ran = true, false
        local lexed = lexer(program)
        if outlexed then
            output = output and CheckDeep(outlexed, lexed)
            ran = true
        end
        if outparsed then
            local parsed = parser(lexed)
            output = output and CheckDeep(outparsed, parsed)
            ran = true
        end
        
        if not ran then
            output = false
        end
        return output
    end
end

return test