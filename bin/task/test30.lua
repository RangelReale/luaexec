#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	error "child error"
end)
print "parent done"

--[[
parent done
luatask: bin/task/test30.lua:4: child error
stack traceback:
        [C]: in function 'error'
        bin/task/test30.lua:4: in function <bin/task/test30.lua:3>
        [C]: ?
]]--
