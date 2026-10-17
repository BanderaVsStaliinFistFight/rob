--[[
	Deck plan, in studs. The ship's long axis is Z with the prow towards -Z.
	Floor level is y = 0 everywhere except the bridge's servitor pits.

	  prow  [ Bridge ]--door--[ Corridor ]--door--[ Enginarium ]  stern
	                              |
	                         [ Chapel ] (off the corridor's starboard side)
]]

return {
	Corridor = {
		half = 8, -- inner half-width
		zMin = -32,
		zMax = 32,
		spring = 12, -- where the vault springs from the walls
		radius = 12, -- vault arc radius
		wall = 2,
		walk = 5, -- half-width of the central walkway
		gutter = 2, -- depth of the grated gutters either side
	},
	Bridge = {
		half = 30,
		zMin = -84,
		zMax = -34,
		spring = 20,
		radius = 42,
		wall = 2,
		pit = -4, -- floor of the servitor pits
	},
	Chapel = {
		xMin = 10,
		xMax = 30,
		zMin = -14,
		zMax = 6,
		spring = 10,
		radius = 14,
	},
	Enginarium = {
		half = 22,
		zMin = 34,
		zMax = 70,
		ceiling = 28,
		pitHalf = 9,
		pitDepth = 14,
		reactorZ = 52,
	},
	Door = {
		width = 8,
		height = 12,
	},
	ChapelDoor = {
		z = -4,
		width = 5,
		spring = 7,
	},
}
