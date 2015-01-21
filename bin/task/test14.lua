#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	for i = 1, 10000000 do end
	print "child done"
end)
print(exec.wait())
print "parent done"

--[[
child done
c
parent done
]]--
