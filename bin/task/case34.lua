#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	exec.sleep(100)
	error "something went wrong."
end)
while true do end

--[[
luatask: bin/task/case34.lua:6: something went wrong.
stack traceback:
        [C]: in function 'error'
        bin/task/case34.lua:6: in function <bin/task/case34.lua:3>
        [C]: ?
lua: received abort signal
stack traceback:
        bin/task/case34.lua:8: in main chunk
        [C]: ?
]]-- 
