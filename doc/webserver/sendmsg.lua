local args = Request:getArgs()

if args.submit and args.servermsg then
	-- Server was made accessible via RequestsGlobal, see webserver.lua:
	Request:getGlobal().Server:putMsg(args.servermsg)
end

redirect("/webserver/control.lhtml")
