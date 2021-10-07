local lm       = require 'luamake'
local platform = require 'bee.platform'
local fs       = require 'bee.filesystem'
local exe      = platform.OS == 'Windows' and ".exe" or ""

lm.bindir = "bin/"..platform.OS

lm.EXE_NAME = "Lua"
lm.EXE_DIR = lm.bindir
lm.EXE_RESOURCE = "../../make/Lua.rc"
lm:import "vendor/bee.lua/make.lua"

lm:build 'install' {
    '$luamake', 'lua', 'make/install.lua',
}

lm:copy "copy_bootstrap" {
    input = "make/bootstrap.lua",
    output = lm.bindir.."/main.lua",
}

lm:build "bee-test" {
    lm.bindir.."/"..lm.EXE_NAME..exe,
    pool = "console",
    deps = {
        lm.EXE_NAME,
        "copy_bootstrap"
    },
}

lm:default {
    "bee-test",
    "install",
}