--[[
	Bridge: a cathedral-sized command deck. A raised central aisle carries the
	command throne and hololith towards a great gothic viewport; sunken
	servitor pits full of cogitators flank it on either side.
]]

local Kit = require(script.Parent.Kit)
local Layout = require(script.Parent.Layout)
local Props = require(script.Parent.Props)

local P = Kit.Palette
local M = Enum.Material
local B = Layout.Bridge
local D = Layout.Door

local DECOR = { CanCollide = false }
local GLOW = { CanCollide = false, CastShadow = false }

local DEPTH = B.zMax - B.zMin
local MID = (B.zMin + B.zMax) / 2
local SPAN = B.half * 2
local APEX = B.spring + Kit.archRise(SPAN, B.radius)
local WALL_TOP = APEX + 2
local BOTTOM = B.pit - 1

local AISLE = 10 -- half-width of the raised aisle
local REAR_EDGE = -44 -- rear platform runs from here back to the door
local FRONT_EDGE = -76 -- observation gallery runs from here to the viewport
local THRONE_Z = -58
local HOLOLITH_Z = -70

-- Viewport (in world heights)
local VIEW = { width = 40, sill = 4, spring = 26, radius = 30 }

local PILLARS = { B.zMin + 1, -74, -64, -54, -44, B.zMax - 1 }

local Bridge = {}

-- Frame on a side wall's inner face: X along the wall, -Z into the room.
local function wallFace(side: number, z: number, y: number): CFrame
	return CFrame.fromMatrix(Vector3.new(side * B.half, y, z), Vector3.new(0, 0, -side), Vector3.yAxis)
end

local function deck(parent: Instance)
	Kit.part(
		parent,
		"PitFloor",
		Vector3.new(SPAN + 4, 1, DEPTH),
		CFrame.new(0, B.pit - 0.5, MID),
		P.Iron,
		M.DiamondPlate
	)
	local raised = {
		{ Vector3.new(SPAN, 4, B.zMax - REAR_EDGE), Vector3.new(0, -2, (B.zMax + REAR_EDGE) / 2) },
		{ Vector3.new(SPAN, 4, FRONT_EDGE - B.zMin), Vector3.new(0, -2, (B.zMin + FRONT_EDGE) / 2) },
		{ Vector3.new(AISLE * 2, 4, REAR_EDGE - FRONT_EDGE), Vector3.new(0, -2, (REAR_EDGE + FRONT_EDGE) / 2) },
	}
	for _, r in raised do
		Kit.part(parent, "Deck", r[1], CFrame.new(r[2]), P.Gunmetal, M.DiamondPlate)
	end
	-- Brass edging along the drop into the pits
	for side = -1, 1, 2 do
		Kit.part(
			parent,
			"DeckEdge",
			Vector3.new(0.4, 0.3, REAR_EDGE - FRONT_EDGE),
			CFrame.new(side * (AISLE - 0.2), -0.1, (REAR_EDGE + FRONT_EDGE) / 2),
			P.Brass,
			M.Metal
		)
		for _, z in { REAR_EDGE + 0.2, FRONT_EDGE - 0.2 } do
			Kit.part(
				parent,
				"DeckEdge",
				Vector3.new(B.half - AISLE, 0.3, 0.4),
				CFrame.new(side * (B.half + AISLE) / 2, -0.1, z),
				P.Brass,
				M.Metal
			)
		end
	end
	-- Carpet up the aisle, interrupted by the throne dais
	for _, run in { { B.zMax, THRONE_Z + 5.5 }, { THRONE_Z - 5.5, FRONT_EDGE } } do
		local z0, z1 = run[1], run[2]
		Kit.part(
			parent,
			"Carpet",
			Vector3.new(4.4, 0.08, z0 - z1),
			CFrame.new(0, 0.04, (z0 + z1) / 2),
			P.ImperialRed,
			M.Fabric
		)
		for s = -1, 1, 2 do
			Kit.part(
				parent,
				"CarpetTrim",
				Vector3.new(0.3, 0.1, z0 - z1),
				CFrame.new(s * 2.35, 0.05, (z0 + z1) / 2),
				P.Gold,
				M.Fabric
			)
		end
	end
end

local function pits(structure: Instance, dressing: Instance)
	for side = -1, 1, 2 do
		local sx = side * 20
		-- Stairs from the rear platform down into the pit
		for k = 1, 3 do
			local h = -B.pit - k
			Kit.part(
				structure,
				"Step",
				Vector3.new(6, h, 1.5),
				CFrame.new(sx, B.pit + h / 2, REAR_EDGE - 1.5 * (k - 0.5)),
				P.Gunmetal,
				M.DiamondPlate
			)
			Kit.part(
				structure,
				"StepNosing",
				Vector3.new(6, 0.12, 0.3),
				CFrame.new(sx, B.pit + h - 0.04, REAR_EDGE - 1.5 * k + 0.15),
				P.Brass,
				M.Metal
			)
		end
		for s = -1, 1, 2 do
			local x = sx + s * 3.2
			Kit.railing(dressing, Vector3.new(x, 0, REAR_EDGE + 0.3), Vector3.new(x, B.pit, REAR_EDGE - 4.8), 3.2, 2.5)
		end

		-- Railings around the pit, leaving the stair mouth open
		local inner = side * (AISLE - 0.3)
		Kit.railing(dressing, Vector3.new(inner, 0, REAR_EDGE), Vector3.new(inner, 0, FRONT_EDGE))
		Kit.railing(
			dressing,
			Vector3.new(side * (AISLE - 0.3), 0, REAR_EDGE + 0.3),
			Vector3.new(sx - side * 3.2, 0, REAR_EDGE + 0.3)
		)
		Kit.railing(
			dressing,
			Vector3.new(sx + side * 3.2, 0, REAR_EDGE + 0.3),
			Vector3.new(side * (B.half - 0.4), 0, REAR_EDGE + 0.3)
		)
		Kit.railing(
			dressing,
			Vector3.new(side * (AISLE - 0.3), 0, FRONT_EDGE - 0.3),
			Vector3.new(side * (B.half - 0.4), 0, FRONT_EDGE - 0.3)
		)

		-- Two rows of crewed cogitators facing the viewport
		for _, z in { -58, -68 } do
			for _, x in { 14.5, 24.5 } do
				Props.console(dressing, CFrame.new(side * x, B.pit, z), true)
			end
		end
		-- Cogitator stacks against the hull
		for i, z in { -49, -59, -69 } do
			local front = Kit.lookAt(Vector3.new(side * (B.half - 2), B.pit, z), Vector3.new(0, B.pit, z))
			Props.cogitatorStack(dressing, front, 5.5, 9, i * 7 + side * 3 + 40)
		end
	end
end

local function walls(structure: Instance, dressing: Instance)
	local height = B.spring - BOTTOM
	for side = -1, 1, 2 do
		-- Front bay gets a lancet window, the rest are solid stone
		local frontZ = (B.zMin + PILLARS[2]) / 2
		local base = wallFace(side, frontZ, BOTTOM) * CFrame.new(0, 0, B.wall / 2)
		local win = { width = 5, sill = 6, spring = 13, radius = 3.75 }
		Kit.archWall(structure, "Wall", base, {
			width = PILLARS[2] - B.zMin,
			height = height,
			thickness = B.wall,
			openWidth = win.width,
			sill = win.sill - BOTTOM,
			spring = win.spring - BOTTOM,
			radius = win.radius,
			step = 0.4,
		}, P.Stone, M.Slate)
		Kit.archRib(
			structure,
			"WindowFrame",
			base * CFrame.new(0, win.spring - BOTTOM, 0),
			win.width,
			win.radius,
			0.6,
			B.wall + 0.6,
			7,
			P.Brass,
			M.Metal
		)
		for s = -1, 1, 2 do
			Kit.part(
				structure,
				"WindowJamb",
				Vector3.new(0.6, win.spring - win.sill, B.wall + 0.6),
				base * CFrame.new(s * (win.width / 2 + 0.3), (win.sill + win.spring) / 2 - BOTTOM, 0),
				P.Brass,
				M.Metal
			)
		end
		local glassH = Kit.archRise(win.width, win.radius) + win.spring - win.sill
		Kit.part(
			structure,
			"Glass",
			Vector3.new(win.width, glassH, 0.2),
			base * CFrame.new(0, win.sill - BOTTOM + glassH / 2, 0),
			Color3.fromRGB(150, 175, 200),
			M.Glass,
			{ Transparency = 0.65, CastShadow = false }
		)
		Kit.part(
			structure,
			"WindowSill",
			Vector3.new(win.width + 1.6, 0.5, B.wall + 1.2),
			base * CFrame.new(0, win.sill - BOTTOM - 0.25, 0),
			P.Iron,
			M.Metal
		)

		local solidStart = PILLARS[2]
		Kit.part(
			structure,
			"Wall",
			Vector3.new(B.zMax - solidStart, height, B.wall),
			wallFace(side, (solidStart + B.zMax) / 2, BOTTOM) * CFrame.new(0, height / 2, B.wall / 2),
			P.Stone,
			M.Slate
		)

		-- Buttress pillars with sconces
		for i, z in PILLARS do
			local x = side * (B.half - 0.8)
			Kit.part(
				structure,
				"Pillar",
				Vector3.new(1.6, B.spring - B.pit, 2),
				CFrame.new(x, (B.spring + B.pit) / 2, z),
				P.StoneDark,
				M.Slate
			)
			Kit.part(
				structure,
				"PillarBase",
				Vector3.new(2.4, 1.2, 2.8),
				CFrame.new(side * (B.half - 1.1), B.pit + 0.6, z),
				P.Iron,
				M.Metal
			)
			Kit.part(
				structure,
				"Capital",
				Vector3.new(2.6, 1.0, 3.0),
				CFrame.new(side * (B.half - 1.2), B.spring - 0.5, z),
				P.Brass,
				M.Metal
			)
			if i > 1 and i < #PILLARS then
				local face = Kit.lookAt(Vector3.new(side * (B.half - 1.6), 12, z), Vector3.new(0, 12, z))
				Props.sconce(dressing, face, if i == 3 and side < 0 then 0.7 else nil, 22, 1.1)
			end
		end
		Kit.part(
			structure,
			"Cornice",
			Vector3.new(1.4, 0.8, DEPTH),
			CFrame.new(side * (B.half - 0.7), B.spring, MID),
			P.Brass,
			M.Metal
		)

		-- Banners over the pits
		local emblems = { "skull", "aquila", "skull" }
		for i, z in { -49, -59, -69 } do
			local face = wallFace(side, z, 0)
			for s = -1, 1, 2 do
				Kit.part(
					dressing,
					"BannerBracket",
					Vector3.new(0.35, 0.35, 1.1),
					face * CFrame.new(s * 3.2, 18.9, -0.55),
					P.Iron,
					M.Metal,
					DECOR
				)
			end
			Props.banner(dressing, face * CFrame.new(0, 18.6, -1.1), 5, 11, P.ImperialRed, P.Gold, emblems[i])
		end
		-- Cogitator stacks on the rear platform
		local front = Kit.lookAt(Vector3.new(side * (B.half - 2), 0, -39), Vector3.new(0, 0, -39))
		Props.cogitatorStack(dressing, front, 6, 10, 90 + side)
		Props.beacon(
			dressing,
			Kit.lookAt(Vector3.new(side * (B.half - 1.6), 16.5, REAR_EDGE), Vector3.new(0, 16.5, REAR_EDGE))
		)
	end
end

local function vault(structure: Instance, dressing: Instance)
	Kit.archRib(
		structure,
		"Vault",
		CFrame.new(0, B.spring, MID),
		SPAN + 2,
		B.radius + 1,
		1,
		DEPTH,
		24,
		P.StoneDark,
		M.Slate
	)
	for _, z in PILLARS do
		Kit.archRib(structure, "Rib", CFrame.new(0, B.spring, z), SPAN, B.radius, 2, 2, 20, P.Iron, M.Metal)
		Kit.disc(
			structure,
			"Boss",
			1,
			3.6,
			CFrame.new(0, APEX - 0.2, z) * CFrame.Angles(-math.pi / 2, 0, 0),
			P.Brass,
			M.Metal
		)
		Props.skull(dressing, CFrame.new(0, APEX - 1.6, z) * CFrame.Angles(-math.pi / 2, 0, 0), 1.5)
	end
	-- Two great chandeliers
	for _, z in { -49, -69 } do
		local anchor = Vector3.new(0, APEX + 1.2, z)
		local centre = Vector3.new(0, 36, z)
		Kit.pipe(dressing, "Chain", anchor, centre + Vector3.new(0, 4, 0), 0.3, P.Iron, M.Metal, GLOW)
		Kit.column(dressing, "ChandelierHub", 1.2, 1.6, centre + Vector3.new(0, 3.4, 0), P.Brass, M.Metal, DECOR)
		Props.ring(dressing, "Chandelier", CFrame.new(centre), 4.5, 0.45, 16, P.Brass, M.Metal, DECOR)
		Props.ring(
			dressing,
			"Chandelier",
			CFrame.new(centre + Vector3.new(0, 1.6, 0)),
			2.6,
			0.35,
			12,
			P.Brass,
			M.Metal,
			DECOR
		)
		for k = 0, 2 do
			local a = math.rad(k * 120)
			Kit.pipe(
				dressing,
				"ChandelierChain",
				centre + Vector3.new(0, 4, 0),
				centre + Vector3.new(math.cos(a) * 4.5, 0, math.sin(a) * 4.5),
				0.12,
				P.Iron,
				M.Metal,
				GLOW
			)
		end
		for k = 0, 7 do
			local a = math.rad(k * 45 + 22.5)
			Props.candle(dressing, centre + Vector3.new(math.cos(a) * 4.5, 0.22, math.sin(a) * 4.5), 0.9)
		end
		local globe = Kit.ball(dressing, "Lumen", 1.6, centre + Vector3.new(0, 0.8, 0), P.LumenWarm, M.Neon, GLOW)
		Kit.pointLight(globe, P.LumenWarm, 55, 1.6, true)
		globe:SetAttribute("Fx", "Lumen")
	end
end

local function viewport(structure: Instance, dressing: Instance)
	local base = CFrame.new(0, BOTTOM, B.zMin - B.wall / 2)
	local apex = Kit.archWall(structure, "FrontWall", base, {
		width = SPAN + 2 * B.wall,
		height = WALL_TOP - BOTTOM,
		thickness = B.wall,
		openWidth = VIEW.width,
		sill = VIEW.sill - BOTTOM,
		spring = VIEW.spring - BOTTOM,
		radius = VIEW.radius,
		step = 0.6,
	}, P.Stone, M.Slate) + BOTTOM
	local half = VIEW.width / 2
	local frameDepth = B.wall + 1.2
	Kit.archRib(
		structure,
		"ViewportFrame",
		CFrame.new(0, VIEW.spring, base.Position.Z),
		VIEW.width,
		VIEW.radius,
		2,
		frameDepth,
		18,
		P.Brass,
		M.Metal
	)
	for s = -1, 1, 2 do
		Kit.part(
			structure,
			"ViewportJamb",
			Vector3.new(2, VIEW.spring - VIEW.sill, frameDepth),
			CFrame.new(s * (half + 1), (VIEW.spring + VIEW.sill) / 2, base.Position.Z),
			P.Brass,
			M.Metal
		)
	end
	Kit.part(
		structure,
		"ViewportSill",
		Vector3.new(VIEW.width + 5, 1.2, frameDepth + 2),
		CFrame.new(0, VIEW.sill - 0.6, base.Position.Z + 1),
		P.Iron,
		M.Metal
	)

	-- Tracery: three lancets under a rose window
	local z = base.Position.Z
	local glassH = apex - VIEW.sill
	Kit.part(
		structure,
		"ViewportGlass",
		Vector3.new(VIEW.width, glassH, 0.3),
		CFrame.new(0, VIEW.sill + glassH / 2, z),
		Color3.fromRGB(150, 180, 210),
		M.Glass,
		{ Transparency = 0.8, CastShadow = false }
	)
	local mullionX = VIEW.width / 6
	local mullionTop = VIEW.spring + math.sqrt(VIEW.radius ^ 2 - (mullionX + VIEW.radius - half) ^ 2)
	for s = -1, 1, 2 do
		Kit.part(
			dressing,
			"Mullion",
			Vector3.new(0.9, mullionTop - VIEW.sill, 1.2),
			CFrame.new(s * mullionX, (mullionTop + VIEW.sill) / 2, z),
			P.Iron,
			M.Metal
		)
	end
	for _, y in { 15, VIEW.spring } do
		Kit.part(dressing, "Transom", Vector3.new(VIEW.width, 0.8, 1.1), CFrame.new(0, y, z), P.Iron, M.Metal)
	end
	local roseY, roseR = 40, 5.6
	for k = 0, 23 do
		local a = k * math.pi / 12
		local cf = CFrame.new(0, roseY, z) * CFrame.Angles(0, 0, a) * CFrame.new(roseR, 0, 0)
		Kit.part(dressing, "Rose", Vector3.new(0.8, 2 * roseR * math.tan(math.pi / 24) + 0.1, 1.1), cf, P.Iron, M.Metal)
	end
	for k = 0, 5 do
		local cf = CFrame.new(0, roseY, z) * CFrame.Angles(0, 0, k * math.pi / 3) * CFrame.new(roseR / 2, 0, 0)
		Kit.part(dressing, "RoseSpoke", Vector3.new(roseR, 0.45, 0.9), cf, P.Iron, M.Metal)
	end
	Kit.disc(
		dressing,
		"RoseBoss",
		1.0,
		1.6,
		CFrame.new(0, roseY, z + 0.2) * CFrame.Angles(0, math.pi, 0),
		P.Brass,
		M.Metal
	)
	Kit.part(
		dressing,
		"Mullion",
		Vector3.new(0.8, roseY - roseR - VIEW.spring, 1.1),
		CFrame.new(0, (roseY - roseR + VIEW.spring) / 2, z),
		P.Iron,
		M.Metal
	)
	Kit.part(
		dressing,
		"Mullion",
		Vector3.new(0.8, apex - roseY - roseR, 1.1),
		CFrame.new(0, (apex + roseY + roseR) / 2, z),
		P.Iron,
		M.Metal
	)

	-- Planet-light washing back into the room
	local wash = Kit.part(
		dressing,
		"PlanetLight",
		Vector3.new(1, 1, 1),
		CFrame.new(10, 44, z + 2),
		P.Black,
		M.SmoothPlastic,
		{ Transparency = 1, CanCollide = false, CastShadow = false }
	)
	Kit.spotLight(wash, Color3.fromRGB(255, 170, 120), 60, 0.9, 75, Enum.NormalId.Back, true)

	-- Auspex stations on the observation gallery
	for s = -1, 1, 2 do
		Props.console(dressing, CFrame.new(s * 14, 0, -80.2), true)
		Props.brazier(dressing, Vector3.new(s * 26, 0, -79))
	end
end

local function rearWall(structure: Instance, dressing: Instance)
	local z = B.zMax + B.wall / 2
	Kit.doorWall(
		structure,
		"RearWall",
		CFrame.new(0, BOTTOM, z),
		SPAN + 2 * B.wall,
		WALL_TOP - BOTTOM,
		B.wall,
		D.width,
		-BOTTOM,
		D.height - BOTTOM,
		P.Stone,
		M.Slate
	)
	Props.blastDoor(structure, CFrame.new(0, 0, z), D.width, D.height, B.wall, { "Ave Imperator", "Command Deck" })
	Props.aquila(dressing, CFrame.new(0, 26.5, B.zMax - 0.6), 1.15)
	for side = -1, 1, 2 do
		local heights = {}
		for i = 1, 10 do
			heights[i] = 9 + 16 * math.sin(math.pi * i / 11)
		end
		Props.organPipes(dressing, CFrame.new(side * 20.5, 0, B.zMax - 0.9), heights, 1.4)
	end
end

local function throne(dressing: Instance)
	local tiers = { { 11, 0 }, { 8.5, 1 }, { 6, 2 } }
	for _, tier in tiers do
		local size, y = tier[1], tier[2]
		Kit.part(dressing, "Dais", Vector3.new(size, 1, size), CFrame.new(0, y + 0.5, THRONE_Z), P.StoneDark, M.Slate)
		Kit.part(
			dressing,
			"DaisTrim",
			Vector3.new(size + 0.2, 0.15, size + 0.2),
			CFrame.new(0, y + 0.95, THRONE_Z),
			P.Brass,
			M.Metal
		)
	end
	local t = CFrame.new(0, 3, THRONE_Z)
	Kit.part(dressing, "ThroneBase", Vector3.new(3.6, 1.4, 3.2), t * CFrame.new(0, 0.7, 0.2), P.Gunmetal, M.Metal)
	Kit.seat(dressing, "CommandThrone", Vector3.new(2.8, 0.5, 2.6), t * CFrame.new(0, 1.65, 0), P.ImperialRed, M.Fabric)
	Kit.part(dressing, "ThroneBack", Vector3.new(3.6, 9, 0.9), t * CFrame.new(0, 5.9, 1.55), P.Iron, M.Metal)
	Kit.part(
		dressing,
		"ThroneCushion",
		Vector3.new(2.6, 4.4, 0.2),
		t * CFrame.new(0, 4.3, 1.05),
		P.ImperialRed,
		M.Fabric
	)
	for s = -1, 1, 2 do
		Kit.part(dressing, "ThroneTrim", Vector3.new(0.35, 9, 1.0), t * CFrame.new(s * 1.8, 5.9, 1.55), P.Gold, M.Metal)
		Kit.column(dressing, "ThroneFinial", 1.4, 0.5, t * CFrame.new(s * 1.8, 10.4, 1.55), P.Gold, M.Metal)
		Kit.ball(dressing, "ThroneFinial", 0.6, t * CFrame.new(s * 1.8, 11.9, 1.55), P.Gold, M.Metal)
		Kit.part(dressing, "Armrest", Vector3.new(0.8, 0.5, 2.8), t * CFrame.new(s * 1.8, 3.0, 0), P.Gunmetal, M.Metal)
		Kit.part(
			dressing,
			"ArmSupport",
			Vector3.new(0.6, 1.6, 0.6),
			t * CFrame.new(s * 1.8, 2.15, -1.0),
			P.Iron,
			M.Metal
		)
	end
	Kit.triangle(
		dressing,
		"ThroneSpire",
		(t * CFrame.new(-1.8, 10.4, 1.55)).Position,
		(t * CFrame.new(1.8, 10.4, 1.55)).Position,
		(t * CFrame.new(0, 13.6, 1.55)).Position,
		0.9,
		P.Iron,
		M.Metal
	)
	Props.skull(dressing, t * CFrame.new(0, 10.9, 0.95), 1.0)
	Props.aquila(dressing, t * CFrame.new(0, 7.6, 0.92), 0.15)

	-- Left arm: a small auspex readout. Right arm: the general quarters lever.
	local readout = Kit.part(
		dressing,
		"ArmScreen",
		Vector3.new(0.9, 0.7, 0.1),
		t * CFrame.new(-1.8, 3.65, -0.9) * CFrame.Angles(math.rad(-35), 0, 0),
		P.ScreenBack,
		M.SmoothPlastic,
		DECOR
	)
	local label = Kit.surfaceText(readout, Enum.NormalId.Back, "", {
		font = Enum.Font.Code,
		color = P.Cogitator,
		background = P.ScreenBack,
		lightInfluence = 0,
		scaled = false,
		size = 8,
		alignX = Enum.TextXAlignment.Left,
		alignY = Enum.TextYAlignment.Top,
	})
	label:SetAttribute("Fx", "Cogitator")
	label:SetAttribute("Lines", 4)
	Kit.part(
		dressing,
		"LeverPlate",
		Vector3.new(0.7, 0.15, 0.9),
		t * CFrame.new(1.8, 3.32, -0.9),
		P.Brass,
		M.Metal,
		DECOR
	)
	Kit.pipe(
		dressing,
		"Lever",
		(t * CFrame.new(1.8, 3.35, -0.9)).Position,
		(t * CFrame.new(1.8, 4.3, -1.2)).Position,
		0.15,
		P.Iron,
		M.Metal,
		DECOR
	)
	local knob = Kit.ball(dressing, "LeverKnob", 0.42, t * CFrame.new(1.8, 4.35, -1.22), P.Alert, M.Neon, GLOW)
	Kit.new("ProximityPrompt", {
		Name = "GeneralQuarters",
		ActionText = "Sound General Quarters",
		ObjectText = "Command Throne",
		HoldDuration = 0.6,
		MaxActivationDistance = 9,
		RequiresLineOfSight = false,
	}, knob):SetAttribute("Action", "RedAlert")

	for s = -1, 1, 2 do
		Kit.cable(
			dressing,
			(t * CFrame.new(s * 1.2, 4, 2.0)).Position,
			(t * CFrame.new(s * 2.6, 0.05, 4.2)).Position,
			0.7,
			0.3,
			P.Black,
			6
		)
		Props.brazier(dressing, Vector3.new(s * 4.6, 0, THRONE_Z - 7))
	end
end

local function hololith(dressing: Instance)
	local base = Vector3.new(0, 0, HOLOLITH_Z)
	Kit.column(dressing, "HololithFoot", 1.0, 4.6, base, P.Brass, M.Metal)
	Kit.column(dressing, "HololithPedestal", 2.4, 3.2, base + Vector3.new(0, 1, 0), P.Iron, M.Metal)
	Kit.column(dressing, "HololithTable", 0.35, 4.4, base + Vector3.new(0, 3.4, 0), P.Brass, M.Metal)
	Kit.column(dressing, "HololithLens", 0.15, 1.3, base + Vector3.new(0, 3.75, 0), P.Hologram, M.Neon, GLOW)
	for k = 0, 3 do
		local a = math.rad(k * 90 + 45)
		Props.skull(
			dressing,
			Kit.lookAt(
				base + Vector3.new(math.cos(a) * 1.65, 2.4, math.sin(a) * 1.65),
				base + Vector3.new(math.cos(a) * 4, 2.4, math.sin(a) * 4)
			),
			0.5
		)
	end

	local centre = CFrame.new(base + Vector3.new(0, 6.6, 0))
	local holo = Kit.model(dressing, "Hololith")
	local core = Kit.part(
		holo,
		"Pivot",
		Vector3.new(0.2, 0.2, 0.2),
		centre,
		P.Hologram,
		M.SmoothPlastic,
		{ Transparency = 1, CanCollide = false }
	)
	holo.PrimaryPart = core
	Kit.ball(holo, "HoloPlanet", 3.2, centre, P.Hologram, M.ForceField, GLOW)
	Kit.ball(
		holo,
		"HoloCore",
		2.2,
		centre,
		Color3.fromRGB(30, 140, 100),
		M.Neon,
		{ CanCollide = false, CastShadow = false, Transparency = 0.6 }
	)
	local ring = Props.ring(
		holo,
		"HoloOrbit",
		centre * CFrame.Angles(math.rad(18), 0, 0),
		2.7,
		0.1,
		28,
		P.Hologram,
		M.Neon,
		{ CanCollide = false, CastShadow = false, Transparency = 0.3 }
	)
	Kit.ball(
		ring,
		"HoloMoon",
		0.45,
		centre * CFrame.Angles(math.rad(18), 0, 0) * CFrame.new(2.7, 0, 0),
		P.Hologram,
		M.Neon,
		GLOW
	)
	Kit.column(
		holo,
		"HoloBeam",
		1.6,
		1.0,
		base + Vector3.new(0, 3.85, 0),
		P.Hologram,
		M.Neon,
		{ CanCollide = false, CastShadow = false, Transparency = 0.85 }
	)
	Kit.pointLight(core, P.Hologram, 16, 1.2)
	holo.WorldPivot = centre
	holo:SetAttribute("Fx", "Hologram")
	holo:SetAttribute("SpinSpeed", 0.35)
end

-- The void beyond the viewport: a hive world and its moon.
local function void(ship: Instance)
	local void = Kit.model(ship, "Void")
	local far = { CanCollide = false, CastShadow = false, CanQuery = false }
	Kit.ball(void, "Planet", 1400, Vector3.new(430, 150, -1750), Color3.fromRGB(104, 50, 30), M.Neon, far)
	Kit.ball(void, "Atmosphere", 1470, Vector3.new(430, 150, -1750), Color3.fromRGB(255, 150, 90), M.ForceField, far)
	Kit.ball(void, "Moon", 220, Vector3.new(-520, 380, -2300), Color3.fromRGB(58, 58, 66), M.Neon, far)
end

function Bridge.build(ship: Model)
	local room = Kit.model(ship, "Bridge")
	local structure = Kit.model(room, "Structure")
	local dressing = Kit.model(room, "Dressing")
	deck(structure)
	pits(structure, dressing)
	walls(structure, dressing)
	vault(structure, dressing)
	viewport(structure, dressing)
	rearWall(structure, dressing)
	throne(dressing)
	hololith(dressing)
	Props.servoSkull(dressing, CFrame.new(0, 15, MID - 2 + 12), Vector3.new(17, 1.2, 12), 0.16, 1.7)
	void(ship)
end

return Bridge
