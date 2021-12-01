Item = Object:extend()

function Item:new(id, x, y)
	-- Item.super.new(self, x, y)
	self.id = id
	self.x = x
	self.y = y
	self.type = "item"
	self.width = 16
	self.height = 16
	self.scale = GLOBAL_SCALE
	self.direction = 1
	self.damping = 2.5
	self.joint = nil
	self.holder = nil
	self.itemType = math.random(1,3)

	self.atlas = love.graphics.newImage("assets/gfx/items.png")
	self.animGrid = anim8.newGrid(self.width, self.height, self.atlas:getWidth(), self.atlas:getHeight())
	self.animations = {}
	self.animations.idle = anim8.newAnimation(self.animGrid('1-2',self.itemType), 0.2)
	self.anim = self.animations.idle

	self.collider = world:newCircleCollider(self.x,self.y,self.width - 5)
	self.collider:setFixedRotation(true)
	self.collider:setCollisionClass('Items')
	self.collider:setObject(self)
	self.collider:setRestitution(0.0)
	self.collider:setLinearDamping(self.damping)
end

function Item:update(dt)
	self.x, self.y = self.collider:getPosition()

	-- Item enters basecraft
	if self.collider:enter('BaseCrafter') then
		local collision_data = self.collider:getEnterCollisionData('BaseCrafter')
		local bc = collision_data.collider:getObject()
		if not bc.isFull then
			if self.holder ~= nil then self:unsetHolder() end
			bc:fill(self.itemType)
			destroyEntity(itemList, self.id)
		end
	end

	self.anim:update(dt)
end

function Item:draw()
	self.anim:draw(self.atlas, self.x, self.y, 0, self.scale * self.direction, self.scale, self.width/2, self.height/2)
end

function Item:setHolder(holder)
	local holdOffset = 6
	self.holder = holder
	self.holder.isHolding = self
	self.collider:setPosition(self.holder.x, self.holder.y - holdOffset)
	self.collider:setLinearVelocity(0,0)
	-- self.joint = world:addJoint('DistanceJoint', self.holder.collider, self.collider, self.holder.x, self.holder.y,self.x, self.y, false)
	self.joint = world:addJoint('WeldJoint', self.holder.collider, self.collider, self.holder.x, self.holder.y, false)
	-- self.joint:setLength(1)

	sounds.hold:setPosition(self.x,self.y,0)
	sounds.hold:play()
end
function Item:unsetHolder()
	self.holder.isHolding = nil
	self.holder = nil
	world:removeJoint(self.joint)

	sounds.throw:setPosition(self.x,self.y,0)
	sounds.throw:play()
end

function Item:getCurrentTile()
	local xind = math.floor((self.x / self.scale) / map.tileWidth) + 1
	local yind = math.floor((self.y / self.scale) / map.tileHeight) + 1
	return map.map[(yind - 1) * map.nb_cells_x + xind]
end