local function createPhoneThread()
    Citizen.CreateThread(function()
        local changed = false
        while voiceData.call ~= 0 do
            -- check if they're pressing voice keybinds
            if NetworkIsPlayerTalking(PlayerId()) and not changed then
                changed = true
                TriggerServerEvent('pma-voice:setTalkingOnCall', true)
            elseif changed and NetworkIsPlayerTalking(PlayerId()) ~= 1 then
                changed = false
                TriggerServerEvent('pma-voice:setTalkingOnCall', false)
            end
            Wait(0)
        end
    end)
end

RegisterNetEvent('pma-voice:syncCallData')
AddEventHandler('pma-voice:syncCallData', function(callTable, channel)
    callData = callTable
    for tgt, enabled in pairs(callTable) do
        if tgt ~= playerServerId then
            toggleVoice(tgt, enabled)
        end
    end
    playerTargets(radioData, callData)
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
        toggleVoice(plySource, false)
        playerTargets(radioData, callData)
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
	createPhoneThread()
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

AddEventHandler('pma-voice:clSetPlayerCall', function(callChannel)
	voiceData.call = callChannel
	createPhoneThread()
end)