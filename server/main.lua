voiceData = {}
radioData = {}
callData = {}

function defaultTable()
	return {
		radio = 0,
		call = 0,
		lastRadio = 0,
		lastCall = 0
	}
end

-- temp fix before an actual fix is added
Citizen.CreateThreadNow(function()
	Wait(5000)

	-- handle no convars being set (default drag n' drop)
	if GetConvar('voice_useNativeAudio', 'false') == 'false'
		and GetConvar('voice_use3dAudio', 'false') == 'false'
		and GetConvar('voice_use2dAudio', 'false') == 'false'
	then
		SetConvarReplicated('voice_useNativeAudio', 'true')
		if GetConvar('voice_useSendingRangeOnly', 'false') == 'false' then
			SetConvarReplicated('voice_useSendingRangeOnly', 'true')
		end
		logger.info('No convars detected for voice mode, defaulting to \'setr voice_useNativeAudio true\' and \'setr voice_useSendingRangeOnly true\'')
	elseif GetConvar('voice_useSendingRangeOnly', 'false') == 'false' then
		logger.warn('It\'s recommended to have \'voice_useSendingRangeOnly\' set to true you can do that with \'setr voice_useSendingRangeOnly true\', this prevents players who directly join the mumble server from broadcasting to players.')
	end

	-- we don't ever want this warning to stop, people will complain that 'pma-voice isn't working!'
	-- when its only compatiable with OneSync & OneSync Legacy
	if GetConvar('onesync') == 'off' then
		while true do
			logger.warn("OneSync was not detected, pma-voice will not work without OneSync, if you are on OneSync please use the 'onesync' variable as defined here: https://docs.fivem.net/docs/server-manual/server-commands/#onesync-onofflegacy")
			Wait(5000)
		end
	end
end)

AddEventHandler('playerJoined', function()
	if not voiceData[source] then
		voiceData[source] = defaultTable()
		local plyState = Player(source).state
		if GetConvarInt('voice_syncData', 1) == 1 then
			plyState:set('radio', tonumber(GetConvar('voice_defaultVolume', '0.3')), true)
			plyState:set('phone', tonumber(GetConvar('voice_defaultVolume', '0.3')), true)
			plyState:set('proximity', {}, true)
			plyState:set('callChannel', 0, true)
			plyState:set('radioChannel', 0, true)
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

AddEventHandler('onResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	if GetConvar('onesync') == 'on' then
		local players = GetPlayers()
		for i = 1, #players do
			local ply = tonumber(players[i])
			if not voiceData[ply] then
				voiceData[ply] = defaultTable()
				Player(ply).state:set('routingBucket', GetPlayerRoutingBucket(ply), true)
			end
		end
	end
end)

RegisterCommand('mute', function(_, args)
	local mutePly = tonumber(args[1])
	if mutePly then
		if voiceData[mutePly] then
			TriggerClientEvent('pma-voice:toggleMute', mutePly)
		end
	end
end, true)

if GetConvarInt('voice_externalDisallowJoin', 0) == 1 then
	AddEventHandler('playerConnecting', function(_, _, deferral)
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