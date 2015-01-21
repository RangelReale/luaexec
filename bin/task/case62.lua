#!/usr/bin/env lua
local exec = require "tek.lib.exec"

local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local c = exec.run(function()
		local exec = require "tek.lib.exec"
		exec.sleep(200)
		print "grandchild done"
	end)
	exec.sleep(100)
	c:join()
	print "child done"
end)
c:join()
print "parent done"

--[[
grandchild done
child done
parent done
]]--
