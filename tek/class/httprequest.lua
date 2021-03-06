-------------------------------------------------------------------------------
--
--	tek.class.httprequest
--	(C) by Timm S. Mueller <tmueller@schulze-mueller.de>
--
--	OVERVIEW::
--		[[#ClassOverview]] :
--		[[#tek.class : Class]] /
--		HTTPRequest ${subclasses(HTTPRequest)}
--
--	MEMBERS::
--		- {{Environment [ISG]}} (table)
--			Initial environment of server variables
--		- {{MaxContentLength [ISG]}} (number)
--			Maximum size allowed for POST, in bytes. Default: 1000000
--		- {{RequestsGlobal [ISG]}} (table)
--			Global variables shared by all requests
--
--	IMPLEMENTS::
--		- HTTPRequest.decodeURL() - Decodes an URL-encoded string
--		- HTTPRequest:getArgs() - Gets table of request arguments
--		- HTTPRequest:getDocument() - Gets table of document properties
--		- HTTPRequest:getEnv() - Gets a server environment variable
--		- HTTPRequest:getGlobal() - Gets persistent, global data from server
--		- HTTPRequest:insertArgString() - Insert QUERY_STRING arguments
--		- HTTPRequest:write(s) - Sets an server environment variable
--
--	OVERRIDES::
--		- Class.new()
--
-------------------------------------------------------------------------------

local lfs = require "lfs"
local Class = require "tek.class"
local assert = assert
local char = string.char
local error = error
local getenv = os.getenv
local insert = table.insert
local pairs = pairs
local setmetatable = setmetatable
local stat = lfs.attributes -- stat
local stdout = io.stdout
local tonumber = tonumber
local type = type

local HTTPRequest = Class.module("tek.class.httprequest", "tek.class")
HTTPRequest._VERSION = "HTTPRequest 3.1"


local DEF_MAX_CONTENT_LENGTH = 1000000

local function readonly(t)
	return setmetatable(t, { __newindex = function() 
		error("request globals are read-only") 
	end })
end

-------------------------------------------------------------------------------
--	decoded = decodeURL(url): Decode URL-encoded string
-------------------------------------------------------------------------------

local function f_hexdec(h)
	return char(tonumber(h, 16))
end

function HTTPRequest.decodeURL(url)
	return (url:gsub("+", " ")):gsub("%%(%x%x)", f_hexdec):gsub("\r\n", "\n")
end

-------------------------------------------------------------------------------
--	table = decodeArgs(argstring, table)
-------------------------------------------------------------------------------

function HTTPRequest.decodeArgs(s, args)
	s:gsub("([^&=]+)=([^&=]+)", function(key, value)
		value = HTTPRequest.decodeURL(value)
		local oldval = args[key]
		if oldval == nil then
			args[key] = value
		elseif type(oldval) ~= "table" then
			args[key] = { oldval, value }
		else
			insert(args[key], value)
		end
	end)
	return args
end

-------------------------------------------------------------------------------
--	new: overrides
-------------------------------------------------------------------------------

function HTTPRequest.new(class, self)
	self = self or { }
	self.Args = false
-- 	self.DefaultIndex = self.DefaultIndex or "index.html index.lua"
	self.Document = false
	self.Environment = self.Environment or { }
	self.MaxContentLength = self.MaxContentLength or DEF_MAX_CONTENT_LENGTH
	self.RequestsGlobal = self.RequestsGlobal or readonly { }
	self.write = self.write or class.write
	self = Class.new(class, self)
	setmetatable(self.Environment, {
		__index = function(tab, key)
			local val = self:getHTTPVariable(key)
			tab[key] = val
			return val
		end
	})
	return self
end

-------------------------------------------------------------------------------
--	val = getHTTPVariable(key) - Retrieve server variable from the outside
-------------------------------------------------------------------------------

function HTTPRequest:getHTTPVariable(key)
	return getenv(key)
end

-------------------------------------------------------------------------------
--	write(s): Write data to output stream
-------------------------------------------------------------------------------

function HTTPRequest:write(s)
	return stdout:write(s)
end

-------------------------------------------------------------------------------
--	val = getEnv(key): Get server environment variable
-------------------------------------------------------------------------------

function HTTPRequest:getEnv(key)
	return self.Environment[key]
end

-------------------------------------------------------------------------------
--	setEnv(key, val) - Set an environment (server) variable
-------------------------------------------------------------------------------
--
-- function HTTPRequest:setEnv(key, val)
-- 	if key == "PATH_TRANSLATED" then
-- 		if stat(val, "mode") ~= "file" then
-- 			-- emulate default index file:
-- 			for ext in self.DefaultIndex:gmatch("(%S+)%s?") do
-- 				local fname = val .. "/" .. ext
-- 				if stat(fname, "mode") == "file" then
-- 					val = fname
-- 					break
-- 				end
-- 			end
-- 		end
-- 	end
-- 	self.Environment[key] = val
-- end

-------------------------------------------------------------------------------
--	args = getArgs(): Get table of request arguments
-------------------------------------------------------------------------------

function HTTPRequest:getArgs()
	if not self.Args then
		assert(self:getEnv("REQUEST_METHOD") == "GET")
		self:insertArgString(self:getEnv("QUERY_STRING") or "")
	end
	return self.Args
end

-------------------------------------------------------------------------------
--	insertArgString(string): Insert raw arguments string, e.g. from
--	{{QUERY_STRING}}
-------------------------------------------------------------------------------

function HTTPRequest:insertArgString(s)
	self.Args = HTTPRequest.decodeArgs(s, { })
end

-------------------------------------------------------------------------------
--	document = getDocument(): Get table of document properties, containing
--	e.g. the keys ScriptPath and ScriptFile
-------------------------------------------------------------------------------

function HTTPRequest:getDocument()
	local doc = self.Document
	if not doc then
		doc = { }
		local filename = self:getEnv("PATH_TRANSLATED")
		for i = 1, 2 do
			local found
			while filename and filename ~= "" do
				found = stat(filename, "mode") == "file"
				if found then
					break
				end
				filename = filename:match("^(.*)/[^/]*$")
			end
			if found then
				doc.ScriptPath, doc.ScriptFile =
					filename:match("^(.-/?)([^/]*)$")
				break
			end
			filename = self:getEnv("SCRIPT_FILENAME")
		end
		self.Document = doc
	end
	return doc
end

-------------------------------------------------------------------------------
--	global = getGlobal(): Get HTTP Request global state, containing e.g.
--	internals of the server application.
-------------------------------------------------------------------------------

function HTTPRequest:getGlobal()
	return self.RequestsGlobal
end

return HTTPRequest
