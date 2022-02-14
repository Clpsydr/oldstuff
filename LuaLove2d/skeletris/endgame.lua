endgame = gamestate.new()

function endgame:init()
  
end

function endgame:enter()
  lidfalltimer = 3
  timeelapsed = 0
  lidrange = 700
end

function endgame:update(dt)
  if timeelapsed <= lidfalltimer then
    timeelapsed = timeelapsed + dt
    
  end
end

function endgame:draw()
  love.graphics.clear()
  love.graphics.setCanvas(Display)
  love.graphics.setColor(255,255,255,255)
  
  love.graphics.setCanvas(Cup)
    love.graphics.clear()
    love.graphics.setColor(255,205,205,155)
    love.graphics.draw(UIbackground,0,0)
    drawblocks()
  love.graphics.setCanvas()
  
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(Cup,camerastart[1],camerastart[2])
  
  love.graphics.setColor(255,255,255,255)
  draw_ui()
  
  love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(UIwalls,camerastart[1]-50,camerastart[2]-25)
  love.graphics.draw(Display, 0,0,0,Display_scale, Display_scale)
  
  love.graphics.draw(UIgameover, camerastart[1]-50, camerastart[2]-15-
                      lidrange+easingFunctions.outBounce(timeelapsed,0,lidrange-10,lidfalltimer))
                    
  if timeelapsed > lidfalltimer then
    love.graphics.setColor(255,0,0,255)
    love.graphics.print("score:", 125, 400)
    love.graphics.print(Points, 125, 450)
  end
end