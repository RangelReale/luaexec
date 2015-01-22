#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run({ 
		func = function()
			local exec = require "tek.lib.exec"
			assert(exec.sendmsg("main", "yo"))
			print(exec.waitmsg())
		end
	})
	c:join()
end)
print(exec.getname())
local msg, sender = exec.waitmsg()
print(msg, sender)
assert(exec.sendmsg(sender, "africa"))
c:join()

--[[
task: 0x132db78
yo      task: 0x7f8900001220
africa  task: 0x132db78 m
]]-- 
