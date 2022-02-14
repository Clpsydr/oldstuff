--gamestate = require "gamestate"
howto = gamestate.new()

function howto: init()
end

function howto: enter()
overalltime = 0
end
function howto: update(dt)
	overalltime = overalltime + dt

	if love.keyboard.isDown("return") and overalltime > 1 then
		allowexit = true
		gamestate.switch(intro)
	end
end

function howto: draw()
  love.graphics.setCanvas(Display1024)
	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(howtoimg,0,0)

  love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.clear()
  love.graphics.draw(Display1024, 0,0,0,Display_scale, Display_scale)
end
