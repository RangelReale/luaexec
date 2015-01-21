#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	error "child error"
end)
print(c:join())
print "parent done"

--[[
luatask: bin/task/test31.lua:4: child error
stack traceback:
        [C]: in function 'error'
        bin/task/test31.lua:4: in function <bin/task/test31.lua:3>
        [C]: ?
lua: bin/task/test31.lua:6: received abort signal
stack traceback:
        [C]: in function 'join'
        bin/task/test31.lua:6: in main chunk
        [C]: ?
]]--
