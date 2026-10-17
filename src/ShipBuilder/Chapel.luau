--[[
	Chapel: a small Ecclesiarchy shrine off the corridor's starboard wall, with
	pews, an ossuary of honoured crew, and a stained-glass lancet over the altar.
]]

local Kit = require(script.Parent.Kit)
local Layout = require(script.Parent.Layout)
local Props = require(script.Parent.Props)
local Surface = require(script.Parent.Surface)

local P = Kit.Palette
local M = Enum.Material
local H = Layout.Chapel
local C = Layout.Corridor

local DECOR = { CanCollide = false }
local GLOW = { CanCollide = false, CastShadow = false }

local CX = (H.xMin + H.xMax) / 2
local CZ = (H.zMin + H.zMax) / 2
local LENGTH = H.xMax - H.xMin
local SPAN = H.zMax - H.zMin
local APEX = H.spring + Kit.archRise(SPAN, H.radius)
local TOP = APEX + 1.6
local WALL = 2
local RIBS = { H.xMin + 0.8, 15, 20, 25, H.xMax - 0.8 }

local Chapel = {}

-- Dressed limestone, warmer and finer than the bridge's slate
local function limestone(seed: number): Surface.Style
	return {
		course = 1.6,
		length = { 2.2, 3.6 },
		joint = 0.1,
		bond = true,
		colors = {
			Color3.fromRGB(124, 116, 104),
			Color3.fromRGB(114, 107, 97),
			Color3.fromRGB(132, 123, 110),
			Color3.fromRGB(106, 100, 92),
		},
		materials = { M.Limestone, M.Limestone, M.Sandstone },
		vary = 0.06,
		grime = 0.3,
		seed = seed,
	}
end

-- Vault frame: X across the span (world Z), depth along world X.
local function across(x: number, y: number): CFrame
	return CFrame.fromMatrix(Vector3.new(x, y, CZ), Vector3.zAxis, Vector3.yAxis)
end

local GLASS = {
	red = Color3.fromRGB(150, 22, 20),
	darkRed = Color3.fromRGB(104, 14, 14),
	purple = Color3.fromRGB(84, 30, 110),
	blue = Color3.fromRGB(36, 64, 168),
	gold = Color3.fromRGB(235, 176, 52),
	sky = Color3.fromRGB(44, 86, 196),
	blade = Color3.fromRGB(196, 206, 222),
}

-- Stained-glass lancet: a sword within a halo on a red field, blue border.
-- `face` is the bottom centre of the window on the wall, facing into the room.
local function stainedGlass(parent: Instance, face: CFrame)
	local cols, rectRows, cell = 11, 11, 0.8
	local radius = cols * 0.75
	local rows = rectRows + math.ceil(Kit.archRise(cols, radius))
	local function inside(r: number, c: number): boolean
		if r < 0 or r >= rows or c < 0 or c >= cols then
			return false
		end
		local y = r + 0.5
		local half = if y <= rectRows then cols / 2 else Kit.archHalfWidth(cols, radius, y - rectRows)
		return math.abs(c - (cols - 1) / 2) + 0.5 <= half + 0.15
	end
	local haloRow = 13
	for r = 0, rows - 1 do
		local first, last
		for c = 0, cols - 1 do
			if inside(r, c) then
				local x = c - (cols - 1) / 2
				local d = math.sqrt(x * x + (r - haloRow) ^ 2)
				local color
				if not (inside(r - 1, c) and inside(r + 1, c) and inside(r, c - 1) and inside(r, c + 1)) then
					color = if (r + c) % 3 == 0 then GLASS.gold else GLASS.blue
				elseif x == 0 and r >= 1 and r <= 10 then
					color = GLASS.blade
				elseif r == 11 and math.abs(x) <= 2 then
					color = GLASS.gold
				elseif x == 0 and r >= 12 and r <= 14 then
					color = GLASS.gold
				elseif d >= 2.1 and d <= 3.0 then
					color = GLASS.gold
				elseif d < 2.1 then
					color = GLASS.sky
				elseif (r + c) % 4 == 0 and (r - c) % 4 == 0 then
					color = GLASS.purple
				else
					color = if (r + c) % 2 == 0 then GLASS.red else GLASS.darkRed
				end
				Kit.part(
					parent,
					"StainedGlass",
					Vector3.new(cell * 0.86, cell * 0.86, 0.1),
					face * CFrame.new(x * cell, (r + 0.5) * cell, -0.16),
					color,
					M.Neon,
					GLOW
				)
				first = first or x
				last = x
			end
		end
		if first then
			Kit.part(
				parent,
				"Leading",
				Vector3.new((last - first + 1) * cell, cell, 0.1),
				face * CFrame.new((first + last) / 2 * cell, (r + 0.5) * cell, -0.06),
				P.Black,
				M.Metal,
				DECOR
			)
		end
	end
	-- Frame
	local span = cols * cell + 0.2
	Kit.archRib(
		parent,
		"GlassFrame",
		face * CFrame.new(0, rectRows * cell, -0.2),
		span,
		span * 0.75,
		0.5,
		0.45,
		8,
		P.Brass,
		M.Metal,
		DECOR
	)
	for s = -1, 1, 2 do
		Kit.part(
			parent,
			"GlassFrame",
			Vector3.new(0.5, rectRows * cell, 0.45),
			face * CFrame.new(s * (span / 2 + 0.25), rectRows * cell / 2, -0.2),
			P.Brass,
			M.Metal,
			DECOR
		)
	end
	Kit.part(
		parent,
		"GlassSill",
		Vector3.new(span + 1.2, 0.4, 0.8),
		face * CFrame.new(0, -0.2, -0.4),
		P.Brass,
		M.Metal,
		DECOR
	)
	local height = rows * cell
	local glow = Kit.part(
		parent,
		"GlassGlow",
		Vector3.new(span, height, 0.1),
		face * CFrame.new(0, height / 2, -0.5),
		P.Black,
		M.SmoothPlastic,
		{ Transparency = 1, CanCollide = false, CastShadow = false }
	)
	Kit.new(
		"SurfaceLight",
		{ Face = Enum.NormalId.Front, Color = Color3.fromRGB(255, 165, 115), Range = 22, Brightness = 1.3, Angle = 80 },
		glow
	)
end

local function shell(structure: Instance)
	Kit.part(
		structure,
		"Subfloor",
		Vector3.new(LENGTH + WALL, 1, SPAN + 2 * WALL),
		CFrame.new(CX + WALL / 2, -1.5, CZ),
		P.HullDark,
		M.Metal
	)
	local rand = Kit.random(77)
	for i = 0, LENGTH / 2 - 1 do
		for j = 0, SPAN / 2 - 1 do
			local color = Surface.shade(if (i + j) % 2 == 0 then P.Marble else P.StoneDark, 1 + rand(-0.07, 0.07))
			Kit.part(
				structure,
				"FloorTile",
				Vector3.new(2, 1, 2),
				CFrame.new(H.xMin + 1 + 2 * i, -0.5, H.zMin + 1 + 2 * j),
				color,
				M.Marble
			)
		end
	end
	Kit.part(structure, "Carpet", Vector3.new(14, 0.08, 3.2), CFrame.new(H.xMin + 7, 0.04, CZ), P.ImperialRed, M.Fabric)
	for s = -1, 1, 2 do
		Kit.part(
			structure,
			"CarpetTrim",
			Vector3.new(14, 0.1, 0.25),
			CFrame.new(H.xMin + 7, 0.05, CZ + s * 1.7),
			P.Gold,
			M.Fabric
		)
	end

	-- Walls: north/south up to the springing line, east and the west gable full height
	for s = -1, 1, 2 do
		local z = CZ + s * (SPAN / 2 + WALL / 2)
		Kit.part(
			structure,
			"Wall",
			Vector3.new(LENGTH + WALL, H.spring + 2, WALL),
			CFrame.new(CX + WALL / 2, (H.spring - 2) / 2, z),
			P.Mortar,
			M.Concrete
		)
		Kit.part(
			structure,
			"Cornice",
			Vector3.new(LENGTH, 0.6, 0.9),
			CFrame.new(CX, H.spring, CZ + s * (SPAN / 2 - 0.45)),
			P.Brass,
			M.Metal
		)
		Kit.part(
			structure,
			"Dado",
			Vector3.new(LENGTH, 0.3, 0.3),
			CFrame.new(CX, 3, CZ + s * (SPAN / 2 - 0.15)),
			P.Brass,
			M.Metal
		)
		for _, x in { 15, 20, 25 } do
			Kit.part(
				structure,
				"Pilaster",
				Vector3.new(1.2, H.spring, 0.8),
				CFrame.new(x, H.spring / 2, CZ + s * (SPAN / 2 - 0.4)),
				P.StoneDark,
				M.Slate
			)
			Kit.part(
				structure,
				"PilasterCap",
				Vector3.new(1.6, 0.6, 1.1),
				CFrame.new(x, H.spring - 0.5, CZ + s * (SPAN / 2 - 0.55)),
				P.Brass,
				M.Metal
			)
		end
	end
	Kit.part(
		structure,
		"Wall",
		Vector3.new(WALL, TOP + 2, SPAN + 2 * WALL),
		CFrame.new(H.xMax + WALL / 2, (TOP - 2) / 2, CZ),
		P.Mortar,
		M.Concrete
	)
	Kit.part(
		structure,
		"Gable",
		Vector3.new(0.8, TOP - C.spring, SPAN + 2 * WALL),
		CFrame.new(H.xMin - 0.4, (C.spring + TOP) / 2, CZ),
		P.Mortar,
		M.Concrete
	)

	-- Masonry facing on all four walls
	local vault = { span = SPAN, spring = H.spring, radius = H.radius }
	local pilasters = {}
	for _, x in { -5, 0, 5 } do
		table.insert(pilasters, { x - 0.65, x + 0.65, 0, H.spring })
	end
	for s, z in { H.zMin, H.zMax } do
		local face = Kit.lookAt(Vector3.new(CX, 0, z), Vector3.new(CX, 0, CZ))
		Surface.clad(
			structure,
			face,
			{ x0 = -LENGTH / 2, x1 = LENGTH / 2, y0 = 0, y1 = H.spring - 0.3, skips = pilasters },
			limestone(70 + s)
		)
	end
	Surface.clad(structure, Kit.lookAt(Vector3.new(H.xMax, 0, CZ), Vector3.new(0, 0, CZ)), {
		x0 = -SPAN / 2,
		x1 = SPAN / 2,
		y0 = 0,
		y1 = APEX,
		vault = vault,
		holes = { Surface.archHole(0, 9.0, 6.6, 15.8, 6.75, 0.4) },
	}, limestone(73))
	Surface.clad(structure, Kit.lookAt(Vector3.new(H.xMin, 0, CZ), Vector3.new(100, 0, CZ)), {
		x0 = -SPAN / 2,
		x1 = SPAN / 2,
		y0 = 0,
		y1 = APEX,
		vault = vault,
		holes = {
			Surface.archHole(
				Layout.ChapelDoor.z - CZ,
				Layout.ChapelDoor.width,
				0,
				Layout.ChapelDoor.spring,
				Layout.ChapelDoor.width * 0.75,
				0.5
			),
		},
	}, limestone(74))

	-- Vault
	Kit.archRib(
		structure,
		"Vault",
		across(CX, H.spring),
		SPAN + 1.2,
		H.radius + 0.6,
		0.6,
		LENGTH,
		14,
		P.StoneDark,
		M.Slate
	)
	for _, x in RIBS do
		Kit.archRib(structure, "Rib", across(x, H.spring), SPAN, H.radius, 0.9, 1.2, 10, P.Iron, M.Metal)
		Kit.disc(
			structure,
			"Boss",
			0.5,
			1.8,
			CFrame.new(x, APEX - 0.1, CZ) * CFrame.Angles(-math.pi / 2, 0, 0),
			P.Brass,
			M.Metal
		)
	end
end

local function sanctuary(dressing: Instance)
	-- Stepped dais, altar and reliquary
	Kit.part(dressing, "AltarStep", Vector3.new(6, 0.6, 14), CFrame.new(27, 0.3, CZ), P.Marble, M.Marble)
	Kit.part(dressing, "AltarStep", Vector3.new(4.5, 0.6, 12), CFrame.new(27.75, 0.9, CZ), P.Marble, M.Marble)
	Kit.part(dressing, "StepTrim", Vector3.new(0.25, 0.12, 14), CFrame.new(24.12, 0.6, CZ), P.Gold, M.Metal)
	Kit.part(dressing, "StepTrim", Vector3.new(0.25, 0.12, 12), CFrame.new(25.62, 1.2, CZ), P.Gold, M.Metal)
	Kit.part(dressing, "Altar", Vector3.new(2.6, 3.4, 7), CFrame.new(27.6, 2.9, CZ), P.Marble, M.Marble)
	Kit.part(dressing, "AltarTop", Vector3.new(3.0, 0.3, 7.6), CFrame.new(27.6, 4.75, CZ), P.Bone, M.Marble)
	Kit.part(
		dressing,
		"AltarCloth",
		Vector3.new(0.08, 2.8, 4.2),
		CFrame.new(26.25, 3.2, CZ),
		P.ImperialRed,
		M.Fabric,
		DECOR
	)
	for _, y in { 1.85, 4.55 } do
		Kit.part(
			dressing,
			"AltarClothTrim",
			Vector3.new(0.1, 0.22, 4.2),
			CFrame.new(26.22, y, CZ),
			P.Gold,
			M.Fabric,
			DECOR
		)
	end
	Kit.disc(
		dressing,
		"AltarEmblem",
		0.06,
		1.6,
		Kit.lookAt(Vector3.new(26.18, 3.3, CZ), Vector3.new(0, 3.3, CZ)),
		P.Gold,
		M.Fabric,
		DECOR
	)
	Props.skull(dressing, Kit.lookAt(Vector3.new(25.9, 3.3, CZ), Vector3.new(0, 3.3, CZ)), 0.7)

	Kit.part(dressing, "Reliquary", Vector3.new(1.2, 1.0, 1.8), CFrame.new(27.9, 5.4, CZ), P.Gold, M.Metal)
	Kit.ball(dressing, "ReliquaryDome", 1.0, Vector3.new(27.9, 5.95, CZ), P.Gold, M.Metal)
	Props.skull(dressing, Kit.lookAt(Vector3.new(27.9, 6.85, CZ), Vector3.new(0, 6.85, CZ)), 0.8)
	for s = -1, 1, 2 do
		Props.candelabrum(dressing, Vector3.new(27.6, 4.9, CZ + s * 2.8), 1.2)
		for k = 0, 1 do
			Props.candle(dressing, Vector3.new(26.8, 4.9, CZ + s * (1.5 + k * 0.6)), 0.5 + k * 0.3)
		end
		Props.candelabrum(dressing, Vector3.new(23, 0, CZ + s * 6.5), 4.5)
	end

	-- Kneeler where the faithful pray
	local kneeler =
		Kit.part(dressing, "Kneeler", Vector3.new(1.2, 0.5, 3.0), CFrame.new(24.9, 0.85, CZ), P.ImperialRed, M.Fabric)
	Kit.new("ProximityPrompt", {
		Name = "Prayer",
		ActionText = "Pray",
		ObjectText = "Shrine of the God-Emperor",
		HoldDuration = 1.5,
		MaxActivationDistance = 8,
		RequiresLineOfSight = false,
	}, kneeler):SetAttribute("Action", "Pray")

	stainedGlass(dressing, Kit.lookAt(Vector3.new(H.xMax, 7, CZ), Vector3.new(0, 7, CZ)))
	-- Coloured light falling from the glass through the incense
	local fall = Vector3.new(-0.75, -0.66, 0).Unit
	for _, sh in { { 17, -1.6, Color3.fromRGB(255, 150, 120) }, { 13, 1.4, Color3.fromRGB(255, 212, 150) } } do
		local p0 = Vector3.new(H.xMax - 0.4, sh[1], CZ + sh[2])
		Props.lightShaft(dressing, p0, p0 + fall * (sh[1] / -fall.Y), 3.5, 5.5, sh[3], 0.95)
	end
	Props.dust(dressing, CFrame.new(22, 9, CZ), Vector3.new(14, 14, 12), 8)
	Props.haze(dressing, CFrame.new(CX, 6, CZ), Vector3.new(LENGTH - 4, 8, SPAN - 4), 0.4)
	-- Hung off to one side so it doesn't block the window
	Props.censer(dressing, Vector3.new(26, 21.3, CZ + 5.5), 9)
end

local function nave(dressing: Instance)
	for _, x in { 13.5, 17, 20.5 } do
		for _, z in { CZ - 5.25, CZ + 5.25 } do
			Props.pew(dressing, CFrame.new(x, 0, z) * CFrame.Angles(0, -math.pi / 2, 0), 5.5)
		end
	end
	-- Ossuary shelves of honoured dead along both walls
	local bays = { { 11.6, 14.4 }, { 15.6, 19.4 }, { 20.6, 24.4 } }
	for s = -1, 1, 2 do
		local wallZ = CZ + s * (SPAN / 2)
		for _, bay in bays do
			local x0, x1 = bay[1], bay[2]
			local len = x1 - x0
			Kit.part(
				dressing,
				"Ossuary",
				Vector3.new(len, 0.3, 1.0),
				CFrame.new((x0 + x1) / 2, 6.6, wallZ - s * 0.5),
				P.Iron,
				M.Metal
			)
			Kit.part(
				dressing,
				"OssuaryBack",
				Vector3.new(len, 2.2, 0.1),
				CFrame.new((x0 + x1) / 2, 7.8, wallZ - s * 0.05),
				P.Black,
				M.Slate,
				DECOR
			)
			local count = math.floor(len / 1.25)
			for k = 1, count do
				local x = x0 + len * k / (count + 1)
				Props.skull(
					dressing,
					Kit.lookAt(Vector3.new(x, 7.25, wallZ - s * 0.55), Vector3.new(x, 7.25, CZ)),
					0.95
				)
			end
		end
		local face = Kit.lookAt(Vector3.new(20, 6, CZ + s * (SPAN / 2 - 0.8)), Vector3.new(20, 6, CZ))
		Props.sconce(dressing, face, nil, 16, 0.8)
	end
	for _, x in { 15, 20, 25 } do
		Props.skull(dressing, CFrame.new(x, APEX - 0.75, CZ) * CFrame.Angles(-math.pi / 2, 0, 0), 0.7)
		if x < 25 then
			Props.lantern(dressing, Vector3.new(x, APEX - 1.2, CZ), 7.5, if x == 20 then 0.4 else nil, 24)
		end
	end
	Props.plaque(
		dressing,
		Kit.lookAt(Vector3.new(H.xMin, 14.6, CZ), Vector3.new(40, 14.6, CZ)),
		Vector2.new(8, 1.8),
		"The Emperor Protects"
	)
	Props.banner(
		dressing,
		Kit.lookAt(Vector3.new(H.xMin + 0.9, 21, CZ), Vector3.new(40, 21, CZ)),
		4,
		5.2,
		P.ImperialRed,
		P.Gold,
		nil
	)
end

function Chapel.build(ship: Model)
	local room = Kit.model(ship, "Chapel")
	local structure = Kit.model(room, "Structure")
	local dressing = Kit.model(room, "Dressing")
	shell(structure)
	sanctuary(dressing)
	nave(dressing)
end

return Chapel
