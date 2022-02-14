endgame = gamestate.new()

function gameover:init()
end

function gameover:enter()
  
end

function gameover:update(dt)
end

function gameover:draw()
  love.graphics.clear()
  love.graphics.setCanvas(Display)
  love.graphics.setColor(255,255,255,255)
  
  love.graphics.setColor(255,0,0,255)
  love.graphics.print("REKT",cup.width/2,cup.height/2)
  love.graphics.draw(UIgameover,camerastart[1],camerastart[2])
  
  love.graphics.setCanvas(Cup)
    love.graphics.clear()
    love.graphics.setColor(255,205,205,155)
    love.graphics.draw(UIbackground,0,0)
  love.graphics.setCanvas()
  
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(Cup,camerastart[1],camerastart[2])
  
  love.graphics.setColor(255,255,255,255)
  draw_ui()
  
  love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(UIwalls,75,25)
  love.graphics.draw(Display, 0,0,0,Display_scale, Display_scale)
end