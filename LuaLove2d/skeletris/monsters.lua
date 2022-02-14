function SpawnEnemy()
  local direct = {"left", "right"}
  local newenemy = {}
  
  newenemy.name = monstertypes[math.random(1,3)] --- revert back later on
  newenemy.direction = direct [math.random(1,2)] 
  newenemy.loc = vector(0,0)
  newenemy.animtimer = 0
  newenemy.currentframe = 1
  
  newenemy.movetimer = 1 --- to adjust the movement behaviour
  
  if newenemy.direction == "left" then
    newenemy.loc.x = cup.width
  else
    newenemy.loc.x = 0
  end
  
  if newenemy.name == "bat" then
    newenemy.color = {255,255,255,255}
    newenemy.animcycle = batanim
    newenemy.speed = 50
    
    local i = 1
    local j = 1
    while newenemy.loc.y == 0 and j < Grid.height+1 do  --- bat should appear only when there are no blocks
      if Blockmassive[i][j].name ~= 0 then
        if j < 3 then
          newenemy.loc.y = 1
        else
          newenemy.loc.y = math.random(1,j-2)*GridCell.height  
        end
      end
      
      if i == Grid.width then
        j = j + 1
        i = 1
      else 
        i = i + 1
      end
    end
    
  elseif newenemy.name == "slime" then
    newenemy.color = {255,255,255,255}
    newenemy.animcycle = slimeanim
    newenemy.mood = "idle"
    newenemy.speed = 20
    newenemy.loc.x = 0
    newenemy.destination = vector(0,0)
    
   
    local placeslist = {}
    
    for i=1, Grid.width do
      if Blockmassive[i][Grid.height].name ~= 0 then
        table.insert(placeslist, i)
      end
    end
    if #placeslist > 0 then
      newenemy.loc.x = placeslist[math.random(1,#placeslist)]*GridCell.width - GridCell.width/2
    else
      newenemy.loc.x = GridCell.width - GridCell.width/2  --- halfassed attempt at evading the problem, repair it
    end
    
    newenemy.loc.y = cup.height-GridCell.height/2
    
  elseif newenemy.name == "ghost" then
    newenemy.animcycle = ghostanim
    newenemy.loc.y = math.random(300,400)
    newenemy.mood = "following"
    newenemy.speed = 60
    newenemy.destination = 0
    newenemy.goal = math.random(1,4)
    
  elseif newenemy.name == "spider" then
    newenemy.loc.y = 0
  end
  
  table.insert(Enemies, newenemy)
end

function pickdirection(monster)   ---- currently only works for slime
  local directionlist = {}
--- what if two slimes eat the same block?
--- did you fix isolation?
--- why does it even pick direction during the goddamn movement
  
  if (monster.loc.x+GridCell.width/2)/GridCell.width+1 <= Grid.width then 
  if Blockmassive[(monster.loc.x+GridCell.width/2)/GridCell.width+1][(monster.loc.y+GridCell.height/2)/GridCell.height].name ~= 0 then
    table.insert(directionlist, vector(1,0))
  end
  end

  if (monster.loc.x+GridCell.width/2)/GridCell.width-1 >= 1 then
  if Blockmassive[(monster.loc.x+GridCell.width/2)/GridCell.width-1][(monster.loc.y+GridCell.height/2)/GridCell.height].name ~= 0 then
    table.insert(directionlist, vector(-1,0))
  end
  end
  
  if (monster.loc.y+GridCell.height/2)/GridCell.height+1 <= Grid.height then
  if Blockmassive[(monster.loc.x+GridCell.width/2)/GridCell.width][(monster.loc.y+GridCell.height/2)/GridCell.height+1].name ~= 0 then
    table.insert(directionlist, vector(0,1))
  end
  end

  if (monster.loc.y+GridCell.height/2)/GridCell.height-1 >= 1 then
  if Blockmassive[(monster.loc.x+GridCell.width/2)/GridCell.width][(monster.loc.y+GridCell.height/2)/GridCell.height-1].name ~= 0 then
    table.insert(directionlist, vector(0,-1))
  end
  end

  if #directionlist == 0 then
    monster.mood = "eating"
    monster.hunger = 1
    monster.direction = vector(0,0)
  else
    monster.animframe = 2
    monster.mood = "moving"
    monster.animcycle = slimeanim
    monster.hunger = math.random(1,3)
    monster.direction = directionlist[math.random(1,#directionlist)]
    monster.destination = monster.loc + GridCell.width*monster.direction
  end
end

function Killslimes(row) 
  for i,v in ipairs(Enemies) do
    if (v.loc.y+GridCell.height/2)/GridCell.height == row then
      MonsterDie(i)
      Killslimes(row)
    end
  end
end

function UpdateEnemy(dt)
  for i,v in ipairs(Enemies) do
    v.movetimer = v.movetimer + dt
    v.animtimer = v.animtimer + dt        --- processing animation
 
    ------------------------------------- BAT ------------------------------------
    --- bats fly to the side, depending on their direction, then they switch
    if v.name == "bat" then
      
      if v.animtimer > 0.3 then
        v.animtimer = 0
        if v.currentframe == #v.animcycle then
          v.currentframe = 1
        else 
          v.currentframe = v.currentframe + 1
        end
      end
      
      if v.direction == "left" then   
        v.loc.x = v.loc.x - dt*v.speed 
      else 
        v.loc.x = v.loc.x + dt*v.speed
      end
      v.loc.y = v.loc.y + dt*100*math.sin(9*v.movetimer)
      
      for a,b in ipairs(Activeblock) do
        if Activeblock.mood == "active" then
          blocklocx = (Activeblock.location[1]+Activeblock.type[Activeblock.state][a][1])*GridCell.width
          blocklocy = (Activeblock.location[2]+Activeblock.type[Activeblock.state][a][2])*GridCell.height
          if blocklocx > v.loc.x and blocklocx-GridCell.width < v.loc.x and
          blocklocy-GridCell.height <= v.loc.y and blocklocy >= v.loc.y then
            Activeblock.mood = "paralyze"
         end
        end
      end
            
      --- bat screams at the block on contact and paralyzes it for a bit
      --- check all active blocks and give it paralyze status if its not paralyzed
      --- die, with falling down visual effect 
      
      if v.loc.x < 0 or v.loc.x > cup.width then 
        table.remove(Enemies, i)
      end
    end
    ---------------------------------- SLIME --------------------------------------
    if v.name == "slime" then     --- slimes climb on blocks and eat random soil, moving randomly      
      if v.animtimer > 0.3 then
        v.animtimer = 0
        if v.currentframe == #v.animcycle then
          v.currentframe = 2
        else
          v.currentframe = v.currentframe + 1
        end
      end
      
      if v.mood == "idle" then    --- if stopped then go certain direction
        pickdirection(v)
      end
      
      if v.mood == "moving" then  --- moves while getting hungry
        
        if math.floor(v.loc.x - v.destination.x) ~= 0 or math.floor(v.loc.y - v.destination.y) ~= 0 then           
          v.loc = v.loc + (v.destination-v.loc):normalized()*dt*v.speed
        else
          v.loc = v.destination
          if v.hunger <= 1 then  --- notice how hunger determines length of the pass, if its above 1
            v.mood = "eating"
            v.animcycle = slimeeatanim
          else
            v.hunger = v.hunger - 1
            v.mood = "idle"
          end
        end
      end
      
      if v.mood == "eating" then  --- sits and eats blocks then ready to move
        local currentblock = Blockmassive[(v.loc.x+GridCell.width/2)/GridCell.width][(v.loc.y+GridCell.height/2)/GridCell.height].name
        
        if v.hunger > 0 then
          if currentblock == 0 then
            MonsterDie(i)
          else
            v.currentframe = 1
            v.hunger = v.hunger-dt
          end
        else ---- reducing the block density.
          for d=1, #blockmaterial do
            if currentblock == blockmaterial[d].name then
              ChangeBlock({(v.loc.x+GridCell.width/2)/GridCell.width, (v.loc.y+GridCell.height/2)/GridCell.height}, d-1)
            end
          end
         
          v.mood = "idle"
          v.currentframe = 2
        end
      end  
    end
    ------------------------------------- GHOST
    if v.name == "ghost" then  ---- follows the block to mutate it, can be distacted by dropping
      if v.animtimer > 0.2 then
        v.animtimer = 0
        if v.currentframe == #v.animcycle then
          v.currentframe = 1
        else
          v.currentframe = v.currentframe + 1
        end
      end
      
      if v.mood == "following" then
        local randomblock = vector(
        Activeblock.location[1] + Activeblock.type[Activeblock.state][v.goal][1], 
        Activeblock.location[2] + Activeblock.type[Activeblock.state][v.goal][2])*GridCell.width 
        - vector(GridCell.width/2, GridCell.height/2)
        
        v.destination = randomblock - v.loc 
      else
        v.destination = GridCell.width*v.goal - v.loc
      end
      
      v.loc = v.loc + dt*v.speed*v.destination:normalized()
      
      if math.abs(v.destination.y) < GridCell.height and math.abs(v.destination.x) < GridCell.width then
        
        if v.mood == "following" then
          MakeSparkVisual(v.loc)
          local PreviousForm = Activeblock.type
          repeat
            Activeblock.type = tetroforms[math.random(1,7)]
          until Activeblock.type ~= PreviousForm
            
          repeat
            local colresult = checkTetroCollision(Activeblock.state)
            if colresult == "left" then
              moveactiveblock(1,0)
            elseif colresult == "right" then
              moveactiveblock(-1,0)
            elseif colresult ~= false then
              fossilize(0)
            end
          until colresult == false or Activeblock == {}
        end
        MonsterDie(i)
      end
    end
    
  end
  
  --- AI depends on the type
    ---acid slime crawls below until gets squashed by bricks, and shoots acid balls upwards
    --- spiders sit below and shoot web that counts as a block
    
  --- check collision with player or blockrows and such
  
end

function MonsterDie(monsternumber)
  --- should put there an effect that depends on how the monster looks
  if Enemies[monsternumber].name == "slime" then
    makeeffect("slimedeath",1,Enemies[monsternumber].loc, slimedeadanim)
  elseif Enemies[monsternumber].name == "ghost" then
    makeeffect("ghostdeath",1,Enemies[monsternumber].loc, ghostdeadanim)
  end
  table.remove(Enemies,monsternumber)
end

function CollideWithEnemy()
  end

function DrawEnemy()
  
  for i,v in ipairs(Enemies) do
    if v.name == "bat" then
      love.graphics.setColor(v.color[1],v.color[2],v.color[3],v.color[4])
      if v.direction == "right" then
        love.graphics.draw(v.animcycle[v.currentframe], v.loc.x-GridCell.width/2, v.loc.y-GridCell.height/2)
      else
        love.graphics.draw(v.animcycle[v.currentframe], v.loc.x+GridCell.width/2, v.loc.y-GridCell.height/2, 0 ,-1,1)
      end

    end
    
    if v.name == "slime" then
      love.graphics.setColor(v.color[1],v.color[2],v.color[3],v.color[4])
      love.graphics.draw(v.animcycle[v.currentframe], v.loc.x-GridCell.width/2, v.loc.y-GridCell.height/2)
    end
  
    if v.name == "ghost" then
      love.graphics.setColor (255,255,255,255)
      if v.direction == "right" then
        love.graphics.draw(v.animcycle[v.currentframe], v.loc.x-GridCell.width/2, v.loc.y-GridCell.height/2)
      else
        love.graphics.draw(v.animcycle[v.currentframe], v.loc.x+GridCell.width/2, v.loc.y-GridCell.height/2, 0 ,-1,1)
      end
    end
    
  end
  --- drawn on top of the stuff, very convenient
end