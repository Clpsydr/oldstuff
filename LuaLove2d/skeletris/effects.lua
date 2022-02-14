function makeeffect(effectkind, duration, location, animation)
  effect = {}
  effect.maxduration = duration
  effect.duration = duration
  effect.type = effectkind
  effect.loc = location
  effect.animation = animation
  effect.animtime = 0
  effect.currentframe = 1
  ---- should determine image and animation type
  
  table.insert(Effects, effect)
end

function MakeSparkVisual(location)
  spark = love.graphics.newParticleSystem(Sparks[math.random(1,#Sparks)], 5)
  spark:setEmissionRate          (40)
  spark:setLifetime              (0.5)
  spark:setParticleLife          (0.5)
  spark:setSpread                (-4,4)
  spark:setSpeed                 (100)
  spark:setDirection             (0)
  spark:setSizes                 (1,2)
  spark:setSpin                  (1,15)
  spark:setPosition(location.x,location.y)
  spark:setColors(math.random(1,255),math.random(1,255),math.random(1,255),255,255,255,255,0)
  spark:start()
  table.insert(Particles, spark)
  
  --- replace sparks with brighter ones
end

function MakeFogVisual(location, color1, color2, color3, fogtype)
  fog = love.graphics.newParticleSystem(fogtype[math.random(1,#fogtype)], 5)
  fog:setEmissionRate          (60)
  fog:setLifetime              (0.5)
  fog:setParticleLife          (0.5)
  fog:setSpread                (-4,4)
  fog:setSpeed                 (100)
  fog:setDirection             (0)
  fog:setSizes                 (1,0.5)
  fog:setSpin                  (1,1)
  fog:setPosition(location.x,location.y)
  fog:setColors(color1,color2,color3,255,color1,color2,color3,255)
  fog:start()
  table.insert(Particles, fog)
  
  --- add gravity
end

function UpdateEffects(dt)
  --- handling other animation
  for i,v in ipairs(Effects) do
    if v.type ~= "spawnenemy" then
    if v.animtime > v.maxduration/#v.animation then   --- animation handle
      v.animtime = 0
      if v.currentframe == #v.animation+1  then
        v.currentframe = 1
      else
        v.currentframe = v.currentframe + 1
      end
    else 
      v.animtime = v.animtime + dt
    end
    end
      
    if v.duration < 0.25 then  ---- duration of the effect handling
      if v.type == "spawnenemy" then
        SpawnEnemy()
      end
      table.remove(Effects, i)
      
    else
      v.duration = v.duration - dt
    end
  end
  
  ---- updating and restarting particles 
  for i,v in ipairs(Particles) do
   if v:isActive() == false then
     table.remove(Particles, i)
   end
   v:update(dt)
  end
end


function Draw_Effects()
  love.graphics.setCanvas(Effectcanvas)
  Effectcanvas:clear()
  for i,v in ipairs(Effects) do
    if v.type == "slimedeath" or v.type == "ghostdeath" then
      love.graphics.setColor(255,255,255,255*v.duration)
      love.graphics.draw(v.animation[v.currentframe], v.loc.x-GridCell.width/2+camerastart[1], 
                                                      v.loc.y-GridCell.height/2+camerastart[2])
    elseif v.type == "spawnenemy" then
      love.graphics.setColor(255,255,255,255*3*math.cos(overalltime))
      love.graphics.draw(UIlights,v.loc.x,v.loc.y+25)
    end
  end
  
  love.graphics.setColor(255,255,255,255)
  love.graphics.setCanvas()
end