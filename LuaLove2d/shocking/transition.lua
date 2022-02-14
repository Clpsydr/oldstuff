transition = gamestate.new()

function transition:init()
  fontcanvas = love.graphics.newCanvas(200,200)
end

function transition:enter()
  love.graphics.setColor(0,0,0,255)
  love.graphics.clear()
  timer = 0
  
  transition_rotation = 1-2*math.random(0,1)
end

function transition:update(dt)
  timer = timer +dt
  
  if timer > 2 then
    gamestate.switch(gameplay,gamestage, difficulty)
  end
end

function transition:draw()
  love.graphics.setCanvas(Display1024)
  love.graphics.setColor(0,0,0,255)
  love.graphics.clear()
  love.graphics.setColor(157,161,255)
  love.graphics.rectangle("fill",0,0,screenwidth,screenheight)
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(loadingimg,screenwidth/2, screenheight/2,timer*5*transition_rotation,1,1,screenwidth/4,screenheight/4)
  love.graphics.setColor(0,0,0,255)
  love.graphics.setFont(uifont)
  love.graphics.print("Stage: "..gamestage, screenwidth/2,screenheight/2,0,2,2,40,10)
  love.graphics.print(StageNames[gamestage], screenwidth/2, screenheight/2,0,2,2,40,30)
  
  if timer > 1 then
  love.graphics.setColor(255,255,255,255*(2-timer))
  else
  love.graphics.setColor(255,255,255,255)
  end
  
  love.graphics.setCanvas()
  
  love.graphics.draw(Display1024,0,0,0,Display_scale, Display_scale)
end