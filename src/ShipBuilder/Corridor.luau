--[[
	Corridor: the vaulted processional that links the bridge (prow, -Z) and the
	enginarium (stern, +Z), with the chapel door off its starboard (+X) wall.
]]

local Kit = require(script.Parent.Kit)
local Layout = require(script.Parent.Layout)
local Props = require(script.Parent.Props)
local Surface = require(script.Parent.Surface)

local P = Kit.Palette
local M = Enum.Material
local C = Layout.Corridor
local DOOR = Layout.ChapelDoor

local DECOR = { CanCollide = false }
local GLOW = { CanCollide = false, CastShadow = false }

local LENGTH = C.zMax - C.zMin
local MID = (C.zMin + C.zMax) / 2
local SPAN = C.half * 2
local APEX = C.spring + Kit.archRise(SPAN, C.radius)
local FLOOR_BOTTOM = -C.gutter - 1

-- Rib positions; the end ribs sit flush against the bulkheads.
local RIBS = { C.zMin + 0.8, -24, -16, -8, 0, 8, 16, 24, C.zMax - 0.8 }

-- What dresses each 8-stud bay, from the bridge end. { port (-X), starboard (+X) }
local BAYS = {
	{ "terminal", "terminal" },
	{ "window", "banner" },
	{ "window", "niche" },
	{ "statue", "chapelDoor" },
	{ "banner", "niche" },
	{ "window", "window" },
	{ "window", "window" },
	{ "terminal", "plaque" },
}

local Corridor = {}

-- Riveted hull plating over a dark backing, with diamond-plate kick panels
local function plating(seed: number): Surface.Style
	return {
		course = 3.6,
		length = { 4, 4 },
		joint = 0.1,
		bond = false,
		colors = { P.Hull, Color3.fromRGB(54, 52, 49), Color3.fromRGB(63, 60, 56) },
		materials = { M.Metal },
		vary = 0.07,
		grime = 0.3,
		rust = 0.03,
		seed = seed,
	}
end

local function kickPlates(seed: number): Surface.Style
	return {
		course = 1.2,
		length = { 2, 2 },
		joint = 0.08,
		bond = false,
		colors = { P.HullDark, Color3.fromRGB(42, 40, 38) },
		materials = { M.DiamondPlate },
		vary = 0.06,
		grime = 0.2,
		seed = seed,
	}
end

-- Frame on a wall's inner face: X runs along the wall, -Z points into the corridor.
local function wallFace(side: number, z: number, y: number): CFrame
	return CFrame.fromMatrix(Vector3.new(side * C.half, y, z), Vector3.new(0, 0, -side), Vector3.yAxis)
end

-- Frame in the middle of a wall, at the bottom of the wall.
local function wallBase(side: number, z: number): CFrame
	return wallFace(side, z, FLOOR_BOTTOM) * CFrame.new(0, 0, C.wall / 2)
end

local function solidWall(parent: Instance, side: number, zc: number)
	Kit.part(
		parent,
		"Wall",
		Vector3.new(8, C.spring - FLOOR_BOTTOM, C.wall),
		wallBase(side, zc) * CFrame.new(0, (C.spring - FLOOR_BOTTOM) / 2, 0),
		P.Seam,
		M.Metal
	)
end

-- Pointed lancet window looking out into the void.
local function windowBay(structure: Instance, dressing: Instance, side: number, zc: number)
	local sill, spring, width, radius = 3, 8.5, 4, 3
	local base = wallBase(side, zc)
	local apex = Kit.archWall(structure, "Wall", base, {
		width = 8,
		height = C.spring - FLOOR_BOTTOM,
		thickness = C.wall,
		openWidth = width,
		sill = sill - FLOOR_BOTTOM,
		spring = spring - FLOOR_BOTTOM,
		radius = radius,
		step = 0.4,
	}, P.Seam, M.Metal)
	local frameDepth = C.wall + 0.5
	Kit.archRib(
		structure,
		"WindowFrame",
		base * CFrame.new(0, spring - FLOOR_BOTTOM, 0),
		width,
		radius,
		0.5,
		frameDepth,
		6,
		P.Brass,
		M.Metal
	)
	for s = -1, 1, 2 do
		Kit.part(
			structure,
			"WindowJamb",
			Vector3.new(0.5, spring - sill, frameDepth),
			base * CFrame.new(s * (width / 2 + 0.25), (sill + spring) / 2 - FLOOR_BOTTOM, 0),
			P.Brass,
			M.Metal
		)
	end
	Kit.part(
		structure,
		"WindowSill",
		Vector3.new(width + 1.4, 0.4, frameDepth + 0.6),
		base * CFrame.new(0, sill - FLOOR_BOTTOM - 0.2, 0),
		P.Iron,
		M.Metal
	)
	local glassHeight = apex - (sill - FLOOR_BOTTOM)
	Kit.part(
		structure,
		"Glass",
		Vector3.new(width, glassHeight, 0.2),
		base * CFrame.new(0, sill - FLOOR_BOTTOM + glassHeight / 2, 0),
		Color3.fromRGB(150, 175, 200),
		M.Glass,
		{ Transparency = 0.65, CastShadow = false }
	)
	Kit.part(
		dressing,
		"Mullion",
		Vector3.new(0.25, glassHeight, 0.35),
		base * CFrame.new(0, sill - FLOOR_BOTTOM + glassHeight / 2, 0),
		P.Iron,
		M.Metal
	)
	Kit.part(
		dressing,
		"Transom",
		Vector3.new(width, 0.25, 0.35),
		base * CFrame.new(0, 6.5 - FLOOR_BOTTOM, 0),
		P.Iron,
		M.Metal
	)
end

local function nicheBay(structure: Instance, dressing: Instance, side: number, zc: number)
	solidWall(structure, side, zc)
	local face = wallFace(side, zc, 0)
	local spring, span, radius = 7.5, 3.2, 2.4
	local rise = Kit.archRise(span, radius)
	Kit.part(
		dressing,
		"NicheBack",
		Vector3.new(span, spring - 3.5, 0.12),
		face * CFrame.new(0, (spring + 3.5) / 2, -0.16),
		P.Black,
		M.Slate,
		DECOR
	)
	Kit.triangle(
		dressing,
		"NicheBack",
		(face * CFrame.new(-span / 2, spring, -0.16)).Position,
		(face * CFrame.new(span / 2, spring, -0.16)).Position,
		(face * CFrame.new(0, spring + rise, -0.16)).Position,
		0.12,
		P.Black,
		M.Slate,
		DECOR
	)
	Kit.archRib(
		dressing,
		"NicheFrame",
		face * CFrame.new(0, spring, -0.3),
		span,
		radius,
		0.4,
		0.5,
		5,
		P.Brass,
		M.Metal,
		DECOR
	)
	for s = -1, 1, 2 do
		Kit.part(
			dressing,
			"NicheFrame",
			Vector3.new(0.4, spring - 3.2, 0.5),
			face * CFrame.new(s * (span / 2 + 0.2), (spring + 3.2) / 2, -0.3),
			P.Brass,
			M.Metal,
			DECOR
		)
	end
	Kit.part(
		dressing,
		"NicheShelf",
		Vector3.new(span + 1.2, 0.35, 1.0),
		face * CFrame.new(0, 3.35, -0.5),
		P.Iron,
		M.Metal
	)
	Props.skull(dressing, face * CFrame.new(0, 4.15, -0.55), 1.1)
	Props.candle(dressing, (face * CFrame.new(-1.6, 3.52, -0.55)).Position, 0.9, true)
	Props.candle(dressing, (face * CFrame.new(1.6, 3.52, -0.55)).Position, 0.6)
	Props.candle(dressing, (face * CFrame.new(1.25, 3.52, -0.75)).Position, 0.4)
	Props.puritySeal(dressing, face * CFrame.new(-span / 2 - 0.2, 6.4, -0.55), 0.8)
end

local function bannerBay(structure: Instance, dressing: Instance, side: number, zc: number, emblem: string)
	solidWall(structure, side, zc)
	local face = wallFace(side, zc, 0)
	for s = -1, 1, 2 do
		Kit.part(
			dressing,
			"BannerBracket",
			Vector3.new(0.3, 0.3, 0.9),
			face * CFrame.new(s * 2.7, 11.1, -0.45),
			P.Iron,
			M.Metal,
			DECOR
		)
	end
	Props.banner(dressing, face * CFrame.new(0, 10.8, -0.9), 4.2, 8.6, P.ImperialRed, P.Gold, emblem)
end

local function terminalBay(structure: Instance, dressing: Instance, side: number, zc: number)
	solidWall(structure, side, zc)
	local face = wallFace(side, zc, 0)
	Kit.part(dressing, "Terminal", Vector3.new(3.4, 4.4, 1.0), face * CFrame.new(0, 5.6, -0.5), P.Iron, M.Metal)
	Kit.part(dressing, "TerminalHood", Vector3.new(3.8, 0.4, 1.4), face * CFrame.new(0, 7.95, -0.7), P.Brass, M.Metal)
	Kit.wedge(
		dressing,
		"TerminalDesk",
		Vector3.new(3.2, 0.5, 0.9),
		face * CFrame.new(0, 3.65, -1.45),
		P.Gunmetal,
		M.Metal
	)
	Kit.part(
		dressing,
		"TerminalDeskBase",
		Vector3.new(3.2, 0.6, 0.9),
		face * CFrame.new(0, 3.1, -1.45),
		P.Iron,
		M.Metal
	)
	local screen = Kit.part(
		dressing,
		"Screen",
		Vector3.new(2.6, 1.9, 0.1),
		face * CFrame.new(0, 6.0, -1.03),
		P.ScreenBack,
		M.SmoothPlastic,
		DECOR
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
		{ Face = Enum.NormalId.Front, Color = P.Cogitator, Range = 6, Brightness = 0.5, Angle = 100 },
		screen
	)
	Props.skull(dressing, face * CFrame.new(0, 8.75, -0.9), 0.7)
	Props.puritySeal(dressing, face * CFrame.new(1.2, 4.7, -1.0), 0.7)
	for s = -1, 1, 2 do
		Kit.cable(
			dressing,
			(face * CFrame.new(s * 1.2, 3.4, -0.6)).Position,
			(face * CFrame.new(s * 1.6, -1.5, -1.4)).Position,
			0.6,
			0.22,
			P.Black,
			5
		)
	end
end

local function statueBay(structure: Instance, dressing: Instance, side: number, zc: number)
	solidWall(structure, side, zc)
	local inward = Vector3.new(-side, 0, 0)
	local x = side * (C.half - 1.7)
	local top = 2.5
	Kit.part(
		dressing,
		"Plinth",
		Vector3.new(3.4, top + C.gutter, 4.6),
		CFrame.new(x, (top - C.gutter) / 2, zc),
		P.StoneDark,
		M.Slate
	)
	Kit.part(dressing, "PlinthCap", Vector3.new(3.8, 0.4, 5.0), CFrame.new(x, top - 0.2, zc), P.Brass, M.Metal)
	Kit.part(dressing, "PlinthFoot", Vector3.new(3.8, 0.5, 5.0), CFrame.new(x, 0.25, zc), P.Brass, M.Metal)
	local front = Kit.lookAt(Vector3.new(x - side * 1.7, 1.3, zc), Vector3.new(x - side * 5, 1.3, zc))
	Props.plaque(dressing, front, Vector2.new(3.8, 1.0), "Ever Vigilant")
	Props.marineStatue(dressing, Kit.lookAt(Vector3.new(x, top, zc), Vector3.new(x, top, zc) + inward), 1.1)
	for s = -1, 1, 2 do
		Props.candle(dressing, Vector3.new(x - side * 1.2, top, zc + s * 2.0), 0.8, s > 0)
	end
end

local function plaqueBay(structure: Instance, dressing: Instance, side: number, zc: number)
	solidWall(structure, side, zc)
	local face = wallFace(side, zc, 0)
	Props.plaque(
		dressing,
		face * CFrame.new(0, 6.2, -0.1),
		Vector2.new(5.4, 2.6),
		"Sword-class Frigate\nIndomitable Zeal"
	)
	for s = -1, 1, 2 do
		Props.skull(dressing, face * CFrame.new(s * 3.4, 6.2, -0.55), 0.8)
	end
	Props.puritySeal(dressing, face * CFrame.new(-1.8, 4.6, -0.3), 0.9)
end

local function chapelDoorBay(structure: Instance, dressing: Instance, side: number, zc: number)
	local base = wallBase(side, zc)
	local radius = DOOR.width * 0.75
	Kit.archWall(structure, "Wall", base, {
		width = 8,
		height = C.spring - FLOOR_BOTTOM,
		thickness = C.wall,
		openWidth = DOOR.width,
		sill = -FLOOR_BOTTOM,
		spring = DOOR.spring - FLOOR_BOTTOM,
		radius = radius,
		step = 0.4,
	}, P.Seam, M.Metal)
	local depth = C.wall + 0.6
	Kit.archRib(
		structure,
		"DoorFrame",
		base * CFrame.new(0, DOOR.spring - FLOOR_BOTTOM, 0),
		DOOR.width,
		radius,
		0.6,
		depth,
		8,
		P.Brass,
		M.Metal
	)
	for s = -1, 1, 2 do
		Kit.part(
			structure,
			"DoorJamb",
			Vector3.new(0.6, DOOR.spring, depth),
			base * CFrame.new(s * (DOOR.width / 2 + 0.3), DOOR.spring / 2 - FLOOR_BOTTOM, 0),
			P.Brass,
			M.Metal
		)
		Props.puritySeal(dressing, wallFace(side, zc, 0) * CFrame.new(s * (DOOR.width / 2 + 0.3), 5.5, -0.3), 0.8)
	end
	local apex = DOOR.spring + Kit.archRise(DOOR.width, radius)
	Props.skull(dressing, wallFace(side, zc, 0) * CFrame.new(0, apex + 0.3, -0.6), 0.8)
	-- Threshold plate bridging the gutter
	local gx = side * (C.walk + C.half + C.wall) / 2
	Kit.part(
		structure,
		"Threshold",
		Vector3.new(C.half + C.wall - C.walk, 0.3, DOOR.width + 1),
		CFrame.new(gx, -0.1, zc),
		P.Brass,
		M.DiamondPlate
	)
end

function Corridor.build(ship: Model)
	local room = Kit.model(ship, "Corridor")
	local structure = Kit.model(room, "Structure")
	local dressing = Kit.model(room, "Dressing")

	-- Deck: a raised walkway between two grated gutters
	Kit.part(
		structure,
		"Subfloor",
		Vector3.new(SPAN + 2 * C.wall, 1, LENGTH),
		CFrame.new(0, FLOOR_BOTTOM + 0.5, MID),
		P.HullDark,
		M.Metal
	)
	Surface.tiles(
		structure,
		CFrame.new(0, 0, MID),
		C.walk * 2,
		LENGTH,
		4,
		0.1,
		{ P.Iron, Color3.fromRGB(70, 67, 62), Color3.fromRGB(84, 80, 74) },
		M.DiamondPlate,
		0.06,
		31,
		C.gutter
	)
	Kit.part(structure, "Runner", Vector3.new(3.2, 0.06, LENGTH - 2), CFrame.new(0, 0.03, MID), P.ImperialRed, M.Fabric)
	for side = -1, 1, 2 do
		Kit.part(
			structure,
			"RunnerTrim",
			Vector3.new(0.25, 0.08, LENGTH - 2),
			CFrame.new(side * 1.7, 0.04, MID),
			P.Gold,
			M.Fabric
		)
		Kit.part(
			structure,
			"WalkTrim",
			Vector3.new(0.4, 0.1, LENGTH),
			CFrame.new(side * (C.walk - 0.2), 0.0, MID),
			P.Brass,
			M.Metal
		)

		local gx = side * (C.walk + C.half) / 2
		local gw = C.half - C.walk
		Kit.part(
			structure,
			"GutterGlow",
			Vector3.new(0.4, 0.1, LENGTH),
			CFrame.new(gx + side * 0.7, -C.gutter + 0.05, MID),
			Color3.fromRGB(150, 50, 18),
			M.Neon,
			GLOW
		)
		Kit.cylinder(
			structure,
			"GutterPipe",
			LENGTH,
			0.9,
			CFrame.new(gx - side * 0.5, -C.gutter + 0.55, MID) * CFrame.Angles(0, math.pi / 2, 0),
			P.Brass,
			M.Metal
		)
		Kit.part(
			structure,
			"GrateRail",
			Vector3.new(0.3, 0.45, LENGTH),
			CFrame.new(gx + side * 0.6, -0.48, MID),
			P.HullDark,
			M.Metal
		)
		for i = 0, LENGTH - 1 do
			Kit.part(
				structure,
				"Grate",
				Vector3.new(gw, 0.25, 0.4),
				CFrame.new(gx, -0.125, C.zMin + 0.5 + i),
				P.Gunmetal,
				M.Metal
			)
		end

		-- Conduits along the foot of the vault
		Kit.cylinder(
			structure,
			"Conduit",
			LENGTH,
			0.7,
			CFrame.new(side * (C.half - 0.5), C.spring + 0.85, MID) * CFrame.Angles(0, math.pi / 2, 0),
			P.Brass,
			M.Metal
		)
		Kit.cylinder(
			structure,
			"Conduit",
			LENGTH,
			0.5,
			CFrame.new(side * (C.half - 0.75), C.spring + 1.7, MID) * CFrame.Angles(0, math.pi / 2, 0),
			P.Iron,
			M.Metal
		)
		Kit.part(
			structure,
			"Cornice",
			Vector3.new(1.0, 0.6, LENGTH),
			CFrame.new(side * (C.half - 0.5), C.spring, MID),
			P.Brass,
			M.Metal
		)
	end

	-- Walls, bay by bay
	for i, bay in BAYS do
		local zc = C.zMin + 8 * (i - 1) + 4
		for s, feature in bay do
			local side = if s == 1 then -1 else 1
			if feature == "window" then
				windowBay(structure, dressing, side, zc)
			elseif feature == "niche" then
				nicheBay(structure, dressing, side, zc)
			elseif feature == "banner" then
				bannerBay(structure, dressing, side, zc, if i % 2 == 0 then "skull" else "aquila")
			elseif feature == "terminal" then
				terminalBay(structure, dressing, side, zc)
			elseif feature == "statue" then
				statueBay(structure, dressing, side, zc)
			elseif feature == "plaque" then
				plaqueBay(structure, dressing, side, zc)
			elseif feature == "chapelDoor" then
				chapelDoorBay(structure, dressing, side, zc)
			end
		end
	end

	-- Plating over the side walls and the two bulkheads
	for side = -1, 1, 2 do
		local holes = {}
		for i, bay in BAYS do
			local x = -side * (C.zMin + 8 * (i - 1) + 4)
			local feature = bay[if side < 0 then 1 else 2]
			if feature == "window" then
				table.insert(holes, Surface.archHole(x, 4, 2.75, 8.5, 3, 0.15))
			elseif feature == "chapelDoor" then
				table.insert(holes, Surface.archHole(x, DOOR.width, 0, DOOR.spring, DOOR.width * 0.75, 0.2))
			end
		end
		local face = wallFace(side, MID, 0)
		local half = LENGTH / 2
		Surface.clad(structure, face, { x0 = -half, x1 = half, y0 = 0, y1 = 1.2, holes = holes }, kickPlates(40 + side))
		Surface.clad(
			structure,
			face,
			{ x0 = -half, x1 = half, y0 = 1.2, y1 = C.spring - 0.3, holes = holes },
			plating(50 + side)
		)
	end
	for i, e in { { C.zMin, 1 }, { C.zMax, -1 } } do
		local face = Kit.lookAt(Vector3.new(0, 0, e[1]), Vector3.new(0, 0, e[1] + e[2]))
		local door = Layout.Door
		Surface.clad(structure, face, {
			x0 = -C.half,
			x1 = C.half,
			y0 = 0,
			y1 = APEX,
			vault = { span = SPAN, spring = C.spring, radius = C.radius },
			holes = { { x = 0, width = door.width + 0.4, sill = -1, top = door.height + 0.2 } },
		}, plating(60 + i))
	end

	-- Pillars, ribs and the barrel vault
	Kit.archRib(
		structure,
		"Vault",
		CFrame.new(0, C.spring, MID),
		SPAN + 1.2,
		C.radius + 0.6,
		0.6,
		LENGTH,
		16,
		P.HullDark,
		M.Metal
	)
	for index, z in RIBS do
		for side = -1, 1, 2 do
			Kit.part(
				structure,
				"Pillar",
				Vector3.new(1.2, C.spring + C.gutter, 1.6),
				CFrame.new(side * (C.half - 0.6), (C.spring - C.gutter) / 2, z),
				P.Iron,
				M.Metal
			)
			Kit.part(
				structure,
				"PillarBase",
				Vector3.new(1.8, 1.0, 2.2),
				CFrame.new(side * (C.half - 0.9), 0.5, z),
				P.HullDark,
				M.Metal
			)
			Kit.part(
				structure,
				"Capital",
				Vector3.new(1.9, 0.8, 2.3),
				CFrame.new(side * (C.half - 0.95), C.spring - 0.4, z),
				P.Brass,
				M.Metal
			)
		end
		Kit.archRib(structure, "Rib", CFrame.new(0, C.spring, z), SPAN, C.radius, 1.2, 1.6, 10, P.Iron, M.Metal)
		Kit.disc(
			structure,
			"Boss",
			0.6,
			2.2,
			CFrame.new(0, APEX - 0.1, z) * CFrame.Angles(-math.pi / 2, 0, 0),
			P.Brass,
			M.Metal
		)
		if index > 1 and index < #RIBS then
			Props.skull(dressing, CFrame.new(0, APEX - 0.9, z) * CFrame.Angles(-math.pi / 2, 0, 0), 0.8)
			local flicker = if index == 4 or index == 7 then 0.6 else nil
			Props.lantern(dressing, Vector3.new(0, APEX - 1.4, z), 5.5, flicker, 22)
		end
	end

	-- Sconces and seals on the pillars, warning beacons near the bulkheads
	for _, z in { -24, -8, 8, 24 } do
		for side = -1, 1, 2 do
			local face = Kit.lookAt(Vector3.new(side * (C.half - 1.2), 7.5, z), Vector3.new(0, 7.5, z))
			Props.sconce(dressing, face, if z == 8 and side > 0 then 0.8 else nil, 14, 0.8)
			Props.puritySeal(dressing, face * CFrame.new(0, -2.6, 0), 0.8)
		end
	end
	for _, z in { -24, 24 } do
		Props.beacon(dressing, Kit.lookAt(Vector3.new(C.half - 1.2, 10.6, z), Vector3.new(0, 10.6, z)))
	end

	-- Pipe flanges mid-bay, stencilled deck markings and frame numbers
	for i = 1, #BAYS do
		local z = C.zMin + 8 * (i - 1) + 4
		for side = -1, 1, 2 do
			for _, c in { { C.half - 0.5, C.spring + 0.85, 0.7 }, { C.half - 0.75, C.spring + 1.7, 0.5 } } do
				local cf = CFrame.new(side * c[1], c[2], z) * CFrame.Angles(0, math.pi / 2, 0)
				Kit.cylinder(dressing, "Flange", 0.3, c[3] + 0.25, cf, P.Iron, M.Metal, DECOR)
			end
		end
	end
	for index = 2, #RIBS - 1 do
		local z = RIBS[index]
		for side = -1, 1, 2 do
			local face = Kit.lookAt(Vector3.new(side * (C.half - 1.2), 2.1, z), Vector3.new(0, 2.1, z))
			Surface.stencil(dressing, face, Vector2.new(1.1, 0.55), string.format("VII-%02d", index - 1))
		end
	end
	local markings = {
		{ -1, C.zMin + 4, "COMMAND DECK" },
		{ 1, C.zMin + 4, "COMMAND DECK" },
		{ -1, C.zMax - 4, "ENGINARIUM" },
		{ 1, C.zMax - 4, "DECK VII" },
	}
	for _, m in markings do
		Surface.stencil(dressing, wallFace(m[1], m[2], 10.3), Vector2.new(6, 1.1), m[3])
	end
	Surface.puddle(dressing, Vector3.new(2.3, 0, 26.5), 2.4, 5)
	Surface.puddle(dressing, Vector3.new(-2.6, 0, -13), 1.6, 6)

	-- Cables slung between the ribs
	for i = 1, #RIBS - 1 do
		for side = -1, 1, 2 do
			local x = side * (C.half - 1.6)
			Kit.cable(
				dressing,
				Vector3.new(x, 16.2, RIBS[i]),
				Vector3.new(x, 16.2, RIBS[i + 1]),
				1.4 + (i % 3) * 0.4,
				0.22,
				P.Black,
				7
			)
		end
	end

	Props.servoSkull(dressing, CFrame.new(0, 7.5, MID + 22), Vector3.new(1.8, 0.7, 22), 0.11, 0)
	Props.haze(dressing, CFrame.new(0, 7, MID), Vector3.new(SPAN - 4, 10, LENGTH - 4), 0.35)

	-- Spawn plate near the stern end, facing the bridge
	local spawn = Kit.new("SpawnLocation", {
		Name = "SpawnLocation",
		Anchored = true,
		CanTouch = true,
		Size = Vector3.new(5, 0.2, 5),
		CFrame = CFrame.new(0, 0.1, 20),
		Color = P.Gunmetal,
		Material = M.DiamondPlate,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
		Duration = 0,
		Neutral = true,
	}, dressing)
	for s = -1, 1, 2 do
		Kit.part(
			dressing,
			"SpawnTrim",
			Vector3.new(5.4, 0.25, 0.2),
			spawn.CFrame * CFrame.new(0, 0.02, s * 2.6),
			P.Brass,
			M.Metal
		)
		Kit.part(
			dressing,
			"SpawnTrim",
			Vector3.new(0.2, 0.25, 5.4),
			spawn.CFrame * CFrame.new(s * 2.6, 0.02, 0),
			P.Brass,
			M.Metal
		)
	end
end

return Corridor
