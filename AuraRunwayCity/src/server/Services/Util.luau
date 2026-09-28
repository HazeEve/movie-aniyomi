--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Util = {}
Util.World = nil :: Folder?

function Util.Notify(player: Player?, text: string, kind: string?)
	if player then
		Remotes.Event("Notify"):FireClient(player, text, kind or "info")
	else
		Remotes.Event("Notify"):FireAllClients(text, kind or "info")
	end
end

function Util.Root(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Util.Humanoid(player: Player): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

Util.BeforeTeleport = nil -- set by RPService (wakes sleepers etc.)

function Util.Teleport(player: Player, cf: CFrame)
	local char = player.Character
	local hum = Util.Humanoid(player)
	if not char or not hum then
		return
	end
	if Util.BeforeTeleport then
		Util.BeforeTeleport(player)
	end
	if hum.SeatPart then
		hum.Sit = false
		local weld = hum.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		task.wait()
	end
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 3)
	end)
	char:PivotTo(cf)
end

function Util.Marker(name: string): BasePart?
	local w = Util.World
	if not w then
		return nil
	end
	local stage = w:FindFirstChild("Stage")
	local m = stage and stage:FindFirstChild("Markers")
	return m and m:FindFirstChild(name) :: BasePart?
end

function Util.OnStage(player: Player): boolean
	local root = Util.Root(player)
	local stage = Util.World and Util.World:FindFirstChild("Stage")
	if not root or not stage then
		return false
	end
	local mn, mx = stage:GetAttribute("ZoneMin"), stage:GetAttribute("ZoneMax")
	if not mn or not mx then
		return false
	end
	local p = root.Position
	return p.X >= mn.X and p.X <= mx.X and p.Y >= mn.Y and p.Y <= mx.Y and p.Z >= mn.Z and p.Z <= mx.Z
end

function Util.Players(): { Player }
	return Players:GetPlayers()
end

function Util.Now(): number
	return workspace:GetServerTimeNow()
end

return Util
