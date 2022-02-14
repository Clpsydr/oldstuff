
--- generating some of possible blocks
function makeactiveblock()
  Nextblock = {}
  Nextblock.type = tetroforms[math.random(1,7)] --- all locations of certain block type
  Nextblock.state = 1 --- initial rotational position
  Nextblock.mood = "appearing"   --- for monster interaction, starts as such for falling animation
  Nextblock.duration = 2 --- for status length
  Nextblock.location = {Blockstart[1],Blockstart[2]} --- universal location for entire tetromino
  
  
  for i=1,4 do   --- making a set of tetroblocks
    block = {}
    local newmaterial = math.random(1,#blockmaterial)
    block.material = blockmaterial[newmaterial].name
    block.sprite = blockmaterial[newmaterial][math.random(1,#blockmaterial[newmaterial])]
    table.insert(Nextblock, block)
  end
end

---- makes inactive blocks out of active and checks for completed rows
function fossilize(collisionblocks)
  for i,v in ipairs(Activeblock) do
    Blockmassive[GetXblock(i)][GetYblock(i)].sprite = v.sprite
    Blockmassive[GetXblock(i)][GetYblock(i)].name = v.material
    
    if GetYblock(i) < 3 then causegameover() end ---- extra gameover condition, which usually the one that works
  end
  
  if collisionblocks ~= 0 then
    for i,v in ipairs(collisionblocks) do
      MakeFogVisual(vector(v[1]*GridCell.width, v[2]*GridCell.height), 155,155,155, Fogs2)
    end
  end
  
  for i,v in ipairs(Enemies) do  --- redirects ghosts to the fossilized block
    if v.name == "ghost" and v.mood == "following" then
      v.animcycle = ghostdistanim
      v.mood = "distracted"
      v.goal = vector(Activeblock.location[1]+Activeblock.type[Activeblock.state][v.goal][1], 
                             Activeblock.location[2]+Activeblock.type[Activeblock.state][v.goal][2])
    end
  end
  
  Activeblock = {}
  RenewTetrominos()
  keycooldown = 0.5
  
  checkforclear(true)
end


function moveactiveblock(x,y)  --- if movement is legal, then move, and fossilize if needed
  dothemovement = true 
  
  if x ~= 0 then        --- shouldn't go out of the cup
    for i,v in ipairs(Activeblock) do 
      if GetXblock(i) + x < 1 or GetXblock(i) + x > Grid.width or 
          Blockmassive[GetXblock(i)+x][GetYblock(i)].name ~= 0 then
        dothemovement = false
      end
    end
  end
    --- also add collision with blocks on left or right
  
  if y ~= 0 then   ---- drop the figure if its connected with the row, instead of moving
    local collisions = {}
    for i,v in ipairs(Activeblock) do
      if GetYblock(i) + y > Grid.height or Blockmassive[GetXblock(i)][GetYblock(i)+y].name ~= 0 then
        dothemovement = false
        table.insert(collisions, {GetXblock(i), GetYblock(i)})
      end
    end
    
    if #collisions > 0 then ---- collides with collided blocks remembered (for effects)
      fossilize(collisions)
    end
  end
  
  if dothemovement == true then
    Activeblock.location[1] = Activeblock.location[1] + x
    Activeblock.location[2] = Activeblock.location[2] + y
  end
end

function rotateactiveblock(direction) --- uses next position of the blocks to rotate
  if Activeblock.state + 1 > 4 then
    if checkTetroCollision("next") == false then
      Activeblock.state = 1
    end
  else
    if checkTetroCollision("next") == false then
      Activeblock.state = Activeblock.state + 1
    end
  end
 
end

function checkTetroCollision(position) --- checks tetro collision with block massive and walls, only used in rotation
  for a,b in ipairs (Activeblock) do
      if GetXblockNextstate(a) < 1 then
        return "left"
      elseif GetXblockNextstate(a) > Grid.width then
        return "right"
      elseif Blockmassive[GetXblockNextstate(a)][GetYblockNextstate(a)].name ~= 0 or GetYblockNextstate(a) < 1 or GetYblockNextstate(a) > Grid.height then
        return "vertical"
      end
  end
  return false
end

--- TODO list
--- allow rotating in the upper offscreen row, so it wont get deleted, fix movement in that regard
--- block types are different and should be visible.

--- makes randomly filled row , but also shifts up the other blocks, and causes game over in case of overflow
function generaterow()
  for y=1, Grid.height-1 do   --- all rows ascend
    for x=1, Grid.width do
      Blockmassive[x][y].sprite = Blockmassive[x][y+1].sprite
      Blockmassive[x][y].name = Blockmassive[x][y+1].name
    end
  end
  
  for i=1,Grid.width do   --- attach a new row
    e = math.random(1,6)
    if e > 2 then
      Blockmassive[i][Grid.height].sprite = blockmaterial[1][math.random(1,#blockmaterial[1])]
      Blockmassive[i][Grid.height].name = blockmaterial[1].name
    else
      Blockmassive[i][Grid.height] = {}
      Blockmassive[i][Grid.height].sprite = 0
      Blockmassive[i][Grid.height].name = 0
    end
  end
  
  for i,v in ipairs (Enemies) do --- move all onblock enemies up
    if v.name == "slime" then
      v.loc.y = v.loc.y - GridCell.height
      v.destination.y = v.destination.y - GridCell.height
    end
  end
  
  local collisions = {}
  for i,v in ipairs(Activeblock) do   ---- if figure was in the way, solidify it. 
    if GetYblock(i) > Grid.height or Blockmassive[GetXblock(i)][GetYblock(i)].name ~= 0 then  
       moveactiveblock(0,-1)
       table.insert(collisions, {GetXblock(i), GetYblock(i)})
    end
  end
  if #collisions >0 then fossilize(collisions) end
  
  --- make another row if one got autodeleted
  if checkforclear(false) == true then 
    generaterow() 
  end
  checkgameover()  
end

--- checks for full row, if returns true then the row was removed
function checkforclear(scoring)
  for j = 1, Grid.height do
    local counter = 0
    for i = 1, Grid.width do
      if Blockmassive[i][j].name ~= 0 then 
        counter = counter + 1
      end
      if counter == Grid.width then
        if scoring == true then
          rowtodelete = j
          if gamestate.current() ~= animations then
            gamestate.switch(animations)
          end
        else
          removerow(j, false)
        end
        return true
      end
    end
  end
  return false
end



function removerow(row, scoring)  --- removing row whether for maintenance purposes or because player scored
  for j=row,2,-1 do
    for i=1,Grid.width do
    Blockmassive[i][j] = Blockmassive[i][j-1]
    end
  end
  
  Killslimes(row)  --- slimes die on the removed row
  for i,v in ipairs(Enemies) do  
    if v.name == "slime"  then
      if (v.loc.y+GridCell.height/2)/GridCell.height < row then  --- slimes above the row will descend
        v.loc.y = v.loc.y + GridCell.height
        v.destination.y = v.destination.y + GridCell.height
      end
      
      ---- if row destination would become 21, then relink to 20
      if (v.destination.y+GridCell.height/2)/GridCell.height > Grid.height then
        v.destination.y = v.destination.y - GridCell.height
      end
      
    end
  end

  for i=1,Grid.width do
    Blockmassive[i][1] = {}
    Blockmassive[i][1].sprite = 0
    Blockmassive[i][1].name = 0
  end
  
  if scoring == true then
    Points = Points + 100
  else
    checkforclear(false)   --- recheck the field if it wasn't scoring clearing 
                           ---(currently unneeded, you don't add more than one row anyway)
  end
end

function GetXblock(BlockNumber)  --- returns the number of the segment, where current activeblock is located
  return Activeblock.location[1] + Activeblock.type[Activeblock.state][BlockNumber][1]
end
function GetYblock(BlockNumber)
  return Activeblock.location[2] + Activeblock.type[Activeblock.state][BlockNumber][2]
end

function GetXblockNextstate(BlockNumber)
  if Activeblock.state == 4 then
    return Activeblock.location[1] + Activeblock.type[1][BlockNumber][1]
  else
    return Activeblock.location[1] + Activeblock.type[Activeblock.state+1][BlockNumber][1]
  end
end

function GetYblockNextstate(BlockNumber)
  if Activeblock.state == 4 then
    return Activeblock.location[2] + Activeblock.type[1][BlockNumber][2]
  else
    return Activeblock.location[2] + Activeblock.type[Activeblock.state+1][BlockNumber][2]
  end
end

function ChangeBlock(blockcoords, material)
  if material > 0 then
    Blockmassive[blockcoords[1]][blockcoords[2]].name = blockmaterial[material].name
    Blockmassive[blockcoords[1]][blockcoords[2]].sprite = blockmaterial[material][math.random(1,#blockmaterial[material])]
  else
    Blockmassive[blockcoords[1]][blockcoords[2]].name = 0
    Blockmassive[blockcoords[1]][blockcoords[2]].sprite = 0
  end
end

function drawblocks()
  for i,v in ipairs(Activeblock) do   -- draws the tetromino
   
    if Activeblock.mood == "paralyze" then
      colorblock = 1.3
    else
      colorblock = 1
    end
    
    love.graphics.setColor(255,255,255,255)
    if Activeblock.mood == "active" then
      love.graphics.draw(v.sprite, (GetXblock(i)-1)*GridCell.width, (GetYblock(i)-1)*GridCell.height)
    elseif Activeblock.mood == "paralyze" then
      love.graphics.draw(v.sprite, (GetXblock(i)-1)*GridCell.width+math.random(-5,5), (GetYblock(i)-1)*GridCell.height+math.random(-5,5))
    elseif Activeblock.mood == "appearing" then
      love.graphics.draw(v.sprite, (GetXblock(i)-1)*GridCell.width, (GetYblock(i)-1)*GridCell.height-keycooldown*120)
    end
    
  end
  
  love.graphics.setColor(255,255,255,255) -- draws entire massive of blocks
  for y=1, Grid.height do
    
    --rowtodelete was already calculated before the switch
    --- calculate the remaining duration and show blocks up until height/dur
    if y == rowtodelete then
      limit = math.floor(Grid.width*duration)
      love.graphics.setColor(255,0,0,255)
    else
      limit = Grid.width
    end
    
    love.graphics.setColor(200,200,200,255)
    for x=1, limit do
      if Blockmassive[x][y].sprite ~= 0 then 
        love.graphics.draw(Blockmassive[x][y].sprite, (x-1)*GridCell.width, (y-1)*GridCell.height)
      end
    end
  end

end

