#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	print(exec.waitmsg())
	exec.signal("*p", "m")
end)
c:sendmsg("hello")
print(exec.waitmsg())
c:join()

--[[
hello   task: 0x9a8de8  m
nil     nil     m
]]-- 
