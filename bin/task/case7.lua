#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run({ 
		taskname = "grandchild", 
		func = function()
			local exec = require "tek.lib.exec"
			assert(exec.sendmsg("main", "yo"))
			print(exec.waitmsg())
		end
	})
	c:join()
end)
print(exec.getname())
print(exec.waitmsg())
assert(exec.sendmsg("grandchild", "africa"))
c:join()

--[[
task: 0xee3b48
yo      grandchild      m
africa  task: 0xee3b48  m
]]-- 
