-- Weapons, Shardplate damage and death bookkeeping.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared.Config)
local Core = require(script.Parent.Core)

local Combat = {}

Combat.onDeath = nil

local function characterFromPart(part)
	local current = part
	for _ = 1, 4 do
		if not current then return nil end
		if current:FindFirstChildOfClass('Humanoid') then return current end
		current = current.Parent
	end
	return nil
end

local function meleeSwing(player, character, spec, weaponId)
	local root = Core.rootOf(character)
	if not root then return end

	local hit = false
	for _, target in Core.around(character, root.Position, spec.Range + 2, true) do
		local offset = target.Root.Position - root.Position
		if offset.Magnitude > 0.1 and offset.Unit:Dot(root.CFrame.LookVector) > 0.1 then
			Core.damage(player, target.Character, spec.Damage)
			Core.effect(target.Root.Position, Color3.fromRGB(255, 240, 205), 3, 0.25)
			if spec.Knockback then
				Core.knockback(target.Root, offset, spec.Knockback)
			end
			hit = true
		end
	end

	if hit and weaponId == 'Shardblade' then
		Core.effect(root.Position + root.CFrame.LookVector * 6, Color3.fromRGB(190, 230, 255), 5, 0.2)
	end
end

local function rangedShot(player, character, spec, weaponId)
	local root = Core.rootOf(character)
	if not root then return end

	local origin = root.Position
	local direction = root.CFrame.LookVector * spec.Range
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(origin, direction, params)
	local endPoint = origin + direction

	if result then
		endPoint = result.Position
		local victimCharacter = characterFromPart(result.Instance)
		if victimCharacter then
			Core.damage(player, victimCharacter, spec.Damage)
		end
		Core.effect(result.Position, Color3.fromRGB(255, 235, 200), 3, 0.2)
	end

	local color = weaponId == 'Bow' and Color3.fromRGB(255, 235, 190) or Color3.fromRGB(190, 120, 255)
	Core.tracer(origin, endPoint, color, 0.5)
end

local function weaponPart(container, name, size, cframe, color, material)
	local part = Instance.new('Part')
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = material or Enum.Material.Metal
	part.Color = color or Color3.fromRGB(196, 202, 214)
	part.Parent = container
	return part
end

local function buildHeldWeapon(weaponId, hand, character)
	local model = Instance.new('Model')
	model.Name = 'HeldWeapon'

	if weaponId == 'Spear' then
		weaponPart(model, 'Shaft', Vector3.new(0.22, 7, 0.22), CFrame.new(0, 2.6, 0), Color3.fromRGB(94, 66, 44), Enum.Material.Wood)
		weaponPart(model, 'Tip', Vector3.new(0.42, 1.4, 0.42), CFrame.new(0, 6.8, 0), Color3.fromRGB(206, 212, 226), Enum.Material.Metal)
	elseif weaponId == 'Shardblade' then
		weaponPart(model, 'Blade', Vector3.new(0.35, 7.6, 1.0), CFrame.new(0, 4.2, 0), Color3.fromRGB(168, 214, 255), Enum.Material.Neon)
		weaponPart(model, 'Guard', Vector3.new(2.0, 0.3, 0.5), CFrame.new(0, 0.3, 0), Color3.fromRGB(120, 140, 170), Enum.Material.Metal)
		weaponPart(model, 'Grip', Vector3.new(0.3, 1.1, 0.3), CFrame.new(0, -0.4, 0), Color3.fromRGB(40, 40, 48), Enum.Material.Fabric)
	elseif weaponId == 'Shardhammer' then
		weaponPart(model, 'Haft', Vector3.new(0.28, 4.6, 0.28), CFrame.new(0, 2.1, 0), Color3.fromRGB(94, 66, 44), Enum.Material.Wood)
		weaponPart(model, 'Head', Vector3.new(1.2, 1.2, 2.2), CFrame.new(0, 4.6, 0), Color3.fromRGB(150, 156, 170), Enum.Material.Metal)
	elseif weaponId == 'Dagger' then
		weaponPart(model, 'Blade', Vector3.new(0.2, 2.4, 0.6), CFrame.new(0, 1.5, 0), Color3.fromRGB(198, 206, 222), Enum.Material.Metal)
		weaponPart(model, 'Grip', Vector3.new(0.28, 0.9, 0.28), CFrame.new(0, -0.2, 0), Color3.fromRGB(50, 44, 40), Enum.Material.Fabric)
	elseif weaponId == 'Bow' then
		weaponPart(model, 'LimbTop', Vector3.new(0.24, 3.4, 0.4), CFrame.new(0, 2.1, 0) * CFrame.Angles(math.rad(12), 0, 0), Color3.fromRGB(120, 86, 58), Enum.Material.Wood)
		weaponPart(model, 'LimbBottom', Vector3.new(0.24, 3.4, 0.4), CFrame.new(0, -2.1, 0) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(120, 86, 58), Enum.Material.Wood)
		weaponPart(model, 'String', Vector3.new(0.06, 7, 0.06), CFrame.new(0, 0, 0.5), Color3.fromRGB(222, 222, 228), Enum.Material.SmoothPlastic)
	elseif weaponId == 'Voidlash' then
		weaponPart(model, 'Staff', Vector3.new(0.24, 5.4, 0.24), CFrame.new(0, 2.4, 0), Color3.fromRGB(64, 52, 74), Enum.Material.Metal)
		weaponPart(model, 'Crystal', Vector3.new(0.5, 1.4, 0.5), CFrame.new(0, 5.4, 0), Color3.fromRGB(186, 106, 255), Enum.Material.Neon)
	else
		model:Destroy()
		return nil
	end

	local grip = CFrame.new(0, -0.9, -0.5) * CFrame.Angles(math.rad(-90), 0, 0)
	model:PivotTo(hand.CFrame * grip)

	for _, part in model:GetChildren() do
		if part:IsA('BasePart') then
			local weld = Instance.new('WeldConstraint')
			weld.Part0 = hand
			weld.Part1 = part
			weld.Parent = part
		end
	end

	model.Parent = character
	return model
end

function Combat.equip(character, weaponId)
	for _, child in character:GetChildren() do
		if child:IsA('Tool') then
			child:Destroy()
		end
	end

	local spec = Config.Weapons[weaponId]
	if not spec then
		spec = Config.Weapons.Fists
		weaponId = 'Fists'
	end

	local tool = Instance.new('Tool')
	tool.Name = weaponId
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute('WeaponId', weaponId)
	tool:SetAttribute('NextAttack', 0)
	tool.Parent = character

	local heldModel = nil

	local function clearHeld()
		if heldModel then
			heldModel:Destroy()
			heldModel = nil
		end
	end

	tool.Equipped:Connect(function()
		clearHeld()
		local holder = tool.Parent
		local hand = holder and (holder:FindFirstChild('RightHand') or holder:FindFirstChild('Right Arm'))
		if hand then
			heldModel = buildHeldWeapon(weaponId, hand, holder)
		end
	end)

	tool.Unequipped:Connect(clearHeld)

	tool.Activated:Connect(function()
		local humanoid = Core.humanoidOf(character)
		local player = Core.playerFromCharacter(character)
		if not humanoid or not player or humanoid.Health <= 0 then return end

		local now = os.clock()
		if now < (tool:GetAttribute('NextAttack') or 0) then return end
		tool:SetAttribute('NextAttack', now + spec.Cooldown)

		if spec.Kind == 'ranged' then
			rangedShot(player, character, spec, weaponId)
		else
			meleeSwing(player, character, spec, weaponId)
		end
	end)

	local humanoid = Core.humanoidOf(character)
	if humanoid then
		humanoid:EquipTool(tool)
	end

	return tool
end

function Combat.watchDeath(character)
	local humanoid = Core.humanoidOf(character)
	if not humanoid then return end

	humanoid.Died:Connect(function()
		local victimPlayer = Core.playerFromCharacter(character)
		local attackerId = humanoid:GetAttribute('LastAttacker') or 0
		local attackerPlayer = nil
		if attackerId ~= 0 then
			attackerPlayer = Players:GetPlayerByUserId(attackerId)
		end

		if Combat.onDeath then
			Combat.onDeath(victimPlayer, attackerPlayer)
		end

		print(string.format(
			'[Stormlight Archives] death: %s at %s (attacker: %s)',
			victimPlayer and victimPlayer.Name or 'world',
			tostring(character:GetPivot().Position),
			attackerPlayer and attackerPlayer.Name or 'none'
		))
	end)
end

return Combat
