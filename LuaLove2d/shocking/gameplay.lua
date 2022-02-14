gameplay = gamestate.new()
require "spark_class"
require "facilities_class"
require "relay_class"
require "calamity_class"
require "bonus_class"

------------------Power up all connected relays and relays connected to relays------------------------------------
function CastEnergy(relay)
	for i,v in ipairs(relay.connections) do
		for j,b in ipairs(Relays) do
			if v.ID == b.ID and b.active == false then
				b.active = true
				checkConnectionBuilding(b)
				CastEnergy(b)
			end
		end
	end
end
------------------------Turn on or off relays based on generator amount-----------------------------------------
function checkConnection()
	for i,v in ipairs(facilityblock) do				--- switch off facilities, only connected will be turned on again
		v.connected = false
	end

	for i,v in ipairs(Relays) do					--- switch off relays, only connected will be turned on again
		v.active = false
	end

	for i,v in ipairs(Transformers) do
		if v.active == true then
			for j,b in ipairs(Relays) do
				for h,c in ipairs(b.connections) do
					if c.ID == v.ID then
						b.active = true
						checkConnectionBuilding(b)
						CastEnergy(b)
					end
				end
			end
		end
	end
end
------------------------Sweeps relay for buildings around to power them on-----------------------------------------
function checkConnectionBuilding(relay)
	for i,v in ipairs(facilityblock) do
    for b,c in ipairs (Wires) do
      if c.coordb == relay.location and c.coorda == v.location then
        v.connected = true
      end
    end
  end
  --- since it checks all facilities, might as well do this function once, after every node was checked
end
------------------------tells if this generator is active----------------------------------------------------
function thissubstation(ID)
	for i,v in ipairs (Transformers) do
		if v.ID == ID and v.active == true then
			return true
		end
	end
	return false
end


---------------------Check if player is standing on generator--------------------------------------------
function aroundthegen(genlist)
	for i,v in ipairs (genlist) do
		if math.abs(v.location.x-PlayerLoc.x) < PlayerSizex + SubstationSizex and
			math.abs(v.location.y-PlayerLoc.y) < PlayerSizey + SubstationSizey and
			 v.active == false then
		return i
		end
	end
return 0
end
--------------------Check how many generators are working------------------------------------------------
function activegenscount(genlist)
	count = 0
	for i,v in ipairs (genlist) do
		if v.active == true then count = count + 1 end
	end
return count
end
---------------------Puts message in queue for display---------------------------------------------------
function addmessage(length, text, color)
	message = {}
	message.text = text
	message.length = string.len(text)
  message.location = screenwidth
  message.color = color
	table.insert(Messages, message)
end
---------------------Updates messages to put them out and remove ----------------------------------------
function messagecycle(dt)
	for i,v in ipairs(Messages) do
    v.location = v.location - 200*dt
    if v.location+v.length*10 < 0 then
      table.remove(Messages, i)
    end
    
    if v.location > 100 then
      return
    end
	end
end
-----------------------Creates a particle effect of sparks-------------------------------------------------------
function MakeSparkVisual(location, offsetx, offsety)
  toolrebound = love.graphics.newParticleSystem(particle_spark, 5)
  toolrebound:setEmissionRate          (40)
  toolrebound:setLifetime              (0.5)
  toolrebound:setParticleLife          (0.5)
  toolrebound:setSpread                (-4,4)
  toolrebound:setSpeed                 (100)
  toolrebound:setDirection             (0)
  toolrebound:setSizes                 (0.5,1,2)
  toolrebound:setSpin                  (1,15,1)
  toolrebound:setPosition(location.x+offsetx,location.y+offsety)
  toolrebound:setColors(255,255,155,255,255,255,155,0)
  toolrebound:start()
  table.insert(Effects, toolrebound)
end
----------------------------------------------------------------------------------------------------------
function TransformersUpdate(dt)
	for i,v in ipairs(Transformers) do			---- generators calculation, sparking and scoring
		v.discharge = v.discharge - dt
    if v.active == true then
			v.energy = v.energy - dt
      v.scorerefresh = v.scorerefresh + dt
      
      if v.scorerefresh > 0.1 then            ---- score ticks
        Score = Score + (difficulty+1)*0.5*1
        v.scorerefresh = 0
      end

			if v.energy < 0 then				---- rechecking poles on discharge
				v.active = false
				checkConnection()

			else
				if v.discharge < 0 then
					makesparks(2+extrasparks, v.location, "swaying", 0, sparkimg, 0)
          MakeSparkVisual(v.location,math.random(-25,25), math.random(-15,15))
					v.discharge = 1
				end
			end
		elseif v.discharge < 0 then
      makesparks(0+extrasparks, v.location, "direct", 0.5, cogproj, math.random(0,360))
      makesparks(0+extrasparks, v.location, "direct", 0.5, cogproj, math.random(0,360))
      v.discharge = 0.5
    end
	end
end

------------------------------------------------------------------------------------------------------
function isBuildingThere(typebuilding)
  for i,v in ipairs(facilityblock) do
    if v.type == typebuilding then 
      return true
    end
  end
  return false
end
---------------------------------------------------------------------------------------------------------
function HurtPlayer(health)
  if showshock <= 0 then 
    fusecapacity = fusecapacity - health
    showshock = 1
  end
  
	if fusecapacity < 0 then
		Fuse = Fuse - 1
		showshock = 5
		addmessage(message_def_time, "one fuse went down!", {200,0,0})
		fusecapacity = defaultfusecapacity
	end
end
--------------------------------------------------------------------------------------------------------
function gameplay:init()
	extrasparks = 0					      -- amount of extra sparks added to generation
	sparkcolor = {255,100,0,255}	-- color of normal sparks
  coverage = 200					      -- default relay coverage
end

---------------------------------------------------------------------------------------------------------
function gameplay:enter()
 
  leldown = 0
	Transformers = {}				-- table for substations
	Sparks = {}						  -- table for active sparks
  RunningSparks = {}      -- table for wired sparks
	Relays = {}						  -- table for relay towers
	Wires = {}						  -- table for wiring
	Messages = {}					  -- table for announcements
  Instruments = {}				-- table for player instruments flying around
  Effects = {}            -- particle effect table
  facilityblock = {}      -- table for buildings
  Calamities = {}         -- table for danmaku 
  Bonus = {}              -- table for bonuses
  
	toolspeed = 300					-- speed of a flying instrument
	toolcd = 0.3						-- shooting speed
	shotmemory = vector(0,0)

	buildcooldown = 1				  -- time to make a building
	chargingtime = 0.5				-- time between sparking
	message_def_time = 4			-- default time between messages
	globaldeadline = 50				-- deafult time for decaying of the facility

	guitensionbar = 380				-- default capacity of city energy
	defaultfusecapacity = 50	-- default fuse strength

	relayID = 0						  -- current counter for relays
	substationID = 999999		-- current counter for substations
  wireIDcounter = 0
	overalltime = 0					-- game flow time
	fusecapacity = 10				-- current player hp
	standardenergy	= 3+difficulty*1.3			-- current facility quota
	standardexenergy = 3+difficulty*1.5		-- current extra facility quota
	maxgens = 1						  -- maximum amount of substations
	genleft = maxgens				-- amount of starting substations
	gencap = 15						  -- time one substation lasts
	relaycap = 30					  -- time one relay lasts
	relaycount = 0 					-- current amount of relays installed

	PlayerLoc = vector (500, 500)	-- player location
	acceleration = vector (0,0)		-- acceleraton direction
	PlayerFuture = PlayerLoc  		-- useful for collision
  player_currentframe = 1       -- current player frame
  player_framechange = 0        -- frametimer

	buildcharge = 0					-- current building progress status
	tension = -20					  -- starting tension
  
	eventcooldown = 10 			-- time until next extra facility
	deadline = 0					  -- time current facility lasts

	showshock = 0 					-- damage display timer
  stagewarp = 6            -- countdown until end of the stage is preset 
  stagerequirement = math.floor(3+difficulty*1.3)   -- a quota for the stage
  buildings_done = 0      -- amount of buildings energized, should met the quota
  
  addmessage(message_def_time,"stage "..gamestage..": power up "..stagerequirement.." buildings", {0,0,200})
  overalltime = 0
  
  canvasbuilds = {} --- stack for buildings drawn on canvas
  
  currentcity = MakeCity(5*difficulty)
  BakeCity(currentcity)
  --cityrotation = math.random(1,600)*0.01
end

---------------------------------------------------------------------------------------------------------
function gameplay:update(dt)

if paused == false then
	overalltime = overalltime + dt
	buildcooldown = buildcooldown - dt								-- build cooldown
	if fusecapacity < defaultfusecapacity then fusecapacity = fusecapacity + dt end	-- player hp restores
	if tension < maxgens * 50 then tension = tension + dt end		-- tension increase but only when possible
	
  if tension > activegenscount(Transformers)*50 then 			-- extra sparks happen with increased tension
		extrasparks = 1
		sparkspeed = 2
		exshift = 2
	else
		extrasparks = 0
		sparkspeed = 1.2
		exshift = 1
	end
	if showshock > 0 then showshock = showshock - dt end    --- damage display decay
	animchange = animchange + dt                            --- animation changing timer
  
  --- updating the messages
	messagecycle(dt)
  
  ---- if the bonus effect is ended, recreate, or make bonus working.
  BuildSpawnHandler(dt)
  updateFacilities(dt)

---- player movement if not building, also frame change
	if buildcharge == 0 then
		if love.keyboard.isDown("left") then
			xacceleration = xacceleration - 1
		end
		if love.keyboard.isDown("right") then
			xacceleration = xacceleration + 1
		end
		if love.keyboard.isDown("up") then
			yacceleration = yacceleration - 1
		end
		if love.keyboard.isDown("down") then
			yacceleration = yacceleration + 1
		end

		if xacceleration ~= 0 or yacceleration ~= 0 then
      player_framechange = player_framechange + dt
      if player_framechange > 0.1 then
        player_framechange = 0
        if player_currentframe == 6 then
           player_currentframe = 1
        else 
           player_currentframe = player_currentframe + 1
        end
      end
			shotmemory = vector(xacceleration,yacceleration)
		end

--- shooting stuff in player direction
		if love.keyboard.isDown(" ") and buildcooldown < 0 and shotmemory ~= vector(0,0) then
			newtool = {}
			newtool.type = ToolTypes[math.random(1,2)]
			newtool.location = PlayerLoc
			newtool.direction = vector(shotmemory.x,shotmemory.y)
			newtool.rotation = 0
			newtool.todelete = false
			table.insert(Instruments,newtool)
			buildcooldown = toolcd
		end

-- player movement
		PlayerLoc = PlayerLoc + vector(xacceleration,yacceleration)*speedplayer*dt  --- moving around
		xacceleration = 0
		yacceleration = 0
	end

--- move instruments, remove out of bounds ones, make effect of the ricochet
	for i,v in ipairs(Instruments) do
		v.location = v.location + v.direction*dt*toolspeed
		v.rotation = v.rotation + 10*dt

		if v.location.x > screenwidth or v.location.x < 0 or
			v.location.y < 0 or v.location.y > screenheight then
				v.todelete = true
		end

		for j,b in ipairs(Transformers) do
			if v.location.x < b.location.x + SubstationSizex and v.location.x > b.location.x - SubstationSizex and
				v.location.y < b.location.y + SubstationSizey and v.location.y > b.location.y - SubstationSizey then
        
          toolrebound = love.graphics.newParticleSystem(v.type, 1)
          toolrebound:setEmissionRate          (10)
          toolrebound:setLifetime              (1)
          toolrebound:setParticleLife          (1)
          toolrebound:setSpread                (0.2)
          toolrebound:setSpeed                 (100, 200)
          toolrebound:setGravity               (200)
          toolrebound:setRadialAcceleration    (1)
          toolrebound:setSizes                 (1)
          toolrebound:setRotation              (1)
          toolrebound:setSpin                  (10,15,1)
          toolrebound:setPosition(v.location.x,v.location.y)
          toolrebound:setDirection(math.random(-10,10)*0.1)
          toolrebound:setColors(100,100,100,255,100,100,100,0)
          toolrebound : start()
          table.insert(Effects, toolrebound)
          b.energy = b.energy + 10
					if b.energy > gencap then
							b.energy = gencap
					end
					if b.active == false then
						b.active = true
						checkConnection()
					end
          v.todelete = true
			end
		end

		if v.todelete == true then
			table.remove(Instruments, i)
		end
	end
  
 ---- updating and restarting systems that arent active
  for i,v in ipairs(Effects) do
   if v:isActive() == false then
     table.remove(Effects, i)
   end
   v:update(dt)
  end

--- creating the substation or recharging existing one
	if (love.keyboard.isDown("z") or love.keyboard.isDown("x")) and buildcooldown < 0 then
		if love.keyboard.isDown ("z") and genleft > 0 then
			buildcharge = buildcharge + dt

			if buildcharge > chargingtime then

				substation = {}
				substation.ID = substationID + 1
				substationID = substationID + 1
				substation.energy = gencap
				substation.discharge = 2-(difficulty-1)*0.2
				substation.location = PlayerLoc
				substation.active = true
        substation.scorerefresh = 0

				table.insert(Transformers, substation)
				genleft = genleft - 1

				buildcooldown = 2
				checkConnection()
			end

---- adding relay and connecting to another energy source
		elseif love.keyboard.isDown ("x") then
			buildcharge = buildcharge + dt

			if buildcharge > chargingtime then
				create_relay_dependency()
			end
		end

	else buildcharge = 0
  end

	if PlayerLoc.y < 1+PlayerSizey then			---- Player stays inbound
	  PlayerLoc.y = 1+PlayerSizey
	end

	if PlayerLoc.y > screenheight-PlayerSizey then
	PlayerLoc.y = screenheight-PlayerSizey
	end

	if PlayerLoc.x < 1+PlayerSizex then
	PlayerLoc.x = 1+PlayerSizex
	end

	if PlayerLoc.x > screenwidth-PlayerSizex then
	PlayerLoc.x = screenwidth-PlayerSizex
	end

	TransformersUpdate(dt)
	RelaysUpdate(dt)
  UpdateDisaster(dt)
	SparksUpdate(dt)
  RunningSparksUpdate(dt)
  updateBonus (dt)

	if Fuse < 0 then						-- gameover conditions
		gamestate.switch(gameover)
	end
  
  --- moving on the new stage
  if buildings_done >= stagerequirement then
    if gamestage > 7 then
      stagerequirement = stagerequirement + 10
    else 
      if stagewarp > 5 then
        Messages = {}
        addmessage(message_def_time,"Well Done! next stage soon!",{200,255,200})  -- only once
        stagewarp = 5
      end
      stagewarp = stagewarp - dt
    
      --- setting up new stage parameters
      -- should make probabilities for new buildings, to make special stage conditions
      -- should replace custom skin for valhalla and cemetery
      if stagewarp < 0 then
        gamestage = gamestage + 1
        difficulty = difficulty + 1
        BuildBack = love.graphics.newCanvas(1024,1024)
        gamestate.switch(transition, gamestage)
      end
    end
  end

end
end
---------------------------------------------------------------------------------------------------------
function gameplay:draw()
  love.graphics.setCanvas(Display1024)
  love.graphics.setColor(255,255,255,255)
  if overalltime < 2 then
    love.graphics.clear()
    love.graphics.setStencil(StartStencil)
  end
  if stagewarp < 2 then
    love.graphics.clear()
    love.graphics.setStencil(EndStencil)
  end
  
  -- drawing out background
  
  
  love.graphics.draw(citycanvas,0,0)
  love.graphics.setFont(normalfont)

  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(BuildBack,0,0)
  for i,v in ipairs(facilityblock) do
    if v.type == "standard" then
      drawCommonBuilding(v)
    else
      drawSpecialBuilding(v)
    end
  end

	draw_substations()
  draw_playerstatus()
	draw_relays()
	draw_wires()
	draw_sparks()
  draw_runningsparks()
	draw_tools()
  draw_disaster()
  draw_bonus()
 
  love.graphics.setColor(255,255,255,255)
  for i,v in ipairs(Effects) do
    love.graphics.draw(v,0,0)
  end
  
  love.graphics.draw(mapmode[mapmode_curr].bord,0,0)
	draw_announce()
  
	love.graphics.setColor(0,0,0,255)  --- gui
	love.graphics.print("SCORE: " .. tostring(math.floor(Score)), screenwidth-140, 30)
	love.graphics.print("SUBSTATIONS: ", 80, 100)
	love.graphics.print("fps: "..tostring(love.timer.getFPS()),screenwidth-140,60)
  --love.graphics.print("particle systems: "..tostring(#Effects), screenwidth-240,90)
  love.graphics.print("stage "..tostring(gamestage), screenwidth-200, 90)
  if stagerequirement-buildings_done < 0 then
      love.graphics.print("0 left", screenwidth-100,90)
  else
      love.graphics.print(tostring(stagerequirement-buildings_done).." left", screenwidth-100,90)
  end

	--- fuse capacity bar that gets redder with more hits
	if showshock < 1 then
		love.graphics.setColor(255,255*fusecapacity/defaultfusecapacity,255*fusecapacity/defaultfusecapacity,255)
		love.graphics.draw(fusetubestringimg,100,40)
		love.graphics.draw(fusetubeimg,30,30)
	else
		love.graphics.setColor(255,255,255,255)
	off_a =	math.random(-10,10)
	off_b = math.random(-10,10)
		love.graphics.draw(fusetubeblownimg,100,40,0,1,1,off_a, off_b)
		love.graphics.draw(fusetubeimg,30,30,0,1,1,off_a, off_b)
	end

	love.graphics.setColor(255,255,255,255)
  if Fuse < 5 then
    j = Fuse
  else
    j = 4
  end
	for i = 1,j do		--number of fuses left
		love.graphics.draw(fuseimg,330+(i-1)*30,30)
	end

	if genleft == 0 then
		love.graphics.setColor(255,100,100,255)
		love.graphics.print ("NONE", 220,100)
	else
		for i=1,genleft do 	-- number of gens left
			love.graphics.draw(onsubstationimg, 200+(i-1)*25,100, 0, 0.2,0.2)
		end
	end

	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle("fill", 478, 35, guitensionbar, 25)  --- tension bar
	love.graphics.setColor(100,0,255,155)
	love.graphics.rectangle("fill", 478, 36,guitensionbar/maxgens*activegens ,23) -- active gens coverage
	love.graphics.setColor(0,0,0,255)
	love.graphics.setColor(255,0,0,255)
	if tension > 0 then  -- actual tension if not negative
		love.graphics.rectangle("fill", 478, 37,guitensionbar/maxgens/50*tension,21)
	end

	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(powermeterimg, 450, 30,0,0.7,0.7)
	for i= 1,maxgens do		-- gui linemarking
		love.graphics.setColor(255,255,255,255)
		--love.graphics.line(guitensionbar/maxgens*(i-1)+10,screenheight-80,guitensionbar/maxgens*(i-1)+10,screenheight-60)
		love.graphics.line(guitensionbar/maxgens*(i-1)+480,35,guitensionbar/maxgens*(i-1)+480,60)
	end
  if tension > activegenscount(Transformers)*50 then
    love.graphics.setFont(uifont)
    love.graphics.setColor(255,0,0,math.cos(3*overalltime))
    love.graphics.print("OVERLOAD", 450,60)
  end  
  
  love.graphics.setFont(menufont)
  love.graphics.setColor(100,0,0,255)
  if paused == true then
    love.graphics.printf("PAUSED", 0, 420, screenwidth, "center")
  end 
  love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.clear()
  love.graphics.draw(Display1024, 0,0,0,Display_scale, Display_scale)
end
------------------------------------------------------END OF DRAW UPD---------------------------------------------------
function draw_playerstatus() 				--- player and his effects

	if showshock > 0 then						--- pain effects predefine
		off_a =	math.random(-3,3)
		off_b = math.random(-3,3)
		playerstatus = 50
		love.graphics.setColor(200,255,200,255)
    currentanim = shockedplayerbatch
	else
    currentanim = playerbatch
		playerstatus = 255
		off_a = 0
		off_b = 0
	end
  if buildcooldown > 0 then opacityplayer = 200 else opacityplayer = 255 end
	love.graphics.setColor(255,playerstatus,playerstatus, opacityplayer)		--- player
  love.graphics.drawq(currentanim, playeranim[player_currentframe], PlayerLoc.x, PlayerLoc.y,0,1,1,PlayerSizex/2+off_a, PlayerSizey/2+off_b)
	if showshock > 0 then
    love.graphics.setColor(255,255,0,2.55*math.random(1,100))
    love.graphics.draw(calamimg,PlayerLoc.x, PlayerLoc.y, overalltime, 0.4,0.4, 30,30)
		if animchange > 0.1 then
			animchange = 0
			shockframe = math.random(1,3)
		end
	end

	if buildcharge ~= 0 then		--charge fill
		love.graphics.setColor(0,50,0,255)
    love.graphics.draw(twizzler, PlayerLoc.x-10, PlayerLoc.y,3*buildcharge,1,1,7,28)
		love.graphics.draw(screwdriver, PlayerLoc.x+10, PlayerLoc.y,-3*buildcharge,1,1,7,28)

		if love.keyboard.isDown("x") then
      love.graphics.setLine(2,"smooth")
			love.graphics.setColor(0,100,255,255)
			love.graphics.circle ("line", PlayerLoc.x, PlayerLoc.y, coverage)
      love.graphics.setLine(1,"smooth")
		end
	end
end

-- draw tools
function draw_tools()
	for i,v in ipairs(Instruments) do
		love.graphics.setColor(0,0,0,255)
		love.graphics.draw(v.type, v.location.x+2,v.location.y+2,v.rotation,1,1,toolsize.x/2,toolsize.y/2)
		love.graphics.setColor(255,255,255,255)
		love.graphics.draw(v.type, v.location.x,v.location.y,v.rotation,1,1,toolsize.x/2,toolsize.y/2)
	end
end

--draw text messages
function draw_announce()
  if #Messages > 0 then
    love.graphics.setColor(155,155,155,55)
    love.graphics.rectangle("fill",0,screenheight-65, screenwidth,40)
    for i,v in ipairs(Messages) do  	--- messages popping up
      love.graphics.setColor(v.color[1],v.color[2],v.color[3],255)
      love.graphics.print(v.text, v.location, screenheight-60)
    end
  end
end

--- generators display
function draw_substations()
		activegens = 0
	for i,v in ipairs(Transformers) do
		if v.active == false then
			love.graphics.setColor(50,50,50,255)
			love.graphics.draw(onsubstationimg, v.location.x-SubstationSizex/2-10, v.location.y-SubstationSizey/2-15,0,0.5,0.5)
			love.graphics.setColor(255,255,255,255)
			love.graphics.draw(nopowersign, v.location.x-SubstationSizex/2+30, v.location.y-SubstationSizey/2-15,0,0.5,0.5)
		else
			love.graphics.setColor(255,255,0,255)
			love.graphics.rectangle("fill",v.location.x+40, v.location.y-20, SubstationSizex/3, SubstationSizey)
			activegens = activegens + 1
			love.graphics.setColor(205*v.energy/gencap+50,205*v.energy/gencap+50,205*v.energy/gencap+50,255)
			love.graphics.draw(onsubstationimg, v.location.x-SubstationSizex/2-10, v.location.y-SubstationSizey/2-15,0,0.5,0.5)
			if v.energy < gencap/5 then				--- warning about low gen capacity
				love.graphics.setColor(255,0,0,255*math.abs(math.sin(overalltime)))
				love.graphics.draw(exclam1, v.location.x-10, v.location.y-SubstationSizey-30,0,0.3,0.3)
			end
		end

		--love.graphics.setColor(0,0,0,255)
		--love.graphics.rectangle("line", v.location.x - SubstationSizex/2, v.location.y-SubstationSizey/2, SubstationSizex, SubstationSizey)
		--love.graphics.print(tostring(v.ID),v.location.x,v.location.y-10)
		--love.graphics.print(tostring(math.floor(v.energy)), v.location.x-15,v.location.y+25)
	end
end

function bezierpoint(t, p0, p1, p2, p3)
  u = 1 - t
  tt = t*t
  uu = u*u
  uuu = uu*u
  ttt = tt*t
  
  local p = uuu*p0
  p = p + 3*uu*t*p1
  p = p + 3*u*tt*p2
  p = p + ttt*p3
  return p 
end

function makeWireList(wiretarget1, wiretarget2)   --coorda and coordb
  distance = (wiretarget2-wiretarget1):len()
  if wiretarget1.x > wiretarget2.x then
    angle1 = -math.pi/8*(wiretarget1.x-wiretarget2.x)/100
    angle2 = math.pi/8*(wiretarget1.x-wiretarget2.x)/100
  else
    angle1 = math.pi/8*(wiretarget2.x-wiretarget1.x)/100
    angle2 = -math.pi/8*(wiretarget2.x-wiretarget1.x)/100
  end

  medium = wiretarget1+((wiretarget2-wiretarget1):normalized()*distance/4)+vector(0,15)--:rotated(angle1)
  medium2 = wiretarget2+((wiretarget1-wiretarget2):normalized()*distance/4)+vector(0,15)--:rotated(angle2)

  drawpoints = {}
  begin_p = bezierpoint(0, wiretarget1, medium, medium2, wiretarget2)
  table.insert(drawpoints, begin_p)            
  for i=1,10 do
    t = i/10
    bezier_p = bezierpoint(t, wiretarget1, medium, medium2, wiretarget2)
    table.insert(drawpoints, bezier_p)
  end
  return drawpoints
end

 --- wires drawing
function draw_wires()
	for i,v in ipairs(Wires) do
		love.graphics.setColor(50,50,50,255)
		for i=1, 10 do
      love.graphics.line(v.drawpoints[i].x, v.drawpoints[i].y, v.drawpoints[i+1].x, v.drawpoints[i+1].y)
      love.graphics.line(v.drawpoints2[i].x, v.drawpoints2[i].y, v.drawpoints2[i+1].x, v.drawpoints2[i+1].y)
    end
	end
end
