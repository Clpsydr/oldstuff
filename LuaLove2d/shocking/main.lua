function love.load(arg)

if arg[#arg] == "-debug" then require("mobdebug").start() end

vector = require "vector"
gamestate = require "gamestate"
require "gameplay"
require "gameover"
require "intro"
require "hiscore"
require "howto"
require "transition"
require "citybuild"

Timer = require "timer"

playerbatch             = love.graphics.newImage("player_animation.png")
shockedplayerbatch      = love.graphics.newImage("player_animation_shock.png")
playeranim              = {
      love.graphics.newQuad(1,1,20,35,126,37),
      love.graphics.newQuad(22,1,20,35,126,37),
      love.graphics.newQuad(43,1,20,35,126,37),
      love.graphics.newQuad(64,1,20,35,126,37),
      love.graphics.newQuad(85,1,20,35,126,37),
      love.graphics.newQuad(106,1,20,35,126,37),
  }

onsubstationimg 	      = love.graphics.newImage("substation2.png")
poleimg 			          = love.graphics.newImage("electropole_small.png")
onbuilding 			        = love.graphics.newImage("building_common.png")
building_WTC_img        = love.graphics.newImage("building_extra1.png")
building_factory_img 		= love.graphics.newImage("building_extra2.png")
building_museum_img     = love.graphics.newImage("building_museum.png")
building_hospital_img   = love.graphics.newImage("building_hospital.png")
building_observatory_img= love.graphics.newImage("building_observatory.png")

sparkbatch      = love.graphics.newImage("batch_spark.png")
sparkimg        = {love.graphics.newQuad(1,1,10,10,23,45), love.graphics.newQuad(12,1,10,10,23,45)}
deadsparkimg    = {love.graphics.newQuad(1,12,10,10,23,45), love.graphics.newQuad(1,12,10,10,23,45)}
cogproj         = {love.graphics.newQuad(1,23,10,10,23,45), love.graphics.newQuad(1,23,10,10,23,45)}
scorespark      = {love.graphics.newQuad(1,34,4,10,23,45), love.graphics.newQuad(12,34,4,10,23,45)}
particle_spark  = love.graphics.newImage("spark.png") --- made separately to support particles of Love2d

loadingimg      = love.graphics.newImage("loading_rotating_small.png")
howtoimg 			  = love.graphics.newImage("howto.png")
gameoverimg			= love.graphics.newImage("gameover2.png")
mapmode = {{},{}}
mapmode[1].img = love.graphics.newImage("map.png")
mapmode[1].bord = love.graphics.newImage("mapborder.png")
mapmode[2].img = love.graphics.newImage("map2.png")
mapmode[2].bord = love.graphics.newImage("mapborder2.png")
mapmode_curr = 2

exclam1				  = love.graphics.newImage("bumpy exclam.png")
exclam2				  = love.graphics.newImage("ugly exclam.png")
battery				  = love.graphics.newImage("battery.png")
battery100			= love.graphics.newImage("batteryOK.png")
powersign			  = love.graphics.newImage("power on.png")
nopowersign			= love.graphics.newImage("poweroff.png")
calamimg        = love.graphics.newImage("calamity_w.png")
calamimg2       = love.graphics.newImage("calamity2_w.png")

powermeterimg 		= love.graphics.newImage("powermeter.png")
fuseimg				    = love.graphics.newImage("minifuse.png")
fusetubeimg			  = love.graphics.newImage("fuse tube.png")
fusetubestringimg	= love.graphics.newImage("fuse string.png")
fusetubeblownimg	= love.graphics.newImage("fuse busted.png")

twizzler			  = love.graphics.newImage("twizzlers_small.png")
screwdriver 		= love.graphics.newImage("screwdriver_small.png")

bonus_expandgen   = love.graphics.newImage("bonusicon1.png")
bonus_fuse        = love.graphics.newImage("bonusicon2.png")
bonus_energy      = love.graphics.newImage("bonusicon3.png")
bonus_extragen    = love.graphics.newImage("bonusicon4.png")

deathfont 			= love.graphics.newFont("EccentricStd.otf",150)
normalfont 			= love.graphics.newFont("upclb.ttf",25)
uifont          = love.graphics.newFont("QuartzMS.ttf",20)
menufont 			  = love.graphics.newFont("SegoeWP.ttf",30)
menudoublefont  = love.graphics.newFont("MotorwerkOblique.ttf",30)
menufontless		= love.graphics.newFont("SegoeWP-Black.ttf",30)

Display1024 = love.graphics.newCanvas(1024,1024)    --- main screen window
BuildBack = love.graphics.newCanvas(1024,1024)      --- for drawing some buildings dones
Display_scale = 1

blureffect = love.graphics.newPixelEffect [[
extern vec2 size;
extern int samples = 50; // pixels per axis; higher = bigger glow, worse performance
extern float quality = 50; // lower = smaller glow, better quality
 
vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
{
vec4 source = Texel(tex, tc);
vec4 sum = vec4(0);
int diff = (samples - 1) / 2;
vec2 sizeFactor = vec2(1) / size * quality;
for (int x = -diff; x <= diff; x++)
{
for (int y = -diff; y <= diff; y++)
{
vec2 offset = vec2(x, y) * sizeFactor;
sum += Texel(tex, tc + offset);
}
}
return ((sum / (samples * samples)) + source) * colour;
}
]]


--- stencil forms
ThatsAllFolks = function()
   love.graphics.circle("fill",screenwidth/2,screenheight/2,screenwidth*stagewarp/2*stagewarp/2,30)
 end
ItBegins = function()
   love.graphics.circle("fill",screenwidth/2,screenheight/2,screenwidth/2*overalltime,30)
 end 

 EndStencil = love.graphics.newStencil(ThatsAllFolks)
 StartStencil = love.graphics.newStencil(ItBegins)


--- randomize setup
math.randomseed(os.time())

--- resolution setup
screenwidth = 1024
screenheight = 1024

-- Player
PlayerSizex = 20
PlayerSizey = 35
speedplayer = 150				-- player speed
playerstatus = 0				--- color modifier for being shocked
animchange = 0
shockframe = 1

toolsize = vector(18,28)

-- Environment
paused = false
standardspeed = 50            --- retarded declaration of spark speed
SubstationSizex = 50
SubstationSizey = 25
HomeSize = vector(78,41)   		--- 156 - 82
RelaySize = vector(50,74)       --- 100 - 148

-- enums
StageNames              = {"village", "town", "city", "industrial zone", "megapolis", "cemetery", "valhalla"}
FacilityTypes 		      = {"standard", "Trade center", "Factory", "Museum", "Hospital", "Observatory"}
FacilitySizes           = {vector(78,41), vector(77,78),vector(78,85),vector(77,53),vector(75,42),vector(77,55)}
FacilityRelayOffsets    = {vector(-24,-19), vector(-25,-3),vector(-27,-19),vector(-29,-4),vector(-29,10),vector(-27,1)}
FacilityImages = {onbuilding, building_WTC_img, building_factory_img, building_museum_img, building_hospital_img, building_observatory_img}
ToolTypes 			= {screwdriver, twizzler}
Shockanimtemp		= {shock1, shock2, shock3}


love.graphics.setMode(screenwidth, screenheight,false,false,0)
gamestate.switch(intro)

end

function love.update(dt)
	gamestate.update(dt)
end

function love.draw()
	gamestate.draw()
end

function love.keypressed(key, unicode)
	if key == "return" or key == "space" then
		pressed = true
	end

  if unicode < 127 and unicode > 64 then
		keystack = key
	elseif key == "backspace" then
		keystack = key
	end
  
  if key == "p" then
		if paused == false then
			paused = true
		else
			paused = false
		end
	end
  
  if key == "b" then
    if mapmode_curr == 1 then
      mapmode_curr = 2
    else 
      mapmode_curr = 1
    end
    BakeCity(currentcity)
  end

  if key == "-" then
    Display_scale = 0.6
    love.graphics.setMode(3*screenwidth/5, 3*screenheight/5,false,false,1)
    if gamestate.current() == gameplay then
    BakeCity(currentcity)
    end
  end
  if key == "=" then
    Display_scale = 1
    love.graphics.setMode(screenwidth, screenheight,false,false,0)
    if gamestate.current() == gameplay then
    BakeCity(currentcity)
    end
  end
	if key == "escape" then
		if gamestate ~= "intro" then
			gamestate.switch(intro)
      love.graphics.setStencil()
		else
			love.event.quit()
		end
	end
end

