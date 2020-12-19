RegisterNetEvent('pma-voice:syncCallData')
AddEventHandler('pma-voice:syncCallData', function(callTable)
    callData = callTable
    for tgt, enabled in pairs(callTable) do
        if tgt ~= playerServerId then
            toggleVoice(tgt, enabled)
            playerTargets(radioData, callData)
        end
    end
end)

RegisterNetEvent('pma-voice:setTalkingOnCall')
AddEventHandler('pma-voice:setTalkingOnCall', function(tgt, enabled)
    if tgt ~= playerServerId then
        toggleVoice(tgt, enabled)
        callData[tgt] = enabled
        playerTargets(radioData, callData)
    end
end)

RegisterNetEvent('pma-voice:addPlayerToCall')
AddEventHandler('pma-voice:addPlayerToCall', function(plySource)
    callData[plySource] = false
    playerTargets(radioData, callData)
end)

RegisterNetEvent('pma-voice:removePlayerFromCall')
AddEventHandler('pma-voice:removePlayerFromCall', function(plySource)
    if plySource == playerServerId then
        for tgt, enabled in pairs(callData) do
            if tgt ~= playerServerId then
                toggleVoice(tgt, false)
            end
        end
        callData = {}
        playerTargets(radioData, callData)
    else
        callData[plySource] = nil
        playerTargets(radioData, callData)
        toggleVoice(plySource, false)
    end
end)

function setCallChannel(channel)
    TriggerServerEvent('pma-voice:setPlayerCall', channel)
	voiceData.call = channel
	if Cfg.enableUi then
		SendNUIMessage({
			callInfo = channel
		})
	end
    Citizen.CreateThread(function()
        while voiceData.call ~= 0 do
            -- check if they're pressing voice keybinds
            if IsControlJustPressed(0, 249) or IsControlJustPressed(1, 249) or IsControlJustPressed(2, 249) then
                TriggerServerEvent('pma-voice:setTalkingOnCall', true)
            elseif IsControlJustReleased(0, 249) or IsControlJustReleased(1, 249) or IsControlJustReleased(2, 249) then
                TriggerServerEvent('pma-voice:setTalkingOnCall', false)
            end
            Citizen.Wait(0)
        end
    end)
end

exports('setCallChannel', setCallChannel)
exports('addPlayerToCall', function(call)
    local call = tonumber(call)
    if call then
        setCallChannel(call)
    end
end)
exports('removePlayerFromCall', function()
    setCallChannel(0)
end)
