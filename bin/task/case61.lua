#!/usr/bin/env lua
local exec = require "tek.lib.exec"

local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run(function()
		local exec = require "tek.lib.exec"
		exec.sleep(100)
		error "something went wrong"
	end)
	exec.sleep(200)
	print "child done"
end)

c:join()
print "parent done"

--[[
luatask: bin/task/case61.lua:9: something went wrong
stack traceback:
        [C]: in function 'error'
        bin/task/case61.lua:9: in function <bin/task/case61.lua:6>
        [C]: ?
luatask: bin/task/case61.lua:11: received abort signal
stack traceback:
        [C]: in function 'sleep'
        bin/task/case61.lua:11: in function <bin/task/case61.lua:4>
        [C]: ?
lua: bin/task/case61.lua:15: received abort signal
stack traceback:
        [C]: in function 'join'
        bin/task/case61.lua:15: in main chunk
        [C]: ?
]]--
