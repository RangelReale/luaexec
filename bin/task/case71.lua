#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({ 
	taskname = "child", 
	func = function()
		local exec = require "tek.lib.exec"
		assert(exec.sendmsg("main", "yo"))
		print(exec.waitmsg())
	end
})
print(exec.getname())
print(exec.waitmsg())
assert(exec.sendmsg("child", "africa"))
c:join()

--[[
task: 0xba8928
yo      child   m
africa  task: 0xba8928  m
]]-- 
