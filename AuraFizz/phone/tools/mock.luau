-- Tiny Roblox mock for running the phone scripts in the plain `luau` CLI.
-- Virtual-time scheduler + Instances with real Parent/children + fireable signals.
local M = {}
local now = 0
local queue = {}
local errors = {}
local function schedule(at, co, ...)
	table.insert(queue, { at = at, co = co, args = table.pack(...) })
end
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		table.insert(errors, tostring(err) .. "\n" .. debug.traceback(co))
	end
end
task = {
	spawn = function(fn, ...)
		local co = if type(fn) == "thread" then fn else coroutine.create(fn)
		resume(co, ...)
		return co
	end,
	defer = function(fn, ...)
		local co = coroutine.create(fn)
		schedule(now, co, ...)
		return co
	end,
	delay = function(t, fn, ...)
		local co = coroutine.create(fn)
		schedule(now + (t or 0), co, ...)
		return co
	end,
	wait = function(t)
		local co = coroutine.running()
		schedule(now + (t or 0.03), co)
		coroutine.yield()
		return t
	end,
}
function M.run(seconds)
	local stop = now + seconds
	while true do
		table.sort(queue, function(a, b) return a.at < b.at end)
		local nxt = queue[1]
		if not nxt or nxt.at > stop then break end
		table.remove(queue, 1)
		now = math.max(now, nxt.at)
		resume(nxt.co, table.unpack(nxt.args, 1, nxt.args.n))
	end
	now = stop
end
function M.errors() return errors end
local realOs = os
os = { date = realOs.date, clock = function() return now end,
	time = function(t) if t then return realOs.time(t) end return 1700000000 + math.floor(now) end }
warn = function(...) print("WARN", ...) end

-- Signals
local Signal = {}
Signal.__index = Signal
function M.signal() return setmetatable({ fns = {} }, Signal) end
function Signal:Connect(fn) table.insert(self.fns, fn); return { Disconnect = function() end } end
function Signal:Fire(...) for _, fn in self.fns do task.spawn(fn, ...) end end

-- datatypes
local function vec2(x, y) return setmetatable({ X = x or 0, Y = y or 0 }, { __sub = function(a, b) return vec2(a.X - b.X, a.Y - b.Y) end }) end
Vector2 = { new = vec2 }
Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
local function udim(s, o) return { Scale = s or 0, Offset = o or 0 } end
UDim = { new = udim }
local U2 = {}
U2.__add = function(a, b) return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
U2.__sub = function(a, b) return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset) end
UDim2 = {
	new = function(a, b, c, d) return setmetatable({ X = udim(a, b), Y = udim(c, d) }, U2) end,
	fromScale = function(a, b) return UDim2.new(a, 0, b, 0) end,
	fromOffset = function(a, b) return UDim2.new(0, a, 0, b) end,
}
local Col = {}
Col.__index = Col
function Col:Lerp(o, t) return Color3.new(self.R + (o.R - self.R) * t, self.G + (o.G - self.G) * t, self.B + (o.B - self.B) * t) end
Color3 = {
	new = function(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Col) end,
	fromRGB = function(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end,
	fromHex = function(h)
		h = string.gsub(h, "#", "")
		assert(#h == 6, "bad hex " .. h)
		return Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
	end,
}
ColorSequence = { new = function(...) return { ... } end }
ColorSequenceKeypoint = { new = function(t, c) assert(c and c.R, "keypoint color"); return { Time = t, Value = c } end }
TweenInfo = { new = function(...) return { ... } end }
local function enumItem(path) return setmetatable({ Name = path }, { __index = function(t, k) return enumItem(path .. "." .. k) end }) end
local enumCache = {}
Enum = setmetatable({}, { __index = function(_, k) enumCache[k] = enumCache[k] or setmetatable({}, { __index = function(t, v) local it = { Name = v, EnumType = k }; rawset(t, v, it); return it end }); return enumCache[k] end })
typeof = function(v) return type(v) end

-- Instances
local EVENTS = { Activated = 1, MouseButton1Down = 1, MouseButton1Up = 1, MouseLeave = 1, FocusLost = 1, Completed = 1, OnClientEvent = 1,
	OnServerEvent = 1, PlayerAdded = 1, PlayerRemoving = 1, InputBegan = 1, PromptGamePassPurchaseFinished = 1 }
local DEFAULTS = { AbsoluteCanvasSize = vec2(0, 400), AbsoluteWindowSize = vec2(0, 300), AbsoluteSize = vec2(100, 100), Text = "", Visible = true,
	ViewportSize = vec2(1366, 768), Rotation = 0, ZIndex = 1, BackgroundTransparency = 0 }
local Inst = {}
M.all = {}
local function make(class, props)
	local self = { __class = class, __props = props or {}, __children = {}, __signals = {} }
	setmetatable(self, Inst)
	table.insert(M.all, self)
	return self
end
M.make = make
Inst.__index = function(self, k)
	local p = rawget(self, "__props")
	if p[k] ~= nil then return p[k] end
	if EVENTS[k] then
		local s = M.signal(); p[k] = s; return s
	end
	local method = Inst[k]
	if method then return method end
	if k == "Parent" or k == "Name" then return p[k] end
	if DEFAULTS[k] ~= nil then return DEFAULTS[k] end
	for _, c in rawget(self, "__children") do if c.Name == k then return c end end
	return nil
end
Inst.__newindex = function(self, k, v)
	local p = rawget(self, "__props")
	if k == "Parent" then
		local old = p.Parent
		if old then
			local ch = rawget(old, "__children")
			local i = table.find(ch, self); if i then table.remove(ch, i) end
		end
		if v then table.insert(rawget(v, "__children"), self) end
	end
	if p[k] ~= nil and type(p[k]) == "table" and getmetatable(p[k]) == Signal then
		error("assigned to event " .. k)
	end
	p[k] = v
end
Inst.__tostring = function(self) return self.__class .. ":" .. tostring(self.Name) end
function Inst:GetChildren() return table.clone(rawget(self, "__children")) end
function Inst:GetDescendants()
	local out = {}
	for _, c in rawget(self, "__children") do table.insert(out, c); for _, d in c:GetDescendants() do table.insert(out, d) end end
	return out
end
function Inst:FindFirstChild(n) for _, c in rawget(self, "__children") do if c.Name == n then return c end end return nil end
function Inst:WaitForChild(n) local c = self:FindFirstChild(n); assert(c, "WaitForChild would hang: " .. n); return c end
function Inst:IsA(c) return rawget(self, "__class") == c or c == "Instance" or c == "GuiObject" end
function Inst:Destroy() self.Parent = nil; rawget(self, "__props").__destroyed = true end
function Inst:ClearAllChildren() for _, c in self:GetChildren() do c:Destroy() end end
function Inst:GetPropertyChangedSignal() return M.signal() end
function Inst:ReleaseFocus() end
Instance = { new = function(class) local o = make(class); o.Name = class; return o end }
return M
