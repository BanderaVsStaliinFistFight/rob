--[[
	Kit: low-level construction helpers shared by every room.

	Everything in the builder only uses Instance.new and Roblox datatypes, so the
	same code runs in Roblox Studio and in Lune (which bakes the .rbxm). Lune's
	CFrame.lookAt does not match Roblox, so orientation helpers here build frames
	with CFrame.fromMatrix instead.
]]

local Kit = {}

Kit.Palette = {
	Hull = Color3.fromRGB(58, 56, 53),
	HullDark = Color3.fromRGB(33, 32, 30),
	Iron = Color3.fromRGB(76, 72, 67),
	Gunmetal = Color3.fromRGB(98, 96, 93),
	Stone = Color3.fromRGB(84, 79, 73),
	StoneDark = Color3.fromRGB(54, 51, 48),
	Brass = Color3.fromRGB(170, 128, 58),
	Gold = Color3.fromRGB(216, 170, 68),
	Bone = Color3.fromRGB(218, 206, 178),
	Marble = Color3.fromRGB(196, 190, 178),
	ImperialRed = Color3.fromRGB(116, 18, 16),
	MechanicusRed = Color3.fromRGB(150, 26, 20),
	Black = Color3.fromRGB(16, 16, 16),
	Hazard = Color3.fromRGB(222, 170, 24),
	Wood = Color3.fromRGB(72, 45, 28),
	Parchment = Color3.fromRGB(228, 214, 172),
	Wax = Color3.fromRGB(148, 18, 18),
	Candle = Color3.fromRGB(236, 226, 196),
	LumenWarm = Color3.fromRGB(255, 176, 108),
	LampGlass = Color3.fromRGB(255, 222, 176),
	Mortar = Color3.fromRGB(40, 37, 34),
	Seam = Color3.fromRGB(26, 25, 23),
	Flame = Color3.fromRGB(255, 168, 64),
	Cogitator = Color3.fromRGB(90, 255, 140),
	ScreenBack = Color3.fromRGB(6, 20, 10),
	Plasma = Color3.fromRGB(120, 210, 255),
	Hologram = Color3.fromRGB(80, 255, 190),
	Alert = Color3.fromRGB(255, 40, 28),
}

local Material = Enum.Material

-- Deterministic pseudo-random numbers (Park-Miller), so every bake is identical.
function Kit.random(seed: number): (min: number?, max: number?) -> number
	local state = math.max(1, math.floor(seed) % 2147483647)
	return function(min: number?, max: number?): number
		state = (state * 16807) % 2147483647
		local r = state / 2147483647
		if min and max then
			return min + (max - min) * r
		end
		return r
	end
end

-- Instances --------------------------------------------------------------

function Kit.new(className: string, props: { [string]: any }?, parent: Instance?): any
	local inst: any = Instance.new(className)
	if props then
		for key, value in props do
			inst[key] = value
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Kit.model(parent: Instance, name: string): Model
	return Kit.new("Model", { Name = name }, parent)
end

local function finishPart(
	p: any,
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): any
	p.Name = name
	p.Anchored = true
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if props then
		for key, value in props do
			p[key] = value
		end
	end
	p.Parent = parent
	return p
end

function Kit.part(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Part
	return finishPart(Instance.new("Part"), parent, name, size, cf, color, material, props)
end

-- WedgePart: full along the bottom and back (+Z) faces, sloping up towards the back.
function Kit.wedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): WedgePart
	return finishPart(Instance.new("WedgePart"), parent, name, size, cf, color, material, props)
end

-- Seat a character can sit in; they face the CFrame's -Z.
function Kit.seat(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Seat
	local seat = finishPart(Instance.new("Seat"), parent, name, size, cf, color, material, props)
	seat.CanTouch = true
	return seat
end

-- Cylinder whose axis runs along the CFrame's X axis.
function Kit.cylinder(
	parent: Instance,
	name: string,
	length: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	return finishPart(p, parent, name, Vector3.new(length, diameter, diameter), cf, color, material, props)
end

-- Upright cylinder standing on `base` (a position or CFrame at its bottom centre).
function Kit.column(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	base: Vector3 | CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Part
	local cf = if typeof(base) == "Vector3" then CFrame.new(base) else base
	return Kit.cylinder(
		parent,
		name,
		height,
		diameter,
		cf * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material,
		props
	)
end

-- Flat disc facing the CFrame's -Z (front) direction, centred on `cf`.
function Kit.disc(
	parent: Instance,
	name: string,
	thickness: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Part
	return Kit.cylinder(
		parent,
		name,
		thickness,
		diameter,
		cf * CFrame.Angles(0, math.pi / 2, 0),
		color,
		material,
		props
	)
end

function Kit.ball(
	parent: Instance,
	name: string,
	diameter: number,
	at: Vector3 | CFrame,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	local cf = if typeof(at) == "Vector3" then CFrame.new(at) else at
	return finishPart(p, parent, name, Vector3.new(diameter, diameter, diameter), cf, color, material, props)
end

-- Orientation -------------------------------------------------------------

-- Frame at `position` whose -Z (LookVector) points at `target`.
function Kit.lookAt(position: Vector3, target: Vector3, upHint: Vector3?): CFrame
	local look = (target - position).Unit
	local up = upHint or Vector3.yAxis
	if math.abs(look:Dot(up)) > 0.999 then
		up = Vector3.zAxis
	end
	local right = look:Cross(up).Unit
	return CFrame.fromMatrix(position, right, right:Cross(look))
end

-- Frame centred between two points with its X axis running from p0 to p1.
-- The Y axis stays as close to world-up as possible. Also returns the length.
function Kit.alongX(p0: Vector3, p1: Vector3): (CFrame, number)
	local delta = p1 - p0
	local x = delta.Unit
	local ref = if math.abs(x.Y) < 0.95 then Vector3.yAxis else Vector3.zAxis
	local z = x:Cross(ref).Unit
	return CFrame.fromMatrix((p0 + p1) / 2, x, z:Cross(x)), delta.Magnitude
end

-- Shapes between points ---------------------------------------------------

-- Rectangular bar from p0 to p1 (`height` is the up-ish dimension).
function Kit.beam(
	parent: Instance,
	name: string,
	p0: Vector3,
	p1: Vector3,
	width: number,
	height: number,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Part
	local cf, length = Kit.alongX(p0, p1)
	return Kit.part(parent, name, Vector3.new(length, height, width), cf, color, material, props)
end

function Kit.pipe(
	parent: Instance,
	name: string,
	p0: Vector3,
	p1: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): Part
	local cf, length = Kit.alongX(p0, p1)
	return Kit.cylinder(parent, name, length, diameter, cf, color, material, props)
end

-- Sagging cable between two points, built from short pipe segments.
function Kit.cable(
	parent: Instance,
	p0: Vector3,
	p1: Vector3,
	sag: number,
	diameter: number,
	color: Color3,
	segments: number?
)
	local n = segments or 8
	local last = p0
	for i = 1, n do
		local t = i / n
		local point = p0:Lerp(p1, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		local cf, length = Kit.alongX(last, point)
		Kit.cylinder(
			parent,
			"Cable",
			length + diameter * 0.6,
			diameter,
			cf,
			color,
			Material.Rubber,
			{ CanCollide = false, CastShadow = false }
		)
		last = point
	end
end

-- Flat triangle with corners a, b, c, made of two wedges (the classic Roblox
-- triangle technique). Returns both wedges.
function Kit.triangle(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): (WedgePart, WedgePart)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local w1 = Kit.wedge(
		parent,
		name,
		Vector3.new(thickness, height, math.abs(ab:Dot(back))),
		CFrame.fromMatrix((a + b) / 2, right, up, back),
		color,
		material,
		props
	)
	local w2 = Kit.wedge(
		parent,
		name,
		Vector3.new(thickness, height, math.abs(ac:Dot(back))),
		CFrame.fromMatrix((a + c) / 2, -right, up, -back),
		color,
		material,
		props
	)
	return w1, w2
end

-- Gothic arches -------------------------------------------------------------
--[[
	Arch space: X across the span (0 = centre line), Y up (0 = springing line),
	Z through the arch. Each side is an arc whose centre sits on the springing
	line; a radius larger than span/2 gives the pointed gothic profile.
]]

-- Height of the apex above the springing line.
function Kit.archRise(span: number, radius: number): number
	local cx = span / 2 - radius
	return math.sqrt(radius * radius - cx * cx)
end

-- Half-width of the opening at height `y` above the springing line.
function Kit.archHalfWidth(span: number, radius: number, y: number): number
	local h = radius * radius - y * y
	if h <= 0 then
		return 0
	end
	return math.max(0, span / 2 - radius + math.sqrt(h))
end

-- Ring of blocks following the arch, sitting just outside the opening so the
-- clear span stays exactly `span`. `base` is the centre of the springing line.
function Kit.archRib(
	parent: Instance,
	name: string,
	base: CFrame,
	span: number,
	radius: number,
	thickness: number,
	depth: number,
	segments: number,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): { BasePart }
	local cx = span / 2 - radius
	local top = math.acos(math.clamp(-cx / radius, -1, 1))
	local step = top / segments
	local mid = radius + thickness / 2
	local length = 2 * (radius + thickness) * math.sin(step / 2) + 0.05
	local parts: { BasePart } = {}
	for side = -1, 1, 2 do
		for i = 0, segments - 1 do
			local angle = step * (i + 0.5)
			local x = (cx + mid * math.cos(angle)) * side
			local y = mid * math.sin(angle)
			local cf = base * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, side * (angle + math.pi / 2))
			table.insert(
				parts,
				Kit.part(parent, name, Vector3.new(length, thickness, depth), cf, color, material, props)
			)
		end
	end
	return parts
end

-- Walls ----------------------------------------------------------------------

--[[
	Solid wall with a pointed-arch hole through it. `base` is the bottom centre of
	the wall: X along the wall, Y up, Z through it. The stepped spandrels leave
	small notches along the curve, so always frame the hole with an archRib at
	least as deep as the wall. Returns the apex height of the opening.
]]
export type ArchWall = {
	width: number,
	height: number,
	thickness: number,
	openWidth: number,
	sill: number,
	spring: number,
	radius: number,
	step: number?,
}

function Kit.archWall(
	parent: Instance,
	name: string,
	base: CFrame,
	o: ArchWall,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
): number
	local half = o.width / 2
	local open = o.openWidth / 2
	local function slab(x0: number, x1: number, y0: number, y1: number)
		if x1 - x0 > 0.02 and y1 - y0 > 0.02 then
			local cf = base * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0)
			Kit.part(parent, name, Vector3.new(x1 - x0, y1 - y0, o.thickness), cf, color, material, props)
		end
	end
	slab(-half, -open, 0, o.height)
	slab(open, half, 0, o.height)
	slab(-open, open, 0, o.sill)
	local apex = o.spring + Kit.archRise(o.openWidth, o.radius)
	local step = o.step or 0.5
	local y = o.spring
	while y < apex - 1e-4 do
		local y1 = math.min(y + step, apex)
		local inner = Kit.archHalfWidth(o.openWidth, o.radius, y - o.spring)
		slab(-open, -inner, y, y1)
		slab(inner, open, y, y1)
		y = y1
	end
	slab(-open, open, apex, o.height)
	return apex
end

-- Solid wall with a rectangular hole (doorways). Same `base` convention as archWall.
function Kit.doorWall(
	parent: Instance,
	name: string,
	base: CFrame,
	width: number,
	height: number,
	thickness: number,
	openWidth: number,
	openBottom: number,
	openTop: number,
	color: Color3,
	material: Enum.Material,
	props: { [string]: any }?
)
	local half, open = width / 2, openWidth / 2
	local function slab(x0: number, x1: number, y0: number, y1: number)
		if x1 - x0 > 0.02 and y1 - y0 > 0.02 then
			local cf = base * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0)
			Kit.part(parent, name, Vector3.new(x1 - x0, y1 - y0, thickness), cf, color, material, props)
		end
	end
	slab(-half, -open, 0, height)
	slab(open, half, 0, height)
	slab(-open, open, 0, openBottom)
	slab(-open, open, openTop, height)
end

-- Railings and trims ------------------------------------------------------------

-- Railing along the floor from p0 to p1 (both at floor level).
function Kit.railing(parent: Instance, p0: Vector3, p1: Vector3, height: number?, spacing: number?)
	local h = height or 3.2
	local delta = p1 - p0
	local posts = math.max(1, math.floor(delta.Magnitude / (spacing or 3.5) + 0.5))
	for i = 0, posts do
		local base = p0:Lerp(p1, i / posts)
		Kit.column(parent, "RailPost", h, 0.35, base, Kit.Palette.Iron, Material.Metal)
		Kit.ball(parent, "RailKnob", 0.5, base + Vector3.new(0, h, 0), Kit.Palette.Brass, Material.Metal)
	end
	local up = Vector3.new(0, h, 0)
	Kit.pipe(parent, "Rail", p0 + up, p1 + up, 0.3, Kit.Palette.Brass, Material.Metal)
	Kit.pipe(parent, "Rail", p0 + up * 0.55, p1 + up * 0.55, 0.2, Kit.Palette.Iron, Material.Metal)
end

-- Alternating yellow/black stripes laid along the CFrame's X axis.
function Kit.hazardStripes(
	parent: Instance,
	cf: CFrame,
	length: number,
	width: number,
	thickness: number,
	stripe: number?
)
	local s = stripe or 1
	local count = math.max(1, math.floor(length / s + 0.5))
	local w = length / count
	for i = 0, count - 1 do
		local color = if i % 2 == 0 then Kit.Palette.Hazard else Kit.Palette.Black
		local x = -length / 2 + w * (i + 0.5)
		Kit.part(
			parent,
			"Hazard",
			Vector3.new(w, thickness, width),
			cf * CFrame.new(x, 0, 0),
			color,
			Material.SmoothPlastic
		)
	end
end

-- Lights and text -------------------------------------------------------------

function Kit.pointLight(
	parent: Instance,
	color: Color3,
	range: number,
	brightness: number,
	shadows: boolean?
): PointLight
	return Kit.new(
		"PointLight",
		{ Color = color, Range = range, Brightness = brightness, Shadows = shadows == true },
		parent
	)
end

function Kit.spotLight(
	parent: Instance,
	color: Color3,
	range: number,
	brightness: number,
	angle: number,
	face: Enum.NormalId,
	shadows: boolean?
): SpotLight
	return Kit.new("SpotLight", {
		Color = color,
		Range = range,
		Brightness = brightness,
		Angle = angle,
		Face = face,
		Shadows = shadows == true,
	}, parent)
end

export type TextOptions = {
	font: Enum.Font?,
	color: Color3?,
	background: Color3?,
	pixelsPerStud: number?,
	lightInfluence: number?,
	scaled: boolean?,
	size: number?,
	alignX: Enum.TextXAlignment?,
	alignY: Enum.TextYAlignment?,
}

-- SurfaceGui with a single TextLabel filling one face of `part`.
function Kit.surfaceText(part: BasePart, face: Enum.NormalId, text: string, o: TextOptions?): TextLabel
	local opts: TextOptions = o or {}
	local gui = Kit.new("SurfaceGui", {
		Name = "Text",
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = opts.pixelsPerStud or 50,
		LightInfluence = opts.lightInfluence or 1,
		ClipsDescendants = true,
	}, part)
	return Kit.new("TextLabel", {
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = opts.background or Color3.new(0, 0, 0),
		BackgroundTransparency = if opts.background then 0 else 1,
		BorderSizePixel = 0,
		Font = opts.font or Enum.Font.GrenzeGotisch,
		Text = text,
		TextColor3 = opts.color or Kit.Palette.Gold,
		TextScaled = opts.scaled ~= false,
		TextSize = opts.size or 14,
		TextWrapped = true,
		TextXAlignment = opts.alignX or Enum.TextXAlignment.Center,
		TextYAlignment = opts.alignY or Enum.TextYAlignment.Center,
	}, gui)
end

return Kit
