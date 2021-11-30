function love.load()
	io.stdout:setvbuf("no")
	love.graphics.setDefaultFilter("nearest", "nearest")
	Object = require "lib/classic"
	wf = require 'lib/windfield'
	camera = require 'lib/camera'
	anim8 = require "lib/anim8"
	timer = require "lib/timer"
	joysticks = love.joystick.getJoysticks()
	joystick = joysticks[1]

	require "entities/constants"
	require "entities/entities"
	require "entities/ant"
	require "entities/spider"
	require "entities/beetle"
	require "entities/bullet"
	require "entities/item"
	require "entities/baseCrafter"
	require "entities/base"
	require "maps/map"

	gameWidth, gameHeight = love.graphics.getDimensions()

	initMenu()
end

function love.update(dt)
	if dt > 0.040 then return end

	if gameState == 0 then
		menuUpdate(dt)
	elseif gameState == 1 then
		if not gamePaused then mainGameUpdate(dt) end
	end
end

function love.draw()
	if gameState == 0 then
		menuDraw()
	elseif gameState == 1 then
		mainGameDraw()
	end
end

--[[

	MENU SCENE

]]--

function initMenu() 
	fontHeader = love.graphics.newFont("assets/fonts/PearSoda.ttf",40)
	fontNormal = love.graphics.newFont("assets/fonts/PearSoda.ttf",20)

	menuTimer = 0
	titleScreen = {x= gameWidth / 2 - 161, y= 80.00, img= love.graphics.newImage("assets/gfx/titleScreen.png"), timer=0, goingDown=true}
	antHead = {
		img= love.graphics.newImage("assets/gfx/antHead.png"), 
		quad=love.graphics.newQuad(0, 0, 68, 69, 206, 69),
		x=gameWidth/2 - 66, y=gameHeight/2 - 33, xoffset=0, timer= 0
	}
	titleScreenText = "Press SPACE or A to start."
	gameState = 0
end

function menuUpdate(dt)
	if menuTimer > 0.5 then

		if titleScreen.timer <= 2 then
			titleScreen.timer = titleScreen.timer + dt
		else
			titleScreen.timer = 0
			titleScreen.goingDown = not titleScreen.goingDown 
		end
		if titleScreen.goingDown then titleScreen.y = titleScreen.y + dt * 5
		else titleScreen.y = titleScreen.y - dt * 5 end


		if antHead.timer <= 0.1 then
			antHead.timer = antHead.timer + dt
		else
			if antHead.xoffset < 2 then antHead.xoffset = antHead.xoffset + 1
			else antHead.xoffset = 0 end
			antHead.quad:setViewport(antHead.xoffset * 68, 0, 68, 69, 206, 69)
			antHead.timer = 0
		end

		if love.keyboard.isDown('space') then
			titleScreenText = "Generating map..."
			newGame()
			gameState = 1
			menuTimer = 0
			titleScreenText = "Press SPACE or A to start."
		end

		if love.keyboard.isDown("escape") then
			love.event.quit()
		end
		if love.keyboard.isDown("f") then
			love.window.setFullscreen( not love.window.getFullscreen( ) )
			gameWidth, gameHeight = love.graphics.getDimensions()
			titleScreen.x = gameWidth / 2 - 161
			antHead.x=gameWidth / 2 - 66
			antHead.y=gameHeight / 2 - 33
		end
	else
		menuTimer = menuTimer + dt
	end
end

function menuDraw()
	love.graphics.setBackgroundColor(0.38, 0.29, 0.23, 1)
	love.graphics.setColor(0.16, 0.15, 0.12, 1)
	love.graphics.rectangle("fill", 30, 30, gameWidth - 60, gameHeight - 60)
	love.graphics.setColor(0.89, 0.81, 0.70, 1)
	-- love.graphics.setFont(fontHeader)
	-- love.graphics.printf("ANTRUM", 0, 80, gameWidth, "center")
	love.graphics.draw(titleScreen.img, titleScreen.x, titleScreen.y)
	love.graphics.draw(antHead.img, antHead.quad, antHead.x, antHead.y, 0, 2, 2)
	love.graphics.setFont(fontNormal)
	love.graphics.printf(titleScreenText, 0, gameHeight - 100, gameWidth, "center")
end

--[[

	MAIN GAME SCENE

]]--
function mainGameUpdate(dt) 
	-- if joystick ~= nil then print(joystick:getAxis(1),joystick:getAxis(2)) end
	timer.update(dt)
	if gameTimer > 0 then gameTimer = gameTimer - dt 
	else setGameOver(false) end
	world:update(dt)
	base:update(dt)
	particleSystem:update(dt)

	for _,it in ipairs(itemList) do
		it:update(dt)
	end

	for _,e in ipairs(entitiesList) do
		if not e.isPlayerControlled and e.state ~= "death" then e:AIupdate(dt) end
		e:update(dt)
	end

	if currentPlayed.state == "death" and drawNextAntTimer <= 1 then
		drawNextAntTimer = drawNextAntTimer + dt
	end

	if DEBUG then
		hudText = "Entities : " .. #entitiesList .. " | FPS : " .. tostring(love.timer.getFPS( )) .. "\n"
		.. " Food left : " .. #itemList .. " | Ants alive : " .. #antsAlive ..
		"\nDead ents : " .. #deadEntities .. " Time left : " .. math.floor(gameTimer)
	else
		hudText = "Food left : " .. #itemList .. "\nAnts alive : " .. #antsAlive ..
		"\nTime left : " .. math.floor(gameTimer)
	end

	handleCamera(dt)
end

function mainGameDraw()
	if not DEBUG then love.graphics.setShader(shaderLight)	end
	shaderLight:send("screen", {map.mapWidth, map.mapHeight})

	shaderLight:send("num_lights", #entitiesList)
	for i=1,#entitiesList do
		local name = "lights[" .. i .."]"
		shaderLight:send(name .. ".position", 
			{gameWidth/2 - cam.x + entitiesList[i].x, gameHeight/2 - cam.y + entitiesList[i].y})

		shaderLight:send(name .. ".diffuse", {0.5, 0.5, 0.5})
		shaderLight:send(name .. ".power", 64)
	end

	cam:attach()

	map:draw()
	base:draw()
	love.graphics.draw(particleSystem)
	for _,e in ipairs(deadEntities) do
		e:draw()
	end
	for _,e in ipairs(entitiesList) do
		e:draw()
	end
	for _,it in ipairs(itemList) do
		it:draw()
	end
	if DEBUG then world:draw() end

	love.graphics.setShader()

	cam:detach()

	-- TODO HUD HERE
	love.graphics.print(hudText, 16, 16)

	if drawNextAntTimer > 1 then
		love.graphics.printf("Your ant is dead :'(\nPress E to switch to another ant.", 0, gameHeight/2 - 5, gameWidth, "center")
	end

	-- GAME PAUSE MENU
	if gamePaused then
		love.graphics.setColor(0.16, 0.15, 0.12, 1)
		love.graphics.rectangle("fill", gameWidth/2 - 250, gameHeight/2 - 100, 500, 200)
		love.graphics.setColor(0.89, 0.81, 0.70, 1)
		love.graphics.setFont(fontHeader)
		love.graphics.printf(pausedText, 0, gameHeight/2 - 60, gameWidth, "center")
		love.graphics.setFont(fontNormal)
		if pausedSubtext ~= nil then
			love.graphics.printf(pausedSubtext, 0, gameHeight/2 - 20, gameWidth, "center")
		end
		love.graphics.printf("Press SPACE or A to go to main menu", 0, gameHeight/2 + 15, gameWidth, "center")
		if not gameOver then
			love.graphics.printf("Press ESC or MENU to continue", 0, gameHeight/2 + 35, gameWidth, "center")
		end
	end

end


function handleCamera(dt)
	cam:lookAt(currentPlayed.x, currentPlayed.y)
	if cam.x < gameWidth/2 then
		cam.x = gameWidth/2
	end
	if cam.y < gameHeight/2 then
		cam.y = gameHeight/2
	end
	if cam.x > (map.mapWidth - gameWidth/2) then
		cam.x = (map.mapWidth - gameWidth/2)
	end
	if cam.y > (map.mapHeight - gameHeight/2) then
		cam.y = (map.mapHeight - gameHeight/2)
	end

	if cam.t < cam.shakeDuration then
		cam.t = cam.t + dt
		local dx = love.math.random(-cam.shakeMagnitude, cam.shakeMagnitude)
		local dy = love.math.random(-cam.shakeMagnitude, cam.shakeMagnitude)
		cam:move(dx,dy)
	end
end

--[[

	GLOBAL FUNCTIONS

]]--
function createEntity(list, entityName, x, y)
	local newEntity = entityName(id, x, y)
	table.insert(list, newEntity)
	id = id + 1
	return newEntity
end
function createLoot(entitiesList, x, y, name)
	local newLoot = Loot(id, x, y, name)
	table.insert(entitiesList, newLoot)
	id = id + 1
	return newLoot
end
function destroyEntity(entitiesList, id)
	for i,v in ipairs(entitiesList) do
		if v.id == id then
			if v.collider ~= nil then 
				if v.collider.body ~= nil then v.collider:destroy() end
			end
			table.remove(entitiesList, i)
			break
		end
	end
end
function newGame()
	require "keyboard"
	require "joystick"

	-- init world
	world = wf.newWorld(0, 0, true)
	world:addCollisionClass('World')
	world:addCollisionClass('BaseCrafter')
	world:addCollisionClass('Ant',{ignores = {'BaseCrafter', 'Ant'}})
	world:addCollisionClass('Spider',{ignores = {'BaseCrafter'}})
	world:addCollisionClass('Beetle',{ignores = {'BaseCrafter', 'Beetle'}})
	world:addCollisionClass('Items',{ignores = {'BaseCrafter'}})
	world:addCollisionClass('Bullet_ant',{ignores = {'BaseCrafter', 'Ant'}})
	world:addCollisionClass('Bullet_beetle',{ignores = {'BaseCrafter', 'Beetle'}})
	world:setQueryDebugDrawing(QUERY_DEBUG)

	-- init global vars
	gamePaused = false
	map = nil
	currentPlayed = nil
	id = 0
	entitiesList = {}
	itemList = {}
	antList = {}
	antsAlive = {}
	deadEntities = {}
	map = Map(0, 0)
	base = Base(99, map.map[map.baseAnts].x, map.map[map.baseAnts].y)
	drawNextAntTimer = 0
	gameTimer = TIME_LIMIT 
	gameOver = false

	-- ants spawn
	local offset = 64
	table.insert(antList, createEntity(entitiesList, Ant, map.map[map.baseAnts].x, map.map[map.baseAnts].y))
	table.insert(antList, createEntity(entitiesList, Ant, map.map[map.baseAnts].x + offset, map.map[map.baseAnts].y))
	table.insert(antList, createEntity(entitiesList, Ant, map.map[map.baseAnts].x + offset, map.map[map.baseAnts].y + offset))
	table.insert(antList, createEntity(entitiesList, Ant, map.map[map.baseAnts].x, map.map[map.baseAnts].y + offset))
	antsAlive = antList

	-- spider spawn
	createEntity(entitiesList, Spider, map.map[map.baseSpider].x, map.map[map.baseSpider].y)

	-- item spawn
	for _,v in ipairs(map.startItems) do
		createEntity(itemList, Item, map.map[v].x, map.map[v].y)
	end
	-- beetle spawn
	for _,v in ipairs(map.startBeetles) do
		createEntity(entitiesList, Beetle, map.map[v].x, map.map[v].y)
	end

	currentPlayed = antList[1]
	currentPlayed:setPlayerControl(true)

	hudText = ""

	cam = camera()
	initParticleSystem()
	-- shader init
	shaderLight = love.graphics.newShader(SHADER_LIGHT)
end
function resetGame() 
	for _,v in ipairs(antList) do
		if v.state ~= "death" then 
			v:remove()
		end
		v = nil
	end 
	for _,v in ipairs(entitiesList) do
		v:remove()
		v = nil
	end 
	for _,v in ipairs(itemList) do
		if v.collider ~= nil then 
			if v.collider.body ~= nil then v.collider:destroy() end
		end
		v = nil
	end
	for _,v in ipairs(deadEntities) do
		v:destroy()
		v = nil
	end
	deadEntities = {}
	entitiesList = {}
	itemList = {}
	antList = {}

	base:destroy()
	map:clearMap()
	map = nil

	shaderLight:release()
	shaderLight = nil
	cam = nil
end

function pauseGame(text, subtext)
	if not gameOver then
		gamePaused = not gamePaused
	else 
		gamePaused = true
	end
	if gamePaused then
		pausedText = text
		if gameOver and subtext ~= nil then
			pausedSubtext = subtext
		end
	else
		pausedText = ""
	end
end

function setGameOver(winCond)
	gameOver = true
	if winCond then
		pauseGame("CONGRATULATION !", "You manage to collect all the food in " .. math.floor(gameTimer) .. " seconds.")
	else
		pauseGame("GAME OVER !", "This seed was too hard...")
	end
end

function getNeighborsTiles(tile)
	local res = {}
	for _,v in ipairs(NEIGHBORS_4) do
		if tile.index + v >= 1 and tile.index + v <= (MAP_SIZE_X*MAP_SIZE_Y) then
			table.insert(res, map.map[tile.index + v])
		end
	end
	return res
end

function initParticleSystem() 
	local imageData = love.image.newImageData(1, 1)
	imageData:setPixel(0,0, 0.83,0.50,0.30,1)

	local image = love.graphics.newImage(imageData)
	particleSystem = love.graphics.newParticleSystem(image, 1000)
	particleSystem:setEmissionRate(150)
	particleSystem:setParticleLifetime(.7, 1)
	particleSystem:setSizes(3)
	particleSystem:setSpread(2*math.pi)
	particleSystem:setSpeed(20, 30)
	particleSystem:setColors(0,1,1,1, 1,1,0,1, 1,0,0,1, 1,0,0,0)
	particleSystem:moveTo(currentPlayed.x,currentPlayed.y)
	particleSystem:setEmitterLifetime(PARTICLE_LIFETIME)
	particleSystem:stop()
end


-- UTILS --
function distance(x1,x2,y1,y2)
	return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end
function manhattan(x1,x2,y1,y2)
	local d1 = math.abs(x2 - x1);
	local d2 = math.abs(y2 - y1);
	return d1 + d2;
end
function dot(x1,y1,x2,y2)
	return (x1 * x2) + (y1 * y2)
end
function mag(x,y)
	return math.sqrt((x * x) + (y * y))
end
function minmax(v, min, max)
	if v < min then
		v = min
	elseif v > max then
		v = max
	end
	return v
end
function randomExcluding(min, max, exclude)
	if exclude == min then
		return math.random(min + 1, max)
	elseif exclude == max then
		return math.random(min, max - 1)
	end

	local res = math.random(min, max)
	if res == exclude then
		if math.random() > 0.5 then
			return res + 1
		else 
			return res - 1
		end
	else
		return res
	end
end
function reverseTable(t)
	local res = {}
	for i = #t, 1, -1 do
		table.insert(res, t[i])
	end
	return res
end
function indexOf(t, val)
	for i, v in ipairs(t) do
		if v == val then
			return i
		end
	end
	return nil
end
function includes(t, val)
	for i, v in ipairs(t) do
		if v == val then
			return true
		end
	end
	return false
end