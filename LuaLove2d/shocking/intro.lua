gamestate = require "gamestate"
intro = gamestate.new()

function intro:enter()
  BuildBack = love.graphics.newCanvas(1024,1024)
	menucounter = 1    --- current cursor position
	overalltime = 0     
	presscooldown = 0  --- to prevent multiple presses
end

function intro:init()
	menunames = {"Start game", "How to play", "Hi score", "Quit"}
	poster 			= love.graphics.newImage("title image.jpg")
	menutotal 		= love.graphics.newImage("title image.jpg")
	menustart		= love.graphics.newImage("title image.jpg")
	menuhelp		= love.graphics.newImage("title image.jpg")
	menuhiscore		= love.graphics.newImage("title image.jpg")
	menuquit		= love.graphics.newImage("title image.jpg")

	introscene = true
end

function intro:update(dt)
	presscooldown = presscooldown + dt
	overalltime = overalltime + dt

 if love.keyboard.isDown("down") and presscooldown > 0.2 then
	menucounter = menucounter + 1
	if menucounter > 4 then
		menucounter = 1
	end
	presscooldown = 0
 end

 if love.keyboard.isDown("up") and presscooldown > 0.2 then
	menucounter = menucounter - 1
	if menucounter < 1 then
		menucounter = 4
	end
	presscooldown = 0
 end

  --- if pressed enable the countdown
  if pressedonce == true then
    transitiontime = transitiontime + dt
  end

  --- if pressed set up the transition
  if love.keyboard.isDown("return") and presscooldown > 0.2 then
    introscene = false
    presscooldown = 0
  
    if menucounter == 1 then
      overalltime = 0
      introscene = true
      gamestage = 1
      difficulty = 1
      Fuse = 1						    -- current amount of player lives  
      Score = 0						    -- current score
      gamestate.switch(transition)
    end
    
    if menucounter == 4 then
      love.event.quit()
    end

    if menucounter == 2 then
      gamestate.switch(howto)
    end

    if menucounter == 3 then
      gamestate.switch(hiscore)
    end
  end
end

function intro:draw()
  love.graphics.setCanvas(Display1024)
	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(poster, 0, 0)

	for i = 1, 4 do
		if menucounter == i then
			love.graphics.setFont(menufontless)
			love.graphics.setColor(200, 0, 0 ,255)
			love.graphics.printf(tostring(menunames[menucounter]),0,655+menucounter*50,screenwidth,'center')
		else
			love.graphics.setFont(menufont)
			love.graphics.setColor(0,0,0,255)
			love.graphics.printf(tostring(menunames[i]),0,655+i*50,screenwidth,'center')
		end
	end

	love.graphics.setColor(255,255,255,255)
  love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.clear()
  love.graphics.draw(Display1024, 0,0,0,Display_scale, Display_scale)

end
