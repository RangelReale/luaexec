-------------------------------------------------------------------------------
--
--	tek.class.wtf
--	(C) by Timm S. Mueller <tmueller@schulze-mueller.de>
--
--	OVERVIEW::
--		LuaWTF - Lua Web Tiny Framework
--
--	MEMBERS::
--		- {{Buffered [ISG]}} (boolean)
--			Specifies whether the output stream should be collected in
--			a buffer by default. Default: {{false}}
--		- {{Environment [IG]}} (table)
--			The function environment passed to scripts.
--			Default: an empty environment
--
--	IMPLEMENTS::
--
--	OVERRIDES::
--		- Class.new()
--
-------------------------------------------------------------------------------

local Class = require "tek.class"
local luahtml = require "tek.lib.luahtml"

local _, coxpcall = pcall(require, "coxpcall")
local xpcall = coxpcall and coxpcall.xpcall or xpcall

local concat = table.concat
local encodehtml = luahtml.encode
local error = error
local insert = table.insert
local loadfile = loadfile
local loadhtml = luahtml.load
local open = io.open
local remove = table.remove
local setfenv = setfenv
local setmetatable = setmetatable
local stderr = io.stderr
local traceback = debug.traceback
local type = type

module("tek.class.wtf", tek.class)
_VERSION = "WTF 2.1"
local WTF = _M
Class:newClass(WTF)

-------------------------------------------------------------------------------
--	encodeurl: encode string to url; optionally specify a string with a
--	set of characters that should be left untouched ( default: $&+,/:;=?@ )
-------------------------------------------------------------------------------

local function f_encurl(c)
	return ("%%%02x"):format(c:byte())
end

function WTF.encodeurl(s, excl)
	-- reserved chars with special meaning:
	local matchset = "$&+,/:;=?@"
	if excl then
		matchset = matchset:gsub("[" .. excl:gsub(".", "%%%1") .. "]", "")
	end
	-- unsafe chars are always substituted:
	matchset = matchset .. '"<>#%{}|\\^~[]`]'
	matchset = "[%z\001-\032\127-\255" .. matchset:gsub(".", "%%%1") .. "]"
	return s:gsub(matchset, f_encurl)
end

-------------------------------------------------------------------------------
--	new: overrides
-------------------------------------------------------------------------------

function WTF.new(class, self)
	self = self or { }
	self.Buffered = self.Buffered or false
	self.Environment = self.Environment or { }
	self.CommonPath = self.CommonPath or ""
	self.CommonPathOverlay = self.CommonPathOverlay or false
	return Class.new(class, self)
end

-------------------------------------------------------------------------------
--	env = createEnvironment(request): Creates a request-specific HTML
--	environment derived from the Environment property; can be overridden if
--	the combined environment needs to be intercepted for passing it back to
--	the request, f.ex.:
--			WTF:new { Environment = _G,
-- 				createEnvironment = function(self, req)
-- 					local env = WTF.createEnvironment(self, req)
-- 					req:setHTMLEnvironment(env)
-- 					return env
-- 				end
-- 			}:doRequest(req)
-------------------------------------------------------------------------------

function WTF:createEnvironment(req)
	local Buffers = { }
	local Buffered = self.Buffered
	local function int_flush()
		if #Buffers > 0 then
			for i = 1, #Buffers do
				req:write(Buffers[i])
			end
			Buffers = { }
		end
	end
	local function int_out(s)
		int_flush()
		req:write(s)
	end
	local envtab
	envtab = { 
		addbuffer = function(s)
			insert(Buffers, s) 
		end,
		check = function(cond, func, arg)
			return cond or error(func and function() func(arg) end)
		end,
		dofile = function(fname, ...)
			fname = fname:match("/?([^/]+)$")
			local f
			if self.CommonPathOverlay then
				f = loadfile(self.CommonPathOverlay .. fname, "bt", envtab)
			end
			f = f or loadfile(self.CommonPath .. fname, "bt", envtab)
			if f then
				if setfenv then
					setfenv(f, envtab)
				end
				return f(...)
			end
		end,
		clearbuffer = function() Buffers = { } end,
		encodehtml = encodehtml,
		encodeurl = encodeurl,
		flush = int_flush,
		out = function(s)
			if Buffered then
				insert(Buffers, s)
			else
				int_out(s)
			end
		end,
		redirect = function(url)
			int_out("Status: 303 See Other\r\nLocation: " .. url .. 
				"\r\n\r\n")
		end,
		redirect_permanent = function(url)
			int_out("Status: 301 Moved\r\nLocation: " .. url .. 
				"\r\n\r\n") 
		end,
		setbuffered = function(onoff) Buffered = onoff end,
		Request = req
	}
	return setmetatable(envtab, { 
		__index = self.Environment,
		__newindex = self.Environment
	})
end

-------------------------------------------------------------------------------
--	res = doRequest(req)
-------------------------------------------------------------------------------

local function errhnd(err)
	local trace = traceback("", 2)
	local t = type(err)
	if t == "table" then
		err.trace = err.trace or trace
	elseif t == "function" then
		err()
		err = "errhnd"
	else
		err = { msg = err, trace = trace }
	end
	return err
end

function WTF:doRequest(req)
	local res, message, trace
	local document = req:getDocument()
	local scriptfile = document.ScriptFile
	if scriptfile then
		local num = 1
		local fullname = document.ScriptPath .. scriptfile
		local defaultname
		if document.OverlayScript then
			defaultname = fullname
			fullname = document.OverlayScript
			num = 2
		end
		for i = 1, num do
			local fh = open(fullname)
			if fh then
				local f
				local env = self:createEnvironment(req)
				f, message = loadfile(fullname, "bt", env)
				local page_without_code
				if not f then
					f, message = loadhtml(fh, "out", scriptfile, env)
					page_without_code = f and not message
				end
				fh:close()
				if f then
					env.dofile("default.lua")
					if page_without_code then
						env.addbuffer("Content-Type: text/html\r\n\r\n")
					end
					if setfenv then
						setfenv(f, env)
					end
					res, message = xpcall(f, errhnd)
					if res or message == "errhnd" then
						env.flush()
					else
						message, trace = message.msg, message.trace
						stderr:write(message, trace, "\n")
					end
					break
				else
					stderr:write(message, "\n")
				end
			elseif i == num then
				message = "Could not open script '" .. scriptname .. "'"
				stderr:write(message .. "\n")
			end
			fullname = defaultname
		end
	else
		stderr:write("No script file\n")
	end
	if not res then
		-- dump max. 3 lines: 
		-- trace = trace:match("^(\n?.-\n.-\n.-\n.-\n?).*") or trace
		trace = "" -- do not dump trace to html
		req:write("Content-Type: text/html\r\n\r\n")
		req:write([[<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>Script Error</title>
</head>
<body>
<h2>Error : ]] .. (scriptfile or "script") .. [[</h2>
<pre>]] .. encodehtml(message) .. [[
]] .. (trace and encodehtml(trace) or "") .. [[
</pre>
</body>
</html>
]])
	end
end
