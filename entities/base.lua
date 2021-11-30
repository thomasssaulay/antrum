Base = Entities:extend()

function Base:new(id, x, y)
	Base.super.new(self, id, x, y)


	self.type = "base"
	self.width = 18
	self.height = 16

	self.baseCrafters = {}

	local xoffset = 36
	local yoffset = 20

	for i=-1,1 do
		for j=0,1 do
			local centerOffset = 0
			if i == 0 and j == 0 then centerOffset = -yoffset end
			if i == 0 and j == 1 then centerOffset = yoffset end
			table.insert(self.baseCrafters, BaseCrafter(#self.baseCrafters, self.x + i*xoffset - self.width/2, self.y + j*yoffset + centerOffset - self.height/2, self))
		end
	end
end

function Base:update(dt)
	for _,v in ipairs(self.baseCrafters) do
		v:update(dt)
	end
end

function Base:draw()
	for _,v in ipairs(self.baseCrafters) do
		v:draw()
	end
end

function Base:getNumFilled()
	local n = 0
	for _,v in ipairs(self.baseCrafters) do
		if v.isFull then n = n + 1 end
	end
	return n
end

function Base:checkVictory()
	if self:getNumFilled() == 6 then
		return true
	else 
		return false 
	end
end

-- function Base:craft()
-- 	local n = 0
-- 	for _,v in ipairs(self.baseCrafters) do
-- 		if v.isFull then 
-- 			n = n + 1
-- 			v:empty()
-- 		end
-- 	end
-- 	if n == 1 then 
-- 		id = createLoot(entitiesList, id, self.x+32, self.y+64, "pistol")
-- 	elseif n == 2 then
-- 		id = createLoot(entitiesList, id, self.x+32, self.y+64, "smg")
-- 	elseif n == 5 then
-- 		id = createLoot(entitiesList, id, self.x+32, self.y+64, "rocketlauncher")
-- 	end
-- end

function Base:destroy()
	for _,v in ipairs(self.baseCrafters) do
		v.collider:destroy()
	end
end