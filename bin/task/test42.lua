#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({
	abort = false,
	func = function()
		for i = 1, 10000000 do end
		error "error in child"
	end
})
for i = 1, 20000000 do end
print "parent done"

--[[
luatask: bin/task/test42.lua:7: error in child
stack traceback:
        [C]: in function 'error'
        bin/task/test42.lua:7: in function <bin/task/test42.lua:5>
        [C]: ?
parent done
]]--
