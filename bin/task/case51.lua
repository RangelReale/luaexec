#!/usr/bin/env lua
local db = require "tek.lib.debug"
local exec = require "tek.lib.exec"

local t = { }
for i = 1, 3 do
	t[i] = exec.run(function()
		print(unpack(arg))
		while true do end
	end, "one", "two")
end
print "10 tasks running."

exec.sleep(1000)

--[[
one     two
10 tasks running.
one     two
one     two
luatask: received abort signal
stack traceback:
        bin/task/case51.lua:9: in function <bin/task/case51.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case51.lua:9: in function <bin/task/case51.lua:7>
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case51.lua:9: in function <bin/task/case51.lua:7>
        [C]: ?
]]--
