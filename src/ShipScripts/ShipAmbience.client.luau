--[[
	ShipAmbience (client): everything that moves or glows. Runs on each client
	(RunContext = Client) so animation is smooth and costs the server nothing.

	Instances opt in with an Fx attribute set by the builder:
	    Lumen, Candle, ServoSkull, Spin, Hologram, ReactorCore, Beacon,
	    Blinker, Cogitator, Door (+ DoorLamp)
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ship = script.Parent
local rng = Random.new()

local ALERT = Color3.fromRGB(255, 40, 28)
local PLASMA = Color3.fromRGB(120, 210, 255)
local PLASMA_HOT = Color3.fromRGB(235, 250, 255)
local DOOR_OPEN = Color3.fromRGB(80, 255, 120)
local DOOR_SHUT = Color3.fromRGB(255, 40, 28)
local BLESSING_TIME = 8
local SURGE_TIME = 6
local DOOR_TIME = 1.1

local PHRASES = {
	"++ AUSPEX SWEEP: NO CONTACT",
	"VOID SHIELDS: NOMINAL",
	"GELLAR FIELD: STABLE",
	"MACHINE SPIRIT: CONTENT",
	"PRAISE THE OMNISSIAH",
	"LITANY OF IGNITION 7/12",
	"PLASMA FLUX 0.97 NOMINAL",
	"VOX: STATIC ON CHANNEL 3",
	"NAVIS DATA: DRIFT 0.002",
	"COGITATOR 7G ANOINTED",
	"SERVITOR 114: AWAITING",
	"HULL INTEGRITY 99.2%",
	"WARP COORDINATES LOCKED",
	"MACROCANNON BAY: READY",
	"ASTROPATHIC CHOIR: SILENT",
	"INCENSE RESERVE 61%",
	"THE EMPEROR PROTECTS",
	"SACRED UNGUENTS APPLIED",
	"RITE OF PURE THOUGHT",
	"ENGINE TEMP 4112K",
}
local ALERT_PHRASES = {
	"!! GENERAL QUARTERS !!",
	"ALL HANDS TO STATIONS",
	"VOID SHIELDS: RAISING",
	"MACROCANNONS: LOADING",
	"BRACE FOR IMPACT",
}

local function nextLine(alert: boolean): string
	local roll = rng:NextNumber()
	if alert and roll < 0.4 then
		return ALERT_PHRASES[rng:NextInteger(1, #ALERT_PHRASES)]
	elseif roll < 0.55 then
		return PHRASES[rng:NextInteger(1, #PHRASES)]
	elseif roll < 0.8 then
		local groups = {}
		for i = 1, 4 do
			local bits = {}
			for b = 1, 4 do
				bits[b] = if rng:NextNumber() < 0.5 then "0" else "1"
			end
			groups[i] = table.concat(bits)
		end
		return table.concat(groups, " ")
	end
	return string.format(
		"%04X:%04X  %04X",
		rng:NextInteger(0, 0xFFFF),
		rng:NextInteger(0, 0xFFFF),
		rng:NextInteger(0, 0xFFFF)
	)
end

local function firstLight(inst: Instance): Light?
	return inst:FindFirstChildWhichIsA("Light")
end

-- Collect everything --------------------------------------------------------------

local lumens, candles, skulls, spinners, holograms = {}, {}, {}, {}, {}
local beacons, blinkers, screens, doors = {}, {}, {}, {}
local core

for _, inst in ship:GetDescendants() do
	local fx = inst:GetAttribute("Fx")
	if fx == "Lumen" and inst:IsA("BasePart") then
		local light = firstLight(inst)
		table.insert(lumens, {
			part = inst,
			light = light,
			color = inst.Color,
			lightColor = light and light.Color,
			brightness = light and light.Brightness or 0,
			flicker = inst:GetAttribute("Flicker") or 0,
			dimUntil = 0,
			nextFlicker = rng:NextNumber(0, 3),
		})
	elseif fx == "Candle" and inst:IsA("BasePart") then
		local light = firstLight(inst)
		local fire = inst:FindFirstChildWhichIsA("Fire")
		if light or fire then
			table.insert(candles, {
				light = light,
				brightness = light and light.Brightness or 0,
				fire = fire,
				fireSize = fire and fire.Size or 0,
				seed = rng:NextNumber(0, 100),
			})
		end
	elseif fx == "ServoSkull" and inst:IsA("Model") then
		table.insert(skulls, {
			model = inst,
			start = inst:GetPivot().Position,
			patrol = inst:GetAttribute("Patrol") or Vector3.zero,
			speed = inst:GetAttribute("Speed") or 0.2,
			phase = inst:GetAttribute("Phase") or 0,
		})
	elseif fx == "Spin" and inst:IsA("Model") then
		table.insert(
			spinners,
			{ model = inst, base = inst:GetPivot(), speed = inst:GetAttribute("SpinSpeed") or 0.5, angle = 0 }
		)
	elseif fx == "Hologram" and inst:IsA("Model") then
		local parts = {}
		for _, p in inst:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				table.insert(parts, { part = p, transparency = p.Transparency })
			end
		end
		table.insert(holograms, {
			model = inst,
			base = inst:GetPivot(),
			speed = inst:GetAttribute("SpinSpeed") or 0.3,
			angle = 0,
			parts = parts,
			glitchUntil = 0,
		})
	elseif fx == "ReactorCore" and inst:IsA("BasePart") then
		local light = firstLight(inst)
		core = { part = inst, light = light, brightness = light and light.Brightness or 0 }
	elseif fx == "Beacon" and inst:IsA("Model") then
		local lamp = inst:FindFirstChild("Lamp") :: BasePart
		local rotor = inst:FindFirstChild("Rotor") :: BasePart
		local spots = {}
		for _, l in rotor:GetChildren() do
			if l:IsA("Light") then
				table.insert(spots, l)
			end
		end
		table.insert(beacons, {
			lamp = lamp,
			color = lamp.Color,
			material = lamp.Material,
			rotor = rotor,
			base = rotor.CFrame,
			spots = spots,
		})
	elseif fx == "Blinker" and inst:IsA("BasePart") then
		table.insert(blinkers, { part = inst, color = inst.Color, on = true })
	elseif fx == "Cogitator" and inst:IsA("TextLabel") then
		local lines = {}
		for i = 1, inst:GetAttribute("Lines") or 6 do
			lines[i] = nextLine(false)
		end
		inst.Text = table.concat(lines, "\n")
		table.insert(screens, { label = inst, lines = lines, nextAt = rng:NextNumber(0, 1) })
	elseif fx == "Door" and inst:IsA("Model") then
		local leaf = inst:FindFirstChild("Leaf") :: Model
		local lamps, steam = {}, {}
		for _, p in inst:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("Fx") == "DoorLamp" then
				table.insert(lamps, p)
			elseif p:IsA("ParticleEmitter") and p.Name == "DoorSteam" then
				table.insert(steam, p)
			end
		end
		table.insert(doors, {
			model = inst,
			leaf = leaf,
			closed = leaf:GetPivot(),
			offset = leaf:GetAttribute("OpenOffset") or Vector3.new(0, 12, 0),
			alpha = 0,
			lamps = lamps,
			steam = steam,
			lampOpen = nil,
		})
	end
end

-- Animate ------------------------------------------------------------------------

local clock = 0
local alertMix = 0
local nextBlink = 0

local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

local function decay(since: number, duration: number): number
	if since < 0 or since > duration then
		return 0
	end
	return 1 - since / duration
end

RunService.Heartbeat:Connect(function(dt)
	clock += dt
	local now = Workspace:GetServerTimeNow()
	local alert = ship:GetAttribute("RedAlert") == true
	alertMix = math.clamp(alertMix + (if alert then dt else -dt) * 1.5, 0, 1)
	local pulse = 0.5 + 0.5 * math.sin(clock * 4.5)
	local blessing = decay(now - (ship:GetAttribute("BlessingAt") or 0), BLESSING_TIME)
	local surge = decay(now - (ship:GetAttribute("SurgeAt") or 0), SURGE_TIME)

	-- Lumens flicker now and then; general quarters washes them red and pulsing
	for _, l in lumens do
		local level = 1
		if l.flicker > 0 then
			if clock > l.nextFlicker then
				l.dimUntil = clock + rng:NextNumber(0.04, 0.3)
				l.nextFlicker = clock + rng:NextNumber(0.3, 4) / l.flicker
			end
			if clock < l.dimUntil then
				level = rng:NextNumber(0.05, 0.45)
			end
		end
		local alertLevel = 1 + alertMix * (pulse * 1.1 - 0.6)
		local value = level * alertLevel
		if value ~= l.lastValue or alertMix ~= l.lastMix then
			l.lastValue, l.lastMix = value, alertMix
			l.part.Color = l.color:Lerp(ALERT, alertMix):Lerp(Color3.new(0, 0, 0), 1 - math.min(1, value))
			if l.light then
				l.light.Color = l.lightColor:Lerp(ALERT, alertMix)
				l.light.Brightness = l.brightness * value
			end
		end
	end

	-- Candles and braziers: soft flicker, flaring when someone prays
	for _, c in candles do
		local wobble = 0.85 + 0.25 * math.noise(clock * 3, c.seed)
		local boost = 1 + blessing * 1.8
		if c.light then
			c.light.Brightness = c.brightness * wobble * boost
		end
		if c.fire then
			c.fire.Size = c.fireSize * (1 + blessing * 0.8)
		end
	end

	-- Servo-skulls drift around their patrol ellipses, facing where they fly
	for _, s in skulls do
		local a = s.phase + now * s.speed
		local p = s.patrol
		local centre = s.start - Vector3.new(0, 0, p.Z)
		local position = centre + Vector3.new(p.X * math.sin(a), p.Y * math.sin(a * 3.1), p.Z * math.cos(a))
		local heading = Vector3.new(p.X * math.cos(a), 0, -p.Z * math.sin(a))
		if heading.Magnitude > 1e-3 then
			s.model:PivotTo(
				CFrame.lookAt(position, position + heading)
					* CFrame.Angles(0.15 * math.sin(clock * 1.7 + s.phase), 0, 0)
			)
		end
	end

	-- Spinning containment rings (faster during a surge)
	for _, s in spinners do
		s.angle += dt * s.speed * (1 + surge * 4)
		s.model:PivotTo(s.base * CFrame.Angles(0, s.angle, 0))
	end

	-- Hololith: slow rotation and the occasional glitch
	for _, h in holograms do
		h.angle += dt * h.speed
		h.model:PivotTo(h.base * CFrame.Angles(0, h.angle, 0))
		local glitching = clock < h.glitchUntil
		if not glitching and rng:NextNumber() < dt * 0.4 then
			h.glitchUntil = clock + rng:NextNumber(0.05, 0.2)
			glitching = true
		end
		if glitching ~= h.glitching then
			h.glitching = glitching
			for _, entry in h.parts do
				entry.part.Transparency = if glitching
					then math.min(1, entry.transparency + 0.45)
					else entry.transparency
			end
		end
	end

	-- Plasma core breathes; anointing it makes it surge white-hot
	if core then
		local breath = 0.5 + 0.5 * math.sin(clock * 1.3)
		core.part.Color = PLASMA:Lerp(PLASMA_HOT, math.max(breath * 0.35, surge))
		if core.light then
			core.light.Brightness = core.brightness * (0.85 + 0.25 * math.sin(clock * 2.1)) * (1 + surge * 1.5)
		end
	end

	-- Warning beacons only spin during general quarters
	for _, b in beacons do
		if alert then
			b.lamp.Material = Enum.Material.Neon
			b.lamp.Color = ALERT
			b.rotor.CFrame = b.base * CFrame.Angles(0, clock * 6, 0)
			for _, spot in b.spots do
				spot.Brightness = 6
			end
			b.active = true
		elseif b.active then
			b.active = false
			b.lamp.Material = b.material
			b.lamp.Color = b.color
			for _, spot in b.spots do
				spot.Brightness = 0
			end
		end
	end

	-- Indicator lamps blink at random
	if clock > nextBlink then
		nextBlink = clock + 0.12
		for _, b in blinkers do
			if rng:NextNumber() < 0.06 then
				b.on = not b.on
				b.part.Color = if b.on then b.color else b.color:Lerp(Color3.new(0, 0, 0), 0.85)
			end
		end
	end

	-- Cogitator screens scroll
	for _, s in screens do
		if clock > s.nextAt then
			s.nextAt = clock + rng:NextNumber(0.35, 1.5)
			table.remove(s.lines, 1)
			table.insert(s.lines, nextLine(alert))
			s.label.Text = table.concat(s.lines, "\n")
			s.label.TextColor3 = if alert then Color3.fromRGB(255, 120, 90) else Color3.fromRGB(90, 255, 140)
		end
	end

	-- Blast doors slide up into the bulkhead
	for _, d in doors do
		local target = if d.model:GetAttribute("Open") then 1 else 0
		if d.alpha ~= target then
			d.alpha = math.clamp(d.alpha + (if target > d.alpha then dt else -dt) / DOOR_TIME, 0, 1)
			d.leaf:PivotTo(d.closed * CFrame.new(d.offset * smooth(d.alpha)))
		end
		local open = target == 1
		if open ~= d.lampOpen then
			-- Hydraulics vent a burst of steam as the seals release
			if open and d.lampOpen ~= nil then
				for _, emitter in d.steam do
					emitter:Emit(18)
				end
			end
			d.lampOpen = open
			for _, lamp in d.lamps do
				lamp.Color = if open then DOOR_OPEN else DOOR_SHUT
			end
		end
	end
end)
