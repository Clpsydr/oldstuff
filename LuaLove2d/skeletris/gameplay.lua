gameplay = gamestate.new()
require "block_class"
require "monsters"
require "effects"
require "endgame"
require "animations"

----------------------------------------------------------------------------------------------------------

function gameplay:init()
  camerastart = {50,50}
  Blockstart = {Grid.width/2,0}
  d_linecooldown = 40     --- row autogenerate
  d_gravity = 5           --- block autofall
  xmax = 0
  xmin = 0
  ymax = 0 
  ymin = 0
  
  ---- the part for a new stage
  blocks = {}
  rows = {}
  Activeblock = {}
  Nextblock = {}
  Enemies = {}
  Effects = {}
  Particles = {}
  
  Blockmassive = {}   --- actual field is just a table, with [x][y] as gabarites
  for i=1, Grid.width do
    Blockmassive[i] = {}
    for j=1, Grid.height do
      Blockmassive[i][j] = {}
      Blockmassive[i][j].name = 0
      Blockmassive[i][j].sprite = 0
    end
  end
  
  Points = 0
  rowtodelete = 0        --- current row for deletion
  duration = 0           ---- animation duration
  enemyspawndelay = 1
  
  --- timers and cooldowns
  overalltime = 0
  newlinecooldown = 15   -- cooldown on extra rows
  gravity = 5            -- cooldown on falling block
  keycooldown = 0.5
  defaultenemyspawndelay = 2    --- cooldown on appearance of a new enemy
  maxenemies = 5
  
  generaterow()
end

---------------------------------------------------------------------------------------------------------
function gameplay:enter()
  
end
---------------------------------------------------------------------------------------------------------

function EnemyLimit()
  return Points/1000
end


---------------------------------------------------------------------------------------------------------
function gameplay:update(dt)
  keycooldown = keycooldown - dt
  
if paused == false then
	overalltime = overalltime + dt
  newlinecooldown = newlinecooldown - dt
  gravity = gravity - dt
  enemyspawndelay = enemyspawndelay - dt
  
  if newlinecooldown < 0 then
    generaterow()
    newlinecooldown = d_linecooldown
  end
    
   --- this is retarded and you know it, just make a separate massive for them
  liveenemies = 0
  for i,v in ipairs (Effects) do
    if v.type == "spawnenemy" then
      liveenemies = liveenemies + 1
    end
  end
  if #Enemies+liveenemies <= 2*EnemyLimit() then   --- spawn more enemies, if not popcap or cooldown, and score is high 
    if enemyspawndelay < 0 then
      makeeffect("spawnenemy", 2, vector(0,0))
      enemyspawndelay = defaultenemyspawndelay
    end
  end
  
  --- adds next block and replaces active one with a next
  --- just make a function for nextblock creation 
  RenewTetrominos()
  UpdateEnemy(dt)
  UpdateEffects(dt)
  
  if gravity < 0 then 
    moveactiveblock(0,1)
    gravity = d_gravity
  end
    
  --- make it clearer for different states holy shit
  if Activeblock.mood == "paralyze" then
    if Activeblock.duration > 0 then
      Activeblock.duration = Activeblock.duration - dt
    else
      Activeblock.duration = 2
      Activeblock.mood = "active"
    end
  end
  if Activeblock.mood == "appearing" and keycooldown < 0 then
    moveactiveblock(0,0)
    Activeblock.mood = "active"
  end
  
  --- debug function for adding the line
  if keycooldown < 0 and Activeblock.mood ~= "paralyze" then
    if love.keyboard.isDown("n") then
      generaterow()
      newlinecooldown = d_linecooldown
      keycooldown = 0.2
    end
    
	  if love.keyboard.isDown("left") then
      moveactiveblock(-1,0)
      keycooldown = 0.1
		end
		if love.keyboard.isDown("right") then
      moveactiveblock(1,0)
      keycooldown = 0.1
		end
		if love.keyboard.isDown("up") then
      rotateactiveblock()
      clearingset = not clearingset
      --gamestate.switch(endgame)
--      removerow(Grid.height,false)
      gravity = d_gravity
      keycooldown = 0.2
		end
		if love.keyboard.isDown("down") then
      keycooldown = 0.05
      moveactiveblock(0,1)
      gravity = d_gravity
		end
  end
  
end
end
---------------------------------------------------------------------------------------------------------
function RenewTetrominos()
   if #Activeblock == 0 then
    if #Nextblock == 0 then
      makeactiveblock()
    end
    Activeblock = Nextblock
    makeactiveblock()
  end
end  
  
function causegameover()
  gamestate.switch(endgame)
end

--- if toppest row is filled, game over
function checkgameover()
  for x=1,Grid.width do
    if Blockmassive[x][1].name ~= 0 then
      causegameover()
    end
  end
end

-----------------------------------------------------START OF DRAW UPD-------------------------------------------------
function gameplay:draw()
  draw_environments()
end
-----------------------------------------------------END OF DRAW UPD---------------------------------------------------
function draw_environments()
  love.graphics.setColor(255,255,255,255)
  love.graphics.clear();
  
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(UIwalls,camerastart[1]-50,camerastart[2]-25)
  draw_cup()
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(Cup,camerastart[1],camerastart[2])
  draw_ui()

  Draw_Effects()
  love.graphics.draw(Effectcanvas,0,0)
  
  love.graphics.setColor(255,255,255,255)
end


---- drawing the tetris stuff
function draw_cup()
  love.graphics.setCanvas(Cup)
  Cup:clear()
  love.graphics.setColor(255,205,205,205)
  love.graphics.draw(UIbackground,0,0)
  if paused == false then
    drawblocks()
  else 
    love.graphics.setColor(255,255,0,255)
    love.graphics.print("paused",cup.width/2,cup.height/2)
  end

  for i,v in ipairs(Particles) do
    love.graphics.draw(v,0,0)
  end
 
  love.graphics.setColor(255,225,225,255)
  DrawEnemy()
  love.graphics.setCanvas()
end

function draw_ui()
  love.graphics.setColor(0,255,0,255)
  love.graphics.print("next row in : "..tostring(math.floor(newlinecooldown)),400, 500)
  --love.graphics.print("falling block: "..tostring(math.floor(gravity)), 400, 400)
  love.graphics.print("points: "..Points, 500,550)
  
 -- showing the next block
 love.graphics.setColor(255,255,255,255)
 love.graphics.print("next block: ", 420,60)
 love.graphics.rectangle("line", 485,85,GridCell.width*5, GridCell.height*5)
    for i,v in ipairs(Nextblock) do
      love.graphics.setColor(150,155,155,255)
      local x = Nextblock.type[Nextblock.state][i][1]
      local y = Nextblock.type[Nextblock.state][i][2]
      love.graphics.draw(v.sprite, 475+x*GridCell.width, 75+y*GridCell.height)
      --love.graphics.rectangle("fill", 375+x*GridCell.width, 75+y*GridCell.height, GridCell.width, GridCell.height)
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



