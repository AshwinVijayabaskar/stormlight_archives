-- Server helpers shared by surges, combat and the war mode.
local Players = game:GetService('Players')

local Core = {}

function Core.playerFromCharacter(character)
	if not character then return nil end
	for _, player in Players:GetPlayers() do
		if player.Character == character then
			return player
		end
	end
	return nil
end

function Core.sideOf(player)
	if not player then return nil end
	return player:GetAttribute('Side')
end

function Core.humanoidOf(character)
	return character and character:FindFirstChildOfClass('Humanoid')
end

function Core.rootOf(character)
	return character and character:FindFirstChild('HumanoidRootPart')
end

function Core.alive(player)
	local character = player.Character
	local humanoid = Core.humanoidOf(character)
	return character ~= nil and humanoid ~= nil and humanoid.Health > 0
end

function Core.around(character, position, radius, wantEnemies)
	local results = {}
	local myPlayer = Core.playerFromCharacter(character)
	local mySide = Core.sideOf(myPlayer)

	for _, player in Players:GetPlayers() do
		local isEnemy = Core.sideOf(player) ~= mySide
		local include = wantEnemies and isEnemy or (not wantEnemies and not isEnemy)
		if include and player ~= myPlayer then
			local other = player.Character
			local humanoid = Core.humanoidOf(other)
			local root = Core.rootOf(other)
			if humanoid and root and humanoid.Health > 0 then
				local distance = (root.Position - position).Magnitude
				if distance <= radius then
					table.insert(results, {
						Player = player,
						Character = other,
						Humanoid = humanoid,
						Root = root,
						Distance = distance,
					})
				end
			end
		end
	end

	table.sort(results, function(a, b)
		return a.Distance < b.Distance
	end)

	return results
end

function Core.damage(attackerPlayer, victimCharacter, amount)
	if not victimCharacter or not victimCharacter.Parent then return 0 end

	local humanoid = Core.humanoidOf(victimCharacter)
	if not humanoid or humanoid.Health <= 0 then return 0 end

	local victimPlayer = Core.playerFromCharacter(victimCharacter)
	if victimPlayer and attackerPlayer and victimPlayer == attackerPlayer then
		return 0
	end

	local reduction = 0
	if victimPlayer then
		reduction = victimPlayer:GetAttribute('DamageReduction') or 0
		local integrity = victimPlayer:GetAttribute('PlateIntegrity') or 0
		if integrity > 0 then
			reduction = math.min(0.65, reduction + 0.35)
			victimPlayer:SetAttribute('PlateIntegrity', math.max(0, integrity - amount * 0.5))
		end
	end

	local boost = 1
	if attackerPlayer then
		boost = attackerPlayer:GetAttribute('DamageBoost') or 1
	end

	local final = math.max(1, amount * boost * (1 - reduction))
	humanoid:TakeDamage(final)
	humanoid:SetAttribute('LastAttacker', attackerPlayer and attackerPlayer.UserId or 0)
	return final
end

function Core.knockback(root, direction, force)
	if not root then return end
	local bodyVelocity = Instance.new('BodyVelocity')
	bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 100000
	bodyVelocity.Velocity = direction.Unit * force + Vector3.new(0, force * 0.45, 0)
	bodyVelocity.Parent = root
	task.delay(0.25, function()
		bodyVelocity:Destroy()
	end)
end

function Core.effect(position, color, size, lifetime)
	local part = Instance.new('Part')
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.fromRGB(150, 220, 255)
	part.Transparency = 0.25
	part.Parent = workspace
	task.delay(lifetime or 0.4, function()
		part:Destroy()
	end)
	return part
end

function Core.tracer(fromPosition, toPosition, color, thickness)
	local distance = (toPosition - fromPosition).Magnitude
	if distance < 0.2 then return end

	local beam = Instance.new('Part')
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = color or Color3.fromRGB(180, 230, 255)
	local width = thickness or 0.6
	beam.Size = Vector3.new(width, width, distance)
	beam.CFrame = CFrame.lookAt(fromPosition, toPosition) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = workspace
	task.delay(0.25, function()
		beam:Destroy()
	end)
end

function Core.buff(player, attribute, value, seconds)
	local previous = player:GetAttribute(attribute)
	player:SetAttribute(attribute, value)
	task.delay(seconds, function()
		if player.Parent then
			player:SetAttribute(attribute, previous)
		end
	end)
end

return Core
