#!/usr/bin/env lua
local exec = require "tek.lib.exec"

local c = exec.run(function()
	local exec = require "tek.lib.exec"
	local ui = require "tek.ui"
	ui.Application:new
	{
		handleUserMsg = function(self, msg)
			self:getById("the-text"):setValue("Text", msg[-1])
			return false
		end,
		setup = function(self)
			ui.Application.setup(self)
			self:addInputHandler(ui.MSG_USER, self, self.handleUserMsg)
		end,
		cleanup = function(self)
			self:remInputHandler(ui.MSG_USER, self, self.handleUserMsg)
			ui.Application.cleanup(self)
		end,
		Children =
		{
			ui.Window:new
			{
				HideOnEscape = true,
				Children =
				{
					ui.Text:new { Id = "the-text", Style = "font::50" }
				}
			}
		}
	}:run()
end)

if not exec.waittime(1000, "cm") then
	local msgs = { "Hello", "world!", "quitting now..." }
	for i = 1, #msgs do
		if not c:sendport("ui", msgs[i]) then
			break
		end
		exec.waittime(1000, "cm")
	end
end
c:terminate()
