local voiceData = {}
local radioData = {}
local callData  = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

AddEventHandler("onResourceStart", function(resName) -- Initialises the script, sets up voice related convars
	if GetCurrentResourceName() ~= resName then return end

    SetConvarReplicated("voice_useNativeAudo", mumbleConfig.useNativeAudio and 1 or 0)
	SetConvarReplicated("voice_use3dAudio", 1)	
	SetConvarReplicated("voice_useSendingRangeOnly", 1)	

	local maxChannel = 500

	for i = 1, maxChannel do
		MumbleCreateChannel(i)
    end
    
    print('[pma-voice] Made ' .. maxChannel .. ' channels in mumble')
end)

RegisterNetEvent('pma-voice:registerVoiceInfo')
AddEventHandler('pma-voice:registerVoiceInfo', function()
    voiceData[source] = {
        radio = 0,
        call = 0
    }
end)

function removePlayerFromRadio(source, currentChannel)
    radioData[currentChannel] = radioData[currentChannel] or {}
    for player, _ in pairs(radioData[currentChannel]) do
        TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source)
    end
    radioData[currentChannel][source] = nil
    voiceData[source].radio = 0
end

function addPlayerToRadio(source, channel)
    -- check if the channel exists, if it does set the varaible to it
    -- if not create it (basically if not radiodata make radiodata)
    radioData[channel] = radioData[channel] or {}
    for player, _ in pairs(radioData[channel]) do
        TriggerClientEvent('pma-voice:addPlayerToRadio', player, source)
    end
    voiceData[source].radio = channel
    radioData[channel][source] = false
    TriggerClientEvent('pma-voice:syncRadioData', source, radioData[channel])
end



function setPlayerRadio(source, radioChannel)
    local plyVoice = voiceData[source]
    local radioChannel = tonumber(radioChannel)

    if radioChannel ~= 0 and plyVoice.radio == 0 then
        addPlayerToRadio(source, radioChannel)
    elseif radioChannel == 0 then
        removePlayerFromRadio(source, plyVoice.radio)
    elseif plyVoice.radio > 0 then
        removePlayerFromRadio(source, plyVoice.radio)
        addPlayerToRadio(source, radioChannel)
    end
end
exports('setPlayerRadio', setPlayerRadio)

RegisterNetEvent('pma-voice:setPlayerRadio')
AddEventHandler('pma-voice:setPlayerRadio', function(radioChannel)
    setPlayerRadio(source, radioChannel)
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio')
AddEventHandler('pma-voice:setTalkingOnRadio', function(talking)
    local plyVoice = voiceData[source]
    local radioTbl = radioData[plyVoice.radio]
    if radioTbl then
        for player, _ in pairs(radioTbl) do
            TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, talking)
        end
    end
end)

function removePlayerFromCall(source, currentChannel)
    callData[currentChannel] = callData[currentChannel] or {}
    for player, _ in pairs(callData[currentChannel]) do
        TriggerClientEvent('pma-voice:removePlayerFromCall', player, source)
    end
    callData[currentChannel][source] = nil
    voiceData[source].call = 0
end

function addPlayerToCall(source, channel)
    -- check if the channel exists, if it does set the varaible to it
    -- if not create it (basically if not callData make callData)
    callData[channel] = callData[channel] or {}
    callData[channel][source] = false
    voiceData[source].call = channel
    for player, _ in pairs(callData[channel]) do
        TriggerClientEvent('pma-voice:addPlayerToCall', player, source)
    end
    TriggerClientEvent('pma-voice:syncCallData', source, callData[channel])
end



function setPlayerCall(source, callChannel)
    local plyVoice = voiceData[source]
    local callChannel = tonumber(callChannel)

    if callChannel ~= 0 and plyVoice.call == 0 then
        addPlayerToCall(source, callChannel)
    elseif callChannel == 0 then
        removePlayerFromCall(source, plyVoice.call)
    elseif plyVoice.call > 0 then
        removePlayerFromCall(source, plyVoice.call)
        addPlayerToCall(source, callChannel)
    end
end
exports('setPlayerCall', setPlayerCall)

RegisterNetEvent('pma-voice:setPlayerCall')
AddEventHandler('pma-voice:setPlayerCall', function(callChannel)
    setPlayerCall(source, callChannel)
end)

RegisterNetEvent('pma-voice:setTalkingOnCall')
AddEventHandler('pma-voice:setTalkingOnCall', function(talking)
    local plyVoice = voiceData[source]
    local callTbl = callData[plyVoice.call]
    if callTbl then
        for player, _ in pairs(callTbl) do
            if source ~= player then
                TriggerClientEvent('pma-voice:setTalkingOnCall', player, source, talking)
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local source = source
    if voiceData[source] then
        local plyData = voiceData[source]

        if plyData.radio ~= 0 then
            removePlayerFromRadio(source, plyData.radio)
        end

        if plyData.call ~= 0 then
            removePlayerFromCall(source, plyData.call)
        end

		voiceData[source] = nil
	end
end)
