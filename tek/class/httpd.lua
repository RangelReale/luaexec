-------------------------------------------------------------------------------
--
--	tek.class.httpd
--	Written and (C) by Timm S. Mueller <tmueller@schulze-mueller.de>
--
-------------------------------------------------------------------------------

local db = require "tek.lib.debug"
local _, lfs = pcall(require, "lfs")
local Server = require "tek.class.server"
local socket = require "socket"
local WebRequest = require "tek.class.httprequest"
local CGI = require "tek.class.cgi"
local WTF = require "tek.class.wtf"
pcall(require, "copas")

local assert = assert
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

-------------------------------------------------------------------------------
--	Module header
-------------------------------------------------------------------------------

module("tek.class.httpd", tek.class.server)
local HTTPD = _M
_VERSION = "httpd 1.0"
Server:newClass(HTTPD)

local function readonly(t)
	return setmetatable(t, { __newindex = function() error("read-only") end })
end

-------------------------------------------------------------------------------
--	new
-------------------------------------------------------------------------------

function HTTPD.new(class, self)
	
	self = self or { }
	
	self.Address = self.Address or "127.0.0.1"
	self.ClientTimeout = self.ClientTimeout or false -- 5
	self.DocumentRoot = self.DocumentRoot or "htdocs"
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
	}
	self.MIMEFileNames = self.MIMEFileNames or
	{ 
		readme = "text/plain",
		copying = "text/plain",
		install = "text/plain",
		license = "text/plain",
	}
	self.Handlers = self.Handlers or
	{
		["%.lua"] = { },
		["%.lhtml"] = { },
	}
	self.Listen = self.Listen or false
	self.Port = self.Port or 8080
	self.RequestId = 0
	self.ServerName = self.ServerName or "server-http"
	self.ServerSocket = false
	self.WebData = { State = { Server = self } }
	self.WebEnvironment = readonly 
	{ 
		abs = math.abs,
		assert = assert,
		concat = table.concat,
		date = os.date,
		db = readonly { warn = db.error, db.warn, note = db.note,
			info = db.info, dump = db.dump },
		error = error,
		floor = math.floor,
		insert = table.insert,
		loadstring = loadstring,
		pairs = pairs,
		print = function(...)
			for i = 1, select('#', ...) do
				stderr:write((i > 1 and "\t" or "") .. 
					tostring(select(i, ...)))
			end
			stderr:write("\n") 
		end,
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
--	success = HTTPD:bind()
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
	return fd
end

-------------------------------------------------------------------------------
--	HTTPD:unbind()
-------------------------------------------------------------------------------

function HTTPD:unbind()
	if self.ServerSocket then
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
--	docToRealPath
-------------------------------------------------------------------------------

function HTTPD:docToRealPath(vpath)
	local path = self:getDocumentRoot() .. vpath
	return path
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

function HTTPD:doFileRequest(fd, req)
	local ctype = "text/html"
	local c = { }
	local fname = self:docToRealPath(req.uri)
	if lfs.attributes(fname, "mode") == "directory" then
		local di = self:getDirIterator(req.uri)
		if di then
			for entry in di do
				local fname = self:docToRealPath(req.uri .. "/" .. entry)
				local linkpath = req.uri == "/" and entry or 
					req.uri .. "/" .. entry
				if lfs.attributes(fname, "mode") == "directory" then
					insert(c, '<a href="' .. linkpath .. '">' .. entry .. 
						'/</a><br />\n')
				else
					insert(c, '<a href="' .. linkpath .. '">' .. entry .. 
						'</a><br />\n')
				end
			end
		end
		sort(c)
		insert(c, 1, "Directory listing</br>\n")
		insert(c, 1, "<html><body>")
		insert(c, "</body></html>")
	elseif lfs.attributes(fname, "mode") == "file" then
		local f = open(fname)
		if f then
			insert(c, f:read("*a"))
			f:close()
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
		end
	end
	c = concat(c)
	return self:sendResult(fd, c, ctype)
end

function HTTPD:sendResult(fd, c, ctype)
	fd:send("HTTP/1.1 200 OK\n")
	fd:send("Content-Length: " .. c:len() .. "\n")
	fd:send("Content-Type: "..ctype.."\n\n")
	fd:send(c)
	return true
end

-------------------------------------------------------------------------------
--	success = doHandler(fd, req, handler, hnd_name)
-------------------------------------------------------------------------------

function HTTPD:doHandler(fd, req, handler, hnd_name)
	local httpd = self
	local webenv = self.WebEnvironment
	local webdata = self.WebData
	local addr, port = fd:getpeername()
	local reqid = self.RequestId
	self.RequestId = self.RequestId + 1
	CGI:new {
		read = function(self, nbytes)
			return fd:receive(nbytes)
		end,
		newRequest = function(self)
			return WebRequest:new {
				ResponseHeaders = "",
				write = function(self, s)
					local h = self.ResponseHeaders
					if h then
						h = h .. s
						if h:match("\r\n\r\n") then
							self.ResponseHeaders = false
							local status = h:match("Status:%s*(.-)\r\n") or 
								"200 OK"
-- 							stderr:write("HTTP/1.1 " .. status .. "\r\n")
-- 							stderr:write(h)
							fd:send("HTTP/1.1 " .. status .. "\r\n")
							return fd:send(h)
						end
					end
-- 					stderr:write(s)
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
				Database = webdata,
				newSession = function(self, sessiondata, skey)
					local skey = WebRequest.newSession(self, sessiondata, skey)
					db.warn("webrequest(%08x:%s) new session", reqid, skey)
					return skey
				end,
			}
		end,
		doRequest = function(self, req)
			local t0 = socket.gettime()
			db.info("webrequest(%08x) from %s:%s", reqid, addr, port)
			WTF:new { Environment = webenv }:doRequest(req)
			local t1 = socket.gettime()
			db.info("webrequest(%08x:%s) complete, took %.3fs",
				reqid, "<nosession>", t1 - t0)
		end
	}:serve()
	return true
end

-------------------------------------------------------------------------------
--	serveClient(fd) - This function serves an incoming client request on the
--	specified socket.
-------------------------------------------------------------------------------

function HTTPD:serveClient(fd)
	
	db.trace("serve client")
	if self.ClientTimeout then
		fd:settimeout(self.ClientTimeout)
	end
	
	local req = { headers = { } }
	
	local cmd, msg = fd:receive("*l")
	if not cmd then
		return false
	end
	
	req.method, req.uri, req.proto = cmd:match("^(.+) (.+) (.+)$")
	if not req.method then
		return false
	end
	
	while true do
		local line, msg = fd:receive("*l")
		if line == "" then
			break
		end
		local hkey, hval = line:match("^([%a-_]+)%s*%:%s*(.*)%s*$")
		if not hkey then
			db.warn("unrecognized header line")
			return false
		end
-- 		db.warn("header: %s = %s", hkey, hval)
		req.headers[hkey] = hval
		insert(req.headers, hkey)
	end
	
	local handler, hnd_name, scriptpath, scriptname, fname, 
		pathinfo, querystring
	for hnd_match, rec in pairs(self.Handlers) do
		scriptpath, scriptname, pathinfo, querystring = req.uri:match(
			"^(.-)(/[^/]*" .. hnd_match .. ")%f[%A](/?[^?]*)%??(.*)$")
		if scriptpath then
			handler = rec
			hnd_name = handler.name or hnd_match
			fname = scriptpath .. scriptname
			break
		end
	end
	
	fname = self:docToRealPath(fname or req.uri)
	local fmode = lfs.attributes(fname, "mode")
		
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
	
	self:sendResult(fd, "No such file or directory: " .. req.uri, "text/plain")
	return true
end

-------------------------------------------------------------------------------
--	run()
-------------------------------------------------------------------------------

function HTTPD:run()
	self:bind()
	self:registerServer(self.ServerSocket, self.ServerName,
		self.serveClient, self)
	local res = Server.run(self)
	self:unbind()
	return res
end
