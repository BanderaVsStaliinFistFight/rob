--[[
	Bakes the ship with Lune, then wraps it in a place with Rojo.

	    lune run scripts/build             -> dist/ImperialShip.rbxm + dist/ImperialShip.rbxl
	    lune run scripts/build model       -> dist/ImperialShip.rbxm only

	The builder is ordinary Roblox code, so it runs here unchanged; this file
	only provides the Roblox globals and a small `require(script.X)` loader.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local SOURCE = "src/ShipBuilder"
local SCRIPTS = "src/ShipScripts"
local OUTPUT = "dist"

-- Module loader -------------------------------------------------------------
-- `script` is a proxy that maps instance paths onto files: script.Parent.Kit
-- inside src/ShipBuilder/Bridge.luau resolves to src/ShipBuilder/Kit.luau.

local proxyPaths: { [any]: string } = setmetatable({}, { __mode = "k" }) :: any
local cache: { [string]: any } = {}

local function proxy(path: string): any
	local p = setmetatable({}, {
		__index = function(_, key: string)
			if key == "Parent" then
				return proxy((string.match(path, "^(.*)/[^/]+$")) or "")
			end
			return proxy(path .. "/" .. key)
		end,
	})
	proxyPaths[p] = path
	return p
end

local loadModule: (path: string) -> any

local function fakeRequire(target: any): any
	local path = proxyPaths[target]
	if not path then
		error("require() expects a script path, got " .. tostring(target), 2)
	end
	return loadModule(path)
end

function loadModule(path: string): any
	if cache[path] ~= nil then
		return cache[path]
	end
	local file = if fs.isFile(path .. ".luau") then path .. ".luau" else path .. "/init.luau"
	if not fs.isFile(file) then
		error("no module at " .. path)
	end
	local env: { [string]: any } = {}
	for key, value in roblox :: any do
		env[key] = value
	end
	env.script = proxy(path)
	env.require = fakeRequire
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

-- Build -----------------------------------------------------------------------

local args = process.args
local modelOnly = table.find(args, "model") ~= nil

local ShipBuilder = loadModule(SOURCE)
local ship = ShipBuilder.build(nil)

local function addScript(name: string, file: string, context: string)
	local s = roblox.Instance.new("Script")
	s.Name = name
	s.Source = fs.readFile(file)
	s.RunContext = (roblox.Enum.RunContext :: any)[context]
	s.Parent = ship
end
addScript("ShipSystems", SCRIPTS .. "/ShipSystems.server.luau", "Server")
addScript("ShipAmbience", SCRIPTS .. "/ShipAmbience.client.luau", "Client")

local parts, lights = 0, 0
for _, d in ship:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	elseif d:IsA("Light") then
		lights += 1
	end
end

if not fs.isDir(OUTPUT) then
	fs.writeDir(OUTPUT)
end
fs.writeFile(OUTPUT .. "/ImperialShip.rbxm", roblox.serializeModel({ ship }))
print(string.format("Baked %s/ImperialShip.rbxm: %d parts, %d lights", OUTPUT, parts, lights))

if not modelOnly then
	local rojo = process.env.ROJO or "rojo"
	local result = process.spawn(rojo, { "build", "default.project.json", "--output", OUTPUT .. "/ImperialShip.rbxl" })
	if not result.ok then
		print(result.stdout)
		print(result.stderr)
		error("rojo build failed")
	end
	print("Built " .. OUTPUT .. "/ImperialShip.rbxl")
end
