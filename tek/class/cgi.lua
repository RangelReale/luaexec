-------------------------------------------------------------------------------
--
--	tek.class.cgi
--	(C) by Timm S. Mueller <tmueller@schulze-mueller.de>
--
--	OVERVIEW::
--		[[#ClassOverview]] :
--		[[#tek.class : Class]] /
--		CGI ${subclasses(CGI)}
--
--	IMPLEMENTS::
--		- CGI:beginPost()
--		- CGI:beginUpload()
--		- CGI:doRequest()
--		- CGI:endPost()
--		- CGI:endRequest()
--		- CGI:endUpload()
--		- CGI:haveParams()
--		- CGI:updatePost()
--		- CGI:updateUpload()
--
--	OVERRIDES::
--		- Class.new()
--
-------------------------------------------------------------------------------

local db = require "tek.lib.debug"
local FIFO = require "tek.class.fifo"
local Class = require "tek.class"
local assert = assert
local min = math.min
local require = require
local stdin = io.stdin
local tmpfile = io.tmpfile
local tonumber = tonumber

local CGI = Class.module("tek.class.cgi", "tek.class")
CGI._VERSION = "CGI 5.2"

-------------------------------------------------------------------------------
-- CGI class:
-------------------------------------------------------------------------------

function CGI.new(class, self)
	self = self or { }
	-- FIFO buffering current multipart POST argument:
	self.ArgBuffer = false
	-- Filehandle receiving the current POST file upload:
	self.ArgFD = false
	-- Name of the current file upload:
	self.ArgFilename = false
	-- Name of the current argument:
	self.ArgName = false
	-- Table of multipart POST arguments:
	self.Arguments = false
	-- Boundary string:
	self.Boundary = false
	-- State of multipart POST parser:
	self.ParseState = false
	-- Current separator to match for in stream:
	self.Separator = false
	return Class.new(class, self)
end

-------------------------------------------------------------------------------
--	continue = beginPost(req): Signals that a POST request has begun.
--	Parameters are known, but data is yet to be read.
-------------------------------------------------------------------------------

function CGI:beginPost(req)
	local content_type = req:getEnv("CONTENT_TYPE")
	self.Boundary = content_type and content_type:match(
		"^multipart/form%-data;%s*boundary%s*=%s*(%-%-%S*)") or false
	if self.Boundary then
		self.ParseState = "separator"
		self.Separator = "--" .. self.Boundary .. "\r\n"
		self.Arguments = { }
	end
	return true
end

-------------------------------------------------------------------------------
--	doRequest(req): Function called when a request can be processed.
-------------------------------------------------------------------------------

function CGI:doRequest(req)
end

-------------------------------------------------------------------------------
--	continue = endPost(req, s): Signals that all data belonging to a POST
--	request have arrived.
-------------------------------------------------------------------------------

function CGI:endPost(req, s)
	if not self.ParseState then
		req:insertArgString(s:read("*a"))
	else
		req.Args = self.Arguments	
		self.Arguments = false	
	end
	self:doRequest(req)
	return self:endRequest(req)
end

-------------------------------------------------------------------------------
--	success, msg = endRequest(request[, protstatus[, appstatus]]):
--	Confirms the end of a CGI request. Optionally, the application can
--	signify a protocol status (e.g., FCGI_REQUEST_COMPLETE) and an
--	application status (by default, 0).
--	The result will be true, indicating success, or nil followed by an
--	error message.
-------------------------------------------------------------------------------

function CGI:endRequest(req, protstatus, appstatus)
	return true
end

-------------------------------------------------------------------------------
--	continue = haveParams(req):
--	Signals the arrival of all parameters that belong to the request. The
--	return value is a boolean indicating success and whether processing
--	should continue.
-------------------------------------------------------------------------------

function CGI:haveParams(req)
	local request_method = req:getEnv("REQUEST_METHOD")
	if request_method == "GET" then
		self:doRequest(req)
		self:endRequest(req)
		return false
	elseif request_method == "POST" then
		return self:beginPost(req)
	end
	return false -- unhandled request method, do not continue
end

-------------------------------------------------------------------------------
--	req = newRequest()
-------------------------------------------------------------------------------

function CGI:newRequest()
end

-------------------------------------------------------------------------------
--	data = read(bytes)
-------------------------------------------------------------------------------

function CGI:read(nbytes)
	return stdin:read(nbytes)
end

-------------------------------------------------------------------------------
--	serve()
-------------------------------------------------------------------------------

function CGI:serve()
	local req = self:newRequest()
	if self:haveParams(req) then
		if req:getEnv("REQUEST_METHOD") == "POST" then
			local len = tonumber(req:getEnv("CONTENT_LENGTH"))
			local fifo = FIFO:new()
			while len > 0 do
				local buf = self:read(min(len, 8192))
				if not buf then
					break
				end
				fifo:write(buf)
				self:updatePost(req, fifo)
				len = len - buf:len()
			end
			self:endPost(req, fifo)
		end
	end	
end

-------------------------------------------------------------------------------
--	fh = beginUpload(req, fname, argname): Begin upload
-------------------------------------------------------------------------------

function CGI:beginUpload(req, fname, argname)
	return tmpfile()
end

-------------------------------------------------------------------------------
--	success = updateUpload(req, fname, fh, buf): Update upload
-------------------------------------------------------------------------------

function CGI:updateUpload(req, fn, fh, buf)
	return fh:write(buf)
end

-------------------------------------------------------------------------------
--	is_valid = endUpload(req, fname, fh): Complete upload
-------------------------------------------------------------------------------

function CGI:endUpload(req, fn, fh)
	local pos, msg = fh:seek("cur")
	if pos and pos > 0 then
		self.Arguments[self.ArgName] = fh
		self.Arguments[self.ArgName .. "__filename"] = fn
		return true
	else
		fh:close()
	end
	if msg then
		db.warn("endupload: %s", msg)
	end
end

-------------------------------------------------------------------------------
--	continue = updatePost(req, s): Signals that new data is available on the
--	stream that belongs to a POST request. The return value indicates whether
--	processing should continue.
-------------------------------------------------------------------------------

function CGI:updatePost(req, s)
	local parse = self.ParseState
	if not parse then
		return true
	end
	local separator = self.Separator
	local buf, complete
	while true do
		if parse == "stream" then
			buf, complete = s:readpatlen(separator)
			if buf then
				if buf:len() > 0 then
					if self.ArgFD then
						self:updateUpload(req, self.ArgFilename, self.ArgFD, buf)
					else
						self.ArgBuffer:write(buf)
					end
				end
				if complete then
					separator = "\r\n"
					parse = "next"
					if self.ArgFD then
						self:endUpload(req, self.ArgFilename, self.ArgFD)
						self.ArgFD = false
					else
						local arg = self.ArgBuffer:read("*a")
						self.ArgBuffer = false
						self.Arguments[self.ArgName] = arg
					end
				end
			elseif not complete then
				break
			end
		elseif parse then
			buf = s:read(separator)
			if not buf then
				break
			end
			if parse == "separator" then
				separator = "\r\n"
				parse = "header"
			elseif parse == "header" then
				if buf == "" then
					parse = "stream"
					separator = "\r\n--" .. self.Boundary
				else
					if buf:match(
						'^[Cc]ontent%-[Dd]isposition:%s*form%-data;%s*') then
						local name = buf:match(';%s*name="(.-)"')
						if name then
							self.ArgName = name
							local filename = buf:match(';%s*filename="(.-)"')
							if filename then
								self.ArgFilename = filename
								self.ArgFD = self:beginUpload(req, filename, name)
								assert(self.ArgFD)
							else
								self.ArgBuffer = FIFO:new()
							end
						end
					end
				end
			elseif parse == "next" then
				parse = "header"
			end
		end
	end
	self.Separator = separator
	self.ParseState = parse
	return true
end

return CGI
