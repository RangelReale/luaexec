#!/usr/bin/env lua
local exec = require "tek.lib.exec"

local c1 = exec.run(function()
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

exec.sleep(1000)
c1:sendport("ui", "Hello")
exec.sleep(1000)
c1:sendport("ui", "world!")
exec.sleep(2000)
c1:sendport("ui", "Quitting now...")
exec.sleep(2000)
c1:terminate()
