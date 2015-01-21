#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	print "child done."
end)
local s = exec.wait()
print("signals received: " .. s)

--[[
child done.
signals received: c
]]-- 
