Spider = Entities:extend()

function Spider:new(id, x, y)
	Spider.super.new(self, id, x, y, speed, scale, direction)
	self.type = "spider"
	self.width = 54
	self.height = 48

	-- STATS
	self.speed = 420
	self.sightDistance = 1500
	self.hp = 12 -- 12
	self.tileAccuracy = 35
	self.fireRate = 0.5
	self.wanderSpeed = 5.0
	self.state = "idle"
	self.damping = 5

	self.atlas = love.graphics.newImage("assets/gfx/spider.png")
	self.animGrid = anim8.newGrid(self.width, self.height, self.atlas:getWidth(), self.atlas:getHeight())

	self.animations = {}
	self.animations.idle = anim8.newAnimation(self.animGrid('1-7',1), 0.2)
	self.animations.walk = anim8.newAnimation(self.animGrid('1-6',2), 0.1)
	self.animations.hurt = anim8.newAnimation(self.animGrid('1-2',3), 0.1)
	self.animations.stun = anim8.newAnimation(self.animGrid('1-4',4), 0.1, "pauseAtEnd")
	self.anim = self.animations.idle

	self.collider = world:newCircleCollider(self.x,self.y,self.width - 10)
	self.collider:setFixedRotation(true)
	self.collider:setCollisionClass('Spider')
	self.collider:setObject(self)
	self.collider:setRestitution(0)
	self.collider:setLinearDamping(self.damping)

	self.isPlayerControlled = false;

	self.fireRate_timer = 0
	self.wander_timer = 0.0
	self.search_timer = 0

	self.seekTimer = timer.every(0.5, function() 
		self:raycast()
	end)
end


function Spider:update(dt)
	-- hp update
	if self.hp <= 0 and self.state ~= "stun" then
		self:stun()
	end

	if self.state ~= "death" then 
		self.x, self.y = self.collider:getPosition() 
	end

	self.anim:update(dt)
end

function Spider:draw()
	if self.anim == nil then
		self.anim = self.animations.idle
	else self.anim:draw(self.atlas, self.x, self.y, 0, self.scale * self.direction, self.scale, self.width/2, self.height/2)
	end
end