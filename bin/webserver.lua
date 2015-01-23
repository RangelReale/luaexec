#!/usr/bin/env lua
local success, socket = pcall(require, "socket")
if not success then
	print "requires luasocket"
	return
end
local exec = require "tek.lib.exec"
local listen = arg[1] or "localhost:8080"
local httpd = exec.run( {
	taskname = "webserver",
	func = function()
		local exec = require "tek.lib.exec"
		local server = require "tek.class.httpd":new { 
			Listen = arg[1], DocumentRoot = "doc",
			checkAbort = function(self)
				if exec.getsignals("ta") then
					self:setServerState("break")
				end
			end,
			putMsg = function(self, msg)
				exec.sendmsg("*p", msg)
			end
		}
		exec.sendmsg("*p", "running")
		server:run()
	end }, 
	listen)
assert(exec.waitmsg() == "running")
print("httpd is running on "..listen)
while true do
	local sig = exec.waittime(10000, "tcm")
	if sig and sig:find("[tc]") then
		print("received signal " .. sig)
		break
	end
	local msg, sender = exec.getmsg()
	if msg then
		print(msg .. " from " .. (sender or "unknown"))
	else
		print "I have nothing to do..."
	end
end
httpd:terminate()
print "webserver exited gracefully."
