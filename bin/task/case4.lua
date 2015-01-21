#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({ taskname = "child", func = function()
	local exec = require "tek.lib.exec"
	print(exec.waitmsg())
	exec.sendmsg("*p", "world")
end })
c:sendmsg("hello")
print(exec.waitmsg())
c:join()

--[[
hello   task: 0x100bec8 m
world   child   m
]]-- 
