#!/usr/bin/env lua
local exec = require "tek.lib.exec"

local c = exec.run(function()
	error "something went wrong." 
end)

local s = exec.wait()
print("signals received: " .. s)

--[[
luatask: bin/task/case3.lua:5: something went wrong.
stack traceback:
        [C]: in function 'error'
        bin/task/case3.lua:5: in function <bin/task/case3.lua:4>
        [C]: ?
lua: bin/task/case3.lua:8: received abort signal
stack traceback:
        [C]: in function 'wait'
        bin/task/case3.lua:8: in main chunk
        [C]: ?
]]-- 
