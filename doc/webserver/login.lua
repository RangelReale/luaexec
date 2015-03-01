local args = Request:getArgs()
local success, perm = login(args.name, args.pass)
if not success then
	return redirect("/webserver/login.lhtml")
end
local session = { name = args.name }
Request:newSession(session)
addbuffer(Request:createSessionCookie())
return redirect("/webserver/login.lhtml")
