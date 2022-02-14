function MakeCity(size)
  city = {}
  
--- parameters for displaying
  city.color_road = {130,128,88,255}
  city.color_grass = {255,252,173,255}
  city.color_block = {155,155,155,255}
  city.rotation = 2*math.pi*math.random(1,360)
  city.shift = {math.random(-30,30), math.random(-30,30)}
  city.zoom = 1
  
  city.scale = size               --- just remember what was the initial number
  city.size = {size*5, size*5}   --- city constraints
  
  city.streets = {}
  for i=1, math.random(1,size) do  --- create several main streets (some are perpendicular)
    
    randlocation = math.random(0,city.size[1])
    if math.random(1,2) == 2 then   --- horizontal or vertical
      street = {{randlocation, 0}, {randlocation, city.size[2]}}
    else
      street = {{0, randlocation}, {city.size[1], randlocation}}
    end
      street.type = "main"
      table.insert(city.streets, street)
  end
  
  return city
end

function BakeCity(city)
  --- draw to canvas using Makecity parameters
  --blocksize = 1024 / city.size[1]
  citycanvas = love.graphics.newCanvas(1024, 1024)
  love.graphics.setCanvas(citycanvas)
  love.graphics.clear()
  
  love.graphics.setColor(255,255,255,255)
  --- draw the map of the current city
  love.graphics.draw(mapmode[mapmode_curr].img,0,0)
  
  -- invoke the buildings in case they got lost
  for i,v in ipairs(canvasbuilds) do
    love.graphics.setCanvas(BuildBack)
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(v.image, v.location.x-v.size.x/2, v.location.y-v.size.y/2, 0,0.5,0.5)
    love.graphics.setCanvas()
  end
  love.graphics.draw(BuildBack)
  
  love.graphics.setCanvas()
end