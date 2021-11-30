BaseCrafter = Entities:extend()

function BaseCrafter:new(id, x, y, base)
	BaseCrafter.super.new(self, id, x, y)

	self.type = "BaseCrafter"
	self.width = 19
	self.height = 19

	self.base = base

	self.atlas = love.graphics.newImage("assets/gfx/basecrafter.png")
	self.animGrid = anim8.newGrid(self.width, self.height, self.atlas:getWidth(), self.atlas:getHeight())
	self.animations = {}
	self.animations.empty = anim8.newAnimation(self.animGrid(1,1), 0.1)
	self.anim = self.animations.empty

	self.collider = world:newRectangleCollider(self.x,self.y,self.width * self.scale,self.height * self.scale)
	self.collider:setType('static')
	self.collider:setCollisionClass('BaseCrafter')
	self.collider:setObject(self)

	self.isFull = false
end


function BaseCrafter:update(dt)
	self.anim:update(dt)
	self.x, self.y = self.collider:getPosition()
end

function BaseCrafter:draw()
	-- draw self
	self.anim:draw(self.atlas, self.x, self.y, 0, self.scale * self.direction, self.scale, self.width/2, self.height/2)
end

function BaseCrafter:fill(itemType)
	self.isFull = true
	self.animations.full = anim8.newAnimation(self.animGrid(1 + itemType,1), 0.1)
	self.anim = self.animations.full

	if base:checkVictory() then
		setGameOver(true)
	end
end
function BaseCrafter:empty()
	self.isFull = false
	self.anim = self.animations.empty
end