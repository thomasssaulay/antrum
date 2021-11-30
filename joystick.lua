function love.joystickpressed(joystick,button)
   if gameState == 1 then
      if button == 3 then
         -- CYCLE THRU ANT LIST
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
            drawNextAntTimer = 0
            currentPlayed:setPlayerControl(true)
         end
      end
      if button == 2 then
         particleSystem:stop()
         particleSystem:moveTo(currentPlayed.x, currentPlayed.y)
         particleSystem:start()
         for i,v in ipairs(antList) do
            if v.id ~= currentPlayed.id and v.isHolding == nil then
               v.path = v:findPath(map.map[currentPlayed:getCurrentTileIndex()])
            end
         end
      end
      if button == 8 then
         pauseGame("PAUSED !")
      end
      if button == 1 then
         if not gamePaused and currentPlayed.state ~= "death" then
            local actionDone = false
            local query = world:queryCircleArea(currentPlayed.x, currentPlayed.y, 48)
            for _, collider in ipairs(query) do
               local vx,vy = currentPlayed.collider:getLinearVelocity() 
               collider:applyLinearImpulse(vx/2, vy/2)
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
         else
            gameState = 0
            clearAllTimers()
            initMenu()
         end
      end
   end
end