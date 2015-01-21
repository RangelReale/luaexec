#!/usr/bin/env lua
local exec = require "tek.lib.exec"

local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run(function()
		local exec = require "tek.lib.exec"
		exec.sleep(200)
		print "grandchild done"
	end)
	exec.sleep(100)
	print "child done"
	-- c garbage collected here, raising abort in grandchild
end)
c:join()
print "parent done"

--[[
child done
luatask: bin/task/case6.lua:8: received abort signal
stack traceback:
        [C]: in function 'sleep'
        bin/task/case6.lua:8: in function <bin/task/case6.lua:6>
        [C]: ?
lua: bin/task/case6.lua:15: received abort signal
stack traceback:
        [C]: in function 'join'
        bin/task/case6.lua:15: in main chunk
        [C]: ?
]]--
