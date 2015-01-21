#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	for i = 1, 10000000 do end
	print "child done"
end)
print "parent done"
--	child still running when parent ends

--[[
parent done
luatask: received abort signal
stack traceback:
        bin/task/test12.lua:4: in function <bin/task/test12.lua:3>
        [C]: ?
]]--
