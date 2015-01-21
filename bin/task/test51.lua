#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c = exec.run({
	func = function()
		for i = 1, #arg do
			print(arg[i])
		end
		return "eins", "zwei"
	end
}, "hallo", "welt")
print(c:join())

--[[
hallo
welt
true    eins    zwei
]]--
