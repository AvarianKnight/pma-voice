if gameVersion == 'fivem' and GetConvarInt('voice_enableSubmix', 1) == 1 and GetConvarInt("voice_enableAudioOcclusion", 1) == 1 then
    local disabledAudioOcclusion = {}
    local muffledPlayers = {}

    local audioOcclusionEnabled = GetConvarInt("voice_enableAudioOcclusion", 1) == 1

    -- was not done with the internal submix modules since we still have to preserve the calculation of distances, which the "toggleVoice" function overrides
    local audioOcclusionSubmix = CreateAudioSubmix('audioOcclusion')
    SetAudioSubmixEffectRadioFx(audioOcclusionSubmix, 0)
    SetAudioSubmixEffectParamInt(audioOcclusionSubmix, 0, `default`, 1)
    SetAudioSubmixEffectParamFloat(audioOcclusionSubmix, 0, `freq_low`, 0.0)
    SetAudioSubmixEffectParamFloat(audioOcclusionSubmix, 0, `freq_hi`, 850.0)
    SetAudioSubmixEffectParamFloat(audioOcclusionSubmix, 0, `rm_mix`, 0.00)
    SetAudioSubmixEffectParamFloat(audioOcclusionSubmix, 0, `o_freq_lo`, 0.0)
    SetAudioSubmixEffectParamFloat(audioOcclusionSubmix, 0, `o_freq_hi`, 850.0)
    AddAudioSubmixOutput(audioOcclusionSubmix, 0)
   
    RaycastHitSomething = function(coords, coords2, flags, ignore)
        local rayHandle = StartShapeTestLosProbe(coords, coords2, flags, ignore)
        local code, hit = GetShapeTestResult(rayHandle)
        
        while code == 1 do
            code, hit = GetShapeTestResult(rayHandle)
            Citizen.Wait(1)
        end
    
        return hit == 1
    end
    
    ExpensiveLosCheck = function(entity1, entity2, flags)
        local coords1 = GetEntityCoords(entity1)
        local coords2 = GetEntityCoords(entity2)
        local center = RaycastHitSomething(coords1, coords2, flags, entity1)
        local losCheckOffset = tonumber(GetConvar("voice_audioOcclusionExpensiveCheckOffset", "0.5")) -- we convert string to number to allow floats

        -- we do one check at a time to limit the raycasts performed as much as possible
        if center then
            local leftCoords = GetOffsetFromEntityInWorldCoords(entity1, losCheckOffset, 0.0, 0.0)
            local left = RaycastHitSomething(leftCoords, coords2, flags, entity1)
            
            if left then
                local rightCoords = GetOffsetFromEntityInWorldCoords(entity1, -losCheckOffset, 0.0, 0.0)
                local right = RaycastHitSomething(rightCoords, coords2, flags, entity1)
                
                if right then
                    local topCoords = GetOffsetFromEntityInWorldCoords(entity1, 0.0, 0.0, losCheckOffset)
                    local top = RaycastHitSomething(topCoords, coords2, flags, entity1)
    
                    if top then
                        return false -- If all 4 raycasts fail (center, left, right, top) then it means that there is probably a large enough object that is blocking
                    end
                end
            end
        end
    
        return true
    end
    
    DoInteriorChecks = function(interior, currentPlayerRoom, playerRoom, currentPlayer, player)
        local roomCount = GetInteriorRoomCount(interior) - 1
                            
        if roomCount > 1 then
            if currentPlayerRoom ~= playerRoom and not HasEntityClearLosToEntity(currentPlayer, player, 17) then -- If the players are in different rooms and the 2 players cannot see each other (this prevent audio occlusion when opening a door)
                return true
            else
                return false
            end
        else
            if GetConvarInt("voice_audioOcclusionLight", 0) == 1 then
                return not HasEntityClearLosToEntity(currentPlayer, player, 17)
            else
                -- If there are no rooms inside the interior (poorly made interiors or single rooms) 
                -- we shoot 4 beams from the current player to the other player to not perform audio occlusion even when there is only one pillar blocking the two players. 
                return not ExpensiveLosCheck(currentPlayer, player, 17)
            end
        end
    end
    
    DoVehicleChecks = function(player)
        local vehicle = GetVehiclePedIsIn(player)
    
        if vehicle > 0 and DoesVehicleHaveRoof(vehicle) then
            local doors = GetNumberOfVehicleDoors(vehicle)
    
            for i=0, 6 do
                if DoesVehicleHaveDoor(vehicle, i) then
                    if IsVehicleDoorDamaged(vehicle, i) or IsVehicleDoorFullyOpen(vehicle, i) or GetVehicleDoorAngleRatio(vehicle, i) > 0.0 then
                        return false
                    end
                end
            end
            
            if AreAllVehicleWindowsIntact(vehicle) then
                return true
            end
            
            return false
        else
            return false
        end
    end

    Citizen.CreateThread(function()
        local voiceRange = GetConvar('voice_useNativeAudio', 'false') == 'true' and proximity * 3 or proximity
    
        while true do
            muffledPlayers = {}

            if audioOcclusionEnabled then
                local player = PlayerPedId()
                local playerRoom = GetRoomKeyFromEntity(player)
                local players = GetActivePlayers()
        
                if #players > 1 then
                    for k,v in ipairs(players) do
                        local otherPlayer = GetPlayerPed(v)
                        
                        if player ~= otherPlayer then
                            local needToCheck, distance = addProximityCheck(v)
    
                            if needToCheck then
                                local interior = GetInteriorFromEntity(otherPlayer)
                                local playerServerId = GetPlayerServerId(v)
                                local audioOcclusion = nil

                                if interior > 0 and not disabledAudioOcclusion[interior] and GetConvarInt("voice_enableInteriorsAudioOcclusion", 1) == 1 then
                                    local otherPlayerRoom = GetRoomKeyFromEntity(otherPlayer)
                                    
                                    audioOcclusion = DoInteriorChecks(interior, playerRoom, otherPlayerRoom, otherPlayer, player)
                                else
                                    if GetConvarInt("voice_enableVehicleAudioOcclusion", 1) == 1 then
                                        audioOcclusion = DoVehicleChecks(otherPlayer)
                                    end
                                end

                                if audioOcclusion then
                                    muffledPlayers[playerServerId] = true
                                    MumbleSetSubmixForServerId(playerServerId, audioOcclusionSubmix)
                                else
                                    muffledPlayers[playerServerId] = nil
                                    MumbleSetSubmixForServerId(playerServerId, -1)
                                end
                            end
                        end
                    end
                end
            end

            Citizen.Wait(GetConvarInt('voice_audioOcclusionRefreshRate', 500))
        end
    end)
    
    exports("setAudioOcclusion", function(active)
        for id,v in pairs(muffledPlayers) do
            MumbleSetSubmixForServerId(id, -1)
        end

        audioOcclusionEnabled = active
    end)

    exports("getMuffledPlayers", function()
        return muffledPlayers
    end)

    exports("isPlayerMuffled", function(serverId)
        return muffledPlayers[serverId]
    end)
    
    exports("setInteriorAudioOcclusionDisabled", function(interior, active)
        disabledAudioOcclusion[interior] = active
    end)

    exports("isInteriorAudioOcclusionDisabled", function(interiorId)
        return disabledAudioOcclusion[interior] == true
    end)

    exports("getInteriorsWithDisabledAudioOcclusion", function()
        return disabledAudioOcclusion
    end)
end