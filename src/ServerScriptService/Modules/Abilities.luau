-- Every surge and singer form ability. Costs and cooldowns come from Config.Abilities.
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared.Config)
local Core = require(script.Parent.Core)
local Stormlight = require(script.Parent.Stormlight)

local Abilities = {}

local cooldowns = {}

local STORM_BLUE = Color3.fromRGB(150, 220, 255)
local DIVISION_ORANGE = Color3.fromRGB(255, 140, 60)
local PROGRESSION_GREEN = Color3.fromRGB(110, 235, 150)
local VOID_PURPLE = Color3.fromRGB(180, 90, 255)
local SOULCAST_WHITE = Color3.fromRGB(245, 245, 255)

local function characterFromPart(part)
	local current = part
	for _ = 1, 4 do
		if not current then return nil end
		if current:FindFirstChildOfClass('Humanoid') then return current end
		current = current.Parent
	end
	return nil
end

local function holdInPlace(root, seconds)
	if not root or not root.Parent then return end
	root.Anchored = true
	task.delay(seconds, function()
		if root.Parent then
			root.Anchored = false
		end
	end)
end

local function spawnWall(position, size, color, material, lifetime)
	local wall = Instance.new('Part')
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.Material = material or Enum.Material.Slate
	wall.Color = color or Color3.fromRGB(120, 120, 130)
	wall.Parent = workspace
	task.delay(lifetime, function()
		wall:Destroy()
	end)
	return wall
end

local function shiftTransparency(character, amount, seconds)
	local originals = {}
	for _, part in character:GetDescendants() do
		if part:IsA('BasePart') then
			originals[part] = part.Transparency
			part.Transparency = math.clamp(part.Transparency + amount, 0, 1)
		end
	end
	task.delay(seconds, function()
		for part, original in originals do
			if part.Parent then
				part.Transparency = original
			end
		end
	end)
end

local function surgeRay(player, character, range, damage, color)
	local root = Core.rootOf(character)
	if not root then return end

	local origin = root.Position
	local direction = root.CFrame.LookVector * range
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(origin, direction, params)
	local endPoint = origin + direction

	if result then
		endPoint = result.Position
		local victimCharacter = characterFromPart(result.Instance)
		if victimCharacter then
			Core.damage(player, victimCharacter, damage)
		end
		Core.effect(result.Position, color, 4, 0.3)
	end

	Core.tracer(origin, endPoint, color, 0.8)
end

local implementations = {}

implementations.Lashing = function(player, character, humanoid, root)
	root.AssemblyLinearVelocity = Vector3.new(0, 145, 0) + root.CFrame.LookVector * 35
	Core.effect(root.Position, STORM_BLUE, 7, 0.6)
end

implementations.Adhesion = function(player, character, humanoid, root)
	local targets = Core.around(character, root.Position, 32, true)
	local target = targets[1]
	if not target then return end

	holdInPlace(target.Root, 2.5)
	Core.damage(player, target.Character, 10)
	Core.effect(target.Root.Position, STORM_BLUE, 6, 0.6)
end

implementations.Division = function(player, character, humanoid, root)
	local targets = Core.around(character, root.Position, 70, true)
	local target = targets[1]
	if not target then return end

	Core.tracer(root.Position, target.Root.Position, DIVISION_ORANGE, 0.7)
	for tick = 1, 4 do
		task.delay(tick * 0.6, function()
			if target.Character.Parent then
				Core.damage(player, target.Character, 12)
				Core.effect(target.Root.Position, DIVISION_ORANGE, 4, 0.3)
			end
		end)
	end
end

implementations.Abrasion = function(player, character, humanoid, root)
	local speed = humanoid.WalkSpeed
	humanoid.WalkSpeed = speed + 16
	task.delay(4, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = speed
		end
	end)
	Core.effect(root.Position, Color3.fromRGB(200, 255, 240), 6, 0.5)
end

implementations.Progression = function(player, character, humanoid, root)
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 40)
	Core.effect(root.Position, PROGRESSION_GREEN, 8, 0.6)

	for _, ally in Core.around(character, root.Position, 30, false) do
		ally.Humanoid.Health = math.min(ally.Humanoid.MaxHealth, ally.Humanoid.Health + 40)
		Core.effect(ally.Root.Position, PROGRESSION_GREEN, 5, 0.5)
	end
end

implementations.Illumination = function(player, character, humanoid, root)
	shiftTransparency(character, 0.75, 6)
	Core.effect(root.Position, VOID_PURPLE, 7, 0.5)
end

implementations.Transformation = function(player, character, humanoid, root)
	local targets = Core.around(character, root.Position, 55, true)
	local target = targets[1]
	if not target then return end

	Core.damage(player, target.Character, 35)
	Core.effect(target.Root.Position, SOULCAST_WHITE, 9, 0.7)

	local speed = target.Humanoid.WalkSpeed
	target.Humanoid.WalkSpeed = math.max(6, speed - 8)
	task.delay(6, function()
		if target.Humanoid.Parent then
			target.Humanoid.WalkSpeed = speed
		end
	end)
end

implementations.Transportation = function(player, character, humanoid, root)
	Core.effect(root.Position, STORM_BLUE, 6, 0.5)
	root.CFrame = root.CFrame * CFrame.new(0, 0, -45)
	Core.effect(root.Position, STORM_BLUE, 6, 0.5)
end

implementations.Cohesion = function(player, character, humanoid, root)
	local targets = Core.around(character, root.Position, 24, true)

	for _, target in targets do
		holdInPlace(target.Root, 1.8)
		Core.damage(player, target.Character, 12)
		Core.effect(target.Root.Position, Color3.fromRGB(150, 130, 90), 5, 0.4)
	end

	Core.effect(root.Position, Color3.fromRGB(150, 130, 90), 20, 0.6)
end

implementations.Tension = function(player, character, humanoid, root)
	local position = root.Position + root.CFrame.LookVector * 12 + Vector3.new(0, 5, 0)
	spawnWall(position, Vector3.new(20, 14, 4), Color3.fromRGB(130, 125, 120), Enum.Material.Slate, 8)
end

implementations.SquireOath = function(player, character, humanoid, root)
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 25)
	Core.buff(player, 'DamageReduction', 0.25, 6)
	Core.effect(root.Position, STORM_BLUE, 10, 0.7)

	for _, ally in Core.around(character, root.Position, 30, false) do
		Stormlight.add(ally.Player, 15)
		ally.Humanoid.Health = math.min(ally.Humanoid.MaxHealth, ally.Humanoid.Health + 25)
		Core.effect(ally.Root.Position, STORM_BLUE, 4, 0.4)
	end
end

implementations.WarShock = function(player, character, humanoid, root)
	Core.effect(root.Position, Color3.fromRGB(200, 120, 90), 22, 0.5)

	for _, target in Core.around(character, root.Position, 22, true) do
		Core.damage(player, target.Character, 20)
		Core.knockback(target.Root, target.Root.Position - root.Position, 55)
	end
end

implementations.Stormcall = function(player, character, humanoid, root)
	surgeRay(player, character, 150, 45, VOID_PURPLE)
end

implementations.NimbleDash = function(player, character, humanoid, root)
	root.AssemblyLinearVelocity = root.CFrame.LookVector * 95 + Vector3.new(0, 25, 0)

	local speed = humanoid.WalkSpeed
	humanoid.WalkSpeed = speed + 6
	task.delay(3, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = speed
		end
	end)

	Core.effect(root.Position, Color3.fromRGB(200, 160, 255), 6, 0.4)
end

implementations.Barricade = function(player, character, humanoid, root)
	local position = root.Position + root.CFrame.LookVector * 10 + Vector3.new(0, 4, 0)
	spawnWall(position, Vector3.new(16, 10, 3), Color3.fromRGB(110, 85, 60), Enum.Material.WoodPlanks, 10)
end

implementations.RhythmAura = function(player, character, humanoid, root)
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 15)
	Core.buff(player, 'DamageBoost', 1.25, 8)
	Core.effect(root.Position, VOID_PURPLE, 12, 0.7)

	for _, ally in Core.around(character, root.Position, 30, false) do
		Core.buff(ally.Player, 'DamageBoost', 1.25, 8)
		ally.Humanoid.Health = math.min(ally.Humanoid.MaxHealth, ally.Humanoid.Health + 15)
		Core.effect(ally.Root.Position, VOID_PURPLE, 4, 0.4)
	end
end

implementations.PrecisionShot = function(player, character, humanoid, root)
	surgeRay(player, character, 260, 60, Color3.fromRGB(230, 220, 255))
end

implementations.SmokeCloud = function(player, character, humanoid, root)
	local cloud = Instance.new('Part')
	cloud.Shape = Enum.PartType.Ball
	cloud.Size = Vector3.new(30, 30, 30)
	cloud.Position = root.Position
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.CanQuery = false
	cloud.Material = Enum.Material.SmoothPlastic
	cloud.Color = Color3.fromRGB(45, 40, 55)
	cloud.Transparency = 0.55
	cloud.Parent = workspace

	task.delay(8, function()
		cloud:Destroy()
	end)

	shiftTransparency(character, 0.55, 5)
end

implementations.DecayAura = function(player, character, humanoid, root)
	local origin = root.Position

	for tick = 1, 5 do
		task.delay(tick, function()
			if not character.Parent then return end
			for _, target in Core.around(character, origin, 22, true) do
				Core.damage(player, target.Character, 9)
			end
			Core.effect(origin, Color3.fromRGB(120, 40, 140), 22, 0.4)
		end)
	end
end

implementations.ShadowStep = function(player, character, humanoid, root)
	local targets = Core.around(character, root.Position, 70, true)
	local target = targets[1]

	if target then
		Core.effect(root.Position, Color3.fromRGB(90, 60, 130), 6, 0.4)
		root.CFrame = target.Root.CFrame * CFrame.new(0, 0, 6)
		Core.damage(player, target.Character, 25)
		Core.effect(root.Position, Color3.fromRGB(90, 60, 130), 6, 0.4)
	else
		root.CFrame = root.CFrame * CFrame.new(0, 0, -30)
	end
end

implementations.BattleCharge = function(player, character, humanoid, root)
	local speed = humanoid.WalkSpeed
	humanoid.WalkSpeed = speed + 12
	Core.buff(player, 'DamageReduction', 0.3, 5)
	Core.effect(root.Position, Color3.fromRGB(210, 170, 120), 7, 0.5)

	task.delay(5, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = speed
		end
	end)
end

implementations.VoidlightBurn = function(player, character, humanoid, root)
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 70)
	Core.buff(player, 'DamageBoost', 1.25, 6)
	Core.effect(root.Position, VOID_PURPLE, 9, 0.7)
end

function Abilities.cooldown(player, abilityId)
	local perPlayer = cooldowns[player]
	local untilTime = perPlayer and perPlayer[abilityId]
	if not untilTime then return 0 end
	return math.max(0, untilTime - os.clock())
end

local targetAbilities = {
	Adhesion = 32,
	Division = 70,
	Transformation = 55,
}

function Abilities.use(player, abilityId)
	local spec = Config.Abilities[abilityId]
	if not spec then return false, 'Unknown surge' end

	local character = player.Character
	local humanoid = Core.humanoidOf(character)
	local root = Core.rootOf(character)
	if not humanoid or not root or humanoid.Health <= 0 then
		return false, 'No living body'
	end

	local impl = implementations[abilityId]
	if not impl then return false, 'Surge not available' end

	if Abilities.cooldown(player, abilityId) > 0 then
		return false, 'Surge recharging'
	end

	if Stormlight.get(player) < spec.Cost then
		return false, 'Not enough light'
	end

	local targetRange = targetAbilities[abilityId]
	if targetRange and #Core.around(character, root.Position, targetRange, true) == 0 then
		return false, 'No enemy in range'
	end

	if not Stormlight.spend(player, spec.Cost) then
		return false, 'Not enough light'
	end

	local perPlayer = cooldowns[player]
	if not perPlayer then
		perPlayer = {}
		cooldowns[player] = perPlayer
	end
	perPlayer[abilityId] = os.clock() + spec.Cooldown

	impl(player, character, humanoid, root)
	return true
end

return Abilities
