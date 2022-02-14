--- spark generation related on type
function makesparks(number, center, sparktype, extraspeed, img, shift)
	if sparktype == "swaying" then
    for i = 1, number do
      spark = {}
      spark.location = center
      spark.type = sparktype
      spark.img = img
      spark.speed = sparkspeed+extraspeed
      spark.size = 1
      spark.arrow = vector(math.random(-100,100), math.random(-100,100)) --directional vector
      spark.direction = math.random(-600,600) --rotational vector
      spark.freq = math.random(1,5)
      table.insert(Sparks, spark)
    end
  elseif sparktype == "direct" then
    
    for i = 1, number do
      spark = {}
      spark.location = center
      spark.type = sparktype
      spark.img = img
      spark.speed = sparkspeed+extraspeed
      spark.size = 1
      spark.arrow = vector(0,1)      --directional vector
      spark.direction = shift+2*math.pi/number*i      --rotational vector
      table.insert(Sparks, spark)
    end
  elseif sparktype == "big" then
    
    for i = 1, number do
      spark = {}
      spark.location = center
      spark.type = sparktype
      spark.img = img
      spark.speed = (sparkspeed+extraspeed)/2
      spark.size = 5
      spark.arrow = vector(0,1)
      spark.direction = shift+math.random(0,359)/180*math.pi
      table.insert(Sparks, spark)
    end
    
  elseif sparktype == "homing" then
    for i = 1, number do 
      spark = {}
      spark.location = center
      spark.type = sparktype
      spark.img = img
      spark.speed = sparkspeed+extraspeed
      spark.size = 1
      spark.arrow = (PlayerLoc - spark.location):rotated(math.random(-45,45)/180*math.pi)      --directional vector
      spark.direction = shift+2*math.pi/number*i --rotational vector
      table.insert(Sparks, spark)
    end
    
  elseif sparktype == "spiraling" then
    for i = 1, number do
      spark = {}
      spark.location = center 
      spark.type = sparktype
      spark.img = img
      spark.speed = sparkspeed+extraspeed
      spark.size = 1
      spark.arrow = vector(1,1)      --directional vector
      spark.direction = shift*2*math.pi/number*i      --rotational vector, will be directed CW or CCW depending on shift
      table.insert(Sparks, spark)
    end
    
  elseif sparktype == "puff" then
    for i = 1, number do
      spark = {}
      spark.location = center
      spark.type = sparktype
      spark.img = img
      spark.speed = sparkspeed+extraspeed+math.random(0, 150)*0.01 
      spark.size = 2
      spark.arrow = vector(math.random(-10,10)*0.1, math.random(-10,10)*0.1)
      spark.direction = 0
      table.insert(Sparks, spark)
    end
  end
end

--- spark generation running on wires
function makerunningsparks(movementpath, ID, reversal)
  spark = {}
  spark.path = movementpath
  if reversal == true then
    spark.reversal = true
    spark.currentnode = 10
    spark.location = movementpath[10]
  else
    spark.reversal = false
    spark.currentnode = 1
    spark.location = movementpath[1]
  end
  spark.img = sparkimg
  spark.type = "swaying"
  spark.size = 1
  spark.speed = 100---sparkspeed+difficulty*10
  spark.ID = ID
  table.insert(RunningSparks, spark)
end

--- sparks on a wire
function RunningSparksUpdate(dt)
  for i,v in ipairs (RunningSparks) do
    if v.reversal == false then
      if v.currentnode == 10 then
        table.remove (RunningSparks, i)
      else
        v.location = v.location - (v.path[v.currentnode] - v.path[v.currentnode+1]):normalized()*v.speed*dt
        if v.location.x < v.path[v.currentnode+1].x+3 and v.location.x > v.path[v.currentnode+1].x-3 and
          v.location.y < v.path[v.currentnode+1].y+3 and v.location.y > v.path[v.currentnode+1].y-3 then
            v.currentnode = v.currentnode+1
        end
      end
    else
      if v.currentnode == 1 then
        table.remove (RunningSparks, i)
      else
        v.location = v.location - (v.path[v.currentnode] - v.path[v.currentnode-1]):normalized()*v.speed*dt
        if v.location.x < v.path[v.currentnode-1].x+3 and v.location.x > v.path[v.currentnode-1].x-3 and
          v.location.y < v.path[v.currentnode-1].y+3 and v.location.y > v.path[v.currentnode-1].y-3 then
            v.currentnode = v.currentnode-1
        end
      end
    end
 
    if math.abs(v.location.x - PlayerLoc.x) < v.size+PlayerSizex/2 and math.abs(v.location.y - PlayerLoc.y) < v.size+PlayerSizey/2 and showshock <= 0 then
      fusecapacity = fusecapacity - 10
      if fusecapacity < 0 then
        Fuse = Fuse - 1
        showshock = 10
        addmessage(message_def_time, "one fuse went down!", {255,0,0})
        fusecapacity = defaultfusecapacity
      else
        showshock = 1
      end
    
      table.remove (RunningSparks, i)
    end
  end
end

---- flight and collision of normal sparks
function SparksUpdate(dt)
	for i,v in ipairs (Sparks) do			
    if v.type == "swaying" then
      v.location = v.location+vector(v.speed*standardspeed*dt,math.sin(v.freq*overalltime/5)*sparkspeed*standardspeed*dt):rotated(v.direction/100)
    elseif v.type == "direct" or v.type == "big" then
      v.location = v.location+v.speed*standardspeed*dt*v.arrow:normalized():rotated(v.direction)
    elseif v.type == "homing" then
      newdirection = PlayerLoc - v.location
      if crossproduct({newdirection.x, newdirection.y, 0}, {v.arrow.x, v.arrow.y, 0}) > 0 then
        v.arrow = v.arrow:rotated(-0.001)
      else
        v.arrow = v.arrow:rotated(0.001)
      end
      v.direction = math.atan2(v.arrow.y, v.arrow.x)
      v.speed = v.speed + 0.009
      v.location = v.location+v.speed*standardspeed*dt*v.arrow:normalized()
    elseif v.type == "spiraling" then
      if v.direction < 0 then
        v.direction = v.direction-dt
      else
        v.direction = v.direction+dt
      end
      v.arrow = v.arrow+vector(1,1):normalized()*dt*v.speed*standardspeed/30
      v.location = v.location+v.arrow:rotated(2*v.direction)*dt*v.speed*standardspeed
    elseif v.type == "puff" then
      v.direction = overalltime
      if v.speed <= 0 then
        v.speed = 0
        if math.abs((v.location - PlayerLoc):len()) < 300  then
          MakeSparkVisual(v.location, 0, 0)
          makesparks(1, v.location, "homing", 1, scorespark, 0)
          table.remove(Sparks, i)
        end
      else
        v.location = v.location+(v.speed)*standardspeed*dt*v.arrow:normalized()
        v.speed = v.speed - dt
      end
    end
  ---------------
	if math.abs(v.location.x - PlayerLoc.x) < v.size+PlayerSizex/2 and math.abs(v.location.y - PlayerLoc.y) < v.size+PlayerSizey/2 then
      HurtPlayer(10)
			table.remove (Sparks, i)
		elseif v.location.x < -200 or v.location.x > screenwidth+200 
        or v.location.y < -200 or v.location.y > screenheight+200 then
			table.remove (Sparks, i)
		end
	end
end

-- Sparks drawing
function draw_sparks()
	for i,v in ipairs(Sparks) do 		--- sparks
    if v.type == "big" or v.type == "puff" then
      scalespark = 2
    else 
      scalespark = 1
    end
		love.graphics.setColor(0,0,0,200)
    if v.type == "direct" then
      love.graphics.drawq(sparkbatch, v.img[exshift], v.location.x+2, v.location.y+2, v.direction,scalespark,scalespark,5,5)
      love.graphics.setColor(255,255,255,255)
      love.graphics.drawq(sparkbatch, v.img[exshift], v.location.x, v.location.y,v.direction,scalespark,scalespark,5,5)
    else
      love.graphics.drawq(sparkbatch, v.img[exshift], v.location.x+2, v.location.y+2, v.direction-math.pi/2,scalespark,scalespark,5,5)
      love.graphics.setColor(255,255,255,255)
      love.graphics.drawq(sparkbatch, v.img[exshift], v.location.x, v.location.y,v.direction-math.pi/2,scalespark,scalespark,5,5)
    end
  end
end

function draw_runningsparks()
 	for i,v in ipairs(RunningSparks) do 		--- sparks
		love.graphics.setColor(0,0,0,255)
    love.graphics.drawq(sparkbatch, v.img[exshift], v.location.x+2, v.location.y+2, 0,v.size,v.size,5,5)
		love.graphics.setColor(100,0,155,255)
    love.graphics.drawq(sparkbatch, v.img[exshift], v.location.x, v.location.y,0,v.size,v.size,5,5)
    love.graphics.setColor(0,0,0,255)
  end
end

function crossproduct (first, second)
  product = {}
  product[1] = (first[2] * second[3] - first[3] * second[2])
  product[2] = -( first[1] * second[3] - first[3] * second[1])
  product[3] = (first[1] * second[2] - first[2] * second[1])
  return product[3]
end