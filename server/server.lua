voiceData = {}
radioData = {}
callData = {}

function defaultTable(source)
	return {
		radio = 0,
		call = 0,
		lastRadio = 0,
		lastCall = 0
	}
end

-- temp fix before an actual fix is added
CreateThread(function()
    for i = 1, 1024 do
        MumbleCreateChannel(i)
    end
	Wait(5000)
	if GetConvarInt('voice_zoneRadius', 256) < 256 then
		logger.warn('The convar \'voice_zoneRadius\' is less then 256 (currently %s, recommended is 256).', GetConvarInt('voice_zoneRadius', 256))
	end

	-- handle no convars being set
	if GetConvar('voice_useNativeAudio', 'false') == 'false' and GetConvar('voice_use3dAudio', 'false') == 'false' and GetConvar('voice_use2dAudio', 'false') == 'false' then
		SetConvarReplicated('voice_useNativeAudio', 'true')
		if GetConvar('voice_useSendingRangeOnly', 'false') == 'false' then
			SetConvarReplicated('voice_useSendingRangeOnly', 'true')
		end
		logger.warn('No convars detected for voice mode, defaulting to \'setr voice_useNativeAudio true\' and \'setr voice_useSendingRangeOnly true\'')
	elseif GetConvar('voice_useSendingRangeOnly', 'false') == 'false' then
		logger.warn('It\'s recommended to have \'voice_useSendingRangeOnly\' set to true you can do that with \'setr voice_useSendingRangeOnly true\', this prevents players who directly join the mumble server from broadcasting to players.')
	end
end)

RegisterNetEvent('playerJoined', function()
	if not voiceData[source] then
		voiceData[source] = defaultTable(source)
		local plyState = Player(source).state
		plyState:set('routingBucket', 0, true)
		if GetConvarInt('voice_syncData', 0) == 1 then
			plyState:set('radio', tonumber(GetConvar('voice_defaultVolume', '0.3')), true)
			plyState:set('phone', tonumber(GetConvar('voice_defaultVolume', '0.3')), true)
			plyState:set('proximity', {}, true)
			plyState:set('callChannel', 0, true)
			plyState:set('radioChannel', 0, true)
		end
	end
end)

--- update/sets the players routing bucket
---@param source number the player to update/set
---@param routingBucket number the routing bucket to set them to
function updateRoutingBucket(source, routingBucket)
	local route
	-- make it optional to provide the routing bucket just incase 
	-- people use another resource to manage their routing buckets.
	if routingBucket then
		SetPlayerRoutingBucket(source, routingBucket)
	else
		route = GetPlayerRoutingBucket(source)
	end
	Player(source).state:set('routingBucket', route or routingBucket, true)
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

AddEventHandler('onResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	if GetConvar('onesync') == 'on' then
		local players = GetPlayers()
		for i = 1, #players do
			local ply = players[i]
			if not voiceData[ply] then
				voiceData[ply] = defaultTable(ply)
				Player(ply).state:set('routingBucket', GetPlayerRoutingBucket(ply), true)
			end
		end
	end
end)

RegisterCommand('mute', function(source, args)
	local mutePly = tonumber(args[1])
	if mutePly then
		if voiceData[mutePly] then
			TriggerClientEvent('pma-voice:toggleMute', mutePly)
		end
	end
end, true)

if GetConvarInt('voice_externalDisallowJoin', 0) == 1 then
	AddEventHandler('playerConnecting', function(playerName, kickReason, deferral)
		deferral.defer()
		Wait(0)
		deferral.done('This server is not accepting connections.')
	end)
end


function getPlayersInRadioChannel(channel)
	local returnChannel = radioData[channel]
	if returnChannel then
		return returnChannel
	end
	-- channel doesnt exist
	return {}
end
exports('getPlayersInRadioChannel', getPlayersInRadioChannel)
exports('GetPlayersInRadioChannel', getPlayersInRadioChannel)