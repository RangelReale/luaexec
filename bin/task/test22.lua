#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	print "child done"
end)
exec.sleep(100)
print "parent done"

--[[
child done
parent done
]]--
