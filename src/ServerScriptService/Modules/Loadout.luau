-- Class selection, character stats, weapons and hero slots.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared.Config)
local Core = require(script.Parent.Core)
local Combat = require(script.Parent.Combat)

local Loadout = {}

local heroOwners = { Radiant = nil, Void = nil }

function Loadout.defaultClass(side)
	if side == 'Radiant' then
		return 'Squire'
	end
	return 'Dullform'
end

function Loadout.heroOwner(side)
	local owner = heroOwners[side]
	if owner and owner.Parent and Core.alive(owner) then
		return owner
	end
	return nil
end

function Loadout.releaseHero(player)
	for side, owner in heroOwners do
		if owner == player then
			heroOwners[side] = nil
		end
	end
end

function Loadout.selectClass(player, classId)
	local class = Config.ClassById[classId]
	if not class then
		return false, 'Unknown class'
	end
	if class.Side ~= player:GetAttribute('Side') then
		return false, 'Wrong side'
	end

	if class.Hero then
		local score = player:GetAttribute('Score') or 0
		if score < Config.Mode.HeroScoreRequired then
			return false, 'Reach ' .. Config.Mode.HeroScoreRequired .. ' score to deploy as a hero'
		end
		local taken = Loadout.heroOwner(class.Side)
		if taken and taken ~= player then
			return false, 'That hero is already on the field'
		end
		heroOwners[class.Side] = player
	else
		if heroOwners[class.Side] == player then
			heroOwners[class.Side] = nil
		end
	end

	player:SetAttribute('ClassId', classId)
	return true
end

function Loadout.apply(player)
	local character = player.Character
	if not character then return end

	local humanoid = Core.humanoidOf(character)
	if not humanoid then return end

	local side = player:GetAttribute('Side') or 'Radiant'
	local classId = player:GetAttribute('ClassId')
	local class = classId and Config.ClassById[classId]

	if not class or class.Side ~= side then
		class = Config.ClassById[Loadout.defaultClass(side)]
	end

	player:SetAttribute('ClassId', class.Id)

	humanoid.MaxHealth = class.Health
	humanoid.Health = class.Health
	humanoid.WalkSpeed = class.WalkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = class.JumpPower

	player:SetAttribute('HasPlate', class.Plate == true)
	player:SetAttribute('PlateIntegrity', class.Plate and 100 or 0)
	player:SetAttribute('DamageReduction', 0)
	player:SetAttribute('DamageBoost', 1)
	player:SetAttribute('MaxStormlight', Config.Stormlight.Max)

	local oldHighlight = character:FindFirstChild('TeamHighlight')
	if oldHighlight then
		oldHighlight:Destroy()
	end

	local highlight = Instance.new('Highlight')
	highlight.Name = 'TeamHighlight'
	highlight.FillColor = Config.Teams[side].Color
	highlight.FillTransparency = 0.78
	highlight.OutlineColor = Config.Teams[side].Color
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character

	Combat.equip(character, class.Weapon)
	Combat.watchDeath(character)

	local spawnName = side == 'Radiant' and 'RadiantSpawn' or 'VoidSpawn'
	local spawnPart = workspace:FindFirstChild(spawnName)
	if spawnPart then
		local placed = false
		for _ = 1, 8 do
			local offset = Vector3.new(math.random(-18, 18), 8, math.random(-14, 14))
			local target = spawnPart.Position + offset

			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { character }
			local blocked = false
			for _, part in workspace:GetPartBoundsInRadius(target + Vector3.new(0, 2, 0), 3, params) do
				if part.CanCollide then
					blocked = true
					break
				end
			end

			if not blocked then
				character:PivotTo(CFrame.new(target))
				placed = true
				break
			end
		end

		if not placed then
			character:PivotTo(CFrame.new(spawnPart.Position + Vector3.new(0, 9, 0)))
		end
	end

	local forceField = Instance.new('ForceField')
	forceField.Visible = false
	forceField.Parent = character
	task.delay(2.5, function()
		if forceField.Parent then
			forceField:Destroy()
		end
	end)
end

local lastDeploy = {}

function Loadout.deploy(player)
	local now = os.clock()
	if now - (lastDeploy[player] or 0) < 1.5 then
		return false
	end
	lastDeploy[player] = now

	Loadout.releaseHero(player)
	player:LoadCharacter()
	return true
end

return Loadout
