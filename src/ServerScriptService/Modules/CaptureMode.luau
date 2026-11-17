-- Supremacy: hold command posts, bleed the enemy tickets, break their army.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared.Config)
local Core = require(script.Parent.Core)

local CaptureMode = {}

local points = {}
local tickets = { Radiant = Config.Mode.StartingTickets, Void = Config.Mode.StartingTickets }
local finished = false

local function publishTickets()
	workspace:SetAttribute('RadiantTickets', math.max(0, math.floor(tickets.Radiant)))
	workspace:SetAttribute('VoidTickets', math.max(0, math.floor(tickets.Void)))
end

local function publishPoints()
	for _, point in points do
		local part = point.Part
		part:SetAttribute('Owner', point.Owner)
		part:SetAttribute('Progress', point.Progress)

		local spire = part:FindFirstChild('Spire')
		if spire then
			local team = Config.Teams[point.Owner]
			local color = team and team.Color or Color3.fromRGB(226, 190, 110)
			spire.Color = color

			local light = spire:FindFirstChildOfClass('PointLight')
			if light then
				light.Color = color
			end

			local sparkles = spire:FindFirstChildOfClass('Sparkles')
			if sparkles then
				sparkles.Color = color
			end

			local beam = part:FindFirstChild('Beam')
			if beam then
				beam.Color = color
			end
		end
	end
end

local function playersOnPoint(part)
	local counts = { Radiant = 0, Void = 0 }

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = Core.humanoidOf(character)
		local root = Core.rootOf(character)

		if humanoid and root and humanoid.Health > 0 then
			if (root.Position - part.Position).Magnitude <= Config.Mode.CaptureRadius then
				local side = Core.sideOf(player)
				if counts[side] then
					counts[side] = counts[side] + 1
				end
			end
		end
	end

	return counts
end

function CaptureMode.awardCapture(side, point)
	for _, player in Players:GetPlayers() do
		if Core.sideOf(player) == side then
			local root = Core.rootOf(player.Character)
			if root and (root.Position - point.Part.Position).Magnitude <= Config.Mode.CaptureRadius then
				player:SetAttribute('Score', (player:GetAttribute('Score') or 0) + Config.Scoring.Capture)
			end
		end
	end
end

function CaptureMode.onKill(victimSide)
	if finished then return end
	if tickets[victimSide] then
		tickets[victimSide] = tickets[victimSide] - Config.Mode.KillTicketCost
		publishTickets()
	end
end

function CaptureMode.tickets()
	return tickets.Radiant, tickets.Void
end

function CaptureMode.resetRound()
	tickets.Radiant = Config.Mode.StartingTickets
	tickets.Void = Config.Mode.StartingTickets
	finished = false
	workspace:SetAttribute('Winner', '')

	for _, point in points do
		point.Owner = 'Neutral'
		point.Progress = 0
	end

	publishTickets()
	publishPoints()

	for _, player in Players:GetPlayers() do
		player:LoadCharacter()
	end
end

function CaptureMode.start()
	task.spawn(function()
		local step = 0.5

		while true do
			task.wait(step)

			if not finished then
				local held = { Radiant = 0, Void = 0 }
				local rate = step / Config.Mode.CaptureSeconds

				for _, point in points do
					local counts = playersOnPoint(point.Part)
					local attackers = nil

					if counts.Radiant > 0 and counts.Void == 0 then
						attackers = 'Radiant'
					elseif counts.Void > 0 and counts.Radiant == 0 then
						attackers = 'Void'
					end

					if attackers then
						if point.Owner == attackers then
							point.Progress = math.max(0, point.Progress - rate)
						else
							point.Progress = point.Progress + rate
							if point.Progress >= 1 then
								point.Progress = 0
								point.Owner = attackers
								CaptureMode.awardCapture(attackers, point)
							end
						end
					else
						point.Progress = math.max(0, point.Progress - rate * 0.5)
					end

					if point.Owner == 'Radiant' then
						held.Radiant = held.Radiant + 1
					elseif point.Owner == 'Void' then
						held.Void = held.Void + 1
					end
				end

				if held.Radiant > 0 then
					tickets.Void = tickets.Void - held.Radiant * Config.Mode.DrainPerPointPerSecond * step
				end
				if held.Void > 0 then
					tickets.Radiant = tickets.Radiant - held.Void * Config.Mode.DrainPerPointPerSecond * step
				end

				publishTickets()
				publishPoints()

				if tickets.Radiant <= 0 or tickets.Void <= 0 then
					finished = true
					local winner = 'Radiant'
					if tickets.Radiant <= 0 then
						winner = 'Void'
					end
					workspace:SetAttribute('Winner', winner)
					task.delay(12, CaptureMode.resetRound)
				end
			end
		end
	end)
end

function CaptureMode.init()
	points = {}

	local folder = workspace:FindFirstChild('CapturePoints')
	if folder then
		for _, part in folder:GetChildren() do
			if part:IsA('BasePart') and part:GetAttribute('Label') then
				table.insert(points, {
					Part = part,
					Label = part:GetAttribute('Label') or part.Name,
					Owner = 'Neutral',
					Progress = 0,
				})
			end
		end
	end

	workspace:SetAttribute('Winner', '')
	publishTickets()
	publishPoints()
	CaptureMode.start()
end

return CaptureMode
