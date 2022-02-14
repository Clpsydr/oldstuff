function RelaysUpdate(dt)
	for i,v in ipairs(Relays) do				---- relays calculation, sparking and decaying
		if v.immortal == false then
      v.energy = v.energy - dt
    end

		if v.energy < 0 then 					---delete if expired, otherwise maintain
			for j,b in ipairs(Wires) do		--- check if all wires are removed properly
				if b.coorda == v.location or b.coordb == v.location then
					b.todelete = true
				end
			end

			for j,b in ipairs(Relays) do		-- check if any relay is connected to this one, sever the connection
				for g,z in ipairs(b.connections) do
					if z.ID == v.ID then
						table.remove(b.connections, g)
					end
				end
			end

			table.remove(Relays, i)
			relaycount = relaycount - 1
			checkConnection()

		else  --- emit particles if active
			if v.active == true then

				v.discharge = v.discharge - dt

				if v.discharge < 0 then
          for mu, bu in ipairs(Wires) do
            if bu.coordb == v.location then
              makerunningsparks(bu.drawpoints2, bu.ID, false)
              makerunningsparks(bu.drawpoints, bu.ID, true)
            end
          end
          MakeSparkVisual(v.location,0,-40)
					v.discharge = 2
				end
			end
		end
	end

	for j,b in ipairs(Wires) do			---- cleaning up unused wires 
		if b.todelete == true then
      for ai, bi in ipairs(RunningSparks) do
          if bi.ID == b.ID then
            table.remove(RunningSparks, ai)
          end
      end
      table.remove(Wires,j)
		end
	end
end

--- relays drawing
function draw_relays()

	for i,v in ipairs(Relays) do
    if v.immortal == true then
      love.graphics.setColor(255,0,0,255)
		elseif v.active == true then
			love.graphics.setColor(205*v.energy/relaycap+10,205*v.energy/relaycap+10,205*v.energy/relaycap+10,255)
		else
			love.graphics.setColor(10,10,10,255)
		end
    
		if v.energy < 1 then
			love.graphics.draw(poleimg, v.location.x, v.location.y,0,0.3,0.3*v.energy,RelaySize.x,2*RelaySize.y)
		else
			love.graphics.draw(poleimg, v.location.x, v.location.y,0,0.3,0.3,RelaySize.x,2*RelaySize.y)
		end
  end
  
end
---------------------------------------------------------------------------------------------------------
function create_relay_dependency()
  relay = {}
				relay.ID = relayID+1
				relayID = relayID+1
				relay.energy = relaycap
				relay.active = false
				relay.discharge = 2-(difficulty-1)*0.2
				relay.location = PlayerLoc
				relay.coverage = coverage
				relay.connections = {}
        relay.immortal = false

				-- adding wire in case relay is close to something
				--- also making it possible to trace if there is a substation working
				shortest = relay.coverage

				for i,v in ipairs(Transformers) do					--- pick closest possible substation
					if v.location:dist(relay.location) < shortest then
						shortest = v.location:dist(PlayerLoc)
						origin = {}
						origin.type = "substation"
						origin.ID = v.ID
						
            wire = {}
            wireIDcounter = wireIDcounter + 1
            wire.ID = wireIDcounter 
						wire.type = "substation"
						wire.coorda = v.location
						wire.coordb = relay.location
            wire.drawpoints = makeWireList(wire.coorda+vector(-20,-15), wire.coordb+vector(-RelaySize.x/4, -RelaySize.y/2))
            wire.drawpoints2 = makeWireList(wire.coorda+vector(-11,-25), wire.coordb+vector(RelaySize.x/4, -RelaySize.y/2))
					end
				end

				if shortest < relay.coverage then							--- only add relation once if gen was around
					table.insert(relay.connections, origin)
					table.insert(Wires,wire)
				end

				for i,v in ipairs(Relays) do			---- attach to every other relay near, make wires
					if v.location:dist(relay.location) < relay.coverage then

						origin = {}
						origin.type = "relay"
						origin.ID = v.ID
						table.insert(relay.connections, origin)

						origin = {}
						origin.type = "relay"
						origin.ID = relay.ID
						table.insert(v.connections, origin)

						wire = {}
            wireIDcounter = wireIDcounter + 1
            wire.ID = wireIDcounter 
						wire.type = "relay"
						wire.coorda = v.location
						wire.coordb = relay.location
            wire.drawpoints = makeWireList(wire.coorda+vector(-RelaySize.x/4, -RelaySize.y/2), wire.coordb+vector(-RelaySize.x/4, -RelaySize.y/2))
            wire.drawpoints2 = makeWireList(wire.coorda+vector(RelaySize.x/4, -RelaySize.y/2), wire.coordb+vector(RelaySize.x/4, -RelaySize.y/2))
						table.insert(Wires, wire)
					end
				end

				--- check once to install an extra wire on facility and mark relay as feeding
				for i,v in ipairs(facilityblock) do
					if math.abs(relay.location.x - v.location.x) < relay.coverage and
					math.abs(relay.location.y - v.location.y) < relay.coverage and
					v.energyneed > 0 then
            
            origin = {}
            origin.type = "facility"
            origin.ID = v.location
            table.insert(relay.connections, origin)
            
						v.connected = true
						wire = {}
            for a,h in ipairs(FacilityTypes) do
              if h == v.type then
                wire.type = a
              end
            end
            wireIDcounter = wireIDcounter + 1
            wire.ID = wireIDcounter 
            wire.coorda = v.location
						wire.coordb = relay.location
						wire.drawpoints = makeWireList(wire.coorda+FacilityRelayOffsets[wire.type],wire.coordb+vector(-RelaySize.x/4, -RelaySize.y/2))
            wire.drawpoints2 = makeWireList(wire.coorda+FacilityRelayOffsets[wire.type],wire.coordb+vector(RelaySize.x/4, -RelaySize.y/2))
          
          table.insert(Wires, wire)
					end
				end

				table.insert(Relays, relay)				--- insert new relay and check how others are connected now
				relaycount = relaycount + 1

				buildcooldown = 2
				checkConnection()
end