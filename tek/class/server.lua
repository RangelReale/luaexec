-------------------------------------------------------------------------------
--
--	tek.class.server
--	Written and (C) by Timm S. Mueller <tmueller at schulze-mueller.de>
--
--	OVERVIEW::
--		[[#ClassOverview]] :
--		[[#tek.class : Class]] /
--		Server ${subclasses(Server)}
--
--		This class implements a server.
--		If copas is used, this server provides nonblocking multiplexed I/O.
--
--	IMPLEMENTS::
--		- Server:registerClient() - Register a client socket
--		- Server:registerInterval() - Register an interval function
--		- Server:registerOnce() - Register a one-shot function
--		- Server:registerServer() - Register a server socket
--		- Server:removeInterval() - Remove an interval function
--		- Server:run() - Run server (mainloop)
--		- Server:setServerState() - Sets server state
--		- Server:shutdown() - Tries to shut down services, protected
--		- Server:startup() - Checks configuration and starts up services
--		- Server:unregister() - Unregisters a socket
--
--	OVERRIDES::
--		- Class.new()
--
-------------------------------------------------------------------------------

local db = require "tek.lib.debug"
local have_copas, copas = pcall(require, "copas")
local have_coxpcall, coxpcall = pcall(require, "coxpcall")
local Class = require "tek.class"
local socket = require "socket"

local assert = assert
local coroutine = coroutine
local error = error
local gettime = socket.gettime
local insert = table.insert
local min = math.min
local pairs = pairs
local pcall = have_coxpcall and coxpcall.pcall or pcall
local remove = table.remove
local tostring = tostring
local type = type
local unpack = unpack or table.unpack
local xpcall = have_coxpcall and coxpcall.xpcall or xpcall

local Server = Class.module("tek.class.server", "tek.class")
Server._VERSION = "Server 2.6"

if have_copas then
	copas.autoclose = false
	db.info("using copas")
else
	db.warn("not using copas")
end

Server.copas = have_copas and copas
Server.xpcall = xpcall
Server.pcall = pcall

local NO_TIMEOUT = 2000000000

-------------------------------------------------------------------------------
--	new
-------------------------------------------------------------------------------

function Server.new(class, self)
	self = self or { }
	self.Ids = self.Ids or { }
	self.Intervals = { }
	self.NextId = self.NextId or 1
	self.NumIds = 0
	self.RecvFDs = { } -- recv file descriptors, indexed numerically
	self.RegisteredFDs = { } -- records of registered recvfds, indexed by fd
	self.RegisteredNames = { } -- registered file descriptors, by name
	self.Status = "init"
	self = Class.new(class, self)
	self:registerInterval(1, self.checkAbort, self)
	return self
end

-------------------------------------------------------------------------------
--	checkAbort(): Override this function to check for termination of the
--	server. Since we cannot suspend in I/O and signals or messages at the
--	same time, we must check for termination periodically. A pity
-------------------------------------------------------------------------------

function Server:checkAbort()
end

-------------------------------------------------------------------------------
--	id = allocId()
-------------------------------------------------------------------------------

function Server:allocId()
	local nextid = self.NextId
	local ids = self.Ids
	local newid = nextid
	local numid = self.NumIds + 1
	ids[nextid] = true
	if nextid == numid then
		self.NumIds = numid
		self.NextId = numid + 1
	else
		for i = nextid + 1, numid do
			if ids[i] == nil then
				self.NextId = i
				break
			end
		end
	end
	return newid
end

-------------------------------------------------------------------------------
--	collectGarbage()
-------------------------------------------------------------------------------

function Server:collectGarbage()
end

-------------------------------------------------------------------------------
--	newtimeout = expireIntervals()
-------------------------------------------------------------------------------

function Server:expireIntervals()
	local ct = { } -- operate on copy:
	for id, record in pairs(self.Intervals) do
		ct[id] = record
	end
	local timeout = NO_TIMEOUT
	local t = gettime()
	for id, record in pairs(ct) do
		if t >= record.timeout then
			record.timeout = t + record.interval
			record.func(record.data, id)
		end
	end
	for id, record in pairs(self.Intervals) do
		timeout = min(timeout, record.timeout)
	end
	if timeout < NO_TIMEOUT then
		timeout = timeout - t -- make relative
		if timeout >= 0 then
			return timeout -- time to wait
		end
	end
end

-------------------------------------------------------------------------------
--	freeId(id)
-------------------------------------------------------------------------------

function Server:freeId(id)
	local numid = self.NumIds
	if type(id) == "number" and id > 0 and id <= numid then
		local nextid = self.NextId
		local ids = self.Ids
		ids[id] = nil
		if id == numid then
			for i = numid - 1, nextid + 1, -1 do
				if ids[i] ~= nil then
					break
				end
				numid = numid - 1
			end
			self.NumIds = numid
			self.NextId = min(numid, nextid)
		elseif id < nextid then
			self.NextId = id
		end
	end
end

-------------------------------------------------------------------------------
--	id = registerClient(fd, name, func[, data[, ...]]): Register client
-------------------------------------------------------------------------------

function Server:registerClient(fd, name, func, data, ...)
	return self:registerFD("client", fd, name, func, data, ...)
end

-------------------------------------------------------------------------------
--	success = registerFD(type, fd, name, func[, data[, ...]])
-------------------------------------------------------------------------------

function Server:registerFD(type, fd, name, func, data, ...)
	assert(fd)
	assert(func)
	local regfd = self.RegisteredFDs -- records, indexed by fd
	local recvfd = self.RecvFDs -- fds, indexed numerically
	local regnames = self.RegisteredNames -- fds, by name
	if regnames[name] then
		db.warn("'%s' already registered", name)
		return false
	end
-- 	assert(not regnames[name], name .. " already registered")
	assert(not regfd[fd])
	insert(recvfd, fd)
	local rec = { recvfunc = func, name = name, data = data or self,
		type = type, args = { ... } }
	regfd[fd] = rec
	regnames[name] = fd
	db.info("socket '%s' registered, num=%s", name, #recvfd)
	if have_copas then
		if type == "server" then
			copas.addserver(fd, function(fd)
				db.trace("enter server: %s", fd)
				local cfd = copas.wrap(fd)
				if func(data or self, cfd, name, unpack(rec.args)) then
					db.trace("return from server %s, closing socket", name)
					fd:close()
				else
					db.trace("return from server %s, not closing socket", name)
				end
			end)
		else
			copas.addthread(function()
				db.trace("enter client thread: %s", fd)
				fd:settimeout(0)
				local cfd = copas.wrap(fd)
				while regnames[name] do
					func(data or self, cfd, name, unpack(rec.args))
				end
				db.trace("return from client thread %s, closing socket", fd)
				fd:close()
			end)
		end
	end
	return true
end

-------------------------------------------------------------------------------
--	id = registerInterval(interval_in_seconds, func): Register interval
-------------------------------------------------------------------------------

function Server:registerInterval(interval, func, data)
	local id = self:allocId()
	self.Intervals[id] = { func = func, data = data or self,
		timeout = gettime() + interval, interval = interval }
	return id
end

-------------------------------------------------------------------------------
--	registerOnce(delay, func[, data]): Register a function to be called in the
--	server main loop once, after the given delay
-------------------------------------------------------------------------------

function Server:registerOnce(delay, func, data)
	local id = self:allocId()
	self.Intervals[id] = { 
		func = function(data, id)
			func(data)
			self:removeInterval(id)
		end, 
		data = data or self, timeout = gettime() + (delay or 0), interval = 1 }
	return id
end

-------------------------------------------------------------------------------
--	id = registerServer(fd, name, func[, data[, ...]]): Register server socket
-------------------------------------------------------------------------------

function Server:registerServer(fd, name, func, data, ...)
	return self:registerFD("server", fd, name, func, data, ...)
end

-------------------------------------------------------------------------------
--	removeInterval(id): Remove an interval by id
-------------------------------------------------------------------------------

function Server:removeInterval(id)
	if id and self.Intervals[id] then
		self.Intervals[id] = nil
		self:freeId(id)
	end
end

-------------------------------------------------------------------------------
--	handleFDs(ready)
-------------------------------------------------------------------------------

if not have_copas then
	
function Server:handleFDs(ready)
	local regfd = self.RegisteredFDs -- records, indexed by fd
	local recvfd = self.RecvFDs -- fds, indexed numerically
	for i = 1, #ready do
		local fd = ready[i]
		local rec = regfd[fd]
		if rec then
			if rec.type == "server" then
				local clientfd, msg = fd:accept()
				if clientfd then
					if rec.recvfunc(rec.data, clientfd, rec.name, 
							unpack(rec.args)) then
						clientfd:close()
					end
				end
			else
				rec.recvfunc(rec.data, fd, rec.name, unpack(rec.args))
				fd:close()
			end
		else
			error("unknown fd : " .. tostring(fd))
		end
	end
end

end

-------------------------------------------------------------------------------
--	status = run(): Run server
-------------------------------------------------------------------------------

function Server:run()
	self.Status = "run"
	db.info("server running")
	if have_copas then
		local c = coroutine.create(function()
			while self.Status == "run" do
				local timeout = self:expireIntervals()
				db.trace("timeout=%.02fs", timeout)
				copas.step(timeout)
				self:collectGarbage()
			end
		end)
		while true do
			local res, msg = coroutine.resume(c)
			if not res then
				db.error("main : %s", msg)
				break
			end
		end
	else
		local recvt = self.RecvFDs
		local sendt = { }
		while self.Status == "run" do
			local ready, msg
			local timeout = self:expireIntervals()
			db.trace("timeout=%.02fs", timeout)
			ready, msg = socket.select(recvt, sendt, timeout)
			self:handleFDs(ready)
			self:collectGarbage()
		end
	end
	self:shutdown()
	db.info("server exit")
	return self.Status
end

-------------------------------------------------------------------------------
--	setServerState(state[, delay]): Supported are "break", "restart", ...
-------------------------------------------------------------------------------

function Server:setServerState(state, delay)
	if state and state ~= self.Status then
		if not delay or delay == 0 then
			self.Status = state
		else
			self:registerInterval(delay, function(self)
				self.Status = state
			end)
		end
	end
end

-------------------------------------------------------------------------------
--	unregister(name)
-------------------------------------------------------------------------------

function Server:unregister(name)
	assert(name and type(name) == "string")
	local regnames = self.RegisteredNames
	local regfd = self.RegisteredFDs -- records, indexed by fd
	local recvfd = self.RecvFDs -- fds, indexed numerically
	local fd = regnames[name]
	local rec = regfd[fd]
	assert(rec, "unknown registered fd '" .. name .. "'")
	for i = 1, #recvfd do
		if recvfd[i] == fd then
			remove(recvfd, i)
			local rec = regfd[fd]
			regfd[fd] = nil
			regnames[rec.name] = nil
			db.info("fd '%s' unregistered, num=%s", rec.name, #recvfd)
			return
		end
	end
	error("could not find fd")
end

-------------------------------------------------------------------------------
--	shutdown() - try to orderly shut down services
-------------------------------------------------------------------------------

function Server:shutdown()
end

return Server
