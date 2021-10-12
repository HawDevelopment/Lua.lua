local root do
    local sep = package.config:sub(1,1)
    local pattern = "["..sep.."][^"..sep.."]+"
    root = package.cpath:match("(.+)"..pattern..pattern..pattern.."$")
end

local fs = require "bee.filesystem"
fs.current_path(fs.path(root))

package.path = table.concat({
    root .. "/?.lua",
    root .. "/?/init.lua",
}, ";")
assert(require("Lua"))