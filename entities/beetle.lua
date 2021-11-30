Beetle = Entities:extend()

function Beetle:new(id, x, y)
	Beetle.super.new(self, id, x, y, speed, scale, direction)
	self.type = "beetle"
	self.width = 33
	self.height = 21

	-- STATS
	self.speed = 250
	self.sightDistance = 600
	self.hp = 6 -- 8
	self.tileAccuracy = 15
	self.actionRate = 0.1
	self.fireRate = 1.5
	self.bulletSpeed = 200
	self.bulletRange = 2
	self.bulletID = 0
	self.bullets = {}
	self.wanderSpeed = 0.5
	self.state = "idle"

	self.atlas = love.graphics.newImage("assets/gfx/beetle.png")
	self.animGrid = anim8.newGrid(self.width, self.height, self.atlas:getWidth(), self.atlas:getHeight())

	self.animations = {}
	self.animations.idle = anim8.newAnimation(self.animGrid('1-6',1), 0.2)
	self.animations.walk = anim8.newAnimation(self.animGrid('1-6',2), 0.1)
	self.animations.hurt = anim8.newAnimation(self.animGrid('1-2',3), 0.1)
	self.animations.action = anim8.newAnimation(self.animGrid('1-3',4), 0.1)
	self.animations.death = anim8.newAnimation(self.animGrid('1-5',5), 0.1, "pauseAtEnd")
	self.anim = self.animations.idle

	self.collider = world:newCircleCollider(self.x,self.y,self.width - 8)
	self.collider:setFixedRotation(true)
	self.collider:setCollisionClass('Beetle')
	self.collider:setObject(self)
	self.collider:setRestitution(0)

	self.isPlayerControlled = false;

	self.fireRate_timer = 0
	self.actionRate_timer = 0
	self.wander_timer = 0.0
	self.search_timer = 0

	self.seekTimer = timer.every(0.5, function() 
		self:raycast()
	end)
end


function Beetle:update(dt)
	-- hp update
	if self.hp <= 0 then
		self:die()
	end

	if self.state ~= "death" then self.x, self.y = self.collider:getPosition() end

	-- timers update
	if self.fireRate_timer < self.fireRate then self.fireRate_timer = self.fireRate_timer + dt end
	if self.actionRate_timer < self.actionRate then self.actionRate_timer = self.actionRate_timer + dt end
	-- bullet update
	for i,v in ipairs(self.bullets) do
		v:update(dt)
		if v.toDestroy == true then table.remove(self.bullets, i) end
	end

	self.anim:update(dt)
end

function Beetle:draw()
	self.anim:draw(self.atlas, self.x, self.y, 0, self.scale * self.direction, self.scale, self.width/2, self.height/2)
	-- draw bullets
	for _,v in pairs(self.bullets) do
		v:draw()
	end
end