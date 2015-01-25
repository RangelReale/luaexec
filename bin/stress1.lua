#!/usr/bin/env lua

local exec = require "tek.lib.exec"

local workers = { }
for i = 1, 50 do
	workers[i] = exec.run({ taskname = "worker"..i, func = function()
	local exec = require "tek.lib.exec"
	while true do
		local order, sender = exec.waitmsg()
		if order == "getrandom" then
			assert(exec.sendmsg(sender, math.random(1, 10)))
		elseif order == "quit" then
			break
		end
	end
	end })
end
print(#workers .. " workers started")

local consumers = { }
for i = 1, 100 do
  consumers[i] = exec.run(function()
    local exec = require "tek.lib.exec"
    for i = 1, 10000 do
	  local w = (i % arg[1]) + 1
      assert(exec.sendmsg("worker"..w, "getrandom"))
      local number = exec.waitmsg()
    end
  end, #workers)
end
print(#consumers .. " consumers started")

for i = 1, #consumers do
	consumers[i]:join()
end
print "consumeres joined"
for i = 1, #workers do
	workers[i]:sendmsg("quit")
end
print "workers signalled"
for i = 1, #workers do
	workers[i]:join()
end
print "workers joined"
