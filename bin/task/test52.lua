#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({
	abort = false,
	func = function()
		for i = 1, #arg do
			print(arg[i])
		end
		error "child error"
	end
}, "hallo", "welt")
print(c:join())

--[[
hallo
welt
luatask: bin/task/test52.lua:9: child error
stack traceback:
        [C]: in function 'error'
        bin/task/test52.lua:9: in function <bin/task/test52.lua:5>
        [C]: ?
false
]]--
