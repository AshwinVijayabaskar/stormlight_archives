-- Stormlight Archives: server bootstrap. Teams, remotes, surges, war mode.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local Teams = game:GetService('Teams')

local Config = require(ReplicatedStorage:WaitForChild('Shared'):WaitForChild('Config'))
local Modules = ServerScriptService:WaitForChild('Modules')
local Core = require(Modules:WaitForChild('Core'))
local Stormlight = require(Modules:WaitForChild('Stormlight'))
local Abilities = require(Modules:WaitForChild('Abilities'))
local Combat = require(Modules:WaitForChild('Combat'))
local Loadout = require(Modules:WaitForChild('Loadout'))
local CaptureMode = require(Modules:WaitForChild('CaptureMode'))

local function ensureTeam(key)
	local spec = Config.Teams[key]
	local team = Teams:FindFirstChild(spec.Name)
	if not team then
		team = Instance.new('Team')
		team.Name = spec.Name
		team.TeamColor = spec.Brick
		team.AutoAssignable = false
		team.Parent = Teams
	end
	return team
end

local teamBySide = {
	Radiant = ensureTeam('Radiant'),
	Void = ensureTeam('Void'),
}

local remotes = ReplicatedStorage:WaitForChild('Remotes')

local function ensureRemote(name)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local newRemote = Instance.new('RemoteEvent')
	newRemote.Name = name
	newRemote.Parent = remotes
	return newRemote
end

local SelectClass = ensureRemote('SelectClass')
local UseAbility = ensureRemote('UseAbility')
local DrawStormlight = ensureRemote('DrawStormlight')
local Notify = ensureRemote('Notify')

local function pickSide()
	local radiant = 0
	local void = 0

	for _, player in Players:GetPlayers() do
		local side = player:GetAttribute('Side')
		if side == 'Radiant' then
			radiant = radiant + 1
		elseif side == 'Void' then
			void = void + 1
		end
	end

	if radiant <= void then
		return 'Radiant'
	end
	return 'Void'
end

local function onCharacter(player, character)
	character:WaitForChild('Humanoid', 10)
	Loadout.apply(player)
end

local function onPlayerAdded(player)
	if not player:GetAttribute('Side') then
		local side = pickSide()
		player:SetAttribute('Side', side)
		player:SetAttribute('ClassId', Loadout.defaultClass(side))
		player:SetAttribute('Score', 0)
		player.Team = teamBySide[side]
		player.TeamColor = Config.Teams[side].Brick
		Stormlight.setup(player)
	end

	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)

	if player.Character then
		onCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

SelectClass.OnServerEvent:Connect(function(player, classId)
	if type(classId) ~= 'string' then return end

	local ok, reason = Loadout.selectClass(player, classId)
	if ok then
		Loadout.deploy(player)
	else
		Notify:FireClient(player, reason or 'Cannot deploy')
	end
end)

UseAbility.OnServerEvent:Connect(function(player, abilityId)
	if type(abilityId) ~= 'string' then return end

	local class = Config.ClassById[player:GetAttribute('ClassId') or '']
	if not class then return end

	local allowed = false
	for _, id in class.Abilities do
		if id == abilityId then
			allowed = true
		end
	end
	if not allowed then return end

	if not Core.alive(player) then return end

	local ok, reason = Abilities.use(player, abilityId)
	print(string.format('[Surge] %s -> %s ok=%s (%s)', player.Name, abilityId, tostring(ok), tostring(reason)))
	if not ok and reason then
		Notify:FireClient(player, reason)
	end
end)

DrawStormlight.OnServerEvent:Connect(function(player)
	if not Core.alive(player) then return end
	if not Stormlight.draw(player) then
		Notify:FireClient(player, 'Not enough light to draw')
	end
end)

Combat.onDeath = function(victimPlayer, attackerPlayer)
	if attackerPlayer and victimPlayer and attackerPlayer ~= victimPlayer then
		attackerPlayer:SetAttribute('Score', (attackerPlayer:GetAttribute('Score') or 0) + Config.Scoring.Kill)
	end

	if victimPlayer then
		local side = victimPlayer:GetAttribute('Side')
		if side then
			CaptureMode.onKill(side)
		end

		local class = Config.ClassById[victimPlayer:GetAttribute('ClassId') or '']
		if class and class.Hero then
			Loadout.releaseHero(victimPlayer)
			victimPlayer:SetAttribute('ClassId', Loadout.defaultClass(side))
		end

		task.delay(Config.Mode.RespawnSeconds, function()
			if victimPlayer.Parent and not Core.alive(victimPlayer) then
				victimPlayer:LoadCharacter()
			end
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	Loadout.releaseHero(player)
end)

Stormlight.start()
CaptureMode.init()

-- Keep the class weapon in hand: number-key tool toggles would otherwise leave
-- a player unable to attack.
task.spawn(function()
	while true do
		task.wait(2)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = Core.humanoidOf(character)
			if humanoid and humanoid.Health > 0 then
				local inHand = character:FindFirstChildOfClass('Tool')
				if not inHand then
					local backpack = player:FindFirstChildOfClass('Backpack')
					local tool = backpack and backpack:FindFirstChildOfClass('Tool')
					if tool then
						humanoid:EquipTool(tool)
					end
				end
			end
		end
	end
end)

print('[Stormlight Archives] server ready: ' .. #Config.Classes .. ' classes, ' .. #Config.ClassList.Radiant .. ' Radiant, ' .. #Config.ClassList.Void .. ' Voidbringer')
