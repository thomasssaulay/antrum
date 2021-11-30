Entities = Object:extend()

function Entities:new(id, x, y)
	self.type = "entity"
	self.id = id
	self.x = x
	self.y = y
	self.state = "idle"
	self.target = nil
	self.aimTarget = nil

	self.direction = 1
	self.scale = GLOBAL_SCALE
end

function Entities:destroy() 
	destroyEntity(entitiesList, self.id)
end

function Entities:setState(state)
	self.state = state

	if state == "idle" then
		self.anim = self.animations.idle
	elseif state == "hurt" then
		self.anim = self.animations.hurt
	elseif state == "chase" then
		self.anim = self.animations.walk
	elseif state == "wander" then
		self.anim = self.animations.walk
	elseif state == "action" or state == "action_damageWall" or state == "action_shoot" then
		self.anim = self.animations.action
	elseif state == "death" then
		self.anim = self.animations.death
	end
end

function Entities:hurt(amount)
	self:setState("hurt")
	self.hp = self.hp - amount
	self.collider:setLinearVelocity(0,0)
	timer.after(0.3, function() self:setState("idle") end)
end

function Entities:moveToTarget(dt)
	local dist = math.sqrt((self.target.x - self.x)^2 + (self.target.y - self.y)^2)
	local a = self:getAngleWith(self.target)
	local vx = math.cos(a) * self.speed * 0.8 -- SPEED LOWERED FOR AI
	local vy = math.sin(a) * self.speed * 0.8

	if vx < 0 then self.direction = -1
	else self.direction = 1 end

	if dist < self.tileAccuracy then
		self.target = nil
	end

	-- Spider/beetle collide with ant
	if self.type == "spider" or self.type == "beetle" then
		if self.collider:enter('Ant') then
			local collision_data = self.collider:getEnterCollisionData('Ant')
			local obj = collision_data.collider:getObject()
			obj:die()
			self:setState("wander")
		end
	end

	-- Ant collisions
	if self.type == "ant" and self.target ~= nil then
		-- Ant collide with item
		if self.state == "chase" and self.collider:enter('Items') then
			local collision_data = self.collider:getEnterCollisionData('Items')
			local obj = collision_data.collider:getObject()
			if obj.holder == nil and self.isHolding == nil then
				obj:setHolder(self)
				self:setState("chase")
				self.path = self:findPath(map.map[map.baseAnts])
			end
		end
		-- Ant collide with wall while targetting item
		-- if self.target.type == "item" and self.collider:enter('Wall') and self.isHolding == nil then
		-- 	local collision_data = self.collider:getEnterCollisionData('Wall')
		-- 	local obj = collision_data.collider:getObject()
		-- 	self:setTarget(obj)
		-- end
	end
	-- Ant soft collide with ant
	-- if self.type == "ant" and self.collider:enter('Ant') then
	-- 	local collision_data = self.collider:getEnterCollisionData('Ant')
	-- 	local obj = collision_data.collider:getObject()
	-- 	obj.collider:applyLinearImpulse(vx*2,vy*3)
	-- 	self.collider:applyLinearImpulse(-vx*3,-vy*2)
	-- end
	
	-- Beetle collisions
	if self.type == "beetle" then
		-- beetle soft collide with beetle
		-- if self.state == "chase" and self.collider:enter('Beetle') then
		-- 	local collision_data = self.collider:getEnterCollisionData('Beetle')
		-- 	local obj = collision_data.collider:getObject()
		-- 	obj.collider:applyLinearImpulse(vx*2,vy*3)
		-- 	self.collider:applyLinearImpulse(-vx*3,-vy*2)
		-- end
	end
	if self.collider.body ~= nil then self.collider:setLinearVelocity(vx, vy) end
end

function Entities:setTarget(target)
	self.target = target
end

function Entities:setNextWanderTarget()
	local ti = self:getCurrentTileIndex()
	local dir = math.random(1,4)
	-- 1:N , 2:E , 3:S , 4:W

	-- if unbreakable wall
	if (dir == 1 and map.map[ti - map.nb_cells_x].unbreakable) 
		or (dir == 2 and map.map[ti + 1].unbreakable) 
		or (dir == 3 and map.map[ti + map.nb_cells_x].unbreakable) 
		or (dir == 4 and map.map[ti - 1].unbreakable) then 
		--	
		-- dir = randomExcluding(1,4,dir)
		dir = 0
		self.target = map.map[ti]
	end

	if dir == 1 then
		self.target = map.map[ti - map.nb_cells_x]
	elseif dir == 2 then
		self.target = map.map[ti + 1]
	elseif dir == 3 then
		self.target = map.map[ti + map.nb_cells_x]
	elseif dir == 4 then
		self.target = map.map[ti - 1]
	end

	-- Spider avoid walls
	if self.type == "spider" and (self.target.type == "wall" or self.target.type == "wood") then
		self.target = map.map[ti]
	end

	if (self.target.type == "wall" or self.target.type == "wood") and not self.target.unbreakable then
		self:setState("action_damageWall")
	end
end

function Entities:getCurrentTile()
	local xind = math.floor((self.x / self.scale) / map.tileWidth) + 1
	local yind = math.floor((self.y / self.scale) / map.tileHeight) + 1
	return map.map[(yind - 1) * map.nb_cells_x + xind]
end

function Entities:getCurrentTileIndex()
	local xind = math.floor((self.x / self.scale) / map.tileWidth) + 1
	local yind = math.floor((self.y / self.scale) / map.tileHeight) + 1
	return (yind - 1) * map.nb_cells_x + xind
end

function Entities:getAngleWith(ent)
	return math.atan2( self.y - ent.y , self.x - ent.x ) + math.pi
end

function Entities:seek()
	if self.state == "wander" or self.state == "idle" then
		local query = world:queryCircleArea(self.x, self.y, self.sightDistance)
		for _, collider in ipairs(query) do
			local obj = collider:getObject()
			if obj.type == "item" then
				if obj.holder == nil then
					self.path = self:findPath(obj:getCurrentTile())
				else
					self:setNextWanderTarget()
				end
			end
			if obj.type == "beetle" then
				if self:findPath(obj:getCurrentTile()) ~= nil then
					self.aimTarget = obj
					self:setState("action_shoot")
				else
					self:setNextWanderTarget()
				end
			end
		end
	end
end

function Entities:raycast()
	local slices = 128
	local foundSomething = false
	for theta=0, math.pi*2, math.pi/slices*2 do
		dx, dy = math.cos(theta), math.sin(theta)

		dx = dx * self.sightDistance
		dy = dy * self.sightDistance

		local closestX, closestY, closestF

		closestX = self.x+dx
		closestY = self.y+dy
		closestF = 1

		world:rayCast(self.x, self.y, self.x+dx, self.y+dy, 
			function(fixture, cx, cy, xn, yn, fraction)
				if fraction < closestF then
					closestF = fraction
					closestX = cx
					closestY = cy
				end

				return -1
			end)

		local query = world:queryLine(self.x, self.y, closestX, closestY)

		for _, collider in ipairs(query) do

			local obj = collider:getObject()
			if self.state == "chase" then
				if obj.type == "ant" then
					self.target = obj
					foundSomething = true
					search_timer = 0
				end
				if not foundSomething then
					self.search_timer = self.search_timer + love.timer.getDelta()
				end
				if not foundSomething and self.search_timer >= 5 then
					self.target = nil
					self:setState("wander")
					self.search_timer = 0
				end
			end
			if self.state == "wander" or self.state == "idle" then
				if obj.type == "ant" then
					self.target = obj
					self.aimTarget = obj
					if self.fireRate_timer >= self.fireRate and self.type == "beetle" then
						self:setState("action_shoot")
					else
						self:setState("chase")
					end
					if self.type == "spider" then
						cam:shake(0.05, 1)
					end
				end
			end
		end

	end

end


--[[
      MAIN AI FUNCTION 
]]--
function Entities:AIupdate(dt)
	if self.target ~= nil and self.state ~= "hurt" and self.state ~= "death" then
		if self.state ~= "action_damageWall" or self.state ~= "action_shoot" then
			self:moveToTarget(dt)
		end
		if self.state == "action_damageWall" and self.actionRate_timer >= self.actionRate then 
			if self.target.damageAmount <= self.target.maxDamage then self.target:damage(1)
			else 
				self:setState("wander")
			end
			self.actionRate_timer = 0
		end
	end
	if self.aimTarget ~= nil and self.state == "action_shoot" and self.fireRate_timer >= self.fireRate then
		self.target = nil
		if self.aimTarget.hp >= 0 then 
			self:shootTarget()
		else 
			self:setState("wander")
		end
	end

	if self.target == nil then
		self:setState("idle")
		if self.collider.body ~= nil then self.collider:setLinearVelocity(0,0) end
		if self.wander_timer >= self.wanderSpeed then
			self:setState("wander")
			self:setNextWanderTarget()
			self.wander_timer = math.random(0.0, self.wanderSpeed)
		else
			self.wander_timer = self.wander_timer + dt 
		end
		if self.path ~= nil then
			self:setState("chase")
			self.target = self.path[#self.path]
			if #self.path > 1 then table.remove(self.path, #self.path)
			else self.path = nil end
		end
	end
end

--[[
      MAIN PLAYER CONTROL 
]]--
function Entities:handlePlayerControls(dt)
	-- movement control

	-- keyboard
	local vx, vy = 0.00, 0.00
	if love.keyboard.isDown('z') or love.keyboard.isDown("w") or love.keyboard.isDown('q') or love.keyboard.isDown("a") or love.keyboard.isDown('s') or love.keyboard.isDown('d') then

		if love.keyboard.isDown("z") or love.keyboard.isDown("w") then
			vy = -self.speed
		elseif love.keyboard.isDown("s") then
			vy = self.speed
		end

		if love.keyboard.isDown("q") or love.keyboard.isDown("a")  then
			vx = -self.speed
			self.direction = -1
		elseif love.keyboard.isDown("d") then
			vx = self.speed
			self.direction = 1
		end

		if vx ~= 0.0 and vy ~= 0.0 then
			vx, vy = vx / 1.4142, vy / 1.4142
		end

	else
		if self.state ~= "action" then self.anim = self.animations.idle end
	end

	-- gamepad move
	if joystick ~= nil then 
		if math.abs(joystick:getAxis(1)) > GAMEPAD_THRESHOLD or math.abs(joystick:getAxis(1)) > GAMEPAD_THRESHOLD then
			vx = self.speed * joystick:getAxis(1)
			vy = self.speed * joystick:getAxis(2)
			if vx < 0 then self.direction = -1
			else self.direction = 1 end
		end
	end


	------- action control
	local dx = 0
	local dy = 0
	local a = 0
	if love.keyboard.isDown('up') then 
		dy = -1
		a = 270
	elseif love.keyboard.isDown('down') then 
		dy = 1
		a = 90
	elseif love.keyboard.isDown('left') then 
		dx = -1
		a = 180
		self.direction = -1
	elseif love.keyboard.isDown('right') then
		dx = 1
		a = 0
		self.direction = 1
	end

	-- gamepad action
	if joystick ~= nil then 
		if joystick:getAxis(4) > GAMEPAD_THRESHOLD * 5 then
			dx = 1
			a = 270
		elseif joystick:getAxis(4) < -GAMEPAD_THRESHOLD * 5 then
			dx = -1
			a = 90
		elseif joystick:getAxis(5) > GAMEPAD_THRESHOLD * 5 then
			dy = 1
			a = 180
		elseif joystick:getAxis(5) < -GAMEPAD_THRESHOLD * 5 then
			dy = -1
			a = 0
		end
	end

	-- case can fire
	if dx ~= 0 or dy ~= 0 then
		vx = vx / 2
		vy = vy / 2
		if self.actionRate_timer >= self.actionRate then
			local wallFound = false
			local colliders = world:queryLine(self.x, self.y, self.x + dx * 20,  self.y + dy * 20, {'World'})
			for _, collider in ipairs(colliders) do
				local obj = collider:getObject()
				self:setState("action")

				if obj.type == "wall" or obj.type == "wood" and not obj.unbreakable then
					self.actionRate_timer = 0
					obj:damage(1)
					wallFound = true 
				end
			end
			if self.fireRate_timer >= self.fireRate and not wallFound and self.isHolding == nil then
				self:setState("action")

				self:fireBullet(dx,dy,a)
			end
		end
	end

	--case holding item
	if self.isHolding ~= nil then
		if love.keyboard.isDown('up') or love.keyboard.isDown('left') or love.keyboard.isDown('right') then 
			self.isHolding.collider:applyLinearImpulse(dx * self.throwSpeed, dy * self.throwSpeed)
			self.isHolding:unsetHolder()
		elseif love.keyboard.isDown('down') then
			self.isHolding.collider:setPosition(self.x,self.y + 6)
			self.isHolding.collider:applyLinearImpulse(dx * self.throwSpeed, dy * self.throwSpeed)
			self.isHolding:unsetHolder()
		end
	end

	-- stop fire
	if dx == 0 and dy == 0 then
		if self.state == "action" then
			self:setState("idle")
		end
	end

	-- apply actual movement to self
	if vx ~= 0 or vy ~= 0 then
		if self.isHolding ~= nil then 
			vx = vx * 0.7
			vy = vy * 0.7
		end
		if self.state ~= "action" then self.anim = self.animations.walk end
		if self.state ~= "death" then self.collider:setLinearVelocity(vx,vy) end
	end
end



function Entities:remove() 
	if self.isHolding ~= nil then
		self.isHolding:unsetHolder()
	end
	self:setState("death")
	if self.collider ~= nil then 
		if self.collider.body ~= nil then self.collider:destroy() end
	end
	self.path = {}
	if self.seekTimer ~= nil then timer.cancel(self.seekTimer) end
	self.seekTimer = nil
	self.actionRate_timer = 0
	self.fireRate_timer = 0
	self.wander_timer = 0.0
	self.search_timer = 0
end

function Entities:die() 
	if self.isHolding ~= nil then
		self.isHolding:unsetHolder()
	end
	self:setState("death")
	if self.collider ~= nil then 
		if self.collider.body ~= nil then self.collider:destroy() end
	end
	self.path = {}
	if self.seekTimer ~= nil then timer.cancel(self.seekTimer) end
	self.seekTimer = nil
	self.actionRate_timer = 0
	self.fireRate_timer = 0
	self.wander_timer = 0.0
	self.search_timer = 0

	timer.after(1, function() 
		for i,v in ipairs(entitiesList) do
			if v.id == self.id then
				table.insert(deadEntities, self)
				table.remove(entitiesList, i)
			end
		end
	end)

	if self.type == "ant" then
		for i,v in ipairs(antsAlive) do
			if v.id == self.id then
				table.remove(antsAlive, i)
				if #antsAlive == 0 then setGameOver(false)
				end
			end
		end
	end
end

--[[ 
     PATHFINDING FUNCTION 
]]--
function Entities:findPath(targetTile)
	for _,v in ipairs(map.map) do
		v.f = 0
		v.g = 0
		v.h = 0
		v.parent = nil
		if PATHFINDING_DEBUG then v.showDebug = false end
	end

	local closedList = {}
	local openList = {}
	local startTile = self:getCurrentTile()
	table.insert(openList, startTile)

	while #openList > 0 do
		--  Get lowest F tile of the list
		local lowInd = 1
		for i,v in ipairs(openList) do
			if v.f < openList[lowInd].f then lowInd = i end
		end

		local currentTile = openList[lowInd]

		-- End case // Result found, return the traced path
		if currentTile.x == targetTile.x and currentTile.y == targetTile.y then
			local cur = currentTile
			local ret = {}
			while cur.parent do
				table.insert(ret, cur)
				cur = cur.parent 
				if PATHFINDING_DEBUG then cur.showDebug = true end
			end

			return ret
		end

		-- Normal case // move currentTile from open to closed list and go through each of its neighbors
		local curTileInd = indexOf(openList, currentTile)
		table.remove(openList, curTileInd)
		table.insert(closedList, currentTile)
		local neighbors = getNeighborsTiles(currentTile)

		for i,v in ipairs(neighbors) do

			if not includes(closedList, v) and v.type == "land" then

				-- weight more if diagonal
				local weigth = 10
				-- if i == 1 or i == 3 or i == 6 or i == 8 then weigth = 14 end -- DOESNT WORK
				local gScore  = currentTile.g + weigth
				local isBestG = false

				if not includes(openList, v) then
					isBestG = true
					v.h = manhattan(v.x, v.y, targetTile.x, targetTile.y)
					table.insert(openList, v)
				elseif gScore < v.g then
					isBestG = true
				end

				if isBestG then
					v.parent = currentTile
					v.g = gScore
					v.f = v.g + v.h
				end
			end -- if 

		end -- for loop
	end
	print("NOT REACHABLE")
	return nil
end

function Entities:shootTarget()
	if self.fireRate_timer >= self.fireRate then
		local dist = math.sqrt((self.aimTarget.x - self.x)^2 + (self.aimTarget.y - self.y)^2)
		local a = self:getAngleWith(self.aimTarget)
		local dx = math.cos(a)
		local dy = math.sin(a)

		a = math.deg(a)
		self:fireBullet(dx,dy,a)
	end
end
function Entities:fireBullet(dx,dy,angle)
	table.insert(self.bullets, Bullet(self.bulletID, self.x + self.width * dx,self.y + self.height * dy,dx*self.bulletSpeed,dy*self.bulletSpeed,angle,self.bulletRange, self))

	cam:shake(0.1,4)
	self.bulletID = self.bulletID + 1
	self.fireRate_timer = 0
end


-- OLD CODE --
-- function Entities:addLoot(data)
-- 	if(data.type == "weapon") then
-- 		self.weaponData = data
-- 		self.actionRate = data.actionRate
-- 		print("Changing weapon to ", self.weaponData.name)
-- 	end
-- end

-- function Entities:chase(dt, target)
-- 	local vx = (self.target.x - self.x) * self.speed * dt
-- 	local vy = (self.target.y - self.y) * self.speed * dt

-- 	if vx > self.speed then vx = self.speed
-- 	elseif vx < -self.speed then vx = -self.speed end
-- 	if vy > self.speed then vy = self.speed
-- 	elseif vy < -self.speed then vy = -self.speed end
-- 	print(vx , vy)

-- 	self.collider:setLinearVelocity(vx,vy)
-- end
-- function Entities:seekToShoot(distance)
-- 	local nearQuery = world:queryCircleArea(self.x, self.y, distance)
-- 	local result = false
-- 	for _, collider in ipairs(nearQuery) do
-- 		local obj = collider:getObject()
-- 		if obj.type == "Robot" then
-- 			self.shootTarget = obj
-- 			self:shoot(self.shootTarget)
-- 			result = true
-- 		end
-- 		if not result then
-- 			self.shootTarget = nil
-- 		end
-- 	end
-- end
