function love.joystickpressed(joystick,button)
   print(button)
   if button == 2 then
      -- CYCLE THRU ANT LIST
      --------------------------------- TODO :: BUGGY
      if #antsAlive >= 1 then
         local found = false
         for i,v in ipairs(antsAlive) do
            if currentPlayed.id == v.id then
               currentPlayed:setPlayerControl(false)
               if i == #antsAlive then currentPlayed = antsAlive[1]
               else currentPlayed = antsAlive[i+1] end
               found = true
               break
            end 
         end
         if not found then 
            currentPlayed = antsAlive[1] 
         end
         currentPlayed:setPlayerControl(true)
      end
   end
   -- if key == "r" then
   --    createEntity(entitiesList, Beetle,  currentPlayed.x+64, currentPlayed.y)
   --    -- table.insert(antList, createEntity(entitiesList, Ant, currentPlayed.x+32, currentPlayed.y))
   --    -- antList[#antList]:setNextWanderTarget()
   --    -- resetGame()
   --    -- newGame()
   -- end
   -- if key == "t" then
   --    for i,v in ipairs(antList) do
   --       if v.id ~= currentPlayed.id and v.isHolding == nil then
   --          v.path = v:findPath(map.map[currentPlayed:getCurrentTileIndex()])
   --       end
   --    end
   --    -- currentPlayed:die()
   -- end
   -- if key == "escape" then
   --    love.event.quit()
   -- end
   -- if key == "f" then
   --    love.window.setFullscreen( not love.window.getFullscreen( ) )
   --    gameWidth, gameHeight = love.graphics.getDimensions()
   -- end
   if button == 1 then
      -- MAIN ACTION EVENT
      local actionDone = false
      local query = world:queryCircleArea(currentPlayed.x, currentPlayed.y, 48)
      for _, collider in ipairs(query) do
         local vx,vy = currentPlayed.collider:getLinearVelocity() 
         collider:applyLinearImpulse(vx/2, vy/2) -- TOFIX ::
         local obj = collider:getObject()
         if not actionDone then
            if obj.type == "item" then
               if obj.holder == nil then
                  if currentPlayed.isHolding == nil then
                     obj:setHolder(currentPlayed)
                     actionDone = true
                  end
               else
                  obj:unsetHolder()
                  actionDone = true
               end
            end
         end
      end
   end
end