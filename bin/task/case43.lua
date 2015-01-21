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
c:signal("a")
c:join()

--[[
luatask: received abort signal
stack traceback:
        bin/task/case43.lua:7: in function <bin/task/case43.lua:5>
        [C]: ?
luatask: bin/task/case43.lua:9: received abort signal
stack traceback:
        [C]: in function 'join'
        bin/task/case43.lua:9: in function <bin/task/case43.lua:3>
        [C]: ?
lua: bin/task/case43.lua:13: received abort signal
stack traceback:
        [C]: in function 'join'
        bin/task/case43.lua:13: in main chunk
        [C]: ?
]]--
