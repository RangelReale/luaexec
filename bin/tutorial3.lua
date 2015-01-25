#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run(function()
	local exec = require "tek.lib.exec"
	while true do
		local order, sender = exec.waitmsg()
		if order == "getrandom" then
		exec.sendmsg(sender, math.random(1, 10))
		elseif order == "quit" then
		break
		end
	end
end)
for i = 1, 5 do
	c:sendmsg("getrandom")
	print(exec.waitmsg())
end
c:sendmsg("quit")
c:join()
