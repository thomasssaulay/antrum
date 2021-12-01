Ant = Entities:extend()

function Ant:new(id, x, y)
	Ant.super.new(self, id, x, y, speed, scale, direction)
	self.type = "ant"
	self.width = 19
	self.height = 17

	-- STATS
	self.speed = 300.00
	self.sightDistance = 500
	self.throwSpeed = 350
	self.hp = 3
	self.tileAccuracy = 10
	self.fireRate = 1
	self.actionRate = 0.3
	self.bulletSpeed = 300
	self.bulletRange = 1.5
	self.bulletID = 0
	self.bullets = {}
	self.wanderSpeed = 1.0
	self.path = nil
	self.state = "idle"

	self.atlas = love.graphics.newImage("assets/gfx/ant.png")
	self.animGrid = anim8.newGrid(self.width, self.height, self.atlas:getWidth(), self.atlas:getHeight())

	self.animations = {}
	self.animations.idle = anim8.newAnimation(self.animGrid('1-4',1), 0.2)
	self.animations.walk = anim8.newAnimation(self.animGrid('1-6',2), 0.1)
	self.animations.hurt = anim8.newAnimation(self.animGrid('1-2',3), 0.1)
	self.animations.action = anim8.newAnimation(self.animGrid('1-3',4), 0.1)
	self.animations.death = anim8.newAnimation(self.animGrid('1-6',5), 0.1, "pauseAtEnd")
	self.anim = self.animations.idle

	self.collider = world:newCircleCollider(self.x,self.y,self.width - 6)
	self.collider:setFixedRotation(true)
	self.collider:setCollisionClass('Ant')
	self.collider:setObject(self)
	self.collider:setRestitution(0)
	self.collider:setLinearDamping(10)

	self.isPlayerControlled = false;
	self.isHolding = nil

	self.fireRate_timer = 0
	self.actionRate_timer = 0
	self.wander_timer = 0.0
	self.search_timer = 0

	self.seekTimer = timer.every(0.5, function() 
		self:seek() 
	end)
end


function Ant:update(dt)
	-- hp update
	if self.hp <= 0 then
		self:die()
	end
	
	if self.state ~= "death" then self.x, self.y = self.collider:getPosition() end
	if self.isPlayerControlled and self.state ~= "death" then self.handlePlayerControls(self, dt) end

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

function Ant:draw()
	self.anim:draw(self.atlas, self.x, self.y, 0, self.scale * self.direction, self.scale, self.width/2, self.height/2)
	-- draw bullets
	for _,v in pairs(self.bullets) do
		v:draw()
	end
end

function Ant:setPlayerControl(bool)
	self.isPlayerControlled = bool
	if bool then
		-- self.seekTimer:clear()
		if self.seekTimer ~= nil then
			timer.cancel(self.seekTimer)
			self.seekTimer = nil
		end
	else
		self.seekTimer = timer.every(0.5, function() 
			self:seek() 
		end)
	end
end