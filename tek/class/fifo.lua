-------------------------------------------------------------------------------
--
--	tek.class.fifo
--	(C) by Timm S. Mueller <tmueller@schulze-mueller.de>
--
-------------------------------------------------------------------------------

local db = require "tek.lib.debug"
local Class = require "tek.class"
local concat = table.concat
local error = error
local insert = table.insert
local min = math.min
local remove = table.remove
local select = select
local type = type
local unpack = unpack or table.unpack

local FIFO = Class.module("tek.class.fifo", "tek.class")
FIFO._VERSION = "FIFO 2.2"

function FIFO.new(class, self)
	self = self or { }
	self.buf = self.buf or { }
	self.eof = false
	return Class.new(class, self)
end

function FIFO:write(s)
	local buf = self.buf
	if s == -1 then
		self.eof = -1
	elseif s then
		insert(buf, s)
	end
end

function FIFO:readn(len)
	local buf = self.buf
	local t, p, l = { }
	while len > 0 do
		p = remove(buf, 1)
		if not p then
			break -- no more data
		end
		l = p:len()
		if l > len then -- break buffer fragment in two
			insert(t, p:sub(1, len))
			insert(buf, 1, p:sub(len + 1))
			break
		end
		insert(t, p)
		len = len - l
	end
	return concat(t)
end

function FIFO:reada()
	local buf = self.buf
	self.buf = { }
	return concat(buf)
end

function FIFO:readpat(pat)
	local buf = self.buf
	local s
	while true do
		local n = buf[1] or self.eof
		if not n then
			if s then
				insert(buf, 1, s)
			end
			return nil
		end
		s = (s or "") .. (n == -1 and pat or n)
		local a, e = s:find(pat, 1, true)
		if a then
			buf[1] = s:sub(e + 1)
			return s:sub(1, a - 1)
		end
		remove(buf, 1)
	end
end

function FIFO:readpatlen(pat, len)
	len = len or 8192
	local partlen = len + pat:len() 
	local buf = self.buf
	local s, n
	while true do
		local eof = not buf[1] and self.eof
		if not eof then
			n = remove(buf, 1)
			if n then
				if n:len() + (s and s:len() or 0) > partlen then
					local a = n:sub(1, partlen)
					local b = n:sub(partlen + 1)
					insert(buf, 1, b)
					n = a
				end
				s = (s or "") .. n
			else
				if s then
					insert(buf, 1, s)
					return nil
				end
			end
		end
		if not s then
			return nil
		end
		local a = (s .. (eof and pat or "")):find(pat, 1, true)
		if a then
			local found = true
			local e = a + pat:len()
			if a > len + 1 then
				e = len + 1
				a = len + 1
				found = nil
			end
			local rest = s:sub(e)
			if rest ~= "" and not eof then
				insert(buf, 1, rest) -- push back
			end
			return s:sub(1, a - 1), found
		end
		if s:len() >= len then
			local a = s:sub(1, len)
			local b = s:sub(len + 1)
			insert(buf, 1, b)
			return a
		end
	end
end

function FIFO:read(...)
	if #self.buf == 0 then
		return -- EOF
	end
	local t, s = { }
	for i = 1, select('#', ...) do
		local what = select(i, ...)
		if type(what) == "number" then
			s = self:readn(what)
		elseif what == "*l" then
			s = self:readpat("\n")
		elseif what == "*a" then
			s = self:reada()
		else
			s = self:readpat(what)
		end
		insert(t, s)
	end
	return unpack(t)
end

FIFO.receive = FIFO.read

FIFO.send = FIFO.write

function FIFO:close()
	-- no op
end

return FIFO
