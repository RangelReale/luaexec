
local args = Request:getArgs()

for k, v in pairs(args) do
	db.warn("%s = %s (%s)", k, v, type(v))
	if type(v) == "userdata" then
		db.warn("filesize: %s", v:seek("cur"))
	end
end

redirect("/webserver/formtest.lhtml")
