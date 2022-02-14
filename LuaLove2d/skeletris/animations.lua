animations = gamestate.new()

function animations:init()
  
end

function animations:enter()
  duration = 1
  deletingtimer = duration / Grid.width 
  EffectGeneration = 0
end

function animations:update(dt)
  if duration < 0 then
    
    removerow(rowtodelete, true)  --- remove the row, but check for the next one and start removing the next one
    if checkforclear(true) then
      duration = 1
    else
      rowtodelete = 0
      gamestate.switch(gameplay)   ---- if nothing is up then quit
    end
    
  else
    
    UpdateEffects(dt)
    if EffectGeneration < 0 then
      MakeFogVisual(vector(math.floor(Grid.width*duration)*GridCell.width - GridCell.width/2, 
          rowtodelete*GridCell.height - GridCell.height + math.random(-4,4)*GridCell.height/4),
          255,55,55,
          Fogs2)
      deletingtimer = timetowait
    end
    EffectGeneration = EffectGeneration - dt
    duration = duration - dt
  end

end

function animations:draw()
  draw_environments()
end

function Makeanimation(row)
  ClearTime = {}
  ClearTime.duration = 5
  ClearTime.row = row
end