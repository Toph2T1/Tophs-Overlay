local tFeature = {} -- Toggle Features
local vFeature = {} -- Value Features
local INI = IniParser("cfg/TophsOverlaySettings.ini") -- Script Settings Location
local isTrusted = menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_NATIVES)
local mainParent = menu.add_feature("Toph's Overlay", "parent", 0)

local function RGBAToInt(R, G, B, A)
	A = A or 255
	return ((R&0x0ff)<<0x00)|((G&0x0ff)<<0x08)|((B&0x0ff)<<0x10)|((A&0x0ff)<<0x18)
end

tFeature["enableOverlay"] = menu.add_feature("Enable Overlay", "toggle", mainParent.id, function(f)  
    while f.on do
        local info = {}

        local pped = player.player_ped()
		local pid = player.player_id()
		local playercoords = player.get_player_coords(pid)

        if tFeature["calculatedFPS"].on then
            info[#info + 1] = "FPS: " .. math.ceil(1 / gameplay.get_frame_time())
        end

        if tFeature["currentSessionType"].on then
            if isTrusted then
                if network.is_session_started() then
                    if native.call(0xF3929C2379B60CCE):__tointeger() == 1 then -- NETWORK_SESSION_IS_SOLO
                        info[#info + 1] = "Session Type: Solo"
                    elseif native.call(0xCEF70AA5B3F89BA1):__tointeger() == 1 then -- NETWORK_SESSION_IS_PRIVATE
                        info[#info + 1] = "Session Type: Invite Only"
                    elseif native.call(0xFBCFA2EA2E206890):__tointeger() == 1 then -- NETWORK_SESSION_IS_CLOSED_FRIENDS
                        info[#info + 1] = "Session Type: Friends Only"
                    elseif native.call(0x74732C6CA90DA2B4):__tointeger() == 1 then -- NETWORK_SESSION_IS_CLOSED_CREW
                        info[#info + 1] = "Session Type: Crew Only"
                    else
                        info[#info + 1] = "Session Type: Public"
                    end
                else
                    info[#info + 1] = "Session Type: Singleplayer"
                end
            else
                info[#info + 1] = "Session Type: Unknown (Natives Trusted Mode Not Enabled)."
            end
        end

        if tFeature["sessionHiddenStatus"].on then
            if isTrusted then
                if native.call(0xBA416D68C631496A):__tointeger() == 0 then -- NETWORK_SESSION_IS_VISIBLE
                    info[#info + 1] = "Session Hidden: True"
                else
                    info[#info + 1] = "Session Hidden: False"
                end
            else
                info[#info + 1] = "Session Hidden: Unknown (Natives Trusted Mode Not Enabled)"
            end
		end

		if tFeature["currentSessionHost"].on then
            if network.is_session_started() then
                local host = player.get_host()
                local SessionHost = player.get_host() >= 0 and player.get_player_name(host) or "N/A"

                if SessionHost == player.get_player_name(player.player_id()) then
                    info[#info + 1] = "Session Host: #FFB6599B#" .. SessionHost .. "#DEFAULT#"
                elseif player.is_player_friend(host) then
                    info[#info + 1] = "Session Host: #FFE5B55D#" .. SessionHost .. "#DEFAULT#" 
                elseif player.is_player_modder(host, -1) then
                    info[#info + 1] = "Session Host: #FF0000FF#" .. SessionHost .. "#DEFAULT#"
                else
                    info[#info + 1] = "Session Host: " .. SessionHost .. "#DEFAULT#"
                end
            else
                info[#info + 1] = "Session Host: N/A"
            end
		end

		if tFeature["nextSessionHost"].on then
            if network.is_session_started() then
                local next_host = player.get_host()
                for i = 0, 31 do
                    if player.is_player_valid(i) then
                        if player.get_host() ~= -1 and player.get_player_host_priority(i) == 1 and not player.is_player_host(i) then
                            next_host = i
                        elseif player.get_host() ~= -1 and player.get_player_host_priority(i) == 2 and not player.is_player_host(i) then
                            next_host = i
                        end
                    end
                end
                if next_host == player.player_id() then
                    info[#info + 1] = "Next Session Host: #FFB6599B#" .. player.get_player_name(next_host) .. "#DEFAULT#"
                elseif player.is_player_friend(next_host) then
                    info[#info + 1] = "Next Session Host: #FFE5B55D#" .. player.get_player_name(next_host) .. "#DEFAULT#"
                elseif player.is_player_modder(next_host, -1) then
                    info[#info + 1] = "Next Session Host: #FF0000FF#" .. player.get_player_name(next_host) .. "#DEFAULT#"
                else
                    info[#info + 1] = "Next Session Host: " .. player.get_player_name(next_host) 
                end
            else
                info[#info + 1] = "Next Session Host: N/A"
            end
		end

		if tFeature["currentScriptHost"].on then
            if network.is_session_started() then
                local shost = script.get_host_of_this_script()
                local scripthost = script.get_host_of_this_script() >= 0 and player.get_player_name(shost) or "N/A"
                --local scripthost = player.get_player_name(script.get_host_of_this_script())
                if scripthost == player.get_player_name(player.player_id()) then
                    info[#info + 1] = "Script Host: #FFB6599B#" .. scripthost .. "#DEFAULT#"
                elseif player.is_player_friend(shost) then
                    info[#info + 1] = "Script Host: #FFE5B55D#" .. scripthost .. "#DEFAULT#" 
                elseif player.is_player_modder(shost, -1) then
                    info[#info + 1] = "Script Host: #FF0000FF#" .. scripthost .. "#DEFAULT#"
                else
                    info[#info + 1] = "Script Host: " .. scripthost .. "#DEFAULT#"
                end
            else
                info[#info + 1] = "Script Host: N/A"
            end
		end

        local alivePlayers = 0
        local deadPlayers = 0
        local modders = 0
        local spectators = 0
        local friends = 0
        local godmodePlayers = 0
        local vehGodmodePlayers = 0
        local vehiclePlayers = 0
        local inInterior = 0
        local inCutscene = 0
        local isTalking = 0
        
        if network.is_session_started() then
            for i = 0, 31 do
                if player.is_player_valid(i) then
                    if player.get_player_health(i) > 0 then 
                        alivePlayers = alivePlayers + 1
                    else
                        deadPlayers = deadPlayers + 1
                    end
                    if player.is_player_modder(i, -1) then
                        modders = modders + 1
                    end
                    if player.is_player_spectating(i) then
                        spectators = spectators + 1
                    end
                    if player.is_player_friend(i) then
                        friends = friends + 1
                    end
                    if player.is_player_god(i) then
                        godmodePlayers = godmodePlayers + 1
                    end
                    if player.is_player_vehicle_god(i) then
                        vehGodmodePlayers = vehGodmodePlayers + 1
                    end
                    if ped.is_ped_in_any_vehicle(player.get_player_ped(i)) then
                        vehiclePlayers = vehiclePlayers + 1
                    end
                    if interior.get_interior_from_entity(player.get_player_ped(i)) ~= 0 then
                        inInterior = inInterior + 1
                    end
                    if isTrusted then
                        if native.call(0xE73092F4157CD126, i):__tointeger() == 1 or native.call(0x63F9EE203C3619F2, i):__tointeger() == 1 then
                            inCutscene = inCutscene + 1
                        end
                    else
                        inCutscene = "Unknown (Natives Trusted Mode Not Enabled)."
                    end
                    if isTrusted then
                        if native.call(0x031E11F3D447647E, i):__tointeger() == 1 then
                            isTalking = isTalking + 1
                        end
                    else
                        isTalking = "Unknown (Natives Trusted Mode Not Enabled)."
                    end
                end
			end
		end

		if tFeature["currentPlayerCount"].on then
			info[#info + 1] = "Player Count: " .. player.player_count()
		end

		if tFeature["aliveDeadCount"].on then
			if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tAlive: " .. alivePlayers .. " | Dead: " .. deadPlayers
			else
				info[#info + 1] = "Alive Players: " .. alivePlayers .. " | Dead Players: " .. deadPlayers
			end
		end

		if tFeature["modders"].on then
			if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tModders: " .. modders
			else
				info[#info + 1] = "Modders In Session: " .. modders
			end
		end

		if tFeature["friends"].on then
			if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tFriends: " .. friends
			else
				info[#info + 1] = "Friends In Session: " .. friends
			end
		end

		if tFeature["spectators"].on then
			if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tSpectators: " .. spectators
			else
				info[#info + 1] = "Players Spectating: " .. spectators
			end
		end

		if tFeature["godmodePlayers"].on then 
			if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tGodmode: " .. godmodePlayers
			else
				info[#info + 1] = "Players In Godmode: " .. godmodePlayers
			end
		end

        if tFeature["vehicleGodmodePlayers"].on then
            if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tVehicle Godmode: " .. vehGodmodePlayers
            else
                info[#info + 1] = "Players With Vehicle Godmode: " .. vehGodmodePlayers
            end
        end

        if tFeature["isInVehicle"].on then
            if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tIn A Vehicle: " .. vehiclePlayers
            else
                info[#info + 1] = "Players In A Vehicle: " .. vehiclePlayers
            end
        end


		if tFeature["inInterior"].on then
			if tFeature["currentPlayerCount"].on then
				info[#info + 1] = "\tIn Interior: " .. inInterior
			else
				info[#info + 1] = "Players In An Interior: " .. inInterior
			end
		end

        if tFeature["inCutscene"].on then
            if tFeature["currentPlayerCount"].on then
                info[#info + 1] = "\tIn A Cutscene: " .. inCutscene
            else
                info[#info + 1] = "Players In A Cutscene: " .. inCutscene
            end
        end

        if tFeature["isTalking"].on then
            if tFeature["currentPlayerCount"].on then
                info[#info + 1] = "\tIs Talking: " .. isTalking
            else
                info[#info + 1] = "Players Talking: " .. isTalking
            end
        end

		if tFeature["currentHealth"].on then
			info[#info + 1] = string.format("Health: %.0f", player.get_player_health(pid)) ..  string.format(" / %.0f", player.get_player_max_health(pid))
		end

		if tFeature["currentArmor"].on then 
			info[#info + 1] = string.format("Armor: %.0f", player.get_player_armour(pid)) .. " / 50"
		end

        if tFeature["wantedLevel"].on then
            info[#info + 1] = "Wanted Level: " .. player.get_player_wanted_level(pid) .. " / 5"
        end

        if tFeature["currentTargetingMode"].on then
            if isTrusted then
                local targetingMode = {
                    [0] = "Assisted Aim - Full",
                    [1] = "Assisted Aim - Partial",
                    [2] = "Free Aim - Assisted",
                    [3] = "Free Aim"
                }
                
                local modeNumber = native.call(0xBB41AFBBBC0A0287):__tointeger()
                local modeText = targetingMode[modeNumber] or "Unknown Targeting Mode"
                
                info[#info + 1] = "Current Targeting Mode: " .. modeText
            else
                info[#info + 1] = "Session Type: Unknown (Natives Trusted Mode Not Enabled)."
            end
        end
        
		if tFeature["vehicleInformation"].on then
            if ped.is_ped_in_any_vehicle(player.player_ped()) then
                local veh = ped.get_vehicle_ped_is_using(player.player_ped())
                local VehModelLabel = vehicle.get_vehicle_model_label(veh)
                local VehBrand = vehicle.get_vehicle_brand(veh) or ""
                local VehModel = vehicle.get_vehicle_model(veh)
                info[#info + 1] = "Current Vehicle: " .. VehBrand .. " " .. VehModel .. " " .. "[" .. VehModelLabel .. "]"
            else
                info[#info + 1] = "Current Vehicle: N/A"
            end
		end

        if tFeature["vehicleGear"].on then
            if ped.is_ped_in_any_vehicle(player.player_ped()) then
                local veh = player.player_vehicle()
                local currentGear = vehicle.get_vehicle_current_gear(veh)

                if currentGear == 0 then
                    currentGear = "Reverse"
                end

			    info[#info + 1] = "Vehicle Gear: " .. currentGear
            else
                info[#info + 1] = "Vehicle Gear: N/A"
            end
		end

        if tFeature["vehicleRPM"].on then
            if ped.is_ped_in_any_vehicle(player.player_ped()) then
                info[#info + 1] = "Vehicle RPM: " .. math.floor(vehicle.get_vehicle_rpm(player.player_vehicle()) * 10000)
            else
                info[#info + 1] = "Vehicle RPM: N/A"
            end
        end

        if tFeature["currentSpeed"].on then
            if ped.is_ped_in_any_vehicle(player.player_ped()) then
                local veh = ped.get_vehicle_ped_is_using(player.player_ped())
                CurrentSpeed = entity.get_entity_speed(veh)
            else
                CurrentSpeed = entity.get_entity_speed(player.player_ped())
            end

			if vFeature["currentSpeedType"].value == 1 then --KPH
                CurrentSpeed = CurrentSpeed * 3.6
            elseif vFeature["currentSpeedType"].value == 2 then --MPH
                CurrentSpeed = CurrentSpeed * 2.236936
            end

            info[#info + 1] = "Current Speed: " .. math.floor(CurrentSpeed + 0.5) .. " " .. vFeature["currentSpeedType"].str_data[vFeature["currentSpeedType"].value+1]    
		end

		if tFeature["gameTime"].on then
			info[#info + 1] = "Game Time: " .. time.get_clock_hours() .. ":" .. time.get_clock_minutes() .. ":" .. time.get_clock_seconds()
		end
		if tFeature["computerTime"].on then
			if vFeature["computerTimeFormat"].value == 1 then
				info[#info + 1] = "Computer Time: " .. os.date("%H:%M:%S")
			else
				info[#info + 1] = "Computer Time: " .. os.date("%I:%M:%S %p")
			end
		end

		if tFeature["computerDate"].on then
			if vFeature["computerDateFormat"].value == 0 then
				info[#info + 1] = "Computer Date: " .. os.date("%d/%m/%y")
			elseif vFeature["computerDateFormat"].value == 1 then
				info[#info + 1] = "Computer Date: " .. os.date("%x")
			elseif vFeature["computerDateFormat"].value == 2 then
				info[#info + 1] = "Computer Date: " .. os.date("%A, %d %B %Y")
			end
		end

		if tFeature["entityCounts"].on then
			if vFeature["entityCountsFormat"].value == 1 then
				info[#info + 1] = "Loaded Entities: Peds: " .. #ped.get_all_peds() .. " | Vehicles: " .. #vehicle.get_all_vehicles() .. " | Objects: " .. #object.get_all_objects() .. " | Pickups: " .. #object.get_all_pickups()
			else
				info[#info + 1] = "Loaded Entities:\n\tPeds: " .. #ped.get_all_peds() .. "\n\tVehicles: " .. #vehicle.get_all_vehicles() .. "\n\tObjects: " .. #object.get_all_objects() .. "\n\tPickups: " .. #object.get_all_pickups()
			end
		end

		if tFeature["closestPlayer"].on then
            local playerPos = player.get_player_coords(player.player_id())
            local closestPlayer = -1
            local closestDistance = 999999
        
            for pid = 0, 31 do
                if player.is_player_valid(pid) and pid ~= player.player_id() then
                    local otherPlayerPos = player.get_player_coords(pid)
                    local distance = playerPos:magnitude(otherPlayerPos)
        
                    if distance < closestDistance then
                        closestPlayer = pid
                        closestDistance = math.floor(distance)
                    end
                end
            end
        
            local playername = "No Players Found"
            if closestPlayer ~= -1 then
                playername = player.get_player_name(closestPlayer) or "No Players Found"
            end
        
            info[#info + 1] = string.format("Closest Player: %s (%dm)", playername, closestDistance)
        end

        if tFeature["furthestPlayer"].on then
            local playerPos = player.get_player_coords(player.player_id())
            local furthestPlayer = -1
            local furthestDistance = -1
        
            for pid = 0, 31 do
                if player.is_player_valid(pid) and pid ~= player.player_id() then
                    local otherPlayerPos = player.get_player_coords(pid)
                    local distance = playerPos:magnitude(otherPlayerPos)
        
                    if distance > furthestDistance then
                        furthestPlayer = pid
                        furthestDistance = math.floor(distance)
                    end
                end
            end
        
            local playerName = "No Players Found"
            if furthestPlayer ~= -1 then
                playerName = player.get_player_name(furthestPlayer) or "No Players Found"
            end
        
            info[#info + 1] = string.format("Furthest Player: %s (%dm)", playerName, furthestDistance)
        end
        
		if tFeature["currentPosition"].on then
			if vFeature["currentPositionFormat"].value == 1 then
				info[#info + 1] = string.format("Current Position: X: %.3f | Y: %.3f | Z: %.3f", playercoords.x, playercoords.y, playercoords.z)
			else
				info[#info + 1] = string.format("Current Position:\n\tX: %.3f\n\tY: %.3f\n\tZ: %.3f", playercoords.x, playercoords.y, playercoords.z)
			end
		end

        if tFeature["currentDirection"].on then
            local playerHeading = player.get_player_heading(player.player_id())

            local directions = {
                "North", "North-Northeast", "Northeast", "East-Northeast",
                "East", "East-Southeast", "Southeast", "South-Southeast",
                "South", "South-Southwest", "Southwest", "West-Southwest",
                "West", "West-Northwest", "Northwest", "North-Northwest"
            }
        
            local headingNormalized = playerHeading % 360
            if headingNormalized < 0 then
                headingNormalized = 360 + headingNormalized
            end
        
            local index = math.floor((headingNormalized + 11.25) / 22.5) + 1
            if index > #directions then
                index = 1
            end
        
            local compassDirection = directions[index]
        
            info[#info + 1] = string.format("Heading: %.0f (%s)", playerHeading, compassDirection)
		end

		if tFeature["currentStreet"].on then
            if isTrusted then
                local streetInfo = {name = "", xRoad = ""}
                local streetName = native.ByteBuffer8()
                local crossingRoad = native.ByteBuffer8()
        
                native.call(0x2EB41072B4C1E4C0, playercoords.x, playercoords.y, playercoords.z, streetName, crossingRoad)
                streetInfo.name = native.call(0xD0EF8A959B8A4CB9, streetName:__tointeger()):__tostring(true)
                streetInfo.xRoad = native.call(0xD0EF8A959B8A4CB9, crossingRoad:__tointeger()):__tostring(true)
        
                if tFeature["displayCrossroads"].on and streetInfo.xRoad ~= "" then
                    info[#info + 1] = "Current Street: " .. streetInfo.name .. " (Intersecting With: " .. streetInfo.xRoad .. ")"
                else
                    info[#info + 1] = "Current Street: " .. streetInfo.name
                end
            end
        end

		if tFeature["interiorID"].on then
			info[#info + 1] = "Interior ID: " .. interior.get_interior_from_entity(player.player_ped())
		end

        local flags = 0
		if tFeature["textShadow"].on then
			flags = flags | 1 << 1
		end
		if vFeature["textAlignment"].value == 1 or vFeature["textAlignment"].value == 3 then
			flags = flags | 1 << 4
		end
		if vFeature["textAlignment"].value == 2 or vFeature["textAlignment"].value == 3 then
			flags = flags | 1 << 3
		end
        
		local pos = v2(scriptdraw.pos_pixel_to_rel_x(vFeature["overlayXPosition"].value), scriptdraw.pos_pixel_to_rel_y(vFeature["overlayYPosition"].value))
		local color = RGBAToInt(vFeature["red"].value, vFeature["green"].value, vFeature["blue"].value, vFeature["alpha"].value)
		scriptdraw.draw_text(table.concat(info, "\n"), pos, v2(1, 1), vFeature["textScale"].value, color, flags, vFeature["textFont"].value)
		system.wait()
	end
end)

local displayOptions = menu.add_feature("Displayable Options", "parent", mainParent.id)
    tFeature["calculatedFPS"] = menu.add_feature("Calculated FPS", "toggle", displayOptions.id)
    tFeature["currentSessionType"] = menu.add_feature("Current Session Type", "toggle", displayOptions.id)
    tFeature["sessionHiddenStatus"] = menu.add_feature("Session Hidden Status", "toggle", displayOptions.id)
    tFeature["currentSessionHost"] = menu.add_feature("Current Session Host", "toggle", displayOptions.id)
    tFeature["nextSessionHost"] = menu.add_feature("Next Session Host", "toggle", displayOptions.id)
    tFeature["currentScriptHost"] = menu.add_feature("Current Script Host", "toggle", displayOptions.id)
    tFeature["currentPlayerCount"] = menu.add_feature("Current Player Count", "toggle", displayOptions.id)

    local extraPlayerCounts = menu.add_feature("Additional Player Counts", "parent", displayOptions.id)
        tFeature["aliveDeadCount"] = menu.add_feature("Alive and Dead", "toggle", extraPlayerCounts.id)
        tFeature["modders"] = menu.add_feature("Modders", "toggle", extraPlayerCounts.id)
        tFeature["friends"] = menu.add_feature("Friends", "toggle", extraPlayerCounts.id)
        tFeature["spectators"] = menu.add_feature("Spectators", "toggle", extraPlayerCounts.id)
        tFeature["godmodePlayers"] = menu.add_feature("In Godmode", "toggle", extraPlayerCounts.id)
        tFeature["vehicleGodmodePlayers"] = menu.add_feature("Has Vehicle Godmode", "toggle", extraPlayerCounts.id)
        tFeature["isInVehicle"] = menu.add_feature("Is In A Vehicle", "toggle", extraPlayerCounts.id)
        tFeature["inInterior"] = menu.add_feature("In An Interior", "toggle", extraPlayerCounts.id)
        tFeature["inCutscene"] = menu.add_feature("In An Cutscene", "toggle", extraPlayerCounts.id)
        tFeature["isTalking"] = menu.add_feature("Is Talking", "toggle", extraPlayerCounts.id)
        
    tFeature["currentHealth"] = menu.add_feature("Current Health", "toggle", displayOptions.id)
    tFeature["currentArmor"] = menu.add_feature("Current Armor", "toggle", displayOptions.id)
    tFeature["wantedLevel"] = menu.add_feature("Wanted Level", "toggle", displayOptions.id)
    tFeature["currentTargetingMode"] = menu.add_feature("Current Targeting Mode", "toggle", displayOptions.id) 
    tFeature["vehicleInformation"] = menu.add_feature("Vehicle Info", "toggle", displayOptions.id)
    tFeature["vehicleGear"] = menu.add_feature("Vehicle Gear", "toggle", displayOptions.id)
    tFeature["vehicleRPM"] = menu.add_feature("Vehicle RPM", "toggle", displayOptions.id)
    tFeature["currentSpeed"] = menu.add_feature("Current Speed", "toggle", displayOptions.id)
    tFeature["gameTime"] = menu.add_feature("Game Time", "toggle", displayOptions.id)
    tFeature["computerTime"] = menu.add_feature("Computer Time", "toggle", displayOptions.id)
    tFeature["computerDate"] = menu.add_feature("Computer Date", "toggle", displayOptions.id)
    tFeature["entityCounts"] = menu.add_feature("Entity Counts", "toggle", displayOptions.id)
    tFeature["closestPlayer"] = menu.add_feature("Closest Player", "toggle", displayOptions.id)
    tFeature["furthestPlayer"] = menu.add_feature("Furthest Player", "toggle", displayOptions.id)
    tFeature["currentPosition"] = menu.add_feature("Current Position", "toggle", displayOptions.id)
    tFeature["currentDirection"] = menu.add_feature("Current Direction", "toggle", displayOptions.id)
    tFeature["currentStreet"] = menu.add_feature("Current Street", "toggle", displayOptions.id)
    tFeature["interiorID"] = menu.add_feature("Interior ID", "toggle", displayOptions.id)
    

local settingsParent = menu.add_feature("Settings", "parent", mainParent.id)
    local displayFeatureSettings = menu.add_feature("Display Feature Settings", "parent", settingsParent.id)
        vFeature["currentSpeedType"] = menu.add_feature("Speed Measurement", "action_value_str", displayFeatureSettings.id)
        vFeature["currentSpeedType"]:set_str_data({"m/s", "kp/h", "mph"})
        vFeature["computerTimeFormat"] = menu.add_feature("Computer Time Format", "action_value_str", displayFeatureSettings.id)
        vFeature["computerTimeFormat"]:set_str_data({"12 Hour", "24 Hour"})
        vFeature["computerDateFormat"] = menu.add_feature("Computer Date Format", "action_value_str", displayFeatureSettings.id)
        vFeature["computerDateFormat"]:set_str_data({"DD/MM/YY", "MM/DD/YY", "Full Date"})
        vFeature["currentPositionFormat"] = menu.add_feature("Current Position Format", "action_value_str", displayFeatureSettings.id)
        vFeature["currentPositionFormat"]:set_str_data({"Vertical", "Horizontal"})
        vFeature["entityCountsFormat"] = menu.add_feature("Entity Counts Format", "action_value_str", displayFeatureSettings.id)
        vFeature["entityCountsFormat"]:set_str_data({"Vertical", "Horizontal"})
        tFeature["displayCrossroads"] = menu.add_feature("Street Info: Display Intersecting Roads", "toggle", displayFeatureSettings.id)

    local colorsParent = menu.add_feature("Overlay Colors", "parent", settingsParent.id)
        vFeature["red"] = menu.add_feature("Red", "autoaction_value_i", colorsParent.id)
        vFeature["red"].min = 0
        vFeature["red"].max = 255
        vFeature["red"].value = 255
        
        vFeature["green"] = menu.add_feature("Green", "action_value_i", colorsParent.id)
        vFeature["green"].min = 0
        vFeature["green"].max = 255
        vFeature["green"].value = 255

        vFeature["blue"] = menu.add_feature("Blue", "action_value_i", colorsParent.id)
        vFeature["blue"].min = 0
        vFeature["blue"].max = 255
        vFeature["blue"].value = 255
        
        vFeature["alpha"] = menu.add_feature("Alpha", "action_value_i", colorsParent.id)
        vFeature["alpha"].min = 0
        vFeature["alpha"].max = 255
        vFeature["alpha"].value = 255

    local positionFormatSettings = menu.add_feature("Postion / Formatting", "parent", settingsParent.id)
        vFeature["overlayXPosition"] = menu.add_feature("Overlay X Position", "action_value_i", positionFormatSettings.id)
        vFeature["overlayXPosition"].min = 0
        vFeature["overlayXPosition"].max = graphics.get_screen_width()
        vFeature["overlayXPosition"].value = 10

        vFeature["overlayYPosition"] = menu.add_feature("Overlay Y Position", "action_value_i", positionFormatSettings.id)
        vFeature["overlayYPosition"].min = 0
        vFeature["overlayYPosition"].max = graphics.get_screen_height()
        vFeature["overlayYPosition"].value = 10

        vFeature["textAlignment"] = menu.add_feature("Text Alignment", "action_value_str", positionFormatSettings.id)
        vFeature["textAlignment"]:set_str_data({"Top Left", "Top Right", "Bottom Left", "Bottom Right"})

        vFeature["textScale"] = menu.add_feature("Text Scale", "action_value_f", positionFormatSettings.id)
        vFeature["textScale"].min = 0.1
        vFeature["textScale"].max = 5
        vFeature["textScale"].mod = 0.1
        vFeature["textScale"].value = 0.80

        tFeature["textShadow"] = menu.add_feature("Text Shadow", "toggle", positionFormatSettings.id)

        vFeature["textFont"] = menu.add_feature("Text Font", "action_value_str", positionFormatSettings.id)
        vFeature["textFont"]:set_str_data({"Menu Head", "Menu Tab", "Menu Entry", "Menu Foot", "Script 1", "Script 2", "Script 3", "Script 4", "Script 5"})

-- Feature Hints.
tFeature["enableOverlay"].hint = "Enables the overlay.\nOptions to be displayed can be enabled in the 'Displayable Options' submenu."
displayOptions.hint = "A submenu containing all the available options to be displayed in the overlay."
tFeature["calculatedFPS"].hint = "Displays your games current calculated FPS (Frames Per Second)."
tFeature["currentSessionType"].hint = "Displays the current session type.\nSingle Player / Public / Invite Only / Friends Only / Crew Only / Solo"
tFeature["sessionHiddenStatus"].hint = "Displays if the session has been hidden or not."
tFeature["currentSessionHost"].hint = "Displays who the current Session Host is."
tFeature["nextSessionHost"].hint = "Displays who the next Session Host will be."
tFeature["currentScriptHost"].hint = "Displays the current Script Host."
tFeature["currentPlayerCount"].hint = "Displays how many players are currently in the session."

extraPlayerCounts.hint = "Additional player related counts to display."
    tFeature["aliveDeadCount"].hint = "Displays the amount of players who are alive and the amount of players who are dead."
    tFeature["modders"].hint = "Displays the amount of modders detected in the session."
    tFeature["friends"].hint = "Displays the amount of social club friends in the session."
    tFeature["spectators"].hint = "Displays the amount of players who are spectating someone."
    tFeature["godmodePlayers"].hint = "Displays the amount of players who are in god mode."
    tFeature["vehicleGodmodePlayers"].hint = "Displays the amount of players whose vehicle have god mode."
    tFeature["isInVehicle"].hint = "Displays the amount of players currently in a vehicle."
    tFeature["inInterior"].hint = "Displays the amount of players who are in an interior."
    tFeature["inCutscene"].hint = "Displays the amount of players who are watching a cutscene."
    tFeature["isTalking"].hint = "Displays the amount of players talking via Voice Chat."

tFeature["currentHealth"].hint = "Displays your current and maximum health values."
tFeature["currentArmor"].hint = "Displays your current and maximum Armor values."
tFeature["wantedLevel"].hint = "Displays your current wanted level."
tFeature["currentTargetingMode"].hint = "Displays your currently set targeting mode."
tFeature["vehicleInformation"].hint = "Displays information about your current vehicle."
tFeature["vehicleGear"].hint = "Displays what gear the vehicle transmission is in."
tFeature["vehicleRPM"].hint = "Displays the vehicle's engine RPM according to the game. It is not accurate."
tFeature["currentSpeed"].hint = "Shows you how fast you are moving."
tFeature["gameTime"].hint = "Displays the current in game time."
tFeature["computerTime"].hint = "Displays the time set on your computer."
tFeature["computerDate"].hint = "Displays the date set on your computer."
tFeature["entityCounts"].hint = "Displays how many of each entity type has been loaded by your client, much like 2take1's default information overlay."
tFeature["closestPlayer"].hint = "Displays the name of the closest player to your position and how far away they are."
tFeature["furthestPlayer"].hint = "Displays the name of the furthest player to your position and how far away they are."
tFeature["currentPosition"].hint = "Displays your current XYZ Coordinates."
tFeature["currentStreet"].hint = "Displays the current street you are on."
tFeature["interiorID"].hint = "Displays the ID for the interior you are currently in (displays '0' if you are outside)."
tFeature["currentDirection"].hint = "Displays your current heading (direction you are facing)."
vFeature["textFont"].hint = "Matches the overlay font to the selected menu UI element.\n\nTo set a custom font, go to [Local > Settings > Menu UI > Fonts], change one of them such as script 5 to your desired font, then come back to this feature and change it until it matches script 5 (or whatever one you decided on)."

menu.add_feature("Save Settings", "action", settingsParent.id, function(f)
    for k, v in pairs(tFeature) do
        INI:set_b("Toggles", k, v.on)
    end
    for k, v in pairs(vFeature) do
        INI:set_f("Values", k, v.value)
    end
    INI:write()
	menu.notify("Settings Saved", "Toph's Overlay", 7, 0xFF00FF00)
end)

-- Load saved settings on script load:
if INI:read() then
    for k, v in pairs(tFeature) do
        local exists, val = INI:get_b("Toggles", k)
        if exists then
            v.on = val
        end
    end

    for k, v in pairs(vFeature) do
        local exists, val = INI:get_f("Values", k)
        if exists then
            v.value = val
        end
    end
end
