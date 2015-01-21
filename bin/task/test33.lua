#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	error "child error"
end)
c:abort()
print "parent done"

--[[
luatask: bin/task/test33.lua:4: child error
stack traceback:
        [C]: in function 'error'
        bin/task/test33.lua:4: in function <bin/task/test33.lua:3>
        [C]: ?
parent done
]]--
