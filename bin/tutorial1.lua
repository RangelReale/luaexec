#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	print "worker running"
	print(exec.wait())
	return "worker done"
end)
exec.sleep(1000)
print(c:terminate())
