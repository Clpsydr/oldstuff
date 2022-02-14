function makeDisaster(distype, length, speed, step, location)
  disaster = {}
  disaster.type = distype
  disaster.location = location
  if distype == "radial" then
    disaster.shift = math.random(0,90)/180*math.pi   -- random shift for rotating the whole pattern
  end
  if distype == "typhoon" then
    disaster.destination = PlayerLoc - location
  end
  if distype == "bomb" then
    disaster.shift = math.random(0,359)/180*math.pi
    repeat
      rand_X = math.random(-200,200)
      rand_Y = math.random(-200,200)
    until location.x+rand_X < screenwidth and location.x + rand_X > 0 
      and location.y + rand_Y < screenheight and location.y + rand_Y > 0
    disaster.destination = location + vector(math.random(-200,200),math.random(-200,200))  
  end
  
  disaster.length = length
  disaster.speed = speed
  disaster.step = step
  
  disaster.lifetime = 0 
  disaster.phase = 0
  disaster.value = 10
  table.insert(Calamities, disaster)
end

---------------------------------------------------------------------------------------------------------
function UpdateDisaster(dt)
  for i,v in ipairs(Calamities) do
    
    if v.type == "radial" then
      if v.lifetime > v.step then
        if v.phase == 1  then
          makesparks(8+difficulty, v.location, "direct", 1.4, scorespark, v.shift)
          v.phase = 0
        else 
          makesparks(8+difficulty, v.location, "direct", 1.4, scorespark, v.shift+math.pi/8)
          v.phase = 1
        end
        v.lifetime = 0
        Score = Score + v.value
      else 
        v.lifetime = v.lifetime + dt
      end
    elseif v.type == "cluster" then       ----- calamity that creates bombs
      if v.lifetime > v.step then
        makeDisaster("bomb", 99, 100, 0, v.location)
        v.lifetime = 0
      else 
        v.lifetime = v.lifetime + dt
      end
    elseif v.type == "bomb" then            ---- moving calamity that explodes in large sparks
       v.location = (v.location + dt*v.speed*(v.destination-v.location):normalized())
      if (v.destination-v.location):len() < 1 then
        makesparks(10+difficulty, v.location, "big", 1, sparkimg, 0)
        table.remove(Calamities, i)
      end
    elseif v.type == "assault" then         --- creates homing cluster of arrows
      if v.lifetime > v.step then
        v.shift =  math.atan2(PlayerLoc.y - v.location.y, PlayerLoc.x - v.location.x)
        makesparks(3+difficulty, v.location, "homing", 4, scorespark, v.shift)
        v.lifetime = 0
      else 
        v.lifetime = v.lifetime + dt
      end
    elseif v.type == "typhoon" then         --- creates one moving calamity that leaves a trail of sparks
      v.location = v.location + v.destination:normalized()*v.speed*dt
      if v.lifetime > v.step then
        makesparks(1, v.location, "swaying", -0.5, sparkimg, 45/180*math.pi)
        makesparks(1, v.location, "swaying", -0.5, sparkimg, -45/180*math.pi)
        v.lifetime = 0
      else 
        v.lifetime = v.lifetime + dt
      end
    elseif v.type == "outward" then           --- creates a spiral of flying away sparks.
      if v.lifetime > v.step then
        makesparks(16, v.location, "spiraling", 1, sparkimg, -1) --- shift there determines the rotation direction
        --makesparks(4, v.location, "spiraling", 1, sparkimg, 1)
        v.lifetime = 0
      else
        v.lifetime = v.lifetime + dt
      end
    elseif v.type == "mine" then
      if v.lifetime > v.step then
        makesparks(10, v.location, "puff", 1, sparkimg, 0)
        v.length = 0
        v.lifetime = 0
      else 
        v.lifetime = v.lifetime + dt
      end
    end
    
    if math.abs(v.location.x - PlayerLoc.x) < 40 and math.abs(v.location.y - PlayerLoc.y) < 40 then
      HurtPlayer(5)
    end
    
    if v.length < 0 then
      table.remove(Calamities, i)
    else
      v.length = v.length - dt
    end
  end
end

---------------------------------------------------------------------------------------------------------
function draw_disaster()
  for i,v in ipairs(Calamities) do
    if v.step - v.lifetime < 0.5 and (v.type == "assault" or v.type == "radial") then
      love.graphics.setColor(255,255,0,255*0.01*math.random(1,100))
      love.graphics.draw(calamimg2,v.location.x, v.location.y, -overalltime, 2*(v.step-v.lifetime),2*(v.step-v.lifetime), 30,30)
      love.graphics.setColor(255,255,0,255*0.01*math.random(1,100))
      love.graphics.draw(calamimg,v.location.x, v.location.y, overalltime, 2*(v.step-v.lifetime),2*(v.step-v.lifetime), 30,30)
    else
      love.graphics.setColor(255,255,0,255*0.01*math.random(1,100))
      love.graphics.draw(calamimg2,v.location.x, v.location.y, -overalltime, 1,1, 30,30)
      love.graphics.setColor(255,255,0,255*0.01*math.random(1,100))
      love.graphics.draw(calamimg,v.location.x, v.location.y, overalltime, 1,1, 30,30)
    end
  end
end


