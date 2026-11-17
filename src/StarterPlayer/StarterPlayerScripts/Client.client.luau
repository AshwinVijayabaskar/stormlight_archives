-- Stormlight Archives: console-style combat HUD, deployment screen, surge input.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local StarterGui = game:GetService('StarterGui')

local Config = require(ReplicatedStorage:WaitForChild('Shared'):WaitForChild('Config'))
local remotes = ReplicatedStorage:WaitForChild('Remotes')
local SelectClass = remotes:WaitForChild('SelectClass')
local UseAbility = remotes:WaitForChild('UseAbility')
local DrawStormlight = remotes:WaitForChild('DrawStormlight')
local Notify = remotes:WaitForChild('Notify')

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

local theme = {
	bg = Color3.fromRGB(5, 8, 14),
	panel = Color3.fromRGB(11, 16, 26),
	solid = Color3.fromRGB(8, 12, 20),
	track = Color3.fromRGB(26, 34, 50),
	line = Color3.fromRGB(46, 64, 94),
	text = Color3.fromRGB(228, 238, 252),
	dim = Color3.fromRGB(126, 146, 176),
	storm = Color3.fromRGB(126, 216, 255),
	void = Color3.fromRGB(186, 106, 255),
	gold = Color3.fromRGB(226, 190, 110),
}

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in props do
		if key ~= 'Parent' then
			object[key] = value
		end
	end
	object.Parent = parent
	return object
end

local function box(props, parent)
	local object = make('Frame', props, parent)
	object.BorderSizePixel = 0
	return object
end

local function label(props, parent)
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
	props.BorderSizePixel = 0
	if not props.Font then
		props.Font = Enum.Font.GothamMedium
	end
	return make('TextLabel', props, parent)
end

local function line(parent, color, thickness)
	local stroke = Instance.new('UIStroke')
	stroke.Color = color or theme.line
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function round(object, radius)
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, radius or 2)
	corner.Parent = object
	return corner
end

local gui = make('ScreenGui', {
	Name = 'StormlightHUD',
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

-- Cinematic fades
local topFade = box({ Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.28 }, gui)
make('UIGradient', {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, topFade)

local bottomFade = box({ Size = UDim2.new(1, 0, 0, 200), Position = UDim2.new(0, 0, 1, -200), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.3 }, gui)
make('UIGradient', {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	}),
}, bottomFade)

local crosshair = box({ Size = UDim2.new(0, 3, 0, 3), Position = UDim2.new(0.5, -1, 0.5, -1), BackgroundColor3 = theme.storm, BackgroundTransparency = 0.25 }, gui)
round(crosshair, 2)

-- Match header
local header = box({ Size = UDim2.new(0, 800, 0, 56), Position = UDim2.new(0.5, -400, 0, 16), BackgroundColor3 = theme.solid, BackgroundTransparency = 0.2 }, gui)
local headerLine = line(header, theme.line, 1)

local function teamBlock(alignRight, color, title)
	local block = box({
		Size = UDim2.new(0, 250, 1, 0),
		Position = alignRight and UDim2.new(1, -250, 0, 0) or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	}, header)

	local nameLabel = label({
		Size = UDim2.new(1, -22, 0, 12),
		Position = UDim2.new(0, alignRight and 0 or 22, 0, 8),
		Text = title,
		TextSize = 10,
		TextColor3 = theme.dim,
		TextXAlignment = alignRight and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
	}, block)

	local scoreLabel = label({
		Size = UDim2.new(1, -22, 0, 28),
		Position = UDim2.new(0, alignRight and 0 or 22, 0, 20),
		Text = '0',
		TextSize = 26,
		Font = Enum.Font.GothamBold,
		TextColor3 = color,
		TextXAlignment = alignRight and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
	}, block)

	local barTrack = box({
		Size = UDim2.new(1, -22, 0, 3),
		Position = UDim2.new(0, alignRight and 0 or 22, 1, -9),
		BackgroundColor3 = theme.track,
	}, block)

	local barFill = box({ Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = color, BackgroundTransparency = 0.15 }, barTrack)

	return { Name = nameLabel, Score = scoreLabel, Fill = barFill }
end

local radiantBlock = teamBlock(false, Config.Teams.Radiant.Color, 'KNIGHTS RADIANT')
local voidBlock = teamBlock(true, Config.Teams.Void.Color, 'VOIDBRINGERS')

local objectiveRow = box({ Size = UDim2.new(0, 270, 0, 42), Position = UDim2.new(0.5, -135, 0, 7), BackgroundTransparency = 1 }, header)
make('UIListLayout', {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 5),
}, objectiveRow)

local pips = {}

local function buildPips()
	local folder = workspace:FindFirstChild('CapturePoints')
	if not folder then return end

	for _, pip in pips do
		pip.Root:Destroy()
	end
	table.clear(pips)

	for _, part in folder:GetChildren() do
		if part:IsA('BasePart') and part:GetAttribute('Label') then
			local pip = box({ Size = UDim2.new(0, 46, 0, 34), BackgroundColor3 = theme.panel, BackgroundTransparency = 0.1 }, objectiveRow)
			round(pip, 2)
			local pipLine = line(pip, theme.line, 1)
			local pipText = label({
				Size = UDim2.new(1, -4, 0, 10),
				Position = UDim2.new(0, 2, 0, 3),
				Text = string.upper(part.Name),
				TextSize = 8,
				TextColor3 = theme.dim,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, pip)
			local pipBar = box({ Size = UDim2.new(1, -8, 0, 2), Position = UDim2.new(0, 4, 1, -6), BackgroundColor3 = theme.track }, pip)
			local fill = box({ Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = theme.gold }, pipBar)

			table.insert(pips, { Root = pip, Stroke = pipLine, Label = pipText, Fill = fill, Part = part })
		end
	end
end

-- Stormlight gauge
local resourcePanel = box({ Size = UDim2.new(0, 340, 0, 96), Position = UDim2.new(0, 26, 1, -128), BackgroundColor3 = theme.solid, BackgroundTransparency = 0.12 }, gui)
local resourcePanelLine = line(resourcePanel, theme.line, 1)
local resourceEdge = box({ Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = theme.storm }, resourcePanel)

local classTag = label({
	Size = UDim2.new(1, -30, 0, 12),
	Position = UDim2.new(0, 16, 0, 8),
	Text = 'NO ORDER',
	TextSize = 10,
	TextColor3 = theme.dim,
}, resourcePanel)

local resourceName = label({
	Size = UDim2.new(1, -130, 0, 26),
	Position = UDim2.new(0, 16, 0, 22),
	Text = 'STORMLIGHT',
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextColor3 = theme.text,
}, resourcePanel)

local resourceValue = label({
	Size = UDim2.new(0, 110, 0, 28),
	Position = UDim2.new(1, -126, 0, 21),
	Text = '0',
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = theme.storm,
}, resourcePanel)

local segmentRow = box({ Size = UDim2.new(1, -32, 0, 12), Position = UDim2.new(0, 16, 0, 56), BackgroundTransparency = 1 }, resourcePanel)
make('UIListLayout', {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 3),
}, segmentRow)

local segments = {}
for index = 1, 20 do
	local segment = box({ Size = UDim2.new(0, 12, 1, 0), BackgroundColor3 = theme.track, BackgroundTransparency = 0.35 }, segmentRow)
	table.insert(segments, segment)
end

label({ Size = UDim2.new(0, 220, 0, 10), Position = UDim2.new(0, 16, 1, -14), Text = 'F   DRAW LIGHT', TextSize = 9, TextColor3 = theme.dim }, resourcePanel)

-- Surge tiles
local abilityRow = box({
	Size = UDim2.new(0, 0, 0, 96),
	Position = UDim2.new(1, -26, 1, -128),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
}, gui)
make('UIListLayout', {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 6),
}, abilityRow)

local slots = {}
local cooldowns = {}
local showToast = function(message) end
local castAbility

local SLOT_KEYS = { Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.G }
local SLOT_LABELS = { 'Q', 'E', 'R', 'G' }

local function buildSlots(class)
	for _, slot in slots do
		slot.Root:Destroy()
	end
	table.clear(slots)

	for index, abilityId in (class and class.Abilities or {}) do
		local spec = Config.Abilities[abilityId]
		if spec then
			local tile = make('TextButton', {
				Size = UDim2.new(0, 92, 0, 96),
				BackgroundColor3 = theme.solid,
				BackgroundTransparency = 0.1,
				Text = '',
				AutoButtonColor = false,
			}, abilityRow)
			round(tile, 2)
			local tileLine = line(tile, theme.line, 1)
			local tileAccent = box({ Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = theme.storm, BackgroundTransparency = 0.1 }, tile)

			label({ Size = UDim2.new(0, 24, 0, 14), Position = UDim2.new(0, 6, 0, 6), Text = SLOT_LABELS[index] or tostring(index), TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = theme.storm }, tile)
			label({ Size = UDim2.new(0, 34, 0, 12), Position = UDim2.new(1, -40, 0, 7), Text = tostring(spec.Cost), TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = theme.dim }, tile)

			label({
				Size = UDim2.new(1, -12, 0, 42),
				Position = UDim2.new(0, 6, 0, 26),
				Text = string.upper(spec.Name),
				TextSize = 10,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextColor3 = theme.text,
			}, tile)

			local mask = box({
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(3, 5, 9),
				BackgroundTransparency = 0.2,
			}, tile)
			round(mask, 2)

			local cdText = label({ Size = UDim2.new(1, 0, 1, 0), Text = '', TextSize = 18, Font = Enum.Font.GothamBold, TextColor3 = theme.text }, tile)

			tile.MouseButton1Click:Connect(function()
				castAbility(abilityId)
			end)

			table.insert(slots, {
				Root = tile,
				Mask = mask,
				Text = cdText,
				Stroke = tileLine,
				Accent = tileAccent,
				AbilityId = abilityId,
				Spec = spec,
			})
		end
	end

	local count = #slots
	local rowWidth = 0
	if count > 0 then
		rowWidth = count * 92 + (count - 1) * 6
	end
	abilityRow.Size = UDim2.new(0, rowWidth, 0, 96)
end

castAbility = function(abilityId)
	local class = Config.ClassById[player:GetAttribute('ClassId') or '']
	if not class then
		showToast('NO ORDER SELECTED')
		return
	end

	local allowed = false
	for _, id in class.Abilities do
		if id == abilityId then
			allowed = true
		end
	end

	local spec = Config.Abilities[abilityId]
	if not allowed or not spec then
		return
	end

	local remaining = (cooldowns[abilityId] or 0) - os.clock()
	if remaining > 0 then
		showToast(string.upper(spec.Name) .. ' RECHARGING · ' .. math.ceil(remaining) .. 'S')
		return
	end

	if (player:GetAttribute('Stormlight') or 0) < spec.Cost then
		showToast('INSUFFICIENT LIGHT FOR ' .. string.upper(spec.Name))
		return
	end

	cooldowns[abilityId] = os.clock() + spec.Cooldown
	print('[Surge] firing ' .. spec.Name)
	UseAbility:FireServer(abilityId)
end

local weaponReadout = label({
	Size = UDim2.new(0, 300, 0, 12),
	Position = UDim2.new(1, -26, 1, -146),
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = '',
	TextSize = 9,
	TextColor3 = theme.dim,
}, gui)

-- Toast
local toastPanel = box({
	Size = UDim2.new(0, 480, 0, 26),
	Position = UDim2.new(0.5, -240, 1, -172),
	BackgroundColor3 = theme.solid,
	BackgroundTransparency = 0.15,
	Visible = false,
}, gui)
round(toastPanel, 2)
local toastLine = line(toastPanel, theme.gold, 1)
local toastText = label({ Size = UDim2.new(1, 0, 1, 0), Text = '', TextSize = 11, TextColor3 = theme.gold }, toastPanel)

local toastToken = 0

showToast = function(message)
	toastToken = toastToken + 1
	local token = toastToken
	toastText.Text = message
	toastPanel.Visible = true
	task.delay(2.6, function()
		if token == toastToken then
			toastPanel.Visible = false
		end
	end)
end

Notify.OnClientEvent:Connect(function(message)
	showToast(string.upper(tostring(message)))
end)

-- Round banner
local bannerHolder = box({ Size = UDim2.new(0, 720, 0, 90), Position = UDim2.new(0.5, -360, 0.28, 0), BackgroundTransparency = 1, Visible = false }, gui)
box({ Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = theme.gold, BackgroundTransparency = 0.2 }, bannerHolder)
box({ Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = theme.gold, BackgroundTransparency = 0.2 }, bannerHolder)
local banner = label({ Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 24), Text = '', TextSize = 30, Font = Enum.Font.GothamBold, TextColor3 = theme.gold, TextXAlignment = Enum.TextXAlignment.Center }, bannerHolder)

-- Deployment screen
local deployScreen = box({ Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.bg, BackgroundTransparency = 0.03, Visible = false }, gui)
local awaitingClass = true
local selectedId = nil

local titleBar = box({ Size = UDim2.new(1, 0, 0, 78), BackgroundColor3 = theme.solid, BackgroundTransparency = 0.35 }, deployScreen)
box({ Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = theme.gold, BackgroundTransparency = 0.1 }, titleBar)
local titleText = label({ Size = UDim2.new(0, 640, 0, 30), Position = UDim2.new(0, 40, 0, 16), Text = 'STORMLIGHT ARCHIVES', TextSize = 24, Font = Enum.Font.GothamBold, TextColor3 = theme.gold }, titleBar)
local subtitle = label({ Size = UDim2.new(0, 640, 0, 14), Position = UDim2.new(0, 42, 0, 48), Text = '', TextSize = 10, TextColor3 = theme.dim }, titleBar)
local scoreRead = label({ Size = UDim2.new(0, 300, 0, 30), Position = UDim2.new(1, -340, 0, 24), Text = 'SCORE 0', TextSize = 18, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = theme.text }, titleBar)

local detail = box({ Size = UDim2.new(0, 330, 1, -190), Position = UDim2.new(0, 40, 0, 96), BackgroundColor3 = theme.panel, BackgroundTransparency = 0.2 }, deployScreen)
local detailLine = line(detail, theme.line, 1)
local detailEdge = box({ Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = theme.gold, BackgroundTransparency = 0.1 }, detail)

label({ Size = UDim2.new(1, -32, 0, 12), Position = UDim2.new(0, 18, 0, 14), Text = 'SELECTED ORDER', TextSize = 9, TextColor3 = theme.dim }, detail)
local detailName = label({ Size = UDim2.new(1, -32, 0, 30), Position = UDim2.new(0, 16, 0, 28), Text = 'NONE', TextSize = 20, Font = Enum.Font.GothamBold, TextColor3 = theme.text }, detail)
local detailMeta = label({ Size = UDim2.new(1, -32, 0, 14), Position = UDim2.new(0, 16, 0, 60), Text = '', TextSize = 10, TextColor3 = theme.storm }, detail)
local detailBlurb = label({
	Size = UDim2.new(1, -32, 0, 56),
	Position = UDim2.new(0, 16, 0, 82),
	Text = 'Select a class to inspect its surges.',
	TextSize = 10,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = theme.dim,
}, detail)

label({ Size = UDim2.new(1, -32, 0, 12), Position = UDim2.new(0, 16, 0, 146), Text = 'SURGES', TextSize = 9, TextColor3 = theme.dim }, detail)
local surgeHolder = box({ Size = UDim2.new(1, -32, 1, -250), Position = UDim2.new(0, 16, 0, 164), BackgroundTransparency = 1 }, detail)
make('UIListLayout', { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 10) }, surgeHolder)

local deployButton = make('TextButton', {
	Size = UDim2.new(1, -32, 0, 50),
	Position = UDim2.new(0, 16, 1, -66),
	BackgroundColor3 = theme.track,
	Text = 'SELECT A CLASS',
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextColor3 = theme.dim,
	AutoButtonColor = false,
}, detail)
round(deployButton, 2)
local deployStroke = line(deployButton, theme.line, 1)

local gridHolder = box({ Size = UDim2.new(1, -420, 1, -190), Position = UDim2.new(0, 396, 0, 96), BackgroundTransparency = 1 }, deployScreen)
local scroll = make('ScrollingFrame', {
	Size = UDim2.new(1, 0, 1, -40),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = theme.line,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, gridHolder)
make('UIGridLayout', { CellSize = UDim2.new(0, 208, 0, 104), CellPadding = UDim2.new(0, 8, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

label({
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 0, 1, -20),
	Text = 'Q E R G  SURGES        F  DRAW LIGHT        M  LOADOUT        ENTER  DEPLOY',
	TextSize = 9,
	TextColor3 = theme.dim,
}, gridHolder)

local cards = {}

local function clearHolder(holder)
	for _, child in holder:GetChildren() do
		if not child:IsA('UIListLayout') then
			child:Destroy()
		end
	end
end

local function refreshDeployButton()
	if not selectedId then
		deployButton.BackgroundColor3 = theme.track
		deployButton.TextColor3 = theme.dim
		deployButton.Text = 'SELECT A CLASS'
		deployStroke.Color = theme.line
		return
	end

	local class = Config.ClassById[selectedId]
	local locked = class.Hero == true and (player:GetAttribute('Score') or 0) < Config.Mode.HeroScoreRequired

	if locked then
		deployButton.BackgroundColor3 = theme.track
		deployButton.TextColor3 = theme.gold
		deployButton.Text = 'REQUIRES ' .. Config.Mode.HeroScoreRequired .. ' SCORE'
		deployStroke.Color = theme.gold
	else
		deployButton.BackgroundColor3 = theme.storm
		deployButton.TextColor3 = theme.bg
		deployButton.Text = 'DEPLOY'
		deployStroke.Color = theme.storm
	end
end

local function setSelected(classId)
	selectedId = classId
	local class = Config.ClassById[classId]

	for _, card in cards do
		local active = card.Class.Id == classId
		card.Stroke.Color = active and theme.storm or (card.Class.Hero and theme.gold or theme.line)
		card.Stroke.Thickness = active and 2 or 1
		card.Root.BackgroundTransparency = active and 0.02 or 0.15
	end

	if not class then
		detailName.Text = 'NONE'
		detailMeta.Text = ''
		return
	end

	detailName.Text = string.upper(class.Name)
	detailMeta.Text = string.upper(class.Role) .. '   ·   HP ' .. class.Health .. '   ·   SPD ' .. class.WalkSpeed
	detailBlurb.Text = class.Blurb

	clearHolder(surgeHolder)

	for _, abilityId in class.Abilities do
		local spec = Config.Abilities[abilityId]
		if spec then
			local row = box({ Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, surgeHolder)
			label({ Size = UDim2.new(0.62, 0, 0, 14), Text = string.upper(spec.Name), TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = theme.storm }, row)
			label({ Size = UDim2.new(0.38, 0, 0, 14), Position = UDim2.new(0.62, 0, 0, 0), Text = spec.Cost .. ' LIGHT · ' .. spec.Cooldown .. 'S', TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = theme.dim }, row)
			label({ Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 16), Text = spec.Blurb, TextSize = 9, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = theme.dim }, row)
		end
	end

	refreshDeployButton()
end

local function buildCards(side)
	for _, card in cards do
		card.Root:Destroy()
	end
	table.clear(cards)

	for index, class in Config.ClassList[side] do
		local isHero = class.Hero == true
		local root = make('TextButton', {
			Size = UDim2.new(0, 208, 0, 104),
			LayoutOrder = index,
			BackgroundColor3 = theme.panel,
			BackgroundTransparency = 0.15,
			Text = '',
			AutoButtonColor = false,
		}, scroll)
		round(root, 2)
		local rootStroke = line(root, isHero and theme.gold or theme.line, 1)

		label({ Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 6), Text = string.upper(class.Name), TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = isHero and theme.gold or theme.text }, root)
		label({ Size = UDim2.new(1, -16, 0, 12), Position = UDim2.new(0, 8, 0, 24), Text = string.upper(class.Role) .. ' · HP ' .. class.Health .. ' · SPD ' .. class.WalkSpeed, TextSize = 8, TextColor3 = theme.dim }, root)

		local names = {}
		for _, abilityId in class.Abilities do
			local spec = Config.Abilities[abilityId]
			if spec then
				table.insert(names, string.upper(spec.Name))
			end
		end

		label({
			Size = UDim2.new(1, -16, 0, 12),
			Position = UDim2.new(0, 8, 0, 42),
			Text = table.concat(names, '  /  '),
			TextSize = 8,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = isHero and theme.gold or theme.storm,
		}, root)

		if isHero then
			label({ Size = UDim2.new(1, -16, 0, 12), Position = UDim2.new(0, 8, 1, -18), Text = 'HERO · ' .. Config.Mode.HeroScoreRequired .. ' SCORE', TextSize = 8, TextColor3 = theme.gold }, root)
		end

		table.insert(cards, { Root = root, Stroke = rootStroke, Class = class })

		root.MouseButton1Click:Connect(function()
			setSelected(class.Id)
		end)
	end
end

local function requestDeploy()
	if not selectedId then
		showToast('SELECT A CLASS FIRST')
		return
	end

	local class = Config.ClassById[selectedId]
	if class.Hero and (player:GetAttribute('Score') or 0) < Config.Mode.HeroScoreRequired then
		showToast('REACH ' .. Config.Mode.HeroScoreRequired .. ' SCORE FOR HEROES')
		return
	end

	awaitingClass = false
	SelectClass:FireServer(selectedId)
	deployScreen.Visible = false
end

deployButton.MouseButton1Click:Connect(requestDeploy)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.F then
		DrawStormlight:FireServer()
		return
	end

	if input.KeyCode == Enum.KeyCode.M then
		deployScreen.Visible = not deployScreen.Visible
		return
	end

	if input.KeyCode == Enum.KeyCode.Return and deployScreen.Visible then
		requestDeploy()
		return
	end

	for index, key in SLOT_KEYS do
		if input.KeyCode == key then
			local slot = slots[index]
			if slot then
				castAbility(slot.AbilityId)
			end
			return
		end
	end
end)

local function onCharacter(character)
	local humanoid = character:WaitForChild('Humanoid', 10)
	if humanoid then
		humanoid.Died:Connect(function()
			awaitingClass = true
			task.wait(1)
			deployScreen.Visible = true
		end)
	end

	buildSlots(Config.ClassById[player:GetAttribute('ClassId') or ''])
	deployScreen.Visible = awaitingClass
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end

local lastClassId = nil
local lastSide = nil
local lastHeroScore = -1

RunService.Heartbeat:Connect(function()
	local side = player:GetAttribute('Side') or 'Radiant'
	local teamSpec = Config.Teams[side]
	local classId = player:GetAttribute('ClassId') or ''
	local class = Config.ClassById[classId]

	if side ~= lastSide then
		lastSide = side
		buildCards(side)
		buildPips()
		radiantBlock.Name.Text = string.upper(Config.Teams.Radiant.Name)
		voidBlock.Name.Text = string.upper(Config.Teams.Void.Name)
		subtitle.Text = string.upper(teamSpec.Name) .. '   ·   ' .. string.upper(teamSpec.Resource) .. ' LOADOUT'
		detailEdge.BackgroundColor3 = teamSpec.Color
	end

	if classId ~= lastClassId then
		lastClassId = classId
		buildSlots(class)
		classTag.Text = class and string.upper(class.Name) or 'NO ORDER'
	end

	local current = player:GetAttribute('Stormlight') or 0
	local max = player:GetAttribute('MaxStormlight') or Config.Stormlight.Max

	resourceName.Text = string.upper(teamSpec.Resource)
	resourceValue.Text = tostring(math.floor(current))
	resourceValue.TextColor3 = teamSpec.Color
	resourceEdge.BackgroundColor3 = teamSpec.Color

	local filled = math.floor((current / max) * #segments + 0.5)
	for index, segment in segments do
		segment.BackgroundColor3 = index <= filled and teamSpec.Color or theme.track
		segment.BackgroundTransparency = index <= filled and 0.1 or 0.4
	end

	if class then
		local weapon = Config.Weapons[class.Weapon]
		if weapon then
			weaponReadout.Text = string.upper(class.Weapon) .. '   ·   ' .. weapon.Damage .. ' DMG   ·   ' .. weapon.Range .. ' STUDS'
		end
	end

	local score = player:GetAttribute('Score') or 0
	scoreRead.Text = 'SCORE ' .. score

	local radiantTickets = workspace:GetAttribute('RadiantTickets') or 0
	local voidTickets = workspace:GetAttribute('VoidTickets') or 0
	local startTickets = Config.Mode.StartingTickets

	radiantBlock.Score.Text = tostring(radiantTickets)
	voidBlock.Score.Text = tostring(voidTickets)
	radiantBlock.Fill.Size = UDim2.new(math.clamp(radiantTickets / startTickets, 0, 1), 0, 1, 0)
	voidBlock.Fill.Size = UDim2.new(math.clamp(voidTickets / startTickets, 0, 1), 0, 1, 0)

	local winner = workspace:GetAttribute('Winner') or ''
	if winner ~= '' then
		local winnerSpec = Config.Teams[winner]
		bannerHolder.Visible = true
		banner.Text = winnerSpec and (string.upper(winnerSpec.Name) .. ' HOLD THE FIELD') or 'ROUND OVER'
		banner.TextColor3 = winnerSpec and winnerSpec.Color or theme.gold
	else
		bannerHolder.Visible = false
	end

	for _, slot in slots do
		local remaining = (cooldowns[slot.AbilityId] or 0) - os.clock()
		if remaining > 0 then
			slot.Mask.Size = UDim2.new(1, 0, math.clamp(remaining / slot.Spec.Cooldown, 0, 1), 0)
			slot.Text.Text = tostring(math.ceil(remaining))
			slot.Accent.BackgroundColor3 = theme.dim
		else
			slot.Mask.Size = UDim2.new(1, 0, 0, 0)
			slot.Text.Text = ''
			slot.Accent.BackgroundColor3 = teamSpec.Color
		end
		slot.Stroke.Color = current >= slot.Spec.Cost and theme.line or Color3.fromRGB(92, 46, 46)
	end

	for _, pip in pips do
		local owner = pip.Part:GetAttribute('Owner') or 'Neutral'
		local progress = pip.Part:GetAttribute('Progress') or 0
		pip.Fill.Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
		if owner == 'Neutral' then
			pip.Fill.BackgroundColor3 = theme.gold
			pip.Stroke.Color = progress > 0.02 and theme.gold or theme.line
			pip.Label.TextColor3 = theme.dim
		else
			local ownerColor = Config.Teams[owner].Color
			pip.Fill.BackgroundColor3 = ownerColor
			pip.Stroke.Color = ownerColor
			pip.Label.TextColor3 = ownerColor
		end
	end

	if selectedId and score ~= lastHeroScore then
		lastHeroScore = score
		refreshDeployButton()
	end
end)

print('[Stormlight Archives] client HUD ready')
