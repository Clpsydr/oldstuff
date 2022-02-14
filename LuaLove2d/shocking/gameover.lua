gameover = gamestate.new()

function WhoDaBest (scorelist, newscore)   --- inserting new value in hiscore and removing the lowest.
-- implying its sorted already
	if #scorelist > 9 then
		for i,v in ipairs(scorelist) do
			if tonumber(newscore.value) > tonumber(v.value) then
				table.insert(scorelist, i, newscore)
				table.remove(scorelist)
				return true
			end
		end
		return false
	else
		for i,v in ipairs(scorelist) do
			if tonumber(newscore.value) > tonumber(v.value) then
				table.insert(scorelist, i, newscore)
				return true
			end
		end
		table.insert(scorelist, newscore)
		return true
	end
end

function gameover: init()
  gameoverstencil = love.graphics.newStencil(stenciltext)
end

function gameover: enter()
  BakeCity(currentcity)
  
  for i,v in ipairs (Sparks) do
      v.img = deadsparkimg
  end
	keystack = ""
	overalltime = 0
	hiscoretable = {}
	cooldown = 0.5
	writtendown = false   --- checks if user typed down his name
	Name = ""
	typecooldown = 0
	toexit = false
end

function gameover: update(dt)
	overalltime = overalltime + dt
	TransformersUpdate(dt)
	RelaysUpdate(dt)
	SparksUpdate(dt)
	cooldown = cooldown - dt
	typecooldown = typecooldown - dt

	--- return to menu
	if love.keyboard.isDown("return") and toexit == true and cooldown < 0 then
		love.graphics.setStencil()
    gamestate.switch(intro)
	end

	--- input the name
	if toexit == false then
		if keystack ~= "" and typecooldown < 0 then
			if string.len(Name) <= 10 and keystack ~= "backspace" then
				Name = Name .. keystack
			elseif keystack == "backspace" then
				Name = string.sub(Name,1,-2)
			end
			keystack = ""
			typecooldown = 0.05
		end

		--- save the name and put it into the file
		if love.keyboard.isDown("return") and cooldown <0 then
			newhiscore = {}
			newhiscore.name = Name
			newhiscore.value = tostring(math.floor(Score))

			--checking if the file exists
			if love.filesystem.isFile("hiscore.jlmg") == false then
				newscorefile = love.filesystem.newFile("hiscore.jlmg")
				newscorefile:open("w")
				for line in love.filesystem.lines("defaultscore.jlmg") do
					newscorefile:write(line.."\r\n")
				end
				newscorefile:close()
			end

			first = true        ---- Recording the file into the register
			for line in love.filesystem.lines("hiscore.jlmg") do
				if first == true then
					record = {}
					record.name = line
					first = false
				else
					record.value = line
					first = true
					table.insert(hiscoretable, record)
				end
			end

			--decision = WhoDaBest(hiscoretable,newhiscore)
			--writing new table down
			if WhoDaBest(hiscoretable, newhiscore) == true then
				correctedscore = love.filesystem.newFile("hiscore.jlmg")
				correctedscore:open("w")
				for i,v in ipairs(hiscoretable) do
					correctedscore:write(v.name.."\r\n"..v.value.."\r\n")
				end
				correctedscore:close()
				wintext = "you got a high score!"
			else
				wintext = "not enough to get to the top!"
			end

			writtendown = true
			cooldown = 0.5
			toexit = true
		end
	end
end

function stenciltext()
  love.graphics.setFont(deathfont)
  love.graphics.printf("YOU DIED",0,420,screenwidth,'center')
 end

function gameover: draw(dt)
	love.graphics.setCanvas(Display1024)
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(citycanvas,0,0)
	love.graphics.setFont(normalfont)

	 for i,v in ipairs(facilityblock) do
    if v.type == "standard" then
      drawCommonBuilding(v)
    else
      drawSpecialBuilding(v)
    end
  end
	draw_substations(dt)

	draw_relays(dt)

	draw_wires(dt)

	draw_sparks(dt)

--- blanket for gameover
	if overalltime < 3 then
		love.graphics.setColor(255,255,255,80*overalltime)
		love.graphics.setFont(deathfont)
    love.graphics.draw(gameoverimg,0,0)
	else
		love.graphics.setColor(255,255,255,240)
		love.graphics.draw(gameoverimg,0,0)
    love.graphics.setColor(185,0,0,85*overalltime)
		--love.graphics.printf("YOU DIED",0,420,screenwidth,'center')
	end

	love.graphics.setFont(normalfont)
	love.graphics.setColor(255,0,0,255)

	if writtendown == true then					--- shows hiscore if user has typed down the info
		for i,v in ipairs(hiscoretable) do
			love.graphics.printf(wintext,0,400, screenwidth, 'center')
			love.graphics.printf(v.name.." "..v.value,0,450+i*30, screenwidth, 'center')
      love.graphics.setColor(255,0,0,255)
		end
	else
		love.graphics.print("Enter your name: " .. Name, 30 ,600)
		love.graphics.setColor(185,0,0,250)
    love.graphics.setFont(deathfont)
		love.graphics.printf("YOU DIED",0,420,screenwidth,'center')
	end

  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(mapmode[mapmode_curr].bord,0,0)
  
love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.clear()
  love.graphics.draw(Display1024, 0,0,0,Display_scale, Display_scale)
end



