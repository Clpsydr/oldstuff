function drawBuildingToBack(building, image)
  love.graphics.setCanvas(BuildBack)
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(image, building.location.x-building.Size.x/2, building.location.y-building.Size.y/2, 0,0.5,0.5)
  love.graphics.setCanvas()
  
  ---canvas buildings in the stack
  --- draw them always but pop out every time resolution is changed
    buildcanvas = {}
    buildcanvas.location = building.location
    buildcanvas.size = building.Size
    buildcanvas.image = image
    table.insert(canvasbuilds, buildcanvas)
end

function DrawRelayChain(building)  --- finds the relay connected to the turned on building
  routelist = {}   --- list of successful paths
       
  for i,v in ipairs(Relays) do
    for ii,vv in ipairs(v.connections) do     --- check all relays connected to building and check paths from them
      if vv.type == "facility" and vv.ID == building.location then
        thepath({}, v)   --- draws paths from each relay
      end
    end
  end
  comparepaths(routelist)   --- there should be a bunch of saved paths by now
end

function thepath(route, relay)
  local newroute = route
  table.insert(newroute, relay)        --- add to the route list
  
  if #Relays < #route then
    --- check also if the following relays are already in the route list
    return
  end
  
 --- check all connections 
  for i,v in ipairs (relay.connections) do        --- check if there is a connection to generator
    for ii,vv in ipairs (Transformers) do
      if v.type == "substation" and v.ID == vv.ID then
        table.insert(routelist, newroute)        ---- save it into route and finish the function
        return true
      end
    end
  end
 
  for i,v in ipairs (relay.connections) do        
    for ii,vv in ipairs (Relays) do           --- and see if they are connected to other relays
      if v.type == "relay" and vv.ID == v.ID then --- 
        for iii,vvv in ipairs (route) do          --- if it wasn't already in the route
          if vvv.ID ~= vv.ID then
            return thepath(newroute, vv)  --- start the loop from that relay
          end
        end
      end
    end
  end
  
  return ---- otherwise return
  
  --- There could be a problem, if it saves all shit in one "stack" operand
end

function comparepaths(listofpaths)
  counter = #Relays
  winner = 0
  for i,v in ipairs(listofpaths) do
    if #v <= counter then 
      counter = #v
      winner = i
    end
  end
  
  if winner ~= 0 then
    ImmortalizeRelayStack(listofpaths[winner])
  end
  --for each route out of stack, find shortest
  --- immortalize the shortst route
end
 
 function ImmortalizeRelayStack(listofrelays)    --- stop relays from ending
   for i,v in ipairs(listofrelays) do
     for ii,vv in ipairs(Relays) do
       if vv.ID == v.ID then
         vv.immortal = true
         vv.energy = relaycap
       end
     end
   end
 end

function updateFacilities(dt)
  for i,v in ipairs(facilityblock) do
		v.showsuccess = v.showsuccess - dt
    v.lifetime = v.lifetime + dt

		if v.connected == true then				--- if facility is powered, energy is subtracted
			v.energyneed = v.energyneed - dt
		end

		if v.type == "standard" then
			if v.energyneed < 0 and v.fulfill == false then   --- Successful facility

        Score = Score + v.score*(0.9+0.2*difficulty)
				v.showsuccess = 4
				v.connected = false
				v.fulfill = true
				bonustime = math.random(1,3)
				if bonustime == 1 then
					Fuse = Fuse +1
					bonustime = "Extra fuse awarded"
          makeBonusFloat(bonus_fuse, v.location, 5)
				elseif bonustime == 2 then
					gencap = gencap + 10
					bonustime = "Substation capacity increased"
          makeBonusFloat(bonus_expandgen, v.location, 5)
				else
					tension = tension - 10
					bonustime = "Energy demand is reduced"
          makeBonusFloat(bonus_energy, v.location, 5)
				end

				addmessage(message_def_time,"Building is electrified! "..bonustime, {0,0,200})
        buildings_done = buildings_done + 1
        makeDisaster("radial", 10+difficulty, 1, 1, v.location)

			elseif v.showsuccess < 0 and v.fulfill == true then       --- replacing the facility
        drawBuildingToBack(v, onbuilding)   --- puts image of the building on canvas
        DrawRelayChain(v,{},0)              --- makes relays to this building immortal
        table.remove(facilityblock, i)      --- removes the actual building
        
				standardenergy = standardenergy + 5   ---- ! should count in the function above
			end
		else  --- procedure for nonstandard facility
			if v.showsuccess < 0 and deadline <= 0 then          ---- replacing the facility, or failing it
				if deadline < 0 then
					addmessage(message_def_time, "failed to provide energy in time",{200,0,0})
					eventcooldown = 15
				else
          drawBuildingToBack(v, v.img)
          DrawRelayChain(v,{},0)
        end
				table.remove(facilityblock, i)

			elseif v.energyneed < 0 and v.fulfill == false then    --- successful special facility
				Score = Score + v.score*(0.9+0.2*difficulty)
				addmessage(message_def_time, tostring(v.type).." is electrified! Extra generator awarded",{0,0,200})
        makeBonusFloat(bonus_extragen, v.location, 5)
				genleft = genleft + 1
				maxgens = maxgens + 1
        buildings_done = buildings_done + 1
        if v.type == "Museum" then
          makeDisaster("cluster", 10, 1, 1, v.location)
        elseif v.type == "Observatory" then
          makeDisaster("typhoon", 10, 100, 0.3, v.location)
        elseif v.type == "Factory" then
          makeDisaster("assault", 6, 150, 2, v.location)
        elseif v.type == "Hospital" then
          makeDisaster("mine", 50, 0, 1, v.location)
        elseif v.type == "Trade center" then
          makeDisaster("outward", 1.2,1,0.3, v.location)
        end
        deadline = 0
				v.showsuccess = 4
				eventcooldown = 19
				deadline = 0
				v.fulfill = true
			end
		end
	end
end

function BuildSpawnHandler(dt)
    if isBuildingThere("standard") == false then
      facility = {}   				-- facility to fullfill, goes into the list
      facility.energyneed = standardenergy
      facility.type = "standard"		-- type of the facility, standard means usual apartment
      facility.showsuccess = 0		-- time for quota, score showup and cooldown
      facility.fulfill = false		-- denotes if the facility is powered up fully
      facility.score = 100			-- score you get for completing it , should be redone into points per second
      facility.connected = false		-- denotes if the facility receives the energy
      facility.lifetime = 0
      facility.location = vector(math.random(40, screenwidth-40),math.random(100, screenheight-80))
      facility.Size = HomeSize
      table.insert(facilityblock, facility)
    end
  
  --- if time has passed, add event facility, otherwise keep counting, either deadline or cooldown
    if eventcooldown < 0 and deadline <= 0 then
      deadline = globaldeadline
      facility = {}
      facility.location = vector(math.random(40, screenwidth-40),math.random(100, screenheight-80))
      facilitynumber = math.random(2,6)
      facility.type = FacilityTypes[facilitynumber]
      facility.Size = FacilitySizes[facilitynumber]
      facility.Offset = FacilityRelayOffsets[facilitynumber]
      facility.img = FacilityImages[facilitynumber]
     
      facility.energyneed = standardexenergy
      facility.fulfill = false
      facility.showsuccess = 0
      facility.lifetime = 0
      facility.score = 300
      facility.connected = false
      table.insert(facilityblock, facility)
    elseif deadline > 0 then
      deadline = deadline - dt
    else
      eventcooldown = eventcooldown - dt
    end  
  end
    
  --- special buildings drawing
function drawSpecialBuilding(Building)
  if Building.showsuccess > 0 then    --- building is finished and going away
    love.graphics.setColor(255,255,255,255)
		love.graphics.draw(powersign, Building.location.x-Building.Size.x, Building.location.y-Building.Size.y/2,0,0.5,0.5)
		love.graphics.setColor(0,255,0,255)
		love.graphics.draw(battery100,Building.location.x+Building.Size.x-30, Building.location.y-Building.Size.y/2,0,0.3,0.3)
    
    love.graphics.setFont(normalfont)
    love.graphics.setColor(255-230*Building.showsuccess/4,255-230*Building.showsuccess/4,255-230*Building.showsuccess/4,255)
    love.graphics.draw(Building.img, Building.location.x-Building.Size.x/2, Building.location.y-Building.Size.y/2, 0,0.5,0.5)
  else      ---- unfinished or appearing building
    love.graphics.setColor(255,0,0,255)
		love.graphics.rectangle("fill", Building.location.x+Building.Size.x-30, Building.location.y-Building.Size.y/2+33, 15, -25+25*Building.energyneed/standardexenergy)
		love.graphics.setColor(155,155,0,155)
		love.graphics.arc("fill",Building.location.x-Building.Size.x+10,Building.location.y-Building.Size.y/2+10,20, -math.pi/2, -math.pi/2-2*math.pi*deadline/globaldeadline, 15)
    love.graphics.setColor(25,25,25,255)
    if Building.lifetime < 3 then
      love.graphics.setScissor(Building.location.x-Building.Size.x/2, Building.location.y-Building.Size.y/2, Building.Size.x, Building.Size.y)
      love.graphics.draw(Building.img, Building.location.x-Building.Size.x/2+math.random(-1,1), Building.location.y+Building.Size.y/2-(Building.lifetime/3)*Building.Size.y, 0,0.5,0.5)
      love.graphics.setScissor()
    else
			love.graphics.draw(Building.img, Building.location.x-Building.Size.x/2, Building.location.y-Building.Size.y/2, 0,0.5,0.5)
    end
  	love.graphics.draw(battery,Building.location.x+Building.Size.x-30, Building.location.y-Building.Size.y/2,0,0.3,0.3)
  end
  --love.graphics.setPixelEffect()
end

---- common buildings drawing
function drawCommonBuilding(Building)
  if Building.showsuccess > 0 then      --- common building is finished and going away
		love.graphics.setColor(0,255,0,255)
		love.graphics.draw(battery100,Building.location.x+Building.Size.x-30, Building.location.y-Building.Size.y/2,0,0.3,0.3)
    love.graphics.setColor(255,255,0,255)
    
    love.graphics.setFont(normalfont)
    
    love.graphics.setColor(255-230*Building.showsuccess/4,255-230*Building.showsuccess/4,255-230*Building.showsuccess/4,255)
    love.graphics.draw(onbuilding, Building.location.x-Building.Size.x/2, Building.location.y-Building.Size.y/2, 0,0.5,0.5)
    
  else      --- unfinished or appearing common building
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", Building.location.x+Building.Size.x-30, Building.location.y-Building.Size.y/2+33, 15, -25+25*Building.energyneed/standardenergy)
		if Building.lifetime < 3 then
      love.graphics.setScissor(Building.location.x-Building.Size.x/2, Building.location.y-Building.Size.y/2, Building.Size.x, Building.Size.y)
      love.graphics.setColor(0,0,0,255)
      love.graphics.rectangle("fill",Building.location.x-Building.Size.x/4+math.random(-1,1), Building.location.y+Building.Size.y/2+20-(Building.lifetime/3)*Building.Size.y/2, Building.Size.x/2, Building.Size.y/2-5)
      love.graphics.setColor(25,25,25,255)
      love.graphics.draw(onbuilding, Building.location.x-Building.Size.x/2+math.random(-1,1), Building.location.y+Building.Size.y/2-(Building.lifetime/3)*Building.Size.y, 0,0.5,0.5)
      love.graphics.setScissor()
    else
      love.graphics.setColor(0,0,0,255)
      love.graphics.rectangle("fill",Building.location.x-Building.Size.x/4, Building.location.y, Building.Size.x/2, Building.Size.y/2-5)
      love.graphics.setColor(25,25,25,255)
      love.graphics.draw(onbuilding, Building.location.x-Building.Size.x/2, Building.location.y-Building.Size.y/2, 0,0.5,0.5)
    end
    love.graphics.setColor(255,255,255,255)
		love.graphics.draw(battery,Building.location.x+Building.Size.x-30, Building.location.y-Building.Size.y/2,0,0.3,0.3)
  end
end