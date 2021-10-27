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

	local plyTbl = GetPlayers()
	for i = 1, #plyTbl do
		local ply = tonumber(plyTbl[i])
		voiceData[ply] = defaultTable()
	end

	Wait(5000)

	-- handle no convars being set (default drag n' drop)
	if
		GetConvar('voice_useNativeAudio', 'false') == 'false'
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

if GetConvarInt('voice_externalDisallowJoin', 0) == 1 then
	AddEventHandler('playerConnecting', function(_, _, deferral)
		deferral.defer()
		Wait(0)
		deferral.done('This server is not accepting connections.')
	end)
end

-- only meant for internal use so no documentation
function isValidPlayer(source)
	return voiceData[source]
end
exports('isValidPlayer', isValidPlayer)

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