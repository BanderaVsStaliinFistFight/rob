--[[
	Enginarium: the stern machine hall. A plasma reactor rises out of a deep
	pit through the deck, wrapped in spinning containment rings, under a
	girdered ceiling. The aft bulkhead is a shrine to the Omnissiah.
]]

local Kit = require(script.Parent.Kit)
local Layout = require(script.Parent.Layout)
local Props = require(script.Parent.Props)

local P = Kit.Palette
local M = Enum.Material
local E = Layout.Enginarium
local D = Layout.Door

local DECOR = { CanCollide = false }
local GLOW = { CanCollide = false, CastShadow = false }

local HALF = E.half
local MID = (E.zMin + E.zMax) / 2
local DEPTH = E.zMax - E.zMin
local RZ = E.reactorZ
local PIT = E.pitHalf
local PIT_FLOOR = -E.pitDepth
local WALL = 2
local PILLARS = { E.zMin + 1, 43.5, 52, 60.5, E.zMax - 1 }

local Enginarium = {}

local function shell(structure: Instance)
	-- Deck plates around the reactor pit
	local nearZ, farZ = RZ - PIT, RZ + PIT
	Kit.part(
		structure,
		"Deck",
		Vector3.new(2 * HALF, 1, nearZ - E.zMin),
		CFrame.new(0, -0.5, (E.zMin + nearZ) / 2),
		P.Iron,
		M.DiamondPlate
	)
	Kit.part(
		structure,
		"Deck",
		Vector3.new(2 * HALF, 1, E.zMax - farZ),
		CFrame.new(0, -0.5, (farZ + E.zMax) / 2),
		P.Iron,
		M.DiamondPlate
	)
	for side = -1, 1, 2 do
		Kit.part(
			structure,
			"Deck",
			Vector3.new(HALF - PIT, 1, 2 * PIT),
			CFrame.new(side * (HALF + PIT) / 2, -0.5, RZ),
			P.Iron,
			M.DiamondPlate
		)
	end
	-- Hazard band and railing around the pit edge
	for s = -1, 1, 2 do
		Kit.hazardStripes(structure, CFrame.new(0, 0.025, RZ + s * (PIT + 0.6)), 2 * PIT + 2.4, 1.2, 0.05, 1.2)
		Kit.hazardStripes(
			structure,
			CFrame.new(s * (PIT + 0.6), 0.025, RZ) * CFrame.Angles(0, math.pi / 2, 0),
			2 * PIT,
			1.2,
			0.05,
			1.2
		)
	end
	local r = PIT + 0.3
	local corners =
		{ Vector3.new(-r, 0, RZ - r), Vector3.new(r, 0, RZ - r), Vector3.new(r, 0, RZ + r), Vector3.new(-r, 0, RZ + r) }
	for i = 1, 4 do
		Kit.railing(structure, corners[i], corners[i % 4 + 1], 3.4, 3)
	end

	-- The pit itself
	for s = -1, 1, 2 do
		Kit.part(
			structure,
			"PitWall",
			Vector3.new(2 * PIT + 2, -PIT_FLOOR, 1),
			CFrame.new(0, PIT_FLOOR / 2, RZ + s * (PIT + 0.5)),
			P.HullDark,
			M.Metal
		)
		Kit.part(
			structure,
			"PitWall",
			Vector3.new(1, -PIT_FLOOR, 2 * PIT),
			CFrame.new(s * (PIT + 0.5), PIT_FLOOR / 2, RZ),
			P.HullDark,
			M.Metal
		)
		for k = -2, 2 do
			Kit.part(
				structure,
				"PitRib",
				Vector3.new(0.6, -PIT_FLOOR, 0.5),
				CFrame.new(k * 3.4, PIT_FLOOR / 2, RZ + s * (PIT - 0.25)),
				P.Iron,
				M.Metal
			)
			Kit.part(
				structure,
				"PitRib",
				Vector3.new(0.5, -PIT_FLOOR, 0.6),
				CFrame.new(s * (PIT - 0.25), PIT_FLOOR / 2, RZ + k * 3.4),
				P.Iron,
				M.Metal
			)
		end
	end
	Kit.part(
		structure,
		"PitFloor",
		Vector3.new(2 * PIT + 2, 1, 2 * PIT + 2),
		CFrame.new(0, PIT_FLOOR - 0.5, RZ),
		P.HullDark,
		M.DiamondPlate
	)
	for k = 0, 3 do
		local a = math.rad(k * 90 + 45)
		local p = Vector3.new(math.cos(a) * 7.5, PIT_FLOOR + 0.06, RZ + math.sin(a) * 7.5)
		Kit.part(
			structure,
			"PitVent",
			Vector3.new(2.4, 0.12, 2.4),
			CFrame.new(p) * CFrame.Angles(0, a, 0),
			Color3.fromRGB(255, 110, 40),
			M.Neon,
			GLOW
		)
	end
	local pitGlow = Kit.part(
		structure,
		"PitGlow",
		Vector3.new(1, 1, 1),
		CFrame.new(0, PIT_FLOOR + 3, RZ + 6),
		P.Black,
		M.SmoothPlastic,
		{ Transparency = 1, CanCollide = false, CastShadow = false }
	)
	Kit.pointLight(pitGlow, Color3.fromRGB(255, 120, 50), 22, 1.4)

	-- Walls and ceiling
	for side = -1, 1, 2 do
		Kit.part(
			structure,
			"Wall",
			Vector3.new(WALL, E.ceiling + 2, DEPTH),
			CFrame.new(side * (HALF + WALL / 2), E.ceiling / 2, MID),
			P.Hull,
			M.Metal
		)
		for _, z in PILLARS do
			Kit.part(
				structure,
				"Pillar",
				Vector3.new(1.6, E.ceiling, 2),
				CFrame.new(side * (HALF - 0.8), E.ceiling / 2, z),
				P.Iron,
				M.Metal
			)
			Kit.part(
				structure,
				"PillarBase",
				Vector3.new(2.2, 1.2, 2.6),
				CFrame.new(side * (HALF - 1.1), 0.6, z),
				P.HullDark,
				M.Metal
			)
			Kit.hazardStripes(
				structure,
				CFrame.new(side * (HALF - 1.65), 2.2, z) * CFrame.Angles(0, math.pi / 2, 0),
				2.2,
				0.1,
				1.2,
				0.55
			)
		end
		Kit.part(
			structure,
			"WallPanel",
			Vector3.new(0.3, 3.5, DEPTH),
			CFrame.new(side * (HALF - 0.15), 1.75, MID),
			P.HullDark,
			M.Metal
		)
	end
	Kit.part(
		structure,
		"AftWall",
		Vector3.new(2 * HALF + 2 * WALL, E.ceiling + 2, WALL),
		CFrame.new(0, E.ceiling / 2, E.zMax + WALL / 2),
		P.Hull,
		M.Metal
	)
	Kit.part(
		structure,
		"Ceiling",
		Vector3.new(2 * HALF + 2 * WALL, 1, DEPTH + 2 * WALL),
		CFrame.new(0, E.ceiling + 0.5, MID),
		P.HullDark,
		M.Metal
	)
	for _, z in { PILLARS[1], PILLARS[2], PILLARS[4], PILLARS[5] } do
		Kit.part(
			structure,
			"GirderFlange",
			Vector3.new(2 * HALF, 0.35, 1.6),
			CFrame.new(0, E.ceiling - 2.3, z),
			P.Iron,
			M.Metal
		)
		Kit.part(
			structure,
			"GirderWeb",
			Vector3.new(2 * HALF, 2.0, 0.45),
			CFrame.new(0, E.ceiling - 1.1, z),
			P.Iron,
			M.Metal
		)
		for k = -4, 4 do
			Kit.part(
				structure,
				"Rivet",
				Vector3.new(0.3, 0.3, 0.6),
				CFrame.new(k * 4.4, E.ceiling - 1.1, z),
				P.Brass,
				M.Metal,
				DECOR
			)
		end
	end

	-- Bulkhead to the corridor, with its blast door
	local z = E.zMin - WALL / 2
	local bottom = -Layout.Corridor.gutter - 1
	Kit.doorWall(
		structure,
		"FrontWall",
		CFrame.new(0, bottom, z),
		2 * HALF + 2 * WALL,
		E.ceiling + 1 - bottom,
		WALL,
		D.width,
		-bottom,
		D.height - bottom,
		P.Hull,
		M.Metal
	)
	Props.blastDoor(structure, CFrame.new(0, 0, z), D.width, D.height, WALL, { "Enginarium", "Omnissiah Vult" })
end

local function reactor(dressing: Instance)
	local base = Vector3.new(0, PIT_FLOOR, RZ)
	local function at(y: number): Vector3
		return Vector3.new(0, y, RZ)
	end
	Kit.column(dressing, "ReactorHousing", 8, 12, base, P.Iron, M.Metal)
	Kit.column(dressing, "ReactorCollar", 3, 9, at(PIT_FLOOR + 8), P.Brass, M.Metal)
	Kit.column(dressing, "ReactorCollar", 3, 9, at(19), P.Brass, M.Metal)
	Kit.column(dressing, "ReactorCrown", E.ceiling - 22, 12, at(22), P.Iron, M.Metal)
	for k = 0, 7 do
		local a = math.rad(k * 45)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		Kit.part(
			dressing,
			"HousingRib",
			Vector3.new(0.9, 8, 0.9),
			CFrame.new(at(PIT_FLOOR + 4) + dir * 6),
			P.Gunmetal,
			M.Metal
		)
		Kit.part(
			dressing,
			"CrownRib",
			Vector3.new(0.9, E.ceiling - 22, 0.9),
			CFrame.new(at((22 + E.ceiling) / 2) + dir * 6),
			P.Gunmetal,
			M.Metal
		)
		Kit.part(
			dressing,
			"CageBar",
			Vector3.new(0.45, 22, 0.45),
			CFrame.new(at(8) + Vector3.new(math.cos(a + 0.39), 0, math.sin(a + 0.39)) * 3.9),
			P.Iron,
			M.Metal
		)
	end
	Kit.column(
		dressing,
		"ContainmentGlass",
		22,
		6.6,
		at(-3),
		Color3.fromRGB(140, 200, 255),
		M.Glass,
		{ Transparency = 0.55, CastShadow = false, CanCollide = false }
	)
	local core = Kit.column(dressing, "PlasmaCore", 22, 4.6, at(-3), P.Plasma, M.Neon, GLOW)
	core:SetAttribute("Fx", "ReactorCore")
	Kit.pointLight(core, P.Plasma, 60, 2.6, true)

	for i, y in { 2, 8, 14 } do
		local ring = Props.ring(dressing, "ContainmentRing", CFrame.new(at(y)), 4.8, 0.7, 16, P.Brass, M.Metal, DECOR)
		for k = 0, 3 do
			local a = k * math.pi / 2
			Kit.part(
				ring,
				"RingNode",
				Vector3.new(0.5, 1.0, 0.5),
				CFrame.new(at(y) + Vector3.new(math.cos(a), 0, math.sin(a)) * 4.8),
				P.Plasma,
				M.Neon,
				GLOW
			)
		end
		ring:SetAttribute("Fx", "Spin")
		ring:SetAttribute("SpinSpeed", if i % 2 == 0 then -0.7 else 0.5)
	end

	-- Plasma conduits along the ceiling, dropping to junction boxes by the walls
	local conduitY = E.ceiling - 3.6
	for side = -1, 1, 2 do
		local wallX = side * (HALF - 3)
		Kit.pipe(
			dressing,
			"Conduit",
			at(conduitY) + Vector3.new(side * 6, 0, 0),
			Vector3.new(wallX, conduitY, RZ),
			2.2,
			P.Gunmetal,
			M.Metal
		)
		Kit.pipe(
			dressing,
			"Conduit",
			Vector3.new(wallX, conduitY + 1.1, RZ),
			Vector3.new(wallX, 4, RZ),
			2.2,
			P.Gunmetal,
			M.Metal
		)
		for t = 0.2, 0.81, 0.3 do
			local p = (at(conduitY) + Vector3.new(side * 6, 0, 0)):Lerp(Vector3.new(wallX, conduitY, RZ), t)
			Kit.cylinder(dressing, "ConduitBand", 0.4, 2.5, CFrame.new(p), P.Plasma, M.Neon, GLOW)
		end
		Kit.part(dressing, "JunctionBox", Vector3.new(3.4, 4.4, 4.2), CFrame.new(wallX, 2.2, RZ), P.Iron, M.Metal)
		Kit.hazardStripes(
			dressing,
			CFrame.new(wallX - side * 1.72, 0.8, RZ) * CFrame.Angles(0, math.pi / 2, 0),
			4.2,
			0.06,
			1.0,
			0.7
		)
		local gauge = Kit.lookAt(Vector3.new(wallX - side * 1.72, 3.2, RZ), Vector3.new(0, 3.2, RZ))
		Kit.disc(dressing, "Gauge", 0.15, 1.3, gauge, P.Parchment, M.SmoothPlastic, DECOR)
		Kit.disc(dressing, "GaugeRim", 0.12, 1.5, gauge * CFrame.new(0, 0, 0.05), P.Brass, M.Metal, DECOR)
		Kit.part(
			dressing,
			"GaugeNeedle",
			Vector3.new(0.06, 0.5, 0.05),
			gauge * CFrame.new(0, 0, -0.1) * CFrame.Angles(0, 0, 0.7) * CFrame.new(0, 0.2, 0),
			P.Alert,
			M.SmoothPlastic,
			DECOR
		)
	end
	for s = -1, 1, 2 do
		local z0 = RZ + s * 6
		local z1 = if s < 0 then E.zMin + 1 else E.zMax - 1
		Kit.pipe(
			dressing,
			"Conduit",
			Vector3.new(0, conduitY, z0),
			Vector3.new(0, conduitY, z1),
			1.8,
			P.Gunmetal,
			M.Metal
		)
	end
end

local function machinery(dressing: Instance)
	for side = -1, 1, 2 do
		local function face(z: number, y: number): CFrame
			return Kit.lookAt(Vector3.new(side * (HALF - 2), y, z), Vector3.new(0, y, z))
		end
		-- Bay by the bulkhead: plasma regulator with pipes into the wall
		local regulator = (E.zMin + PILLARS[2]) / 2 + 0.5
		Kit.part(
			dressing,
			"Regulator",
			Vector3.new(3.2, 6.5, 5),
			CFrame.new(side * (HALF - 1.6), 3.25, regulator),
			P.Gunmetal,
			M.Metal
		)
		Kit.part(
			dressing,
			"RegulatorCap",
			Vector3.new(3.6, 0.5, 5.4),
			CFrame.new(side * (HALF - 1.6), 6.75, regulator),
			P.Brass,
			M.Metal
		)
		for k = -1, 1 do
			Kit.cylinder(
				dressing,
				"RegulatorTank",
				6,
				1.3,
				CFrame.new(side * (HALF - 3.4), 3.25 + k * 1.6, regulator) * CFrame.Angles(0, math.pi / 2, 0),
				P.Brass,
				M.Metal
			)
		end
		Kit.pipe(
			dressing,
			"Pipe",
			Vector3.new(side * (HALF - 1.2), 7, regulator - 1.5),
			Vector3.new(side * (HALF - 1.2), E.ceiling - 0.5, regulator - 1.5),
			0.8,
			P.Iron,
			M.Metal
		)
		Kit.pipe(
			dressing,
			"Pipe",
			Vector3.new(side * (HALF - 1.2), 7, regulator + 1.5),
			Vector3.new(side * (HALF - 1.2), E.ceiling - 0.5, regulator + 1.5),
			0.8,
			P.Iron,
			M.Metal
		)

		-- Cogitator stack and steam vents
		Props.cogitatorStack(dressing, face((PILLARS[2] + PILLARS[3]) / 2, 0), 5.5, 9, 300 + side)
		Props.steamVent(dressing, Vector3.new(side * (HALF - 4), 0, (PILLARS[3] + PILLARS[4]) / 2))
		Props.plaque(
			dressing,
			face((PILLARS[3] + PILLARS[4]) / 2, 9) * CFrame.new(0, 0, 2 - 0.02),
			Vector2.new(5, 1.6),
			"Praise the Omnissiah"
		)

		-- Lumens and warning beacons on the pillars
		for _, z in { PILLARS[2], PILLARS[4] } do
			local pillarFace = Kit.lookAt(Vector3.new(side * (HALF - 1.6), 12, z), Vector3.new(0, 12, z))
			Props.sconce(dressing, pillarFace, if z == PILLARS[4] and side > 0 then 0.9 else nil, 24, 1.1)
			Props.beacon(dressing, pillarFace * CFrame.new(0, 7, 0))
		end

		-- Cable runs along the walls
		for i = 1, #PILLARS - 1 do
			Kit.cable(
				dressing,
				Vector3.new(side * (HALF - 1.8), 21, PILLARS[i]),
				Vector3.new(side * (HALF - 1.8), 21, PILLARS[i + 1]),
				1.6 + (i % 2) * 0.6,
				0.3,
				P.Black,
				7
			)
		end
	end
end

local function shrine(dressing: Instance)
	local z = E.zMax
	Props.cogMechanicus(dressing, CFrame.new(0, 16.5, z - 0.6), 12)
	for s = -1, 1, 2 do
		local face = Kit.lookAt(Vector3.new(s * 10, 24.5, z - 0.9), Vector3.new(s * 10, 24.5, 0))
		Props.banner(dressing, face, 5, 14, P.MechanicusRed, P.Bone, "cog")
		for _, x in { 6.7, 17.5 } do
			Kit.pipe(
				dressing,
				"ShrinePipe",
				Vector3.new(s * x, 0, z - 0.9),
				Vector3.new(s * x, E.ceiling, z - 0.9),
				1.5,
				P.Brass,
				M.Metal
			)
			for _, y in { 3, 12, 21 } do
				Kit.column(dressing, "PipeBand", 0.4, 1.8, Vector3.new(s * x, y, z - 0.9), P.Iron, M.Metal, DECOR)
			end
		end
	end

	-- Machine altar
	local altarZ = z - 1.6
	Kit.part(dressing, "MachineAltar", Vector3.new(6.5, 3.2, 2.4), CFrame.new(0, 1.6, altarZ), P.Iron, M.Metal)
	Kit.part(dressing, "MachineAltarTop", Vector3.new(7, 0.3, 2.8), CFrame.new(0, 3.35, altarZ), P.Brass, M.Metal)
	Kit.part(
		dressing,
		"AltarCloth",
		Vector3.new(3.4, 2.2, 0.08),
		CFrame.new(0, 2.0, altarZ - 1.24),
		P.MechanicusRed,
		M.Fabric,
		DECOR
	)
	Props.cogMechanicus(dressing, CFrame.new(0, 2.1, altarZ - 1.32), 1.5)
	local screen = Kit.part(
		dressing,
		"Screen",
		Vector3.new(3.0, 1.8, 0.2),
		CFrame.new(0, 4.6, altarZ + 0.6) * CFrame.Angles(math.rad(12), 0, 0),
		P.ScreenBack,
		M.SmoothPlastic
	)
	local label = Kit.surfaceText(screen, Enum.NormalId.Front, "", {
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
	label:SetAttribute("Lines", 7)
	Kit.new(
		"SurfaceLight",
		{ Face = Enum.NormalId.Front, Color = P.Cogitator, Range = 7, Brightness = 0.6, Angle = 100 },
		screen
	)
	for s = -1, 1, 2 do
		Props.candle(dressing, Vector3.new(s * 2.6, 3.5, altarZ - 0.6), 1.0, true)
		Props.candle(dressing, Vector3.new(s * 2.1, 3.5, altarZ - 0.9), 0.6)
		local incense = Kit.column(
			dressing,
			"IncenseBurner",
			0.5,
			0.7,
			Vector3.new(s * 1.4, 3.5, altarZ - 0.7),
			P.Brass,
			M.Metal,
			DECOR
		)
		Props.incense(incense, 1.5)
	end
	local oil =
		Kit.part(dressing, "SacredOils", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 3.8, altarZ - 0.6), P.Brass, M.Metal)
	Kit.new("ProximityPrompt", {
		Name = "Anoint",
		ActionText = "Anoint the Machine Spirit",
		ObjectText = "Machine Altar",
		HoldDuration = 1.2,
		MaxActivationDistance = 9,
		RequiresLineOfSight = false,
	}, oil):SetAttribute("Action", "Anoint")
end

function Enginarium.build(ship: Model)
	local room = Kit.model(ship, "Enginarium")
	local structure = Kit.model(room, "Structure")
	local dressing = Kit.model(room, "Dressing")
	shell(structure)
	reactor(dressing)
	machinery(dressing)
	shrine(dressing)
	Props.servoSkull(dressing, CFrame.new(0, 13, RZ + 10), Vector3.new(10, 1.0, 10), 0.22, 3.1)
end

return Enginarium
