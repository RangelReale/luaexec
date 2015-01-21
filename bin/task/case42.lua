#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({ taskname = "child", func = function()
	local exec = require "tek.lib.exec"
	print(exec.waitmsg(200))
end })
exec.sleep(100)
c:sendmsg("hello")
c:join()

--[[
hello   entry.task      m
]]-- 
