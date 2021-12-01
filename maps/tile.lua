Tile = Object:extend()

function Tile:new(x, y, index, atlas, xoffset, yoffset, type)
	self.x = x
	self.y = y
	self.index = index
	self.atlas = atlas
	self.width = 32
	self.height = 32
	self.scale = GLOBAL_SCALE
	self.type = type
	self.collider = nil
	self.unbreakable = false
	self.damageAmount = 0
	self.crackSprite = nil
	self.angle = 0

	self.g = 0
	self.f = 0
	self.h = 0
	self.parent = nil

	self.showDebug = false

	if self.type == "wall" or self.type == "wood" or self.type == "bedrock" then
		self.collider = world:newRectangleCollider(self.x - self.width, self.y - self.height, self.width * self.scale, self.height * self.scale)
		self.collider:setType('static')
		self.collider:setCollisionClass('World')
		self.collider:setObject(self)
		self.maxDamage = 3

		self.crackAtlas = love.graphics.newImage("assets/gfx/cracks.png")
	end
	if self.type == "wood" then self.maxDamage = 5 end

	self.sprite = love.graphics.newQuad(xoffset, yoffset, self.width, self.height, self.atlas:getDimensions())
end


function Tile:draw()
	love.graphics.draw(self.atlas, self.sprite, self.x, self.y, math.rad(self.angle), self.scale, self.scale, self.width/self.scale, self.height/self.scale)
	if self.crackSprite ~= nil then 
		love.graphics.draw(self.crackAtlas, self.crackSprite, self.x, self.y, 0, self.scale, self.scale, self.width/2, self.height/2)
	end
	if self.showDebug then self:drawDebug() end
end


function Tile:setType(t)
	self.type = t
	local xoff = 0
	local yoff = 0
	if t == "land" then
		self.collider:destroy()
		xoff = math.random(3,5)
		self.sprite = love.graphics.newQuad(xoff * self.width, yoff * self.height, self.width, self.height, self.atlas:getDimensions())
		self.angle = 0
	end

	-- autotiling neighbors
	for _,v in ipairs(NEIGHBORS_4) do
		if map.map[self.index + v].type == "wall" then
			map.map[self.index + v]:autotile()
		end
	end

end

function Tile:damage(amount)
	self.damageAmount = self.damageAmount + amount
	if self.damageAmount > 0 then
		self.crackSprite = love.graphics.newQuad((self.damageAmount-1) * self.width, 0, self.width, self.height, self.crackAtlas:getDimensions())
		if self.damageAmount > self.maxDamage then
			self.crackSprite:release()
			self.crackSprite = nil
			self:setType("land")
		end
	end

	local snd = sounds.dig[math.random(#sounds.dig)]
	snd:setPosition(self.x,self.y,0)
	snd:play()

end

function Tile:autotile()
	--  0:none, 1:N, 2:E, 4:S, 8:W
	local xoff = 0
	local yoff = 1
	if self.index - MAP_SIZE_X > 1 then
		if map.map[self.index - MAP_SIZE_X].type == "wall" then xoff = xoff + 1 end
	else xoff = xoff + 1 end
	if map.map[self.index + 1].type == "wall" then xoff = xoff + 2 end
	if map.map[self.index + MAP_SIZE_X].type == "wall" then xoff = xoff + 4 end
	if self.index - 1 > 1 then
		if map.map[self.index - 1].type == "wall" then xoff = xoff + 8 end
	else xoff = xoff + 8 end
	
	self.sprite = love.graphics.newQuad(xoff * self.width, yoff * self.height, self.width, self.height, self.atlas:getDimensions())
end


function Tile:drawDebug()
	love.graphics.setColor(255, 0, 0)
	love.graphics.print(self.index .."\n"..self.g .. " " .. self.h, self.x - self.width / 2, self.y)
	love.graphics.setColor(255, 255, 255)
end