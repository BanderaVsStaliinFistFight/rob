--[[
	ShipBuilder: assembles the Imperial frigate interior out of plain parts.

	    local ship = require(path.to.ShipBuilder).build(workspace)

	The result is geometry only. scripts/build.luau bakes it into
	dist/ImperialShip.rbxm and adds the runtime scripts from src/ShipScripts.
]]

local Bridge = require(script.Bridge)
local Chapel = require(script.Chapel)
local Corridor = require(script.Corridor)
local Enginarium = require(script.Enginarium)

local ShipBuilder = {}

function ShipBuilder.build(parent: Instance?): Model
	local ship = Instance.new("Model")
	ship.Name = "ImperialShip"
	Corridor.build(ship)
	Bridge.build(ship)
	Chapel.build(ship)
	Enginarium.build(ship)

	-- Shared state, driven by ShipSystems (server) and read by ShipAmbience (client)
	ship:SetAttribute("RedAlert", false)
	ship:SetAttribute("BlessingAt", 0)
	ship:SetAttribute("SurgeAt", 0)

	-- Pivot at the corridor floor, so moving the model in Studio behaves
	local origin = Instance.new("Part")
	origin.Name = "ShipOrigin"
	origin.Anchored = true
	origin.CanCollide = false
	origin.CanQuery = false
	origin.CanTouch = false
	origin.CastShadow = false
	origin.Transparency = 1
	origin.Size = Vector3.new(1, 1, 1)
	origin.CFrame = CFrame.new(0, 0, 0)
	origin.Parent = ship
	ship.PrimaryPart = origin
	ship.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	ship.Parent = parent
	return ship
end

return ShipBuilder
