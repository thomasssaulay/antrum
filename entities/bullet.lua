Bullet = Entities:extend()

function Bullet:new(id, x, y, dx, dy, angle, maxRange, owner)
	self.x = x
	self.y = y
	self.dx = dx
	self.dy = dy
	self.angle = angle
	self.owner = owner
	self.width = 16
	self.height = 16
	self.scale = GLOBAL_SCALE
	self.atlas = love.graphics.newImage("assets/gfx/bullet.png")
	self.animGrid = anim8.newGrid(self.width, self.height, self.atlas:getWidth(), self.atlas:getHeight())

	self.animations = {}
	self.animations.idle = anim8.newAnimation(self.animGrid('1-3',1), 0.1)
	self.animations.explode = anim8.newAnimation(self.animGrid('1-3',2), 0.1)
	self.anim = self.animations.idle

	self.collider = world:newRectangleCollider(self.x, self.y, self.width, self.height / 2)
	self.collider:setObject(self)
	self.collider:setAngle(math.rad(self.angle))
	self.collider:setCollisionClass('Bullet_ant')
	self.collider:setFixedRotation(true)
	self.collider:setBullet(true)

	self.range = 0
	self.maxRange = maxRange
	if owner.type == "beetle" then
		self.scale = GLOBAL_SCALE + 1
		self.collider:setCollisionClass('Bullet_beetle')
	end


	self.exploding = false
end

function Bullet:update(dt)
	-- update if not exploding
	if self.exploding ~= true then
		self.x, self.y = self.collider:getPosition()
		self.collider:setLinearVelocity(self.dx,self.dy)
	end

	-- bullet hits
	if self.owner.type == "ant" and self.collider:enter('Beetle') then
		local collision_data = self.collider:getEnterCollisionData('Beetle')
		local entity = collision_data.collider:getObject()
		entity:hurt(1)
		self.collider:destroy()
		self:destroy()
	end
	if self.owner.type == "beetle" and self.collider:enter('Ant') then
		local collision_data = self.collider:getEnterCollisionData('Ant')
		local entity = collision_data.collider:getObject()
		entity:hurt(1)
	end
	if self.collider:enter('Bullet_beetle') then
		local collision_data = self.collider:getEnterCollisionData('Bullet_beetle')
		local entity = collision_data.collider:getObject()
		self.collider:destroy()
		self:destroy()
	end
	if self.collider:enter('Spider') then
		local collision_data = self.collider:getEnterCollisionData('Spider')
		local entity = collision_data.collider:getObject()
		entity:hurt(1)
		self.collider:destroy()
		self:destroy()
	end
	if self.collider:enter('World') then
		self.collider:destroy()
		self:destroy()
	end
	-- if self.collider:enter('BaseCrafter') then
	-- 	self.collider:destroy()
	-- 	self:destroy()
	-- end
	if self.collider:enter('Items') then
		self.collider:destroy()
		self:destroy()
	end

	--anim
	if(self.anim ~= nil) then
		self.anim:update(dt)
	end

	self.range = self.range + dt
	if self.range >= self.maxRange and self.exploding ~= true then
		self.collider:destroy()
		self:destroy()
	end
end


function Bullet:draw()
	self.anim:draw(self.atlas, self.x, self.y, math.rad(self.angle), self.scale,self.scale, self.width/2, self.height/2)
end

function Bullet:destroy()
	self.anim = self.animations.explode
	self.exploding = true
	timer.after(0.3, function() self.toDestroy = true  end)
end