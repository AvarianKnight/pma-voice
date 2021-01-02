voiceData = {}
radioData = {}
callData = {}

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

AddEventHandler("onResourceStart", function(resName)
    if GetCurrentResourceName() ~= resName then
        return
    end
    -- it was stated that you use one or the other, not both.3
    if Cfg.useNativeAudio then
        SetConvarReplicated("voice_useNativeAudio", 1)
    elseif Cfg.use3dAudio then
        SetConvarReplicated("voice_use3dAudio", 1)
    end
    SetConvarReplicated("voice_useSendingRangeOnly", 1)
end)

Citizen.CreateThread(function()
    local maxChannel = Cfg.zoneOffset + math.ceil((4500.0 + 8022.00) / (Cfg.zoneRadius * 2)) + 10 -- coat 10 channels just to be safe
    if Cfg.enableRouteSupport then
        maxChannel = maxChannel + (Cfg.maxRoutingBuckets * 5)
    end

    print('[pma-voice] Creating ' .. maxChannel .. ' channels in mumble')
    for i = 1, maxChannel do
        MumbleCreateChannel(i)
    end
    print('[pma-voice] Made ' .. maxChannel .. ' channels in mumble')
end)

RegisterNetEvent('pma-voice:registerVoiceInfo')
AddEventHandler('pma-voice:registerVoiceInfo', function()
    voiceData[source] = {
        radio = 0,
        call = 0,
        lastRadio = 0,
        lastCall = 0
    }

    if Cfg.enableRouteSupport then
        voiceData[source].routingBucket = 0
        TriggerClientEvent('pma-voice:setRoutingBucket', source, 0)
    end
end)

function updateRoutingBucket(source, routingBucket)
	if routingBucket > Cfg.maxRoutingBuckets then
		print(('[pma-voice] %s tried setting a routing bucket above the max routing buckets!'):format(GetInvokingResource()))
		return
	end
	local route = 0
	-- make it optional to provide the routing bucket just incase 
	-- people use another resource to manage their routing buckets.
	if routingBucket then
		SetPlayerRoutingBucket(source, routingBucket)
		route = routingBucket
	else
		route = GetPlayerRoutingBucket(source)
	end
    voiceData[source].routingBucket = route
    TriggerClientEvent('pma-voice:updateRoutingBucket', source, route)
end
exports('updateRoutingBucket', updateRoutingBucket)

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
