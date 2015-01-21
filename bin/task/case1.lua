#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	print "child done."
end)
c:join()
print "parent done."

--[[
child done.
parent done.
]]-- 
