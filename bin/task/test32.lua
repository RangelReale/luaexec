#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	error "child error"
end)
exec.sleep(100)
print "parent done"

--[[
luatask: bin/task/test32.lua:4: child error
stack traceback:
        [C]: in function 'error'
        bin/task/test32.lua:4: in function <bin/task/test32.lua:3>
        [C]: ?
lua: bin/task/test32.lua:6: received abort signal
stack traceback:
        [C]: in function 'sleep'
        bin/task/test32.lua:6: in main chunk
        [C]: ?
]]--
