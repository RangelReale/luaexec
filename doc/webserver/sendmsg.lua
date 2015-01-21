
local args = Request:getArgs()

if args.submit and args.servermsg then
	Request:getGlobal().Server:putMsg(args.servermsg)
end
	
redirect("/webserver/control.lhtml")
