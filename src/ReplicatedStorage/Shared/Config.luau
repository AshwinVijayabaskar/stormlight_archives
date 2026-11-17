-- Stormlight Archives: shared data for classes, surges, weapons and the war.
-- Client (spawn screen, HUD) and server (loadouts, combat, capture) both read this.

local Config = {}

Config.Teams = {
	Radiant = {
		Name = 'Knights Radiant',
		Color = Color3.fromRGB(64, 138, 232),
		Brick = BrickColor.new('Bright blue'),
		Resource = 'Stormlight',
	},
	Void = {
		Name = 'Voidbringers',
		Color = Color3.fromRGB(160, 66, 214),
		Brick = BrickColor.new('Bright violet'),
		Resource = 'Voidlight',
	},
}

Config.Mode = {
	StartingTickets = 400,
	CaptureSeconds = 6,
	DrainPerPointPerSecond = 1.5,
	KillTicketCost = 3,
	RoundSeconds = 900,
	CaptureRadius = 26,
	HeroScoreRequired = 400,
	RespawnSeconds = 5,
}

Config.Scoring = {
	Kill = 25,
	Capture = 15,
	Assist = 10,
}

Config.Stormlight = {
	Max = 100,
	Start = 60,
	Regen = 1.3,
	HealPerSecond = 2,
	DrawCost = 30,
	DrawSpeedBonus = 6,
	DrawSeconds = 4,
	GemAmount = 25,
	GemRadius = 9,
	GemRespawn = 18,
}

Config.Weapons = {
	Fists = { Damage = 12, Range = 6, Cooldown = 0.45, Kind = 'melee' },
	Dagger = { Damage = 26, Range = 7, Cooldown = 0.5, Kind = 'melee' },
	Spear = { Damage = 22, Range = 10, Cooldown = 0.8, Kind = 'melee' },
	Shardblade = { Damage = 55, Range = 12, Cooldown = 1.1, Kind = 'melee' },
	Shardhammer = { Damage = 34, Range = 8, Cooldown = 1.0, Kind = 'melee', Knockback = 45 },
	Bow = { Damage = 28, Range = 220, Cooldown = 1.0, Kind = 'ranged' },
	Voidlash = { Damage = 30, Range = 170, Cooldown = 0.9, Kind = 'ranged' },
}

Config.Abilities = {
	-- Knights Radiant surges
	Lashing = { Name = 'Lashing', Cost = 25, Cooldown = 8, Blurb = 'Lash yourself into the sky on a ribbon of stormlight.' },
	Adhesion = { Name = 'Adhesion', Cost = 15, Cooldown = 10, Blurb = 'Bind a foe to the ground with a full lashing.' },
	Division = { Name = 'Division', Cost = 30, Cooldown = 9, Blurb = 'Burn a foe with the surge of Division.' },
	Abrasion = { Name = 'Abrasion', Cost = 15, Cooldown = 7, Blurb = 'Slide frictionless across stone.' },
	Progression = { Name = 'Progression', Cost = 30, Cooldown = 8, Blurb = 'Regrow flesh: heal yourself and nearby Radiants.' },
	Illumination = { Name = 'Illumination', Cost = 25, Cooldown = 10, Blurb = 'Lightweave a cloak of shadow around yourself.' },
	Transformation = { Name = 'Transformation', Cost = 35, Cooldown = 12, Blurb = 'Soulcast the ground beneath a foe and slow them.' },
	Transportation = { Name = 'Transportation', Cost = 25, Cooldown = 9, Blurb = 'Elsecall forward in a flash of light.' },
	Cohesion = { Name = 'Cohesion', Cost = 25, Cooldown = 10, Blurb = 'Soften stone and grip every enemy near you.' },
	Tension = { Name = 'Tension', Cost = 30, Cooldown = 12, Blurb = 'Raise a wall of taut stone.' },
	SquireOath = { Name = 'Squire Oath', Cost = 20, Cooldown = 12, Blurb = 'Rally Radiants nearby with stormlight and shield.' },
	-- Voidbringer forms and rhythms
	WarShock = { Name = 'Rhythm of War', Cost = 25, Cooldown = 8, Blurb = 'Shockwave of warform carapace and hammer.' },
	Stormcall = { Name = 'Stormcall', Cost = 30, Cooldown = 9, Blurb = 'Call a bolt of the Everstorm down your sightline.' },
	NimbleDash = { Name = 'Nimble Dash', Cost = 15, Cooldown = 6, Blurb = 'Nimbleform burst of speed.' },
	Barricade = { Name = 'Barricade', Cost = 25, Cooldown = 12, Blurb = 'Raise a workform barricade.' },
	RhythmAura = { Name = 'War Rhythm', Cost = 25, Cooldown = 12, Blurb = 'Sing a rhythm that empowers nearby singers.' },
	PrecisionShot = { Name = 'Focused Shot', Cost = 20, Cooldown = 8, Blurb = 'Scholarform voidlight shot down a long sightline.' },
	SmokeCloud = { Name = 'Smoke Veil', Cost = 20, Cooldown = 10, Blurb = 'Smokeform veil to break line of sight.' },
	DecayAura = { Name = 'Decay', Cost = 30, Cooldown = 10, Blurb = 'Rot aura: enemies nearby wither over time.' },
	ShadowStep = { Name = 'Shadow Step', Cost = 25, Cooldown = 9, Blurb = 'Nightform blink behind the nearest foe.' },
	BattleCharge = { Name = 'Battle Charge', Cost = 20, Cooldown = 8, Blurb = 'Dullform charge: speed and grit.' },
	VoidlightBurn = { Name = 'Voidlight Burn', Cost = 25, Cooldown = 8, Blurb = 'Burn voidlight to mend and empower yourself.' },
}

Config.Classes = {
	-- Knights Radiant: ten orders and their squires
	{ Id = 'Windrunner', Name = 'Windrunner', Side = 'Radiant', Role = 'Assault', Health = 115, WalkSpeed = 18, JumpPower = 56, Weapon = 'Spear', Abilities = { 'Lashing', 'Adhesion' }, Blurb = 'Life before death. Lash the foe into the sky and pin them there.' },
	{ Id = 'Skybreaker', Name = 'Skybreaker', Side = 'Radiant', Role = 'Vanguard', Health = 125, WalkSpeed = 17, JumpPower = 52, Weapon = 'Shardblade', Abilities = { 'Lashing', 'Division' }, Blurb = 'I swear to the law before the law. Pursue the guilty without pause.' },
	{ Id = 'Dustbringer', Name = 'Dustbringer', Side = 'Radiant', Role = 'Demolition', Health = 105, WalkSpeed = 17, JumpPower = 52, Weapon = 'Shardhammer', Abilities = { 'Division', 'Abrasion' }, Blurb = 'Releaser. Spark the division that breaks an enemy line.' },
	{ Id = 'Edgedancer', Name = 'Edgedancer', Side = 'Radiant', Role = 'Medic', Health = 100, WalkSpeed = 20, JumpPower = 54, Weapon = 'Spear', Abilities = { 'Abrasion', 'Progression' }, Blurb = 'I will remember those who have been forgotten.' },
	{ Id = 'Truthwatcher', Name = 'Truthwatcher', Side = 'Radiant', Role = 'Support', Health = 100, WalkSpeed = 16, JumpPower = 50, Weapon = 'Bow', Abilities = { 'Progression', 'Illumination' }, Blurb = 'See what is, and what could be, then mend it.' },
	{ Id = 'Lightweaver', Name = 'Lightweaver', Side = 'Radiant', Role = 'Infiltrator', Health = 95, WalkSpeed = 19, JumpPower = 54, Weapon = 'Spear', Abilities = { 'Illumination', 'Transformation' }, Blurb = 'Lie so well the world believes you.' },
	{ Id = 'Elsecaller', Name = 'Elsecaller', Side = 'Radiant', Role = 'Soulcaster', Health = 110, WalkSpeed = 16, JumpPower = 50, Weapon = 'Shardblade', Abilities = { 'Transformation', 'Transportation' }, Blurb = 'Journey before destination. Soulcast, then step between places.' },
	{ Id = 'Willshaper', Name = 'Willshaper', Side = 'Radiant', Role = 'Breacher', Health = 118, WalkSpeed = 17, JumpPower = 52, Weapon = 'Shardhammer', Abilities = { 'Transportation', 'Cohesion' }, Blurb = 'Free the stone and it will free the way.' },
	{ Id = 'Stoneward', Name = 'Stoneward', Side = 'Radiant', Role = 'Defender', Health = 135, WalkSpeed = 15, JumpPower = 48, Weapon = 'Shardhammer', Abilities = { 'Cohesion', 'Tension' }, Blurb = 'I will stand where others fall.' },
	{ Id = 'Bondsmith', Name = 'Bondsmith', Side = 'Radiant', Role = 'Commander', Health = 130, WalkSpeed = 15, JumpPower = 48, Weapon = 'Spear', Abilities = { 'Tension', 'Adhesion' }, Blurb = 'Unity binds armies. Bind them and hold the line.' },
	{ Id = 'Squire', Name = 'Squire', Side = 'Radiant', Role = 'Trooper', Health = 110, WalkSpeed = 17, JumpPower = 52, Weapon = 'Spear', Abilities = { 'SquireOath' }, Blurb = 'No spren yet, only oathtaking. Hold what your Radiant holds.' },
	-- Voidbringers: singer forms, regals and fused-touched
	{ Id = 'Warform', Name = 'Warform', Side = 'Void', Role = 'Assault', Health = 125, WalkSpeed = 16, JumpPower = 48, Weapon = 'Shardhammer', Abilities = { 'WarShock' }, Blurb = 'Rhythm of war. Carapace armor and a singer hammer.' },
	{ Id = 'Stormform', Name = 'Stormform', Side = 'Void', Role = 'Artillery', Health = 105, WalkSpeed = 17, JumpPower = 52, Weapon = 'Voidlash', Abilities = { 'Stormcall' }, Blurb = 'Red eyes, storm inside. Call the Everstorm down a sightline.' },
	{ Id = 'Nimbleform', Name = 'Nimbleform', Side = 'Void', Role = 'Scout', Health = 95, WalkSpeed = 21, JumpPower = 56, Weapon = 'Spear', Abilities = { 'NimbleDash' }, Blurb = 'Quick of foot and hand, first into every gap.' },
	{ Id = 'Workform', Name = 'Workform', Side = 'Void', Role = 'Engineer', Health = 140, WalkSpeed = 14, JumpPower = 46, Weapon = 'Shardhammer', Abilities = { 'Barricade' }, Blurb = 'Build the barricade, then hold it with your weight.' },
	{ Id = 'Artform', Name = 'Artform', Side = 'Void', Role = 'Buffer', Health = 100, WalkSpeed = 17, JumpPower = 50, Weapon = 'Spear', Abilities = { 'RhythmAura' }, Blurb = 'Sing the war rhythms until the line stands faster and stronger.' },
	{ Id = 'Scholarform', Name = 'Scholarform', Side = 'Void', Role = 'Sniper', Health = 100, WalkSpeed = 16, JumpPower = 50, Weapon = 'Voidlash', Abilities = { 'PrecisionShot' }, Blurb = 'Study the foe, then place one perfect voidlight bolt.' },
	{ Id = 'Smokeform', Name = 'Smokeform', Side = 'Void', Role = 'Saboteur', Health = 100, WalkSpeed = 19, JumpPower = 52, Weapon = 'Dagger', Abilities = { 'SmokeCloud' }, Blurb = 'Vanishing form, made for the work that needs no witness.' },
	{ Id = 'Decayform', Name = 'Decayform', Side = 'Void', Role = 'Attrition', Health = 110, WalkSpeed = 16, JumpPower = 50, Weapon = 'Spear', Abilities = { 'DecayAura' }, Blurb = 'Everything close enough to smell you begins to rot.' },
	{ Id = 'Nightform', Name = 'Nightform', Side = 'Void', Role = 'Assassin', Health = 100, WalkSpeed = 20, JumpPower = 54, Weapon = 'Dagger', Abilities = { 'ShadowStep' }, Blurb = 'A form for the dark between rhythms.' },
	{ Id = 'Dullform', Name = 'Dullform', Side = 'Void', Role = 'Trooper', Health = 105, WalkSpeed = 17, JumpPower = 50, Weapon = 'Spear', Abilities = { 'BattleCharge' }, Blurb = 'Dullform drudge: no song, no fear, just the charge.' },
	{ Id = 'Regal', Name = 'Regal', Side = 'Void', Role = 'Elite', Health = 120, WalkSpeed = 17, JumpPower = 52, Weapon = 'Shardblade', Abilities = { 'VoidlightBurn' }, Blurb = 'A singer who took a voidspren. Voidlight burns in the chest.' },
	-- Heroes of the Knights Radiant
	{ Id = 'Kaladin', Name = 'Kaladin Stormblessed', Side = 'Radiant', Role = 'Hero', Hero = true, Health = 220, WalkSpeed = 22, JumpPower = 62, Weapon = 'Shardblade', Abilities = { 'Lashing', 'Adhesion' }, Blurb = 'Windrunner of the Fourth Ideal. The storm follows him.' },
	{ Id = 'Shallan', Name = 'Shallan Davar', Side = 'Radiant', Role = 'Hero', Hero = true, Health = 180, WalkSpeed = 21, JumpPower = 58, Weapon = 'Shardblade', Abilities = { 'Illumination', 'Transformation' }, Blurb = 'Lightweaver. Every army she draws becomes real enough to fight.' },
	{ Id = 'Dalinar', Name = 'Dalinar Kholin', Side = 'Radiant', Role = 'Hero', Hero = true, Health = 250, WalkSpeed = 18, JumpPower = 50, Weapon = 'Shardblade', Plate = true, Abilities = { 'Tension', 'Adhesion' }, Blurb = 'Bondsmith. Plate, Shardblade and the weight of every oath at Urithiru.' },
	{ Id = 'Szeth', Name = 'Szeth-son-son-Vallano', Side = 'Radiant', Role = 'Hero', Hero = true, Health = 210, WalkSpeed = 21, JumpPower = 60, Weapon = 'Shardblade', Abilities = { 'Lashing', 'Division' }, Blurb = 'Skybreaker in white. Truthless no longer, but the sky is not safe.' },
	-- Heroes of the Voidbringers
	{ Id = 'Leshwi', Name = 'Leshwi', Side = 'Void', Role = 'Hero', Hero = true, Health = 200, WalkSpeed = 22, JumpPower = 60, Weapon = 'Spear', Abilities = { 'Lashing', 'Stormcall' }, Blurb = 'Fused of the Heavenly Ones. She fights with honor, and she wins.' },
	{ Id = 'Raboniel', Name = 'Raboniel', Side = 'Void', Role = 'Hero', Hero = true, Health = 210, WalkSpeed = 18, JumpPower = 52, Weapon = 'Shardblade', Abilities = { 'DecayAura', 'VoidlightBurn' }, Blurb = 'Lady of Wishes. The rot she offers is a gift, honestly given.' },
	{ Id = 'Vyre', Name = 'Vyre', Side = 'Void', Role = 'Hero', Hero = true, Health = 190, WalkSpeed = 21, JumpPower = 56, Weapon = 'Dagger', Abilities = { 'ShadowStep', 'Division' }, Blurb = 'He Who Quiets. A knife in the dark with a Bondsmith blade.' },
	{ Id = 'YeligNar', Name = 'Yelig-nar', Side = 'Void', Role = 'Hero', Hero = true, Health = 260, WalkSpeed = 16, JumpPower = 48, Weapon = 'Shardblade', Plate = true, Abilities = { 'WarShock', 'VoidlightBurn' }, Blurb = 'Unmade of Blight. It grants every surge, and eats the vessel.' },
}

Config.ClassById = {}
Config.ClassList = { Radiant = {}, Void = {} }
for _, class in Config.Classes do
	Config.ClassById[class.Id] = class
	table.insert(Config.ClassList[class.Side], class)
end

return Config
