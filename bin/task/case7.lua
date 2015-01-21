#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run({ 
		taskname = "hello", 
		func = function()
			local exec = require "tek.lib.exec"
			exec.sendmsg("main", "hello")
			print(exec.waitmsg())
		end
	})
	c:join()
end)
print(exec.getname())
print(exec.waitmsg())
exec.sendmsg("hello", "africa")
c:join()

--[[
task: 0x2095268
hello   hello   m
africa  task: 0x2095268 m
]]-- 
