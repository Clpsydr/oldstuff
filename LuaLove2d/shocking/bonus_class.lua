function makeBonusFloat (image, location, duration)
   boni = {}
   boni.image = image
   boni.location = location
   boni.duration = duration
   boni.life = true
   boni.blink = 0 
    
   table.insert(Bonus, boni)
end
  
function updateBonus (dt)
  for i,v in ipairs(Bonus) do
    v.duration = v.duration - dt
    v.blink = v.blink + dt
    v.location = v.location - vector(0,dt*5)
    if v.duration < 0 then v.life = false end
    if v.blink > 0.5 then v.blink = 0 end
  end
  
  for i,v in ipairs(Bonus) do
    if v.life == false then table.remove(Bonus, i) end
  end
end

function draw_bonus ()
  for i,v in ipairs(Bonus) do
    love.graphics.setColor(255,255,255,255*(1-v.blink))
    love.graphics.draw(v.image, v.location.x-10, v.location.y-20, 0, 0.4, 0.4)
  end
end