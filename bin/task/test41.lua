#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({
	func = function()
		for i = 1, 10000000 do end
		error "error in child"
	end
})
for i = 1, 20000000 do end
print "parent done"

--[[
luatask: bin/task/test41.lua:6: error in child
stack traceback:
        [C]: in function 'error'
        bin/task/test41.lua:6: in function <bin/task/test41.lua:4>
        [C]: ?
lua: received abort signal
stack traceback:
        bin/task/test41.lua:9: in main chunk
        [C]: ?
]]--
