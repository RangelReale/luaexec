#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({ 
	taskname = "hello", 
	func = function()
		local exec = require "tek.lib.exec"
		exec.sendmsg("main", "hello")
		print(exec.waitmsg())
	end
})
print(exec.getname())
print(exec.waitmsg())
exec.sendmsg("hello", "africa")
c:join()

--[[
task: 0x20abef8
hello   hello   m
africa  task: 0x20abef8 m
]]-- 
