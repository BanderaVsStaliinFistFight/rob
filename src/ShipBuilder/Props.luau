--[[
	Props: reusable set dressing. Unless noted otherwise every prop takes a CFrame
	whose -Z (LookVector) is the direction the prop faces, e.g. out of a wall.
]]

local Kit = require(script.Parent.Kit)

local P = Kit.Palette
local M = Enum.Material

local DECOR = { CanCollide = false }
local GLOW = { CanCollide = false, CastShadow = false }

local Props = {}

-- Skulls ----------------------------------------------------------------------

-- `cf` is the middle of the skull. Seven parts; reads as a skull from the front.
function Props.skull(parent: Instance, cf: CFrame, scale: number?, material: Enum.Material?)
	local s = scale or 1
	local mat = material or M.Limestone
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x * s, y * s, z * s)
	end
	Kit.ball(parent, "Cranium", 1.0 * s, at(0, 0.12, 0.06), P.Bone, mat, DECOR)
	Kit.part(parent, "Face", Vector3.new(0.8, 0.52, 0.62) * s, at(0, -0.2, -0.17), P.Bone, mat, DECOR)
	Kit.part(parent, "Jaw", Vector3.new(0.6, 0.22, 0.5) * s, at(0, -0.52, -0.2), P.Bone, mat, DECOR)
	for side = -1, 1, 2 do
		Kit.part(
			parent,
			"EyeSocket",
			Vector3.new(0.24, 0.2, 0.1) * s,
			at(0.19 * side, -0.1, -0.47),
			P.Black,
			M.SmoothPlastic,
			DECOR
		)
	end
	Kit.part(parent, "Nose", Vector3.new(0.1, 0.14, 0.1) * s, at(0, -0.29, -0.47), P.Black, M.SmoothPlastic, DECOR)
	Kit.part(parent, "Teeth", Vector3.new(0.46, 0.05, 0.1) * s, at(0, -0.43, -0.46), P.Black, M.SmoothPlastic, DECOR)
end

-- Hovering servo-skull. The client script flies it around an ellipse with radii
-- `patrol`; the starting point is the ellipse's +Z extreme.
function Props.servoSkull(parent: Instance, cf: CFrame, patrol: Vector3, speed: number, phase: number?): Model
	local m = Kit.model(parent, "ServoSkull")
	local core = Kit.part(
		m,
		"Core",
		Vector3.new(0.4, 0.4, 0.4),
		cf,
		P.Black,
		M.SmoothPlastic,
		{ CanCollide = false, Transparency = 1 }
	)
	m.PrimaryPart = core
	Props.skull(m, cf, 1.3)
	local eye = Kit.ball(m, "Eye", 0.28, cf * CFrame.new(0.25, -0.13, -0.63), P.Alert, M.Neon, GLOW)
	Kit.pointLight(eye, P.Alert, 9, 1.4)
	Kit.part(m, "Implant", Vector3.new(0.3, 0.7, 0.8), cf * CFrame.new(0.6, 0.15, 0.05), P.Brass, M.Metal, DECOR)
	Kit.part(m, "Vox", Vector3.new(0.5, 0.3, 0.3), cf * CFrame.new(-0.3, -0.75, -0.25), P.Gunmetal, M.Metal, DECOR)
	Kit.pipe(
		m,
		"Antenna",
		(cf * CFrame.new(-0.35, 0.6, 0.3)).Position,
		(cf * CFrame.new(-0.6, 1.5, 0.6)).Position,
		0.06,
		P.Iron,
		M.Metal,
		DECOR
	)
	local ring = cf * CFrame.new(0, -1.0, 0.1) * CFrame.Angles(0, 0, math.pi / 2)
	Kit.cylinder(m, "Suspensor", 0.22, 1.2, ring, P.Gunmetal, M.Metal, DECOR)
	Kit.cylinder(m, "SuspensorGlow", 0.08, 0.9, ring * CFrame.new(-0.13, 0, 0), P.Plasma, M.Neon, GLOW)
	for i = -1, 1 do
		local top = (cf * CFrame.new(i * 0.3, -1.05, 0.1)).Position
		Kit.pipe(
			m,
			"Wire",
			top,
			top + Vector3.new(i * 0.1, -0.9 - math.abs(i) * 0.4, 0.1),
			0.06,
			P.Black,
			M.Rubber,
			DECOR
		)
	end
	m.WorldPivot = cf
	m:SetAttribute("Fx", "ServoSkull")
	m:SetAttribute("Patrol", patrol)
	m:SetAttribute("Speed", speed)
	m:SetAttribute("Phase", phase or 0)
	return m
end

-- Wax purity seal with parchment strips, stuck to a surface.
function Props.puritySeal(parent: Instance, cf: CFrame, scale: number?)
	local s = scale or 1
	Kit.disc(parent, "Wax", 0.16 * s, 0.7 * s, cf * CFrame.new(0, 0, -0.08 * s), P.Wax, M.SmoothPlastic, DECOR)
	Kit.disc(parent, "Sigil", 0.04 * s, 0.34 * s, cf * CFrame.new(0, 0, -0.17 * s), P.Gold, M.Metal, DECOR)
	for side = -1, 1, 2 do
		local strip = cf * CFrame.new(0.12 * side * s, -0.85 * s, -0.03 * s) * CFrame.Angles(0, 0, math.rad(7 * side))
		Kit.part(parent, "Parchment", Vector3.new(0.24, 1.3, 0.03) * s, strip, P.Parchment, M.Fabric, DECOR)
	end
end

-- Iconography -------------------------------------------------------------------

-- Two-headed Imperial aquila, roughly 20 x 9 studs at scale 1.
function Props.aquila(parent: Instance, cf: CFrame, scale: number?)
	local s = scale or 1
	local depth = 0.5 * s
	local gold, mat = P.Gold, M.Metal
	local function pt(x: number, y: number, z: number?): Vector3
		return cf * Vector3.new(x * s, y * s, (z or 0) * s)
	end
	local function tri(a: Vector3, b: Vector3, c: Vector3)
		Kit.triangle(parent, "Aquila", a, b, c, depth, gold, mat, DECOR)
	end

	-- Body and tail
	Kit.part(parent, "Aquila", Vector3.new(1.6, 3.0, 0.7) * s, cf * CFrame.new(0, 0, -0.05 * s), gold, mat, DECOR)
	tri(pt(-0.8, -1.5), pt(0.8, -1.5), pt(0, -4.4))
	for side = -1, 1, 2 do
		tri(pt(0.75 * side, -1.4, 0.05), pt(0.1 * side, -1.6, 0.05), pt(1.9 * side, -3.7, 0.05))

		-- Neck, head and beak, looking outwards
		Kit.beam(parent, "Aquila", pt(0.35 * side, 1.2), pt(1.45 * side, 2.6), 0.6 * s, 0.85 * s, gold, mat, DECOR)
		Kit.part(
			parent,
			"Aquila",
			Vector3.new(1.15, 0.95, 0.75) * s,
			cf * CFrame.new(1.75 * side * s, 2.85 * s, 0),
			gold,
			mat,
			DECOR
		)
		tri(pt(2.25 * side, 3.2), pt(3.05 * side, 2.7), pt(2.25 * side, 2.45))
		Kit.part(
			parent,
			"AquilaEye",
			Vector3.new(0.18, 0.18, 0.1) * s,
			cf * CFrame.new(2.0 * side * s, 3.0 * s, -0.4 * s),
			P.Alert,
			M.Neon,
			GLOW
		)

		-- Wing: a raised leading edge with feathers fanning down and outwards
		local shoulder = Vector3.new(0.8 * side, 1.3, 0)
		local tip = Vector3.new(10 * side, 4.8, 0)
		Kit.beam(parent, "Aquila", pt(shoulder.X, shoulder.Y), pt(tip.X, tip.Y), depth * 1.2, 0.7 * s, gold, mat, DECOR)
		local feathers = 8
		local along = (tip - shoulder).Unit
		for k = 0, feathers - 1 do
			local t = (k + 0.5) / feathers
			local root = shoulder:Lerp(tip, t)
			local angle = math.rad(8 + 62 * t)
			local length = 2.6 + 2.8 * t
			local dir = Vector3.new(side * math.sin(angle), -math.cos(angle), 0)
			local half = along * 0.62
			local z = (k % 2) * 0.06
			local a, b = root - half, root + half
			local c = root + dir * length
			tri(pt(a.X, a.Y, z), pt(b.X, b.Y, z), pt(c.X, c.Y, z))
		end
	end
	Props.skull(parent, cf * CFrame.new(0, 0.2 * s, -0.55 * s), 0.9 * s)
end

-- Cog Mechanicus: toothed cog around a half-bone, half-machine skull.
function Props.cogMechanicus(parent: Instance, cf: CFrame, diameter: number)
	local d = diameter
	local t = d * 0.08
	Kit.disc(parent, "Cog", t, d * 0.8, cf, P.Gunmetal, M.Metal, DECOR)
	for k = 0, 11 do
		local tooth = cf * CFrame.Angles(0, 0, math.rad(k * 30)) * CFrame.new(d * 0.43, 0, 0)
		Kit.part(parent, "CogTooth", Vector3.new(d * 0.13, d * 0.13, t), tooth, P.Gunmetal, M.Metal, DECOR)
	end
	Kit.disc(parent, "CogField", t, d * 0.58, cf * CFrame.new(0, 0, -t * 0.3), P.Black, M.Metal, DECOR)
	Kit.disc(parent, "CogRim", t * 0.9, d * 0.64, cf * CFrame.new(0, 0, -t * 0.1), P.MechanicusRed, M.Metal, DECOR)
	local s = d * 0.3
	local skull = cf * CFrame.new(0, 0.05 * s, -t * 0.5 - 0.2 * s)
	Props.skull(parent, skull, s)
	-- Augmetic right half
	Kit.part(
		parent,
		"Augmetic",
		Vector3.new(0.44, 0.75, 0.2) * s,
		skull * CFrame.new(0.22 * s, -0.08 * s, -0.48 * s),
		P.Iron,
		M.Metal,
		DECOR
	)
	Kit.ball(parent, "AugmeticEye", 0.22 * s, skull * CFrame.new(0.2 * s, -0.1 * s, -0.6 * s), P.Alert, M.Neon, GLOW)
end

-- Banner hanging from a pole. `cf` is the middle of the pole.
function Props.banner(
	parent: Instance,
	cf: CFrame,
	width: number,
	length: number,
	cloth: Color3,
	trim: Color3,
	emblem: string?
)
	local tail = width * 0.45
	local body = length - tail
	Kit.cylinder(parent, "BannerPole", width + 1.2, 0.3, cf * CFrame.new(0, 0.3, 0), P.Brass, M.Metal, DECOR)
	for side = -1, 1, 2 do
		Kit.ball(parent, "Finial", 0.55, cf * CFrame.new(side * (width / 2 + 0.6), 0.3, 0), P.Gold, M.Metal, DECOR)
	end
	Kit.part(parent, "Banner", Vector3.new(width, body, 0.12), cf * CFrame.new(0, -body / 2, 0), cloth, M.Fabric, DECOR)
	local a = cf * Vector3.new(-width / 2, -body, 0)
	local b = cf * Vector3.new(width / 2, -body, 0)
	local c = cf * Vector3.new(0, -length, 0)
	Kit.triangle(parent, "Banner", a, b, c, 0.12, cloth, M.Fabric, DECOR)

	local front = cf.LookVector * 0.09
	Kit.part(
		parent,
		"BannerTrim",
		Vector3.new(width, 0.4, 0.06),
		cf * CFrame.new(0, -0.55, -0.09),
		trim,
		M.Fabric,
		DECOR
	)
	for side = -1, 1, 2 do
		Kit.part(
			parent,
			"BannerTrim",
			Vector3.new(0.3, body, 0.06),
			cf * CFrame.new(side * (width / 2 - 0.15), -body / 2, -0.09),
			trim,
			M.Fabric,
			DECOR
		)
	end
	Kit.beam(parent, "BannerTrim", a + front, c + front, 0.06, 0.3, trim, M.Fabric, DECOR)
	Kit.beam(parent, "BannerTrim", b + front, c + front, 0.06, 0.3, trim, M.Fabric, DECOR)
	Kit.ball(parent, "Tassel", 0.45, c - Vector3.new(0, 0.25, 0), trim, M.Fabric, DECOR)

	local centre = cf * CFrame.new(0, -body * 0.5, -0.1)
	if emblem == "skull" then
		Kit.disc(parent, "Emblem", 0.05, width * 0.66, centre, trim, M.Fabric, DECOR)
		Kit.disc(parent, "Emblem", 0.06, width * 0.56, centre * CFrame.new(0, 0, -0.02), cloth, M.Fabric, DECOR)
		Props.skull(parent, centre * CFrame.new(0, 0, -0.3), width * 0.3)
	elseif emblem == "cog" then
		Props.cogMechanicus(parent, centre * CFrame.new(0, 0, -0.1), width * 0.72)
	elseif emblem == "aquila" then
		Props.aquila(parent, centre * CFrame.new(0, width * 0.05, -0.1), width * 0.042)
	end
end

-- Text on a brass plaque (engraved look). `size` is width x height.
function Props.plaque(parent: Instance, cf: CFrame, size: Vector2, text: string): BasePart
	Kit.part(
		parent,
		"PlaqueFrame",
		Vector3.new(size.X + 0.3, size.Y + 0.3, 0.16),
		cf * CFrame.new(0, 0, -0.08),
		P.Iron,
		M.Metal,
		DECOR
	)
	local plate = Kit.part(
		parent,
		"Plaque",
		Vector3.new(size.X, size.Y, 0.12),
		cf * CFrame.new(0, 0, -0.18),
		P.Brass,
		M.Metal,
		DECOR
	)
	Kit.surfaceText(plate, Enum.NormalId.Front, text, { color = P.HullDark, pixelsPerStud = 40 })
	return plate
end

-- Lights ------------------------------------------------------------------------

local function lumen(part: BasePart, flicker: number?)
	part:SetAttribute("Fx", "Lumen")
	if flicker then
		part:SetAttribute("Flicker", flicker)
	end
end

-- Lumen lantern hanging on a chain below `anchor`.
function Props.lantern(parent: Instance, anchor: Vector3, drop: number, flicker: number?, range: number?): BasePart
	local centre = anchor - Vector3.new(0, drop, 0)
	Kit.pipe(parent, "Chain", anchor, centre + Vector3.new(0, 0.8, 0), 0.14, P.Iron, M.Metal, GLOW)
	Kit.column(parent, "LanternCap", 0.35, 1.25, centre + Vector3.new(0, 0.55, 0), P.Brass, M.Metal, DECOR)
	Kit.ball(parent, "LanternFinial", 0.35, centre + Vector3.new(0, 1.0, 0), P.Brass, M.Metal, GLOW)
	Kit.column(parent, "LanternBase", 0.3, 1.0, centre - Vector3.new(0, 0.75, 0), P.Brass, M.Metal, GLOW)
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local p = centre + Vector3.new(math.cos(a) * 0.55, 0, math.sin(a) * 0.55)
		Kit.part(parent, "LanternCage", Vector3.new(0.1, 1.4, 0.1), CFrame.new(p), P.Iron, M.Metal, GLOW)
	end
	local globe = Kit.ball(parent, "Lumen", 0.85, centre, P.LumenWarm, M.Neon, GLOW)
	Kit.pointLight(globe, P.LumenWarm, range or 20, 1.1, true)
	lumen(globe, flicker)
	return globe
end

-- Wall-mounted lumen. `cf` sits on the wall surface facing out of it.
function Props.sconce(parent: Instance, cf: CFrame, flicker: number?, range: number?, brightness: number?): BasePart
	Kit.part(parent, "SconcePlate", Vector3.new(1.0, 1.8, 0.2), cf * CFrame.new(0, 0, -0.1), P.Brass, M.Metal, DECOR)
	Kit.part(parent, "SconceArm", Vector3.new(0.3, 0.3, 1.0), cf * CFrame.new(0, -0.4, -0.65), P.Iron, M.Metal, DECOR)
	local cup = (cf * CFrame.new(0, -0.45, -1.15)).Position
	Kit.column(parent, "SconceCup", 0.4, 0.8, cup, P.Brass, M.Metal, GLOW)
	local glow = Kit.part(
		parent,
		"Lumen",
		Vector3.new(0.4, 0.75, 0.4),
		CFrame.new(cup + Vector3.new(0, 0.78, 0)),
		P.LumenWarm,
		M.Neon,
		GLOW
	)
	Kit.pointLight(glow, P.LumenWarm, range or 16, brightness or 1, true)
	lumen(glow, flicker)
	return glow
end

-- Wax candle standing on `base`. Candle flames get a gentle flicker client-side.
function Props.candle(parent: Instance, base: Vector3, height: number, light: boolean?): BasePart
	Kit.column(parent, "Candle", height, 0.3 + height * 0.06, base, P.Candle, M.SmoothPlastic, DECOR)
	local flame = Kit.part(
		parent,
		"Flame",
		Vector3.new(0.14, 0.3, 0.14),
		CFrame.new(base + Vector3.new(0, height + 0.18, 0)),
		P.Flame,
		M.Neon,
		GLOW
	)
	flame:SetAttribute("Fx", "Candle")
	if light then
		Kit.pointLight(flame, P.Flame, 12, 0.9)
	end
	return flame
end

-- Free-standing candelabrum with a ring of candles.
function Props.candelabrum(parent: Instance, base: Vector3, height: number)
	Kit.column(parent, "CandelabrumFoot", 0.3, 1.6, base, P.Brass, M.Metal)
	Kit.column(parent, "CandelabrumStem", height, 0.3, base, P.Brass, M.Metal)
	local top = base + Vector3.new(0, height, 0)
	Kit.column(parent, "CandelabrumDish", 0.2, 2.0, top, P.Brass, M.Metal, DECOR)
	Props.candle(parent, top + Vector3.new(0, 0.2, 0), 0.9, true)
	for k = 0, 4 do
		local a = math.rad(k * 72)
		Props.candle(parent, top + Vector3.new(math.cos(a) * 0.7, 0.2, math.sin(a) * 0.7), 0.5)
	end
end

-- Fire brazier on a pedestal, ringed with small skulls.
function Props.brazier(parent: Instance, base: Vector3)
	Kit.column(parent, "BrazierFoot", 0.6, 2.4, base, P.Iron, M.Metal)
	Kit.column(parent, "BrazierStem", 3.4, 0.8, base, P.Iron, M.Metal)
	local bowl = base + Vector3.new(0, 3.4, 0)
	Kit.column(parent, "BrazierBowl", 1.0, 2.8, bowl, P.Brass, M.Metal)
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		Props.skull(
			parent,
			Kit.lookAt(bowl + Vector3.new(0, 0.5, 0) + out * 1.45, bowl + Vector3.new(0, 0.5, 0) + out * 3),
			0.45
		)
	end
	local coals =
		Kit.column(parent, "Coals", 0.2, 2.4, bowl + Vector3.new(0, 1.0, 0), Color3.fromRGB(255, 110, 40), M.Neon, GLOW)
	Kit.new(
		"Fire",
		{ Size = 4, Heat = 7, Color = Color3.fromRGB(255, 140, 40), SecondaryColor = Color3.fromRGB(180, 30, 10) },
		coals
	)
	Kit.pointLight(coals, Color3.fromRGB(255, 150, 70), 24, 1.6, true)
	coals:SetAttribute("Fx", "Candle")
end

-- Rotating warning beacon, dark until general quarters is sounded. `cf` sits on
-- the mounting surface, facing out of it.
function Props.beacon(parent: Instance, cf: CFrame): Model
	local m = Kit.model(parent, "Beacon")
	Kit.part(m, "BeaconMount", Vector3.new(1.0, 1.0, 0.6), cf * CFrame.new(0, 0, -0.3), P.Iron, M.Metal, DECOR)
	Kit.part(m, "BeaconArm", Vector3.new(0.4, 0.4, 1.0), cf * CFrame.new(0, -0.2, -1.0), P.Iron, M.Metal, DECOR)
	local base = (cf * CFrame.new(0, -0.55, -1.6)).Position
	Kit.column(m, "BeaconBase", 0.4, 1.1, base, P.Brass, M.Metal, DECOR)
	local centre = base + Vector3.new(0, 0.85, 0)
	Kit.ball(m, "Lamp", 1.0, centre, Color3.fromRGB(80, 22, 16), M.Glass, GLOW)
	local rotor = Kit.part(
		m,
		"Rotor",
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.new(centre),
		P.Alert,
		M.SmoothPlastic,
		{ Transparency = 1, CanCollide = false, CastShadow = false }
	)
	Kit.spotLight(rotor, P.Alert, 32, 0, 45, Enum.NormalId.Front)
	Kit.spotLight(rotor, P.Alert, 32, 0, 45, Enum.NormalId.Back)
	m:SetAttribute("Fx", "Beacon")
	return m
end

-- Brass censer on a chain, trailing incense smoke.
function Props.censer(parent: Instance, anchor: Vector3, drop: number)
	local centre = anchor - Vector3.new(0, drop, 0)
	Kit.pipe(parent, "Chain", anchor, centre + Vector3.new(0, 0.6, 0), 0.12, P.Iron, M.Metal, GLOW)
	Kit.column(parent, "CenserCap", 0.4, 0.8, centre + Vector3.new(0, 0.35, 0), P.Brass, M.Metal, DECOR)
	local bowl = Kit.ball(parent, "Censer", 1.1, centre, P.Brass, M.Metal, DECOR)
	Kit.ball(parent, "Embers", 0.5, centre - Vector3.new(0, 0.2, 0), Color3.fromRGB(255, 120, 50), M.Neon, GLOW)
	Props.incense(bowl, 3)
end

-- Slow, drifting incense smoke from the top of `part`.
function Props.incense(part: BasePart, rate: number)
	Kit.new("ParticleEmitter", {
		Name = "Incense",
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Rate = rate,
		Lifetime = NumberRange.new(5, 8),
		Speed = NumberRange.new(0.4, 1.0),
		SpreadAngle = Vector2.new(25, 25),
		Acceleration = Vector3.new(0, 0.35, 0),
		Drag = 0.4,
		RotSpeed = NumberRange.new(-15, 15),
		Rotation = NumberRange.new(0, 360),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 4.5) }),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Color = ColorSequence.new(Color3.fromRGB(200, 190, 175)),
		LightInfluence = 1,
		EmissionDirection = Enum.NormalId.Top,
	}, part)
end

-- Venting steam from a floor grate centred on `pos`.
function Props.steamVent(parent: Instance, pos: Vector3)
	local grate = Kit.part(
		parent,
		"SteamVent",
		Vector3.new(2.6, 0.1, 2.6),
		CFrame.new(pos + Vector3.new(0, 0.05, 0)),
		P.HullDark,
		M.Metal
	)
	for k = -2, 2 do
		Kit.part(
			parent,
			"VentSlat",
			Vector3.new(2.4, 0.12, 0.2),
			CFrame.new(pos + Vector3.new(0, 0.1, k * 0.45)),
			P.Gunmetal,
			M.Metal,
			DECOR
		)
	end
	Kit.new("ParticleEmitter", {
		Name = "Steam",
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Rate = 7,
		Lifetime = NumberRange.new(1.8, 3),
		Speed = NumberRange.new(4, 7),
		SpreadAngle = Vector2.new(10, 10),
		Acceleration = Vector3.new(0, 1.5, 0),
		Drag = 1.6,
		RotSpeed = NumberRange.new(-40, 40),
		Rotation = NumberRange.new(0, 360),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 6) }),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Color = ColorSequence.new(Color3.fromRGB(225, 225, 230)),
		EmissionDirection = Enum.NormalId.Top,
	}, grate)
end

-- Machinery -----------------------------------------------------------------------

-- Hard-wired servitor seat; the occupant faces -Z.
function Props.servitorSeat(parent: Instance, cf: CFrame)
	Kit.column(parent, "SeatPost", 1.2, 0.6, cf.Position, P.Iron, M.Metal)
	Kit.seat(parent, "Seat", Vector3.new(1.9, 0.4, 1.8), cf * CFrame.new(0, 1.4, 0), P.HullDark, M.Fabric)
	Kit.part(parent, "SeatBack", Vector3.new(1.9, 2.3, 0.3), cf * CFrame.new(0, 2.75, 0.85), P.Iron, M.Metal)
	for side = -1, 1, 2 do
		local p0 = (cf * CFrame.new(side * 0.6, 3.6, 1.0)).Position
		Kit.cable(parent, p0, (cf * CFrame.new(side * 0.9, 0.05, 2.4)).Position, 0.6, 0.18, P.Black, 5)
	end
end

-- Cogitator console. `cf` is on the floor; the operator stands or sits at +Z.
function Props.console(parent: Instance, cf: CFrame, withSeat: boolean?): Model
	local m = Kit.model(parent, "Cogitator")
	Kit.part(m, "Cabinet", Vector3.new(4, 2.6, 1.8), cf * CFrame.new(0, 1.3, 0), P.Iron, M.Metal)
	Kit.part(m, "Kick", Vector3.new(3.6, 0.5, 0.2), cf * CFrame.new(0, 0.25, 0.95), P.HullDark, M.Metal)
	Kit.part(m, "Trim", Vector3.new(4.2, 0.15, 2.0), cf * CFrame.new(0, 2.62, 0), P.Brass, M.Metal)
	Kit.wedge(
		m,
		"Desk",
		Vector3.new(4.2, 0.7, 1.8),
		cf * CFrame.new(0, 3.05, 0) * CFrame.Angles(0, math.pi, 0),
		P.Gunmetal,
		M.Metal
	)
	local tilt = math.atan2(0.7, 1.8)
	local keyColors = { P.Brass, P.Brass, P.Alert, P.Cogitator, P.Brass }
	for row = 0, 1 do
		local z = 0.45 - row * 0.65
		local y = 2.7 + 0.7 * (0.9 - z) / 1.8 + 0.05
		for col = -2, 2 do
			local color = keyColors[(col + row * 2) % #keyColors + 1]
			local mat = if color == P.Brass then M.Metal else M.Neon
			Kit.part(
				m,
				"Key",
				Vector3.new(0.45, 0.12, 0.35),
				cf * CFrame.new(col * 0.75, y, z) * CFrame.Angles(tilt, 0, 0),
				color,
				mat,
				GLOW
			)
		end
	end

	local screenCF = cf * CFrame.new(0, 4.75, -0.55) * CFrame.Angles(math.rad(-12), 0, 0)
	Kit.part(m, "ScreenPost", Vector3.new(0.5, 1.2, 0.4), cf * CFrame.new(0, 3.6, -0.6), P.Iron, M.Metal)
	Kit.part(m, "Bezel", Vector3.new(3.9, 2.8, 0.25), screenCF * CFrame.new(0, 0, -0.1), P.Brass, M.Metal)
	local screen = Kit.part(m, "Screen", Vector3.new(3.4, 2.3, 0.3), screenCF, P.ScreenBack, M.SmoothPlastic)
	local label = Kit.surfaceText(screen, Enum.NormalId.Back, "", {
		font = Enum.Font.Code,
		color = P.Cogitator,
		background = P.ScreenBack,
		lightInfluence = 0,
		scaled = false,
		size = 12,
		alignX = Enum.TextXAlignment.Left,
		alignY = Enum.TextYAlignment.Top,
	})
	label:SetAttribute("Fx", "Cogitator")
	label:SetAttribute("Lines", 8)
	Kit.new(
		"SurfaceLight",
		{ Face = Enum.NormalId.Back, Color = P.Cogitator, Range = 7, Brightness = 0.6, Angle = 100 },
		screen
	)
	Props.skull(m, screenCF * CFrame.new(0, 1.7, -0.1), 0.55)
	for side = -1, 1, 2 do
		Kit.cable(
			m,
			(cf * CFrame.new(side * 1.2, 2.0, -0.9)).Position,
			(cf * CFrame.new(side * 1.6, 0.1, -2.4)).Position,
			0.5,
			0.25,
			P.Black,
			5
		)
	end
	if withSeat then
		Props.servitorSeat(m, cf * CFrame.new(0, 0, 2.7))
	end
	return m
end

-- Tall cogitator stack covered in blinking indicator lamps. `cf` is on the floor
-- against a wall, facing out of it.
function Props.cogitatorStack(parent: Instance, cf: CFrame, width: number, height: number, seed: number)
	local rand = Kit.random(seed)
	Kit.part(parent, "Stack", Vector3.new(width, height, 2), cf * CFrame.new(0, height / 2, 1), P.Iron, M.Metal)
	Kit.part(
		parent,
		"StackCornice",
		Vector3.new(width + 0.4, 0.5, 2.4),
		cf * CFrame.new(0, height + 0.25, 1),
		P.Brass,
		M.Metal
	)
	Kit.part(parent, "StackPlinth", Vector3.new(width + 0.4, 0.6, 2.4), cf * CFrame.new(0, 0.3, 1), P.HullDark, M.Metal)
	local colors = { P.Cogitator, P.Cogitator, P.Hazard, P.Alert }
	local cols = math.max(2, math.floor(width / 0.7))
	for row = 0, 5 do
		for col = 0, cols - 1 do
			local x = (col - (cols - 1) / 2) * 0.62
			local color = colors[math.floor(rand(1, #colors + 0.999))]
			local lamp = Kit.part(
				parent,
				"Indicator",
				Vector3.new(0.28, 0.28, 0.08),
				cf * CFrame.new(x, height - 1.0 - row * 0.55, -0.04),
				color,
				M.Neon,
				GLOW
			)
			lamp:SetAttribute("Fx", "Blinker")
		end
	end
	for k = 0, 1 do
		local dial = cf * CFrame.new((k - 0.5) * width * 0.45, height * 0.42, -0.05)
		Kit.disc(parent, "Dial", 0.1, 0.9, dial, P.Parchment, M.SmoothPlastic, DECOR)
		Kit.part(
			parent,
			"Needle",
			Vector3.new(0.05, 0.38, 0.05),
			dial * CFrame.new(0, 0, -0.08) * CFrame.Angles(0, 0, rand(-1, 1)) * CFrame.new(0, 0.15, 0),
			P.Black,
			M.SmoothPlastic,
			DECOR
		)
	end
	for k = 0, 4 do
		Kit.part(
			parent,
			"Vent",
			Vector3.new(width * 0.8, 0.12, 0.1),
			cf * CFrame.new(0, 1.2 + k * 0.35, -0.05),
			P.HullDark,
			M.Metal,
			DECOR
		)
	end
end

-- Vertical blast door. `cf` is the bottom centre of the opening, in the middle
-- of the wall: X along the wall, Z through it. The leaf rises into the wall
-- above when the server marks the door open.
function Props.blastDoor(
	parent: Instance,
	cf: CFrame,
	width: number,
	height: number,
	wall: number,
	labels: { string }?
): Model
	local door = Kit.model(parent, "BlastDoor")
	local leaf = Kit.model(door, "Leaf")
	local slab = Kit.part(
		leaf,
		"Slab",
		Vector3.new(width + 0.2, height + 0.1, 0.8),
		cf * CFrame.new(0, height / 2, 0),
		P.Gunmetal,
		M.DiamondPlate
	)
	leaf.PrimaryPart = slab
	for face = -1, 1, 2 do
		local z = face * 0.42
		for _, y in { 2.2, height - 1.4 } do
			Kit.part(
				leaf,
				"Band",
				Vector3.new(width, 0.6, 0.12),
				cf * CFrame.new(0, y, z * 1.05),
				P.Iron,
				M.Metal,
				DECOR
			)
		end
		Kit.hazardStripes(leaf, cf * CFrame.new(0, 0.65, z * 1.1), width, 0.1, 1.2, 1)
		-- Emblems stay within the wall's thickness so the leaf can slide into it
		local emblem = cf * CFrame.new(0, 0, z * 1.1) * CFrame.Angles(0, if face > 0 then math.pi else 0, 0)
		Props.aquila(leaf, emblem * CFrame.new(0, height * 0.5 + 0.8, 0.05), width * 0.034)
		Props.skull(leaf, emblem * CFrame.new(0, height * 0.5 - 1.5, 0.12), 1.05)
	end
	leaf:SetAttribute("OpenOffset", Vector3.new(0, height + 0.4, 0))

	-- Frame, hood and lamps on both faces of the wall
	for face = -1, 1, 2 do
		local z = face * (wall / 2 + 0.3)
		local faceCF = cf * CFrame.new(0, 0, z) * CFrame.Angles(0, if face > 0 then math.pi else 0, 0)
		for side = -1, 1, 2 do
			local jamb = faceCF * CFrame.new(side * (width / 2 + 0.75), (height + 1.5) / 2, 0)
			Kit.part(door, "Jamb", Vector3.new(1.5, height + 1.5, 0.6), jamb, P.Iron, M.Metal)
			Kit.hazardStripes(
				door,
				jamb * CFrame.new(0, 0, -0.33) * CFrame.Angles(0, 0, math.pi / 2),
				height + 1.5,
				0.06,
				1.1,
				1.2
			)
			Props.puritySeal(door, faceCF * CFrame.new(side * (width / 2 + 0.75), height * 0.72, -0.36), 1.1)
		end
		Kit.part(
			door,
			"Lintel",
			Vector3.new(width + 3, 1.5, 0.6),
			faceCF * CFrame.new(0, height + 0.75, 0),
			P.Iron,
			M.Metal
		)
		local span = width + 1
		local hood = faceCF * CFrame.new(0, height + 1.5, 0)
		Kit.archRib(door, "Hood", hood, span, span * 0.75, 0.9, 0.7, 7, P.Brass, M.Metal)
		local rise = Kit.archRise(span, span * 0.75)
		Props.skull(door, hood * CFrame.new(0, rise + 0.2, -0.6), 1.1)
		local text = labels and labels[if face < 0 then 1 else 2]
		if text then
			Props.plaque(door, hood * CFrame.new(0, rise * 0.4, -0.3), Vector2.new(span * 0.62, 1.6), text)
		end
		for side = -1, 1, 2 do
			local lamp = Kit.ball(
				door,
				"DoorLamp",
				0.6,
				faceCF * CFrame.new(side * (width / 2 - 0.6), height + 0.75, -0.35),
				P.Alert,
				M.Neon,
				GLOW
			)
			lamp:SetAttribute("Fx", "DoorLamp")
		end
	end
	-- Explicit sensor point: model pivots are not preserved by every serializer
	Kit.part(
		door,
		"Sensor",
		Vector3.new(1, 1, 1),
		cf * CFrame.new(0, 3, 0),
		P.Black,
		M.SmoothPlastic,
		{ Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false }
	)
	door.WorldPivot = cf * CFrame.new(0, height / 2, 0)
	door:SetAttribute("Fx", "Door")
	door:SetAttribute("SensorRadius", 13)
	return door
end

-- Ring of blocks (a torus) around the CFrame's Y axis, as a spinnable model.
function Props.ring(
	parent: Instance,
	name: string,
	cf: CFrame,
	radius: number,
	thickness: number,
	segments: number,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Model
	local m = Kit.model(parent, name)
	local core = Kit.part(
		m,
		"Pivot",
		Vector3.new(0.2, 0.2, 0.2),
		cf,
		color,
		M.SmoothPlastic,
		{ Transparency = 1, CanCollide = false }
	)
	m.PrimaryPart = core
	local length = 2 * (radius + thickness / 2) * math.tan(math.pi / segments) + 0.02
	for k = 0, segments - 1 do
		local seg = cf * CFrame.Angles(0, k * 2 * math.pi / segments, 0) * CFrame.new(0, 0, -radius)
		Kit.part(m, name, Vector3.new(length, thickness, thickness), seg, color, material, props)
	end
	m.WorldPivot = cf
	return m
end

-- Bank of organ pipes along the CFrame's X axis, standing on its origin.
function Props.organPipes(parent: Instance, cf: CFrame, heights: { number }, spacing: number)
	local count = #heights
	for i, h in heights do
		local x = (i - (count + 1) / 2) * spacing
		local d = spacing * 0.82
		local base = cf * CFrame.new(x, 0, 0)
		Kit.column(parent, "OrganPipe", h, d, base, P.Brass, M.Metal)
		Kit.column(parent, "OrganRing", 0.4, d + 0.2, base * CFrame.new(0, h - 0.4, 0), P.Gold, M.Metal, DECOR)
		Kit.column(parent, "OrganRing", 0.3, d + 0.2, base * CFrame.new(0, 1.6, 0), P.Iron, M.Metal, DECOR)
		Kit.part(
			parent,
			"OrganMouth",
			Vector3.new(d * 0.5, 0.9, 0.2),
			base * CFrame.new(0, 2.6, -d / 2 + 0.05),
			P.Black,
			M.SmoothPlastic,
			DECOR
		)
	end
end

-- Furniture and statuary -------------------------------------------------------------

-- Wooden pew with gothic end boards. Sitters face -Z.
function Props.pew(parent: Instance, cf: CFrame, length: number)
	local wood, mat = P.Wood, M.Wood
	for side = -1, 1, 2 do
		local x = side * (length / 2 - 0.15)
		Kit.part(parent, "PewEnd", Vector3.new(0.3, 3.4, 1.8), cf * CFrame.new(x, 1.7, 0.1), wood, mat)
		local top = cf * CFrame.new(x, 3.4, 0.1)
		Kit.triangle(
			parent,
			"PewEnd",
			(top * CFrame.new(0, 0, -0.9)).Position,
			(top * CFrame.new(0, 0, 0.9)).Position,
			(top * CFrame.new(0, 0.7, 0)).Position,
			0.3,
			wood,
			mat
		)
		Kit.ball(parent, "PewKnob", 0.35, top * CFrame.new(0, 0.75, 0), P.Brass, M.Metal, DECOR)
	end
	Kit.seat(parent, "Seat", Vector3.new(length - 0.6, 0.3, 1.3), cf * CFrame.new(0, 1.5, -0.05), wood, mat)
	Kit.part(
		parent,
		"PewBack",
		Vector3.new(length - 0.6, 1.8, 0.25),
		cf * CFrame.new(0, 2.6, 0.75) * CFrame.Angles(math.rad(-6), 0, 0),
		wood,
		mat
	)
	Kit.part(parent, "PewShelf", Vector3.new(length - 0.6, 0.15, 0.5), cf * CFrame.new(0, 3.0, 1.05), wood, mat)
end

-- Marble statue of an Adeptus Astartes resting on his sword. `cf` is between the feet.
function Props.marineStatue(parent: Instance, cf: CFrame, scale: number)
	local s = scale
	local stone, mat = P.Marble, M.Marble
	local function block(name: string, size: Vector3, x: number, y: number, z: number, rot: CFrame?)
		Kit.part(parent, name, size * s, cf * CFrame.new(x * s, y * s, z * s) * (rot or CFrame.identity), stone, mat)
	end
	local function at(x: number, y: number, z: number): Vector3
		return cf * Vector3.new(x * s, y * s, z * s)
	end
	for side = -1, 1, 2 do
		local x = 0.62 * side
		block("Boot", Vector3.new(1.0, 0.8, 1.6), x, 0.4, -0.15)
		block("Greave", Vector3.new(0.92, 1.7, 1.1), x, 1.65, 0)
		block("KneePad", Vector3.new(1.0, 0.8, 0.45), x, 2.45, -0.55, CFrame.Angles(math.rad(-10), 0, 0))
		block("Thigh", Vector3.new(1.0, 1.5, 1.15), x, 3.25, 0)
		block(
			"Tasset",
			Vector3.new(0.95, 1.0, 0.15),
			0.6 * side,
			3.55,
			-0.7,
			CFrame.Angles(math.rad(8), 0, math.rad(6 * side))
		)
		Kit.ball(parent, "Pauldron", 1.95 * s, cf * CFrame.new(1.75 * side * s, 6.1 * s, 0), stone, mat)
		Kit.column(parent, "PauldronRim", 0.35 * s, 2.1 * s, cf * CFrame.new(1.75 * side * s, 5.45 * s, 0), stone, mat)
		local shoulder, elbow, hand = at(1.75 * side, 5.5, 0), at(1.55 * side, 4.45, -0.5), at(0.35 * side, 4.75, -1.25)
		Kit.beam(parent, "UpperArm", shoulder, elbow, 0.82 * s, 0.82 * s, stone, mat)
		Kit.ball(parent, "Elbow", 0.88 * s, elbow, stone, mat)
		Kit.beam(parent, "Forearm", elbow, hand, 0.78 * s, 0.78 * s, stone, mat)
		block("Gauntlet", Vector3.new(0.62, 0.62, 0.62), 0.3 * side, 4.75, -1.3)
		block("Exhaust", Vector3.new(0.45, 1.0, 0.45), 0.7 * side, 6.9, 1.45)
		block("Lens", Vector3.new(0.22, 0.14, 0.1), 0.2 * side, 7.35, -0.53)
	end
	block("Belt", Vector3.new(2.3, 0.7, 1.35), 0, 4.05, 0)
	block("Torso", Vector3.new(2.6, 2.1, 1.6), 0, 5.45, 0)
	block("Plastron", Vector3.new(2.2, 1.3, 0.3), 0, 5.75, -0.85)
	block("Backpack", Vector3.new(2.4, 2.2, 1.1), 0, 5.6, 1.25)
	block("Gorget", Vector3.new(1.4, 0.4, 1.2), 0, 6.65, 0)
	block("Helm", Vector3.new(0.85, 0.95, 0.95), 0, 7.25, -0.05)
	block("Grille", Vector3.new(0.5, 0.35, 0.2), 0, 7.0, -0.55)
	-- Gilded details
	Props.aquila(parent, cf * CFrame.new(0, 5.85 * s, -1.02 * s), 0.1 * s)
	Kit.part(parent, "Buckle", Vector3.new(0.6, 0.45, 0.1) * s, cf * CFrame.new(0, 4.05 * s, -0.7 * s), P.Gold, M.Metal)
	-- Sword planted point-down, hands on the pommel
	local sword = cf * CFrame.new(0, 0, -1.3 * s)
	Kit.ball(parent, "Pommel", 0.42 * s, sword * CFrame.new(0, 5.4 * s, 0), P.Gold, M.Metal)
	Kit.part(parent, "Grip", Vector3.new(0.22, 0.9, 0.22) * s, sword * CFrame.new(0, 4.85 * s, 0), stone, mat)
	Kit.part(parent, "Crossguard", Vector3.new(1.9, 0.25, 0.3) * s, sword * CFrame.new(0, 4.3 * s, 0), P.Gold, M.Metal)
	Kit.part(parent, "Blade", Vector3.new(0.42, 4.1, 0.1) * s, sword * CFrame.new(0, 2.2 * s, 0), stone, mat)
end

return Props
