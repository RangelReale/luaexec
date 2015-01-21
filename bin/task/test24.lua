#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	print "child done"
end)
exec.sleep(100)
print(exec.wait())
print "parent done"

--[[
child done
c
parent done
]]--
