#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	for i = 1, 10000000 do end
	print "child done"
end)
print(c:join())
print "parent done"

--[[
child done
true
parent done
]]--
