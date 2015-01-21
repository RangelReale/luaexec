#!/usr/bin/env lua
local exec = require "tek.lib.exec"
local c1 = exec.run("bin/demo.lua")
exec.sleep(1000)
local c2 = exec.run("bin/plasma.lua")
exec.sleep(2000)
c1:terminate()
c2:terminate()
