#!/usr/bin/env lua
local exec = require "tek.lib.exec"

FILE = "bin/plasma.lua"

local c1 = exec.run(FILE)
local c2 = exec.run(FILE)
exec.sleep(2000)

c1:terminate()
c2:terminate()

exec.sleep(200)
local d1 = exec.run(FILE)
exec.sleep(200)
local d2 = exec.run(FILE)
exec.sleep(500)

d1:terminate()
d2:terminate()
