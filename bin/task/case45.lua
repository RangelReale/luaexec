#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run(function()
		local exec = require "tek.lib.exec"
		while true do end
	end)
	c:join()
end)
exec.sleep(100)
c:abort()
print "parent done"

--[[
luatask: received abort signal
stack traceback:
        bin/task/case45.lua:7: in function <bin/task/case45.lua:5>
        [C]: ?
luatask: bin/task/case45.lua:9: received abort signal
stack traceback:
        [C]: in function 'join'
        bin/task/case45.lua:9: in function <bin/task/case45.lua:3>
        [C]: ?
parent done
]]--
