--[[
	ShipSystems (server): decides shared state for the ship model it sits in.

	* Blast doors open while any player is within a door's SensorRadius.
	* ProximityPrompts tagged with an Action attribute:
	    RedAlert - command throne lever, toggles general quarters
	    Pray     - chapel kneeler, the candles flare
	    Anoint   - machine altar, the reactor surges

	All visuals are done client-side by ShipAmbience, which reads the attributes
	set here (Open on doors; RedAlert, BlessingAt, SurgeAt on the ship).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ship = script.Parent

local DOOR_POLL = 0.2

local doors: { Model } = {}
for _, inst in ship:GetDescendants() do
	if inst:IsA("Model") and inst:GetAttribute("Fx") == "Door" then
		inst:SetAttribute("Open", false)
		table.insert(doors, inst)
	end
end

task.spawn(function()
	while true do
		local positions = {}
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				table.insert(positions, root.Position)
			end
		end
		for _, door in doors do
			local sensor = door:FindFirstChild("Sensor")
			local centre = if sensor and sensor:IsA("BasePart") then sensor.Position else door:GetPivot().Position
			local radius = door:GetAttribute("SensorRadius") or 12
			local open = false
			for _, position in positions do
				if (position - centre).Magnitude <= radius then
					open = true
					break
				end
			end
			if door:GetAttribute("Open") ~= open then
				door:SetAttribute("Open", open)
			end
		end
		task.wait(DOOR_POLL)
	end
end)

local ACTIONS: { [string]: { cooldown: number, run: (ProximityPrompt) -> () } } = {
	RedAlert = {
		cooldown = 1.5,
		run = function(prompt)
			local on = not ship:GetAttribute("RedAlert")
			ship:SetAttribute("RedAlert", on)
			prompt.ActionText = if on then "Stand Down" else "Sound General Quarters"
		end,
	},
	Pray = {
		cooldown = 6,
		run = function()
			ship:SetAttribute("BlessingAt", Workspace:GetServerTimeNow())
		end,
	},
	Anoint = {
		cooldown = 6,
		run = function()
			ship:SetAttribute("SurgeAt", Workspace:GetServerTimeNow())
		end,
	},
}

for _, inst in ship:GetDescendants() do
	if inst:IsA("ProximityPrompt") then
		local action = ACTIONS[inst:GetAttribute("Action") or ""]
		if action then
			local lastUsed = -math.huge
			inst.Triggered:Connect(function()
				local now = os.clock()
				if now - lastUsed >= action.cooldown then
					lastUsed = now
					action.run(inst)
				end
			end)
		end
	end
end
