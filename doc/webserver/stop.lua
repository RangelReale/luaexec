
local args = Request:getArgs()

if args.submit == "Stop Server" then
	Request:getGlobal().Server:setServerState("break")
end
	
redirect("/webserver/control.lhtml")
