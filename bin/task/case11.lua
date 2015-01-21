#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	exec.sleep(100)
	print "child done."
end)
print "parent done."

--[[
parent done.
luatask: bin/task/case11.lua:5: received abort signal
stack traceback:
        [C]: in function 'sleep'
        bin/task/case11.lua:5: in function <bin/task/case11.lua:3>
        [C]: ?
]]-- 
