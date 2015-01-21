#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run(function()
		local exec = require "tek.lib.exec"
		while true do end
	end)
	while true do end
end)
exec.sleep(100)
c:abort()
print "parent done"

--[[
luatask: received abort signal
stack traceback:
        bin/task/case44.lua:9: in function <bin/task/case44.lua:3>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case44.lua:7: in function <bin/task/case44.lua:5>
        [C]: ?
parent done
]]--
