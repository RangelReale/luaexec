#!/usr/bin/env lua

local db = require "tek.lib.debug"
local exec = require "tek.lib.exec"

local MAXWIN = 20
local wins = { }
for i = 1, 25 do
	local w = math.random(0, MAXWIN-1)
	if wins[w] then
		wins[w]:signal()
		wins[w]:join()
	end
	wins[w] = exec.run { filename="bin/plasma.lua", taskname = "child"..w }
	exec.sleep(20)
end

for i = 0, MAXWIN-1 do
	if wins[i] then
		exec.signal("child"..i)
	end
end

for i = 0, MAXWIN-1 do
	if wins[i] then
		wins[i]:join()
	end
end
