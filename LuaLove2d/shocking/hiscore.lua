--gamestate = require("gamestate")
hiscore = gamestate.new()

function hiscore:init()
end

function hiscore:enter()
	overalltime = 0
	firstrow = false  --- marker for through-line printing
	position = 1
	hiscoretable = {}
	pressed = false

	if love.filesystem.isFile("hiscore.jlmg") == false then
		for line in love.filesystem.lines("defaultscore.jlmg") do
			table.insert(hiscoretable, line)
		end
		newscore = love.filesystem.newFile("hiscore.jlmg")
		newscore:open("w")
		for i,v in ipairs(hiscoretable) do
			newscore:write(v.."\n")
		end
		newscore:close()
	else
		for line in love.filesystem.lines("hiscore.jlmg") do
			table.insert(hiscoretable, line)
		end
	end

end

function hiscore:update(dt)
	overalltime = overalltime + dt

	if overalltime > 1 and pressed == true then
		gamestate.switch(intro)
	end
end

function hiscore:draw()
  love.graphics.setCanvas(Display1024)
	if overalltime < 3 and introscene == true then
		love.graphics.setColor(255,255,255,105+50*overalltime)
	else
		love.graphics.setColor(255,255,255,255)
	end
	love.graphics.draw(poster, 0, 0)

	love.graphics.setFont(normalfont)
	love.graphics.setColor(0,0,0,255)
	love.graphics.printf ("TOP ELECTRICIANS", 0, 300, screenwidth, 'center')
	for i,v in ipairs(hiscoretable) do
		if firstrow == false then
			love.graphics.printf(tostring(position)..". "..v,100,400+i*30, screenwidth, 'left')
			position = position + 1
			firstrow = true
		else
			love.graphics.printf(v,-50,400+(i-1)*30, screenwidth, 'right')
			firstrow = false
		end
	end

	position = 1
	firstrow = false
  love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.clear()
  love.graphics.draw(Display1024, 0,0,0,Display_scale, Display_scale)
end
