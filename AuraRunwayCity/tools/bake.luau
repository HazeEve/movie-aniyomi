-- Bakes the procedurally-built world into the place file so it shows up in
-- Studio edit mode.  Usage (from AuraRunwayCity/):
--   rojo build -o build/AuraRunwayCity.rbxl
--   lune run tools/bake.luau build/AuraRunwayCity.rbxl
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local task = require("@lune/task")

local path = process.args[1] or "build/AuraRunwayCity.rbxl"
local game = roblox.deserializePlace(fs.readFile(path))

-- Lune's CFrame.lookAt mirrors Z-facing directions; use a correct one so the
-- baked world matches what Roblox builds at runtime.
local RCFrame = roblox.CFrame
local Vector3 = roblox.Vector3
local function lookAt(pos, target, up)
	up = up or Vector3.new(0, 1, 0)
	local look = (target - pos).Unit
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then
		right = look:Cross(Vector3.new(0, 0, 1))
	end
	right = right.Unit
	return RCFrame.fromMatrix(pos, right, right:Cross(look))
end
local CFrameShim = setmetatable({ lookAt = lookAt }, { __index = RCFrame })

local cache = {}
local env
local function requireModule(ms)
	if cache[ms] ~= nil then
		return cache[ms]
	end
	assert(ms and ms:IsA("ModuleScript"), "require target is not a ModuleScript: " .. tostring(ms))
	local src = ms.Source
	local fn = luau.load(src, { debugName = ms:GetFullName(), environment = env(ms) })
	local result = fn()
	cache[ms] = result
	return result
end

function env(scriptInst)
	local e = {
		Instance = roblox.Instance, CFrame = CFrameShim, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2,
		Color3 = roblox.Color3, Enum = roblox.Enum, Font = roblox.Font, UDim = roblox.UDim, UDim2 = roblox.UDim2,
		ColorSequence = roblox.ColorSequence, ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence, NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange, Rect = roblox.Rect, BrickColor = roblox.BrickColor,
		PhysicalProperties = roblox.PhysicalProperties,
		math = math, table = table, string = string, utf8 = utf8, bit32 = bit32, os = os, coroutine = coroutine,
		print = print, warn = print, error = error, assert = assert, pcall = pcall, xpcall = xpcall,
		pairs = pairs, ipairs = ipairs, next = next, select = select, type = type, typeof = typeof,
		tostring = tostring, tonumber = tonumber, setmetatable = setmetatable, getmetatable = getmetatable,
		rawget = rawget, rawset = rawset, rawequal = rawequal, unpack = table.unpack,
		task = task, game = game, workspace = game:GetService("Workspace"),
		script = scriptInst,
		require = requireModule,
	}
	return e
end

local ws = game:GetService("Workspace")
local old = ws:FindFirstChild("AuraWorld")
if old then
	old:Destroy()
end
local World = requireModule(game:GetService("ServerScriptService").Server.World)
local root = World.Build(ws)
local n = 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		n += 1
	end
end
print(("Baked AuraWorld: %d parts, %d instances"):format(n, #root:GetDescendants()))
fs.writeFile(path, roblox.serializePlace(game))
print("Wrote " .. path)
