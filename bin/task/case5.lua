#!/usr/bin/env lua
local db = require "tek.lib.debug"
local exec = require "tek.lib.exec"

local t = { }
for i = 1, 10 do
	t[i] = exec.run(function()
		while true do end
	end)
end
print "10 tasks running."

exec.sleep(1000)

--[[
10 tasks running.
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case5.lua:8: in function <bin/task/case5.lua:7>
        [C]: ?
]]-- 
