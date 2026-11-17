-- Stormlight (Radaint) and Voidlight (Voidbringer) economy.
-- Regenerates, heals while infused, feeds Shardplate, and lets players drain gem deposits.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared.Config)
local Core = require(script.Parent.Core)

local Stormlight = {}

function Stormlight.get(player)
	return player:GetAttribute('Stormlight') or 0
end

function Stormlight.max(player)
	return player:GetAttribute('MaxStormlight') or Config.Stormlight.Max
end

function Stormlight.setup(player)
	player:SetAttribute('MaxStormlight', Config.Stormlight.Max)
	player:SetAttribute('Stormlight', Config.Stormlight.Start)
	player:SetAttribute('PlateIntegrity', 0)
end

function Stormlight.add(player, amount)
	local current = Stormlight.get(player)
	player:SetAttribute('Stormlight', math.clamp(current + amount, 0, Stormlight.max(player)))
end

function Stormlight.spend(player, amount)
	local current = Stormlight.get(player)
	if current < amount then
		return false
	end
	player:SetAttribute('Stormlight', current - amount)
	return true
end

function Stormlight.draw(player)
	local character = player.Character
	local humanoid = Core.humanoidOf(character)
	if not humanoid or humanoid.Health <= 0 then return false end
	if not Stormlight.spend(player, Config.Stormlight.DrawCost) then return false end

	humanoid.Health = humanoid.MaxHealth

	local speed = humanoid.WalkSpeed
	humanoid.WalkSpeed = speed + Config.Stormlight.DrawSpeedBonus
	task.delay(Config.Stormlight.DrawSeconds, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = speed
		end
	end)

	local root = Core.rootOf(character)
	if root then
		Core.effect(root.Position, Color3.fromRGB(150, 220, 255), 7, 0.5)
	end

	return true
end

local function gemParts(gem)
	local parts = {}
	if gem:IsA('BasePart') then
		table.insert(parts, gem)
	elseif gem:IsA('Model') then
		for _, child in gem:GetDescendants() do
			if child:IsA('BasePart') then
				table.insert(parts, child)
			end
		end
	end
	return parts
end

local function setGemVisible(gem, visible)
	for _, part in gemParts(gem) do
		part.Transparency = visible and 0.12 or 1
		local light = part:FindFirstChildOfClass('PointLight')
		if light then
			light.Enabled = visible
		end
	end
end

function Stormlight.updateGems()
	local folder = workspace:FindFirstChild('GemDeposits')
	if not folder then return end

	for _, gem in folder:GetChildren() do
		local parts = gemParts(gem)
		local anchor = parts[1]

		if anchor and not gem:GetAttribute('Taken') then
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local humanoid = Core.humanoidOf(character)
				local root = Core.rootOf(character)

				if humanoid and root and humanoid.Health > 0 then
					if (root.Position - anchor.Position).Magnitude <= Config.Stormlight.GemRadius then
						Stormlight.add(player, Config.Stormlight.GemAmount)
						gem:SetAttribute('Taken', true)
						setGemVisible(gem, false)
						Core.effect(anchor.Position, Color3.fromRGB(150, 215, 255), 6, 0.45)

						task.delay(Config.Stormlight.GemRespawn, function()
							if gem.Parent then
								gem:SetAttribute('Taken', false)
								setGemVisible(gem, true)
							end
						end)

						break
					end
				end
			end
		end
	end
end

function Stormlight.start()
	task.spawn(function()
		while true do
			task.wait(1)

			for _, player in Players:GetPlayers() do
				local character = player.Character
				local humanoid = Core.humanoidOf(character)

				if humanoid and humanoid.Health > 0 then
					local current = Stormlight.get(player)

					if current > 0 and humanoid.Health < humanoid.MaxHealth then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + Config.Stormlight.HealPerSecond)
					end

					if current < Stormlight.max(player) then
						Stormlight.add(player, Config.Stormlight.Regen)
					end

					if player:GetAttribute('HasPlate') and current > 15 then
						local integrity = player:GetAttribute('PlateIntegrity') or 0
						if integrity < 100 then
							Stormlight.spend(player, 3)
							player:SetAttribute('PlateIntegrity', math.min(100, integrity + 6))
						end
					end
				end
			end

			Stormlight.updateGems()
		end
	end)
end

return Stormlight
