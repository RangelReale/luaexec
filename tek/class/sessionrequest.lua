-------------------------------------------------------------------------------
--
--	tek.class.sessionrequest
--	(C) by Timm S. Mueller <tmueller@schulze-mueller.de>
--
--	OVERVIEW::
--		[[#ClassOverview]] :
--		[[#tek.class : Class]] /
--		[[#tek.class.httprequest : HTTPRequest]] /
--		SessionRequest ${subclasses(SessionRequest)}
--
--	MEMBERS::
--		- {{CookieName [ISG]}} (string)
--			Default basename for cookies, default {{"luawtf"}}
--		- {{SessionExpirationTime [ISG]}} (number)
--			Number of seconds before a session expires, default: 600
--		- {{Sessions [ISG]}} (table)
--			Table of sessions, indexed by session Id. Must be provided during
--			initialization so that session states can be held and found later 
--
--	IMPLEMENTS::
--		- SessionRequest.getRawId() - Get binary data for unique session Id
--		- SessionRequest:createSessionCookie() - Create session cookie string
--		- SessionRequest:deleteSession() - Delete current session
--		- SessionRequest:getSession() - Find session (by session Id in cookie)
--		- SessionRequest:newSession() - Create new session
--		
--	OVERRIDES::
--		- Class.new()
--
-------------------------------------------------------------------------------

local db = require "tek.lib.debug"
local HTTPRequest = require "tek.class.httprequest"
local os_time = os.time
local assert = assert
local open = io.open
local pairs = pairs
local stderr = io.stderr

local SessionRequest = HTTPRequest.module("tek.class.sessionrequest", "tek.class.httprequest")
SessionRequest._VERSION = "SessionRequest 3.0"

-------------------------------------------------------------------------------
--	getRawId([len[, rlen]]): Get unique binary data of given length to be
--	used for a session Id. {{rlen}} is the desired number of bytes of entropy,
--	the regular length (default 6) is usually made up of pseudo random data.
-------------------------------------------------------------------------------

function SessionRequest.getRawId(len, rlen)
	local token = ""
	if rlen and rlen > 0 then
		local f = open("/dev/random", "rb")
		if f then
			token = f:read(rlen)
			f:close()
		end
	end
	local f = open("/dev/urandom", "rb")
	if f then
		token = token .. f:read(len or 6)
		f:close()
	else
		db.warn("** cannot get entropy - using extremely weak random number!")
		token = token .. math.floor(math.random() * 100000000)
	end
	return token
end

-------------------------------------------------------------------------------
--	getId()
-------------------------------------------------------------------------------

function SessionRequest.getId(len, rlen)
	local token = SessionRequest.getRawId(len, rlen)
	return token:gsub('.', function(c) return ("%02x"):format(c:byte()) end)
end

-------------------------------------------------------------------------------
--	new: overrides
-------------------------------------------------------------------------------

function SessionRequest.new(class, self)
	self = self or { }
	self.CookieName = self.CookieName or "luawtf"
	self.Prefix = self.Prefix or ""
	self.Session = false
	self.Sessions = self.Sessions or { }
	self.SessionKey = false
	self.SessionExpirationTime = self.SessionExpirationTime or 600
	return HTTPRequest.new(class, self)
end

-------------------------------------------------------------------------------
--	skey = getSessionKey()
-------------------------------------------------------------------------------

function SessionRequest:getSessionKey()
	local skey = self.SessionKey
	if not skey then
		local cookie = self:getEnv("HTTP_COOKIE")
		skey = cookie and 
			cookie:match(self.CookieName .. "_session=(%x+);?") or false
		self.SessionKey = skey
	end
	db.trace("getsessionkey: %s", skey)
	return skey
end

-------------------------------------------------------------------------------
--	cookie = createSessionCookie([expire]): Create session cookie string
-------------------------------------------------------------------------------

function SessionRequest:createSessionCookie(expires)
	local prefix = self.Prefix
	local prefix = prefix == "" and "/" or prefix
	local cookie
	if expires then
		cookie = ('Set-Cookie: %s_session=%s; Path=%s; Expires=%s; Version=1\r\n'):
			format(self.CookieName, (self.SessionKey or "disabled"), prefix, 
				expires)
	else
		cookie = ('Set-Cookie: %s_session=%s; Path=%s; Version=1\r\n'):format(
			self.CookieName, (self.SessionKey or "disabled"), prefix)
	end
	return cookie
end

-------------------------------------------------------------------------------
--	expireSessions()
-------------------------------------------------------------------------------

function SessionRequest:expireSessions()
	local nowtime = os_time()
	local sessions = self.Sessions
	for skey, session in pairs(sessions) do
		if session.expirydate and nowtime > session.expirydate then
			db.info("session %s expired", skey)
			sessions[skey] = nil
		end
	end
end

-------------------------------------------------------------------------------
--	session, sid = getSession(): Find session by session Id in cookie
-------------------------------------------------------------------------------

function SessionRequest:getSession()
	self:expireSessions()
	local skey = self:getSessionKey()
	local session = self.Session
	if not session then
		local sessions = self.Sessions
		if skey then
			session = sessions[skey]
		end
		if session then
			sessions[skey].expirydate = os_time() + self.SessionExpirationTime
		end
		session = session or false
		self.Session = session
	end
	return session, skey
end

-------------------------------------------------------------------------------
--	sid = newSession(sessiondata[, sid]): Place {{sessiondata}} table in a new
--	session
-------------------------------------------------------------------------------

function SessionRequest:newSession(sessiondata, skey)
	if not skey or self.Sessions[skey] then
		-- do not bind to an already existing session!
		skey = self.getId()
	end
	local sessions = self.Sessions
	sessions[skey] = sessiondata
	self.Session = sessiondata
	self.SessionKey = skey
	return skey
end

-------------------------------------------------------------------------------
--	updateSession(sessiondata)
-------------------------------------------------------------------------------

function SessionRequest:updateSession(sessiondata)
	sessiondata = sessiondata or { }
	local skey = self:getSessionKey()
	self.Session = sessiondata
	local sessions = self.Sessions
	sessions[skey] = sessiondata
end

-------------------------------------------------------------------------------
--	deleteSession(): Delete the current session
-------------------------------------------------------------------------------

function SessionRequest:deleteSession()
	local skey = self:getSessionKey()
	if skey then
		self.Sessions[skey] = nil
	end
	self.SessionKey = false
	self.Session = false
end

return SessionRequest
