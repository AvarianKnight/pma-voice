RegisterNetEvent('pma-voice:syncRadioData')
AddEventHandler('pma-voice:syncRadioData', function(radioTable)
    radioData = radioTable
    for tgt, enabled in pairs(radioTable) do
        if tgt ~= playerServerId then
            toggleVoice(tgt, enabled)
            playerTargets(radioData, callData)
        end
    end
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio')
AddEventHandler('pma-voice:setTalkingOnRadio', function(tgt, enabled)
    if tgt ~= playerServerId then
        toggleVoice(tgt, enabled)
        radioData[tgt] = enabled
        playerTargets(radioData, callData)
    end
end)

RegisterNetEvent('pma-voice:addPlayerToRadio')
AddEventHandler('pma-voice:addPlayerToRadio', function(plySource)
    radioData[plySource] = false
    playerTargets(radioData, callData)
end)

RegisterNetEvent('pma-voice:removePlayerFromRadio')
AddEventHandler('pma-voice:removePlayerFromRadio', function(plySource)
    if plySource == playerServerId then 
        radioData = {}
        playerTargets(radioData, callData)
    else
        radioData[plySource] = nil
        playerTargets(radioData, callData)
    end
end)

function setRadioChannel(channel)
    TriggerServerEvent('pma-voice:setPlayerRadio', channel)
    voiceData.radio = channel
end
exports('setRadioChannel', setRadioChannel)
exports('removePlayerFromRadio', function()
    setRadioChannel(0)
end)
exports('addPlayerToRadio', function(radio)
    local radio = tonumber(radio)
    if radio then
        setRadioChannel(radio)
    end
end)