Map = Object:extend()

function Map:new(x, y)
	require "maps/tile"
	self.x = x
	self.y = y
	self.tileScale = GLOBAL_SCALE
	self.tileWidth = TILE_SIZE_X
	self.tileHeight = TILE_SIZE_Y
	self.nb_cells_x = MAP_SIZE_X
	self.nb_cells_y = MAP_SIZE_Y
	self.startItems = {}
	self.startBeetles = {}
	self.offset_x = self.tileWidth / 2 * self.tileScale
	self.offset_y = self.tileHeight / 2 * self.tileScale
	self.mapWidth = self.nb_cells_x * self.tileWidth * self.tileScale
	self.mapHeight = self.nb_cells_y * self.tileHeight * self.tileScale


	self.walkers = {}
	self.nHoles = 0
	self.landTiles = {}
	self.nearSpiderLandTiles = {}
	self.baseAnts = {x=0,y=0}
	self.baseSpider = {x=0,y=0}


	self.atlas = love.graphics.newImage("assets/gfx/tiles.png")


	math.randomseed(os.time())

	self.map  = {}
	self.mapData = {}
	-- self.mapData = require "maps/map2"
	self.mapData = self:generateNewMap()

	local row = 0
	local col = 0

	for i, v in ipairs(self.mapData) do
		local xoff = 0
		local yoff = 0
		local angle = 0
		local type = nil

		if v == 11 then
			xoff = math.random(0,2)
			type = "land"
		elseif v == 21 then
			type = "wood"
			yoff = 3
			angle = 270
		elseif v == 22 then
			type = "wood"
			yoff = 3
			angle = 180
		elseif v == 23 then
			type = "wood"
			yoff = 3
			angle = 90
		elseif v == 24 then
			type = "wood"
			yoff = 3
			angle = 0
		elseif v == 14 then 
			xoff = math.random(15,17)
			yoff = 1
			type = "wall"
			xoff = self:getContact(i)
		elseif v == 10 then
			yoff = 2
			type = "bedrock"
		elseif v == 51 then
			xoff = math.random(0,2)
			type = "land"
			self.baseAnts = i
		elseif v == 61 then
			xoff = math.random(0,2)
			type = "land"
			self.baseSpider = i
		elseif v == 71 then
			xoff = math.random(0,2)
			type = "land"
			table.insert(self.startBeetles, i)
		elseif v == 81 then
			xoff = math.random(0,2)
			type = "land"
			table.insert(self.startItems, i)
		end

		table.insert(self.map, 
			Tile(self.offset_x + col * self.tileWidth * self.tileScale, 
				self.offset_y + row * self.tileHeight * self.tileScale, 
				i, 
				self.atlas, xoff*self.tileWidth, 
				yoff*self.tileHeight, type)
			)

		if v == 10 then self.map[#self.map].unbreakable = true end
		if angle ~= 0 then self.map[#self.map].angle = angle end

		col = col + 1
		if(i % self.nb_cells_x == 0) then
			row = row + 1
			col = 0
		end
	end

end

function Map:draw()
	for i = 1, #self.map do
		self.map[i]:draw()
	end
end

function Map:getContact(ti)
	--  0:none, 1:N, 2:E, 4:S, 8:W
	local id = 0
	if ti - self.nb_cells_x > 1 then
		if self.mapData[ti - self.nb_cells_x] == 14 then id = id + 1 end
	else id = id + 1 end
	if self.mapData[ti + 1] == 14 then id = id + 2 end
	if self.mapData[ti + self.nb_cells_x] == 14 then id = id + 4 end
	if ti - 1 > 1 then
		if self.mapData[ti - 1] == 14 then id = id + 8 end
	else id = id + 8 end

	return id
end

function Map:generateNewMap()
	self:resetMap()
	self:initMapGen()
	self:updateMapGen()
	self:initRootGen()
	self:updateRootGen()
	return self:endOfGeneration()
end

--[[
		MAP GENERATION
]]--

function Map:resetMap() 
	for i=1, MAP_SIZE_X do
		self.mapData[i] = {}
		for j=1, MAP_SIZE_Y do
			if i == 1 or j == 1 or i == MAP_SIZE_X or j == MAP_SIZE_Y then self.mapData[i][j] = 10
			else 
				self.mapData[i][j] = 14
			end
		end
	end
	self.nHoles = 0
end

function Map:initMapGen()
	math.randomseed(os.time())
	self.walkers = {}

	-- decide which side will the ants start on
	-- spider starts at the opposite side
	-- 1:N , 2:E , 3:S , 4:W
	local antSide = math.random(1,4)
	local startPointAnts = {x=0, y=0, dir = math.random(1,4), r=1, g=0, b=0}
	local startPointSpider = {x=0, y=0, dir = math.random(1,4), r=0, g=0, b=1}
	local border = 8

	if antSide == 1 then
		startPointAnts.x = math.floor(math.random(border,MAP_SIZE_X - border))
		startPointAnts.y = math.floor(math.random(border ,MAP_SIZE_Y / 2 - border))
		startPointSpider.x = math.floor(math.random(border,MAP_SIZE_X - border))
		startPointSpider.y = math.floor(math.random(MAP_SIZE_Y / 2 + border ,MAP_SIZE_Y  - border))
	elseif antSide == 2 then
		startPointAnts.x = math.floor(math.random(MAP_SIZE_X / 2 + border ,MAP_SIZE_X - border))
		startPointAnts.y = math.floor(math.random(MAP_SIZE_Y / 2 + border ,MAP_SIZE_Y  - border))
		startPointSpider.x = math.floor(math.random(border,MAP_SIZE_X / 2 - border))
		startPointSpider.y = math.floor(math.random(border ,MAP_SIZE_Y / 2 - border))
	elseif antSide == 3 then
		startPointAnts.x = math.floor(math.random(border,MAP_SIZE_X - border))
		startPointAnts.y = math.floor(math.random(MAP_SIZE_Y / 2 + border ,MAP_SIZE_Y  - border))
		startPointSpider.x = math.floor(math.random(border,MAP_SIZE_X - border))
		startPointSpider.y = math.floor(math.random(border ,MAP_SIZE_Y / 2 - border))
	elseif antSide == 4 then
		startPointAnts.x = math.floor(math.random(border,MAP_SIZE_X / 2 - border))
		startPointAnts.y = math.floor(math.random(border ,MAP_SIZE_Y / 2 - border))
		startPointSpider.x = math.floor(math.random(MAP_SIZE_X / 2 + border ,MAP_SIZE_X - border))
		startPointSpider.y = math.floor(math.random(MAP_SIZE_Y / 2 + border ,MAP_SIZE_Y  - border))
	end


	self.baseAnts.x = startPointAnts.x
	self.baseAnts.y = startPointAnts.y
	self.baseSpider.x = startPointSpider.x
	self.baseSpider.y = startPointSpider.y


	for i=1,3 do
		table.insert(self.walkers, startPointAnts)
		table.insert(self.walkers, startPointSpider)
	end
end

function Map:updateMapGen()
	-- DIRS
	-- 1 : N
	-- 2 : E
	-- 3 : S
	-- 4 : W

	if self.nHoles >= MAX_HOLES then
		-- end of map generation
		print("done map gen -- now doing root gen")
		self.walkers = {}
	else
		--proceed generation
		for i,v in pairs(self.walkers) do
			-- if reached edge of map, go back opposite dir
			if v.x == 2 and v.dir == 4 then
				v.dir = 2
				v.x = v.x + 1
			elseif v.x == MAP_SIZE_X - 1 and v.dir == 2 then
				v.dir = 4
				v.x = v.x - 1
			elseif v.y == 2 and v.dir == 1 then
				v.dir = 3
				v.y = v.y + 1
			elseif v.y == MAP_SIZE_Y - 1 and v.dir == 3 then
				v.dir = 1
				v.y = v.y - 1
			else
				-- normal walk behavior
				if v.dir == 1 then
					v.y = v.y - 1
				elseif v.dir == 2 then
					v.x = v.x + 1
				elseif v.dir == 3 then
					v.y = v.y + 1
				elseif v.dir == 4 then
					v.x = v.x - 1
				end
			end
			-- dig hole
			if self.mapData[v.x][v.y] == 14 then
				self.mapData[v.x][v.y] = 11
				self.nHoles = self.nHoles + 1
			end
			-- can change dir
			if math.random() <= CHANCE_CHANGEDIR then
				v.dir = math.random(1,4)
			end

			-- can create new walker
			if math.random() <= CHANCE_NEWWALKER and #self.walkers <= MAX_WALKER then
				table.insert(self.walkers, {x = v.x, y = v.y, dir = math.random(1,4), r = v.r, g = v.g, b = v.b})
			end

			-- can die
			if math.random() <= CHANCE_DESTROWALKER and #self.walkers > 1 then
				table.remove(self.walkers, i)
			end
		end
		self:updateMapGen()
	end
end

function Map:initRootGen() 
	-- new walker to generate roots from edges of map
	for i=1,MAX_ROOTS do
		local edge = math.random(1,4)
		if edge == 1 then
			table.insert(self.walkers, {x = math.random(1, MAP_SIZE_X), y = 1, dir = 3})
		elseif edge == 2 then
			table.insert(self.walkers, {x = MAP_SIZE_X, y = math.random(1, MAP_SIZE_Y), dir = 4})
		elseif edge == 3 then
			table.insert(self.walkers, {x = math.random(1, MAP_SIZE_X), y = MAP_SIZE_Y, dir = 1})
		elseif edge == 4 then
			table.insert(self.walkers, {x = 1, y = math.random(1, MAP_SIZE_Y), dir = 2})
		end
		self.walkers[#self.walkers].nSteps = math.random(5,MAX_ROOT_LENGTH)
		self.walkers[#self.walkers].r = 0
		self.walkers[#self.walkers].g = 1
		self.walkers[#self.walkers].b = 0

	end
end

function Map:updateRootGen()

	-- end condition
	if #self.walkers == 0 then
		-- removing single walls, add berock borders, add items and mobs
		self:finalPass()

		-- place ant and spider bases
		self.mapData[self.baseAnts.x][self.baseAnts.y] = 51
		self.mapData[self.baseSpider.x][self.baseSpider.y] = 61

		print("map generation succesful")
		print("========================")
	else
		--proceed generation
		for i,v in pairs(self.walkers) do
			-- if reached edge of map, go back opposite dir
			if v.x == 2 and v.dir == 4 then
				v.dir = 2
				v.x = v.x + 1
			elseif v.x == MAP_SIZE_X and v.dir == 2 then
				v.dir = 4
				v.x = v.x - 1
			elseif v.y == 2 and v.dir == 1 then
				v.dir = 3
				v.y = v.y + 1
			elseif v.y == MAP_SIZE_Y and v.dir == 3 then
				v.dir = 1
				v.y = v.y - 1
			else
				-- normal walk behavior
				if v.dir == 1 then
					v.y = v.y - 1
				elseif v.dir == 2 then
					v.x = v.x + 1
				elseif v.dir == 3 then
					v.y = v.y + 1
				elseif v.dir == 4 then
					v.x = v.x - 1
				end
			end
			v.nSteps = v.nSteps - 1
			-- add wood
			if v.x > 1 and v.x < MAP_SIZE_X and v.y > 1 and v.y < MAP_SIZE_Y then
				self.mapData[v.x][v.y] = 20 + v.dir
			end
			-- can change dir
			if math.random() <= ROOT_CHANCE_CHANGEDIR then
				v.dir = math.random(1,4)
			end

			-- can create new walker
			if math.random() <= ROOT_CHANCE_NEWWALKER and #self.walkers <= MAX_WALKER then
				table.insert(self.walkers, {x = v.x, y = v.y, dir = math.random(1,4), r = v.r, g = v.g, b = v.b, nSteps = v.nSteps})
			end

			-- if reached last step, dies
			if v.nSteps <= 0 then
				table.remove(self.walkers, i)
			end

		end
		self:updateRootGen()
	end
end


function Map:finalPass() 
	local xmin = math.max(self.baseSpider.x - NEAR_BASE_RADIUS, 1)
	local xmax = math.min(self.baseSpider.x + NEAR_BASE_RADIUS, MAP_SIZE_X)
	local ymin = math.max(self.baseSpider.y - NEAR_BASE_RADIUS, 1)
	local ymax = math.min(self.baseSpider.y + NEAR_BASE_RADIUS, MAP_SIZE_X)
	for i=1, MAP_SIZE_X do
		for j=1, MAP_SIZE_Y do
			if i > 2 and i < MAP_SIZE_X - 1 and j > 2 and j < MAP_SIZE_Y - 1 then
				-- single walls remove
				if self.mapData[i-1][j] == 11 and self.mapData[i+1][j] == 11 and self.mapData[i][j-1] == 11 and self.mapData[i][j+1] == 11 then
					self.mapData[i][j] = 11
				end
				-- single land remove
				if self.mapData[i-1][j] == 14 and self.mapData[i+1][j] == 14 and self.mapData[i][j-1] == 14 and self.mapData[i][j+1] == 14 then
					self.mapData[i][j] = 14
				end
			else
				-- add bedrock corners and randomly
				if i == 2 and j == 2 or i == MAP_SIZE_X-1 and j == 2 or i == 2 and j == MAP_SIZE_Y-1 or i == MAP_SIZE_X-1 and j == MAP_SIZE_Y-1 then
					self.mapData[i][j] = 10
				else
					if math.random() <= CHANCE_BEDROCK then self.mapData[i][j] = 10 end
				end
			end
			if self.mapData[i][j] == 11 then
				table.insert(self.landTiles, {x = i, y = j})
				if i >= xmin and i <= xmax and j >= ymin and j <= ymax then
					table.insert(self.nearSpiderLandTiles, {x = i, y = j})
				end
			end
		end
	end
	-- remove walls around ant base
	for i=-2,2 do
		for j=-2,2 do
			self.mapData[self.baseAnts.x + i][self.baseAnts.y + j] = 11
		end
	end


	-- beetles and items spawn points
	for i=1,N_BEETLES do
		local t = self.nearSpiderLandTiles[math.random(#self.nearSpiderLandTiles)]
		self.mapData[t.x][t.y] = 71
	end
	for i=1,N_ITEMS do
		local t = self.landTiles[math.random(#self.landTiles)]
		self.mapData[t.x][t.y] = 81
	end
end

function Map:endOfGeneration() 

	resultMap = {}

	for i=1, MAP_SIZE_X do
		for j=1, MAP_SIZE_Y do
			table.insert(resultMap, self.mapData[i][j])
		end
	end

	return resultMap

end

function Map:clearMap() 

	self.mapData = {}
	for i,v in ipairs(self.map) do
		if v.collider ~= nil then
			if v.collider.body ~= nil then
				v.collider:destroy()
				v.collider = nil
			end
		end
	end
	self.map = {}

end
