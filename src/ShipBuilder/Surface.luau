--[[
	Surface: cladding and weathering.

	Walls are built as plain solid slabs in a dark "carcass" colour. These
	helpers face them with stone courses or metal plates that stand slightly
	proud, so the gaps between pieces read as mortar joints or panel seams.
	They also add the grime, soot, rust and wear that stop surfaces looking
	factory-new.

	Face space: `face` sits on a wall's visible surface with X along the wall,
	Y up and -Z pointing out of the wall towards the viewer.
]]

local Kit = require(script.Parent.Kit)

local M = Enum.Material

local Surface = {}

local STAIN = { CanCollide = false, CanQuery = false, CastShadow = false }

-- A hole the cladding must leave open: a window or doorway.
export type Hole = {
	x: number, -- centre
	width: number,
	sill: number,
	top: number, -- top of the straight sides (the springing line for arches)
	radius: number?, -- pointed-arch head; nil for a square-headed hole
}

-- The patch of wall to clad, in face space.
export type Region = {
	x0: number,
	x1: number,
	y0: number,
	y1: number,
	holes: { Hole }?,
	skips: { { number } }?, -- {x0, x1, y0, y1} rectangles to leave bare
	vault: { span: number, spring: number, radius: number }?, -- clad only beneath this arch
}

export type Style = {
	course: number, -- row height
	length: { number }, -- {min, max} piece length
	joint: number, -- gap between pieces
	bond: boolean, -- stagger alternate rows (masonry) instead of a grid (plating)
	colors: { Color3 },
	materials: { Enum.Material },
	vary: number, -- brightness jitter, e.g. 0.08
	grime: number?, -- darkening towards the foot of the wall
	rust: number?, -- chance of a corroded piece, higher near the floor
	proud: number?, -- how far pieces stand out of the wall
	seed: number,
}

local RUST = Color3.fromRGB(104, 66, 44)

local function subtract(intervals: { { number } }, a: number, b: number): { { number } }
	local out = {}
	for _, iv in intervals do
		if b <= iv[1] or a >= iv[2] then
			table.insert(out, iv)
		else
			if a > iv[1] then
				table.insert(out, { iv[1], a })
			end
			if b < iv[2] then
				table.insert(out, { b, iv[2] })
			end
		end
	end
	return out
end

-- Widest half-width of a hole within the band [y0, y1], or nil if the band misses it.
local function holeHalf(h: Hole, y0: number, y1: number): number?
	local apex = h.top + (if h.radius then Kit.archRise(h.width, h.radius) else 0)
	if y1 <= h.sill or y0 >= apex then
		return nil
	end
	if y0 < h.top or not h.radius then
		return h.width / 2
	end
	return Kit.archHalfWidth(h.width, h.radius, y0 - h.top)
end

-- Hole for a pointed-arch opening, grown by `margin` so the cladding tucks
-- under its frame. Keeps the arcs' centres where the opening's are.
function Surface.archHole(x: number, width: number, sill: number, spring: number, radius: number, margin: number?): Hole
	local m = margin or 0.15
	return { x = x, width = width + 2 * m, sill = sill - m, top = spring, radius = radius + m }
end

-- Scale a colour's brightness, clamped.
function Surface.shade(color: Color3, k: number): Color3
	return Color3.new(math.clamp(color.R * k, 0, 1), math.clamp(color.G * k, 0, 1), math.clamp(color.B * k, 0, 1))
end

-- Face a region of wall with stone courses or metal plates.
function Surface.clad(parent: Instance, face: CFrame, region: Region, style: Style)
	local rand = Kit.random(style.seed)
	local holes: { Hole } = region.holes or {}
	local skips: { { number } } = region.skips or {}
	local proud = style.proud or 0.08
	local depth = proud + 0.3
	local joint = style.joint
	local y = region.y0
	local row = 0
	while y < region.y1 - 0.05 do
		local y1 = math.min(y + style.course, region.y1)
		if region.y1 - y1 < style.course * 0.35 then
			y1 = region.y1
		end
		local intervals = { { region.x0, region.x1 } }
		local vault = region.vault
		if vault then
			local hw = if y1 <= vault.spring
				then vault.span / 2
				else Kit.archHalfWidth(vault.span, vault.radius, y1 - vault.spring)
			intervals = subtract(intervals, -math.huge, -hw)
			intervals = subtract(intervals, hw, math.huge)
		end
		for _, h in holes do
			local half = holeHalf(h, y, y1)
			if half then
				intervals = subtract(intervals, h.x - half, h.x + half)
			end
		end
		for _, s in skips do
			if y1 > s[3] and y < s[4] then
				intervals = subtract(intervals, s[1], s[2])
			end
		end

		local grime = if style.grime then style.grime * math.clamp(1 - (y - region.y0) / 6, 0, 1) else 0
		for _, iv in intervals do
			local x = iv[1]
			local first = true
			while iv[2] - x > joint * 2 do
				local len = rand(style.length[1], style.length[2])
				if first and style.bond and row % 2 == 1 then
					len *= 0.5
				end
				first = false
				if iv[2] - (x + len) < style.length[1] * 0.5 then
					len = iv[2] - x
				end
				local color = style.colors[math.floor(rand(1, #style.colors + 0.999))]
				local material = style.materials[math.floor(rand(1, #style.materials + 0.999))]
				color = Surface.shade(color, (1 + rand(-style.vary, style.vary)) * (1 - grime))
				if style.rust and rand() < style.rust * (1 + grime * 4) then
					material = M.CorrodedMetal
					color = color:Lerp(RUST, 0.55)
				end
				Kit.part(
					parent,
					"Cladding",
					Vector3.new(len - joint, (y1 - y) - joint, depth),
					face * CFrame.new(x + len / 2, (y + y1) / 2, depth / 2 - proud),
					color,
					material
				)
				x += len
			end
		end
		y = y1
		row += 1
	end
end

-- Floor plates on top of a deck. `cf` is the centre of the floor's top surface.
-- With `thickness` > 0.2 the plates are the floor itself and the gaps become slots.
function Surface.tiles(
	parent: Instance,
	cf: CFrame,
	sizeX: number,
	sizeZ: number,
	tile: number,
	gap: number,
	colors: { Color3 },
	material: Enum.Material,
	vary: number,
	seed: number,
	thickness: number?
)
	local rand = Kit.random(seed)
	local t = thickness or 0.06
	local nx, nz = math.max(1, math.floor(sizeX / tile + 0.5)), math.max(1, math.floor(sizeZ / tile + 0.5))
	local wx, wz = sizeX / nx, sizeZ / nz
	local lift = if thickness then -t / 2 else t / 2
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			local color = Surface.shade(colors[math.floor(rand(1, #colors + 0.999))], 1 + rand(-vary, vary))
			local p = cf * CFrame.new(-sizeX / 2 + wx * (i + 0.5), lift, -sizeZ / 2 + wz * (j + 0.5))
			Kit.part(parent, "FloorPlate", Vector3.new(wx - gap, t, wz - gap), p, color, material)
		end
	end
end

-- Weathering -----------------------------------------------------------------------

-- Soot plume rising above a flame or lamp. `face` is on the wall at the source.
function Surface.soot(parent: Instance, face: CFrame, height: number, width: number?)
	local w = width or height * 0.45
	for k = 1, 4 do
		local t = k / 4
		Kit.disc(
			parent,
			"Soot",
			0.02,
			w * (0.45 + 0.75 * t),
			face * CFrame.new(0, height * (0.15 + 0.7 * t), -0.11 - k * 0.012),
			Color3.fromRGB(14, 12, 11),
			M.SmoothPlastic,
			{ CanCollide = false, CanQuery = false, CastShadow = false, Transparency = 0.6 + 0.08 * k }
		)
	end
end

-- Rust or damp streak running down from `face`.
function Surface.streak(parent: Instance, face: CFrame, length: number, width: number, color: Color3?)
	local c = color or RUST
	local props = table.clone(STAIN)
	props.Transparency = 0.45
	Kit.part(
		parent,
		"Streak",
		Vector3.new(width, length * 0.55, 0.02),
		face * CFrame.new(0, -length * 0.275, -0.11),
		c,
		M.SmoothPlastic,
		props
	)
	props = table.clone(STAIN)
	props.Transparency = 0.7
	Kit.part(
		parent,
		"Streak",
		Vector3.new(width * 0.55, length, 0.02),
		face * CFrame.new(width * 0.1, -length * 0.5, -0.12),
		c,
		M.SmoothPlastic,
		props
	)
end

-- Glossy puddle of oil or condensation on the floor at `pos`.
function Surface.puddle(parent: Instance, pos: Vector3, diameter: number, seed: number)
	local rand = Kit.random(seed)
	for k = 1, 3 do
		local offset = Vector3.new(rand(-0.3, 0.3), 0, rand(-0.3, 0.3)) * diameter
		local props = table.clone(STAIN)
		props.Transparency = 0.15
		props.Reflectance = 0.25
		Kit.disc(
			parent,
			"Puddle",
			0.02,
			diameter * rand(0.5, 0.9),
			CFrame.new(pos + offset + Vector3.new(0, 0.07 + k * 0.004, 0)) * CFrame.Angles(math.pi / 2, 0, 0),
			Color3.fromRGB(16, 14, 12),
			M.Glass,
			props
		)
	end
end

-- Stencilled lettering painted on a surface (deck markings, warnings).
function Surface.stencil(parent: Instance, face: CFrame, size: Vector2, text: string, color: Color3?)
	local board = Kit.part(
		parent,
		"Stencil",
		Vector3.new(size.X, size.Y, 0.02),
		face * CFrame.new(0, 0, -0.12),
		Color3.new(0, 0, 0),
		M.SmoothPlastic,
		{ CanCollide = false, CanQuery = false, CastShadow = false, Transparency = 1 }
	)
	local label = Kit.surfaceText(board, Enum.NormalId.Front, text, {
		font = Enum.Font.Oswald,
		color = color or Color3.fromRGB(206, 198, 178),
		pixelsPerStud = 60,
	})
	label.TextTransparency = 0.3
	return label
end

return Surface
