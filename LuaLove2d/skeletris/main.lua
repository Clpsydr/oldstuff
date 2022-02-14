function love.load(arg)

if arg[#arg] == "-debug" then require("mobdebug").start() end

vector = require "vector"
gamestate = require "gamestate"
require "gameplay"
require "endgame"
easingFunctions = require("easing")
outInBounce = easingFunctions.outInBounce

Timer = require "timer"

--playerbatch             = love.graphics.newImage("player_animation.png")
--shockedplayerbatch      = love.graphics.newImage("player_animation_shock.png")
--playeranim              = {
--      love.graphics.newQuad(1,1,20,35,126,37),
--      love.graphics.newQuad(22,1,20,35,126,37),
--      love.graphics.newQuad(43,1,20,35,126,37),
--      love.graphics.newQuad(64,1,20,35,126,37),
--      love.graphics.newQuad(85,1,20,35,126,37),
--      love.graphics.newQuad(106,1,20,35,126,37),
--  }

--- stencil forms
--ThatsAllFolks = function()
--   love.graphics.circle("fill",screenwidth/2,screenheight/2,screenwidth*stagewarp/2*stagewarp/2,30)
-- end

tetrisfont1 = love.graphics.newImageFont("font1.png", 
  " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"")
  
  tetrisfont2 = love.graphics.newImageFont("font2fix.png", 
  "!? abcdefghijklmnopqrstuvwxyz")
  
  tetrisfont3 = love.graphics.newImageFont("font3.png", 
  " ()*+,-./0123456789;:=?abcdefghijklmnopqrstuvwxyz")
  
love.graphics.setFont(tetrisfont3)

--- randoize setup
math.randomseed(os.time())

--- resolution setup
screenwidth = 700
screenheight = 600

--- tetris cup dimensions
GridCell = {}
Grid = {}
cup = {}
GridCell.width = 25
GridCell.height = 25
Grid.width = 10
Grid.height = 20
cup.width = 250
cup.height = 500    

Display = love.graphics.newCanvas(screenwidth,screenheight)    --- main screen window
Cup = love.graphics.newCanvas(cup.width,cup.height) --- cup window
Effectcanvas = love.graphics.newCanvas(screenwidth, screenheight) --- for effects because everything is glitching
Display_scale = 1

-- Environment
paused = false

--- clearing animation
ClearTime = {}
ClearTime.duration = 5

-- enums
--- [block type][position][blocknumber][x or y]
  tetroforms = {"L","J","I","T","O","S","Z"}
  tetroforms[1] = {}  --- L
  tetroforms[1][1] = {{1,2},{2,2},{3,2},{1,3}}
  tetroforms[1][2] = {{2,1},{2,2},{2,3},{1,1}}
  tetroforms[1][3] = {{3,3},{2,3},{1,3},{3,2}}
  tetroforms[1][4] = {{2,3},{2,2},{2,1},{3,3}}
  
  tetroforms[2] = {}  --- J
  tetroforms[2][1] = {{1,2},{2,2},{3,2},{3,3}}
  tetroforms[2][2] = {{2,1},{2,2},{2,3},{1,3}}
  tetroforms[2][3] = {{3,3},{2,3},{1,3},{1,2}}
  tetroforms[2][4] = {{2,3},{2,2},{2,1},{3,1}}
  
  tetroforms[3] = {}  --- O
  tetroforms[3][1] = {{2,1},{3,1},{3,2},{2,2}}
  tetroforms[3][2] = {{3,1},{3,2},{2,2},{2,1}}
  tetroforms[3][3] = {{3,2},{2,2},{2,1},{3,1}}
  tetroforms[3][4] = {{2,2},{2,1},{3,1},{3,2}}
  
  tetroforms[4] = {}  --- T
  tetroforms[4][1] = {{1,2},{2,2},{3,2},{2,3}}
  tetroforms[4][2] = {{2,1},{2,2},{2,3},{1,2}}
  tetroforms[4][3] = {{3,3},{2,3},{1,3},{2,2}}
  tetroforms[4][4] = {{2,1},{2,2},{2,3},{3,2}}
  
  tetroforms[5] = {}  --- S
  tetroforms[5][1] = {{2,2},{3,2},{1,3},{2,3}}
  tetroforms[5][2] = {{2,2},{2,3},{1,1},{1,2}}
  tetroforms[5][3] = {{2,2},{3,2},{1,3},{2,3}}
  tetroforms[5][4] = {{2,2},{2,3},{1,1},{1,2}}
  
  tetroforms[6] = {}  --- Z
  tetroforms[6][1] = {{1,2},{2,2},{2,3},{3,3}}
  tetroforms[6][2] = {{3,1},{3,2},{2,2},{2,3}}
  tetroforms[6][3] = {{1,2},{2,2},{2,3},{3,3}}
  tetroforms[6][4] = {{3,1},{3,2},{2,2},{2,3}}
  
  tetroforms[7] = {}  --- I
  tetroforms[7][1] = {{1,2},{2,2},{3,2},{4,2}}
  tetroforms[7][2] = {{3,1},{3,2},{3,3},{3,4}}
  tetroforms[7][3] = {{4,2},{3,2},{2,2},{1,2}}
  tetroforms[7][4] = {{3,4},{3,3},{3,2},{3,1}}

---- a list of graphics included
blockstone = love.graphics.newImage("assets/tetris_stone.png")
blockgrass1 = love.graphics.newImage("assets/tetris_grass.png")
blockgrass2 = love.graphics.newImage("assets/tetris_grass2.png")
blockgrass3 = love.graphics.newImage("assets/tetris_grass3.png")
blockgrass4 = love.graphics.newImage("assets/tetris_grass4.png")
blockbones1 = love.graphics.newImage("assets/tetris_bones1.png")
blockbones2 = love.graphics.newImage("assets/tetris_bones2.png")

bat1 = love.graphics.newImage("assets/tetris_bat1.png")
bat2 = love.graphics.newImage("assets/tetris_bat2.png")
bat3 = love.graphics.newImage("assets/tetris_bat3.png")

slimeidle = love.graphics.newImage("assets/tetris_slimeidle.png")
slime1 = love.graphics.newImage("assets/tetris_slime1.png")
slime2 = love.graphics.newImage("assets/tetris_slime2.png")
slime3 = love.graphics.newImage("assets/tetris_slime3.png")

slimeeat1 = love.graphics.newImage("assets/tetris_slimeeat1.png")
slimeeat2 = love.graphics.newImage("assets/tetris_slimeeat2.png")

slimedead1 = love.graphics.newImage("assets/tetris_slimedead1.png")
slimedead2 = love.graphics.newImage("assets/tetris_slimedead2.png")
slimedead3 = love.graphics.newImage("assets/tetris_slimedead3.png")

ghost1 = love.graphics.newImage("assets/tetris_ghost1.png")
ghost2 = love.graphics.newImage("assets/tetris_ghost2.png")
ghost3 = love.graphics.newImage("assets/tetris_ghost3.png")

ghostd1 = love.graphics.newImage("assets/tetris_ghostdist1.png")
ghostd2 = love.graphics.newImage("assets/tetris_ghostdist2.png")
ghostd3 = love.graphics.newImage("assets/tetris_ghostdist3.png")

ghostdead1 = love.graphics.newImage("assets/tetris_ghostkill1.png")
ghostdead2 = love.graphics.newImage("assets/tetris_ghostkill2.png")
ghostdead3 = love.graphics.newImage("assets/tetris_ghostkill3.png")

smokeeffect1 = love.graphics.newImage("assets/tetris_smoke1.png")
smokeeffect2 = love.graphics.newImage("assets/tetris_smoke2.png")
smokeeffect3 = love.graphics.newImage("assets/tetris_smoke3.png")
newsmoke1 = love.graphics.newImage("assets/newsmoke.png")
newsmoke21 = love.graphics.newImage("assets/newsmoke2.png")
newsmoke22 = love.graphics.newImage("assets/newsmoke22.png")
newsmoke23 = love.graphics.newImage("assets/newsmoke23.png")
sparkeffect = love.graphics.newImage("assets/tetris_spark.png")
sparkeffect2 = love.graphics.newImage("assets/tetris_spark2.png")

UIbackground = love.graphics.newImage("assets/tetris_coffinback.png")
UIwalls = love.graphics.newImage("assets/tetris_coffinwalls.png")
UIgameover = love.graphics.newImage("assets/tetris_coffinlid.png")
UIlights = love.graphics.newImage("assets/tetris_coffinlights.png")

--- a list of possible shifts

blockmaterial = {}
blockmaterial[1] = {blockgrass1, blockgrass2, blockgrass3, blockgrass4}
blockmaterial[1].name = "dirt"
blockmaterial[2] = {blockbones1, blockbones2}
blockmaterial[2].name = "bone"
blockmaterial[3] = {blockstone}
blockmaterial[3].name = "tomb"

monstertypes = {"bat", "slime", "ghost", "spider"}

batanim = {bat1,bat2,bat3,bat2}
slimeanim = {slimeidle, slime1, slime2, slime3, slime2}
slimeeatanim = {slimeidle, slimeeat1, slimeeat2}
slimedeadanim = {slimedead1, slimedead2, slimedead3}
ghostanim = {ghost1, ghost2, ghost3}
ghostdistanim = {ghostd1, ghostd2, ghostd3}
ghostdeadanim = {ghostdead1, ghostdead2, ghostdead3}
Fogs = {smokeeffect1, smokeeffect2, smokeeffect3}
Fogs2 = {newsmoke21, newsmoke22, newsmoke23}
Fogs3 = {newsmoke1}
Sparks = {sparkeffect, sparkeffect2}


love.graphics.setMode(screenwidth, screenheight,false,false,0)
gamestate.switch(gameplay)

end

function love.update(dt)
	gamestate.update(dt)
end

function love.draw()
	gamestate.draw()
end

function love.keypressed(key)
	if key == "p" then
		if paused == false then
			paused = true
		else
			paused = false
		end
	end
  
	if key == "escape" then
			love.event.quit()
	end
  
  if key == "d" then
    Enemies = {}
  end 
end

