-------------------------------------------------------------------------------
--
--	tek.class.httpd
--	Written and (C) by Timm S. Mueller <tmueller@schulze-mueller.de>
--
--	OVERVIEW::
--		[[#ClassOverview]] :
--		[[#tek.class : Class]] /
--		[[#tek.class.server : Server]] /
--		HTTPD ${subclasses(HTTPD)}
--
--		This class implements a HTTP server.
--
--	MEMBERS::
--		- {{Address [IG]}} (string)
--			Host/address to bind to, default {{"localhost"}}
--		- {{DefaultIndex [ISG]}} (table)
--			Numerically indexed table of filenames accepted for default index
--			documents. Default {{"index.lhtml"}}, {{"index.lua"}},
--			{{"index.html"}}
--		- {{DirList [ISG]}} (string or boolean)
--			Directory listing options, boolean or the key {{"l"}}.
--			Default {{"l"}}, directories will be listed
--		- {{DocumentRoot [ISG]}} (string)
--			Document root path, default {{"htdocs"}}
--		- {{ExtraWebEnvironment [IG]}} (table)
--			Table to be mixed into default web environment
--		- {{Handlers [ISG]}} (table)
--			Table keyed by filename extensions that invoke a Lua handler.
--			The value is a table of additional arguments to the handler.
--			Default {{"%.lua"}}, {{"%.lhtml"}}
--		- {{Listen [IG]}} (string)
--			Combined Host and port specification, e.g. {{localhost:8080}}
--		- {{Port [IG]}} (number)
--			Port to bind to, default {{8080}}
--		- {{RequestArgs [ISG]}} (table)
--			Table of arguments to be mixed into requests
--		- {{RequestClassName [ISG]}} (string)
--			Name of the class that provides requests. Default
--			{{"tek.class.httprequest"}}
--		- {{ServerName [IG]}} (string)
--			Name under which the server will be registered, default
--			{{"server-http"}}
--
--	IMPLEMENTS::
--		- HTTPD:bind() - binds to {{Address}} and {{Port}}
--		- HTTPD:unbind() - unbinds server
--		
--	OVERRIDES::
--		- Class.new()
--		- Server:run()
--
-------------------------------------------------------------------------------

local db = require "tek.lib.debug"
local _, lfs = pcall(require, "lfs")
local Server = require "tek.class.server"
local socket = require "socket"
local CGI = require "tek.class.cgi"
local WTF = require "tek.class.wtf"
pcall(require, "copas")

local assert = assert
local attributes = lfs.attributes
local concat = table.concat
local error = error
local insert = table.insert
local loadstring = loadstring or load
local math = math
local open = io.open
local os = os
local os_remove = os.remove
local pairs = pairs
local pcall = pcall
local rawset = rawset
local require = require
local select = select
local setmetatable = setmetatable
local sort = table.sort
local stderr = io.stderr
local table = table
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

local HTTPD = Server.module("tek.class.httpd", "tek.class.server")
HTTPD._VERSION = "httpd 2.2"


local function readonly(t)
	return setmetatable(t, { __newindex = function() 
		error("globals are forbidden - the environment is read-only") 
	end })
end

-------------------------------------------------------------------------------
--	new
-------------------------------------------------------------------------------

function HTTPD.new(class, self)
	self = self or { }
	self.Address = self.Address or "localhost"
	self.ClientTimeout = self.ClientTimeout or 5
	self.DefaultIndex = self.DefaultIndex or
	{
		"index.lhtml",
		"index.lua",
		"index.html"
	}
	self.DirList = self.DirList == nil and "l" or self.DirList -- "l" = list
	self.DocumentRoot = self.DocumentRoot or "htdocs"
	self.ExtraWebEnvironment = self.ExtraWebEnvironment or { }
	self.Handlers = self.Handlers or
	{
		["%.lua"] = { },
		["%.lhtml"] = { parseluahtml = true },
	}
	self.IncludePath = self.IncludePath or "htinclude"
	self.Listen = self.Listen or false
	self.MIMEFileExts = self.MIMEFileExts or
	{ 
		txt = "text/plain",
		lua = "text/plain",
		c = "text/plain",
		h = "text/plain",
		html = "text/html",
		js = "application/javascript",
		css = "text/css",
		png = "image/png",
		gif = "image/gif",
	}
	self.MIMEFileNames = self.MIMEFileNames or
	{ 
		readme = "text/plain",
		copying = "text/plain",
		install = "text/plain",
		license = "text/plain",
	}
	self.Port = self.Port or 8080
	self.RequestArgs = self.RequestArgs or { }
	self.RequestClassName = self.RequestClassName or "tek.class.httprequest"
	self.RequestId = 0
	self.ServerName = self.ServerName or "server-http"
	self.ServerSocket = false
	self.WebEnvironment = self.WebEnvironment or
	{ 
		abs = math.abs,
		assert = assert,
		concat = table.concat,
		date = os.date,
		db = readonly { warn = db.error, db.warn, note = db.note,
			info = db.info, dump = db.dump },
		error = error,
		floor = math.floor,
-- 		gettime = socket.gettime,
		insert = table.insert,
-- 		loadstring = loadstring,
		pairs = pairs,
		remove = table.remove,
		select = select,
		sort = table.sort,
		stderr = stderr,
		time = os.time,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
	}

	-- request arguments:		
	local reqargs = self.RequestArgs
	reqargs.CookieName = reqargs.CookieName or "luawtf"
	reqargs.RequestsGlobal = reqargs.RequestsGlobal or { }
	reqargs.Sessions = reqargs.Sessions or { }
		
	-- mix in extra environment:
	for key, val in pairs(self.ExtraWebEnvironment) do
		self.WebEnvironment[key] = val
	end
	-- make web environment readonly:
	self.WebEnvironment = readonly(self.WebEnvironment)
	
	if not self.DocumentRoot:match("^/") then
		self.DocumentRoot = lfs.currentdir() .. "/".. self.DocumentRoot
	end

	if self.Listen then
		local addr, port = self.Listen:match("^(.*):(.*)$")
		if addr then
			self.Address = addr
			self.Port = port
		end
	end
	
	return Server.new(class, self)
end

-------------------------------------------------------------------------------
--	success = HTTPD:bind(): Bind server to {{Address}} and {{Port}}.
-------------------------------------------------------------------------------

function HTTPD:bind()
	db.info("bind to %s:%s", self.Address, self.Port)
	local fd
	if self.Port then
		fd = socket.tcp()
		fd:setoption("reuseaddr", true)
	else
		fd = socket.unix()
		os_remove(self.Address)
	end
	assert(fd:bind(self.Address, self.Port))
	assert(fd:listen())
	self.ServerSocket = fd
	
	self:registerServer(self.ServerSocket, self.ServerName,
		self.serveClient, self)
	
	return fd
end

-------------------------------------------------------------------------------
--	HTTPD:unbind(): Unbinds server, frees server socket.
-------------------------------------------------------------------------------

function HTTPD:unbind()
	if self.ServerSocket then
		self:unregister(self.ServerName)
		self.ServerSocket:close()
		self.ServerSocket = false
	end
end

-------------------------------------------------------------------------------
--	getDocumentRoot
-------------------------------------------------------------------------------

function HTTPD:getDocumentRoot()
	return self.DocumentRoot:match("^(.*)/?$") or ""
end

-------------------------------------------------------------------------------
--	sendResult(fd, code, msg, contenttype, content): Send result
-------------------------------------------------------------------------------

function HTTPD:sendResult(fd, code, msg, ctype, c)
	fd:send("HTTP/1.1 " .. code .. " " .. msg .. "\r\n")
	if ctype then
		fd:send("Content-Type: " .. ctype .. "\r\n")
	end
	if c then
		fd:send("Content-Length: " .. c:len() .. "\r\n\r\n")
		fd:send(c)
	end
end

-------------------------------------------------------------------------------
--	docToRealPath
-------------------------------------------------------------------------------

function HTTPD:docToRealPath(vpath)
	local res = vpath and self:getDocumentRoot() .. vpath
	return res
end

-------------------------------------------------------------------------------
--	success = doFileRequest(fd, req)
-------------------------------------------------------------------------------

function HTTPD:getDirIterator(vpath)
	local path = self:docToRealPath(vpath)
	local success, dir, iter = pcall(lfs.dir, path)
	if success then
		return function()
			local e
			repeat
				e = dir(iter)
			until e ~= "." and e ~= ".."
			return e
		end
	end
end

function HTTPD:send403(fd, req)
	self:sendResult(fd, 403, "Forbidden", "text/plain", "403: Forbidden")
	self:logRequest(fd, req, "403")
	return false -- break
end

function HTTPD:send404(fd, req)
	self:sendResult(fd, 404, "Not found", "text/plain", "404: Not found")
	self:logRequest(fd, req, "404")
	return false -- break
end

function HTTPD:doFileRequest(fd, req)
	local ctype = "text/html"
	
	local uri = req.uri:match("^([^?]*)%?(.*)$") or req.uri
	uri = uri:match("^(.-)/?$") or uri
	
	local fname = self:docToRealPath(uri)
	local mode = attributes(fname, "mode")
	if mode == "directory" then
		if not self.DirList then
			return self:send403(fd, req)
		end
		local di = self:getDirIterator(uri)
		if not di then
			return self:send403(fd, req)
		end
		local c = { }
		for entry in di do
			local fname = self:docToRealPath(uri .. "/" .. entry)
			local linkpath = uri == "/" and entry or 
				uri .. "/" .. entry
			if attributes(fname, "mode") == "directory" then
				insert(c, '<a href="' .. linkpath .. '">' .. entry .. 
					'/</a><br />\n')
			else
				insert(c, '<a href="' .. linkpath .. '">' .. entry .. 
					'</a><br />\n')
			end
		end
		sort(c)
		insert(c, 1, "Directory listing<hr />\n")
		insert(c, 1, "<html><body>")
		insert(c, "</body></html>")
		self:sendResult(fd, 200, "OK", ctype, concat(c))
		self:logRequest(fd, req, "200")
		return req.proto ~= "HTTP/1.0" -- continue if >= HTTP/1.1
		
	elseif mode == "file" then
		local fsize = attributes(fname, "size")
		local f = fsize and open(fname)
		if f then
			ctype = "application/octet-stream"
			local lfname = fname:lower()
			if self.MIMEFileNames[lfname] then
				ctype = self.MIMEFileNames[lfname]
			else
				local ext = lfname:match("%.([^.]+)$")
				if ext then
					if self.MIMEFileExts[ext] then
						ctype = self.MIMEFileExts[ext]
					end
				end
			end
			self:sendResult(fd, 200, "OK", ctype)
			fd:send("Content-Length: " .. fsize .. "\r\n\r\n")
			while true do
				local buf = f:read(16384)
				if not buf then
					break
				end
				fd:send(buf)
			end
			f:close()
			self:logRequest(fd, req, "200")
			return req.proto ~= "HTTP/1.0" -- continue if >= HTTP/1.1
		end
		return self:send403(fd, req)
	end
	return self:send404(fd, req)
end

-------------------------------------------------------------------------------
--	success = doHandler(fd, req, handler, hnd_name)
-------------------------------------------------------------------------------

function HTTPD:doHandler(fd, req, handler, hnd_name)
	local orgreq = req
	local chunked = req.proto ~= "HTTP/1.0"
	local httpd = self
	local reqclass = require(self.RequestClassName)
	local addr, port = fd:getpeername()
	local reqid = self.RequestId
	self.RequestId = self.RequestId + 1
	CGI:new {
		read = function(self, nbytes)
			return fd:receive(nbytes)
		end,
		newRequest = function(self)
			local h = chunked and "Transfer-encoding: chunked\r\n" or ""
			local reqinit = {
				write = function(self, s)
					if h then -- headers not yet sent
						h = h .. s
						local head, rest = h:match("^(.-)\r\n\r\n(.*)$")
						if head then
							local status = head:match("Status:%s*(.-)\r\n") or 
								"200 OK"
							if not fd:send("HTTP/1.1 " .. status .. "\r\n" .. 
								head .. "\r\n\r\n") then
								return false
							end
							h = false
							s = rest
						else
							return true
						end
					end
					if chunked then
						local len = s:len()
						if len == 0 then
							return true
						end
						return fd:send(("%x\r\n"):format(len) .. s .. "\r\n")
					end
					return fd:send(s)
				end,
				Environment = {
					CONTENT_LENGTH = req.headers["Content-Length"],
					CONTENT_TYPE = req.headers["Content-Type"],
					DOCUMENT_ROOT = httpd.DocumentRoot,
					GATEWAY_INTERFACE = "CGI/1.1",
					HTTP_ACCEPT = req.headers.Accept,
					HTTP_ACCEPT_CHARSET = req.headers["Accept-Charset"],
					HTTP_ACCEPT_ENCODING = req.headers["Accept-Encoding"],
					HTTP_ACCEPT_LANGUAGE = req.headers["Accept-Language"],
					HTTP_CONNECTION = req.headers.Connection,
					HTTP_COOKIE = req.headers.Cookie,
					HTTP_HOST = req.headers.Host,
					HTTP_REFERER = req.headers.Referer,
					HTTP_USER_AGENT = req.headers["User-Agent"],
					PATH_INFO = req.pathinfo,
					PATH_TRANSLATED = req.pathtranslated,
					QUERY_STRING = req.querystring,
					REMOTE_ADDR = addr,
					REMOTE_PORT = port,
					REQUEST_METHOD = req.method,
					REQUEST_URI = req.uri,
					SCRIPT_FILENAME = req.scriptfilename,
					SCRIPT_NAME = req.scriptname,
				},
				newSession = function(self, sessiondata, skey)
					local skey = reqclass.newSession(self, sessiondata, skey)
					db.warn("webrequest(%08x:%s) new session", reqid, skey)
					return skey
				end,
			}
			-- mix in request arguments:
			for key, val in pairs(httpd.RequestArgs) do
				reqinit[key] = val
			end
			return reqclass:new(reqinit)
		end,
		doRequest = function(self, req)
			local t0 = socket.gettime()
			db.info("webrequest(%08x) from %s:%s", reqid, addr, port)
			WTF:new { 
				Environment = httpd.WebEnvironment,
				IncludePath = httpd.IncludePath,
				ParseLuaHTML = handler.parseluahtml,
			}:doRequest(req)
			if chunked then
				fd:send("0\r\n\r\n")
			end
			httpd:logRequest(fd, orgreq, "200")
			local t1 = socket.gettime()
			db.info("webrequest(%08x:%s) complete, took %.3fs",
				reqid, req.SessionKey or "<nosession>", t1 - t0)
		end
	}:serve()
	return chunked -- continue if transfer was chunked
end

-------------------------------------------------------------------------------
--	logRequest(req, msg)
-------------------------------------------------------------------------------

function HTTPD:logRequest(fd, req, msg)
	local addr, port = fd:getpeername()
	db.warn("%s %s %s %s %s %s %s", fd, req.headers.Host, req.method,
		req.proto, req.uri, msg, addr, req.headers.Referrer)
end

-------------------------------------------------------------------------------
--	serveClient(fd) - This function serves an incoming client request on the
--	specified socket.
-------------------------------------------------------------------------------

function HTTPD:serveClient(fd)
	while self:serveRequest(fd) and self.copas do
		-- continue using connection (needs copas for asynchronoucy)
	end
	return true -- close
end

function HTTPD:serveRequest(fd)
	
	db.trace("serve client")
	if self.ClientTimeout then
		fd:settimeout(self.ClientTimeout)
	end
	
	local req = { headers = { } }
	
	local cmd, msg = fd:receive("*l")
	if not cmd then
		return false -- break
	end
	
	req.method, req.uri, req.proto = cmd:match("^(.+) (.+) (.+)$")
	if not req.method then
		return false -- break
	end
	
	while true do
		local line, msg = fd:receive("*l")
		if line == "" then
			break
		end
		local hkey, hval = line:match("^([%a-_]+)%s*%:%s*(.*)%s*$")
		if not hkey then
			db.warn("unrecognized header line")
			return false -- break
		end
-- 		db.warn("header: %s = %s", hkey, hval)
		req.headers[hkey] = hval
		insert(req.headers, hkey)
	end

	local handler, hnd_name, scriptpath, scriptname, fname, 
		pathinfo, fmode
	
	local uri, querystring = req.uri:match("^([^?]*)%?(.*)$")
	if not uri then
		uri = req.uri
	end
	for trynum = 1, 2 do
		for hnd_match, rec in pairs(self.Handlers) do
			scriptpath, scriptname, pathinfo = uri:match(
				"^(.-)(/[^/]*" .. hnd_match .. ")%f[%A](/?[^?]*)$")
			if scriptpath then
				handler = rec
				hnd_name = handler.name or hnd_match
				fname = scriptpath .. scriptname
				break
			end
		end
		fname = self:docToRealPath(fname or uri)
		if fname then
			fmode = attributes(fname, "mode")
		end
		if handler or fmode == "file" or trynum == 2 then
			break
		end
		local idxfound
		for i = 1, #self.DefaultIndex do
			local idxname = self.DefaultIndex[i]
			local fullname = fname .. "/" .. idxname
			if attributes(fullname, "mode") == "file" then
				if uri:match("/$") then
					uri = uri .. idxname
				else
					uri = uri .. "/" .. idxname
				end
				idxfound = true
				fname = nil
				break
			end
		end
		if not idxfound then
			break
		end
	end

	if handler and fmode == "file" then
		req.pathinfo = pathinfo
		req.scriptfilename = fname
		req.pathtranslated = self.DocumentRoot .. scriptpath .. pathinfo
		req.scriptname = scriptpath .. scriptname
		req.querystring = querystring
		return self:doHandler(fd, req, handler, hnd_name)
	elseif fmode then
		return self:doFileRequest(fd, req)
	end
	
	return self:send404(fd, req)
end

-------------------------------------------------------------------------------
--	run()
-------------------------------------------------------------------------------

function HTTPD:run()
	self:bind()
	local res = Server.run(self)
	self:unbind()
	return res
end

return HTTPD
