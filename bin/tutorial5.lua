#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({ taskname = "worker", func = function()
	local exec = require "tek.lib.exec"
	while true do
		local order, sender = exec.waitmsg()
		if order == "getrandom" then
			exec.sendmsg(sender, math.random(1, 10))
		elseif order == "quit" then
			break
		end
	end
end })
for i = 1, 10 do
exec.run(function()
	local exec = require "tek.lib.exec"
	for i = 1, 10 do
		exec.sendmsg("worker", "getrandom")
		local number = exec.waitmsg()
		exec.sendmsg("*p", number)
	end
end)
end
for i = 1, 100 do
	print(exec.waitmsg())
end
c:sendmsg("quit")
c:join()
