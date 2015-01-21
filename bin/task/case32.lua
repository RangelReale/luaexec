#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	exec.sleep()
end)
exec.sleep(100)
error "something went wrong."

--[[
lua: bin/task/case32.lua:8: something went wrong.
stack traceback:
        [C]: in function 'error'
        bin/task/case32.lua:8: in main chunk
        [C]: ?
luatask: bin/task/case32.lua:5: received abort signal
stack traceback:
        [C]: in function 'sleep'
        bin/task/case32.lua:5: in function <bin/task/case32.lua:3>
        [C]: ?
]]-- 
