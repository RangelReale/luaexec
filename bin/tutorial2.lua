#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	print "your orders please!"
	while true do
		local order, sender = exec.waitmsg()
		print(order, sender)
		if order == "quit" then
			break
		end
	end
end)
exec.sleep(1000)
c:sendmsg("scan")
exec.sleep(1000)
c:sendmsg("quit")
c:join()
