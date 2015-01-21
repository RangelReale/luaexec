#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	while true do end
end)
exec.sleep(100)
error "something went wrong."
-- c garbage collected here
--[[
lua: bin/task/case33.lua:8: something went wrong.
stack traceback:
        [C]: in function 'error'
        bin/task/case33.lua:8: in main chunk
        [C]: ?
luatask: received abort signal
stack traceback:
        bin/task/case33.lua:5: in function <bin/task/case33.lua:3>
        [C]: ?
]]-- 
