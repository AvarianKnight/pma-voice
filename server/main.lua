voiceData = {}
radioData = {}
callData = {}

function defaultTable(source)
	handleStateBagInitilization(source)
	return {
		radio = 0,
		call = 0,
		lastRadio = 0,
		lastCall = 0
	}
end

function handleStateBagInitilization(source)
	local plyState = Player(source).state
	if not plyState.pmaVoiceInit then 
		plyState:set('radio', GetConvarInt('voice_defaultRadioVolume', 30), true)
		plyState:set('call', GetConvarInt('voice_defaultCallVolume', 60), true)
		plyState:set('submix', nil, true)
		plyState:set('proximity', {}, true)
		plyState:set('callChannel', 0, true)
		plyState:set('radioChannel', 0, true)
		plyState:set('voiceIntent', 'speech', true)
		-- We want to save voice inits because we'll automatically reinitalize calls and channels
		plyState:set('pmaVoiceInit', true, false)
	end
end

CreateThread(function()

	local plyTbl = GetPlayers()
	for i = 1, #plyTbl do
		local ply = tonumber(plyTbl[i])
		voiceData[ply] = defaultTable(plyTbl[i])
	end

	Wait(5000)

	local nativeAudio = GetConvar('voice_useNativeAudio', 'false')
	local _3dAudio = GetConvar('voice_use3dAudio', 'false')
	local _2dAudio = GetConvar('voice_use2dAudio', 'false')
	local sendingRangeOnly = GetConvar('voice_useSendingRangeOnly', 'false')
	local gameVersion = GetConvar('gamename', 'fivem')

	-- handle no convars being set (default drag n' drop)
	if
		nativeAudio == 'false'
		and _3dAudio == 'false'
		and _2dAudio == 'false'
	then
        SetConvarReplicated('voice_useNativeAudio', 'true')
        if sendingRangeOnly == 'false' then
            SetConvarReplicated('voice_useSendingRangeOnly', 'true')
            logger.info('No convars detected for voice mode, defaulting to \'setr voice_useNativeAudio true\' and \'setr voice_useSendingRangeOnly true\'')
        end
	elseif sendingRangeOnly == 'false' then
		logger.warn('It\'s recommended to have \'voice_useSendingRangeOnly\' set to true you can do that with \'setr voice_useSendingRangeOnly true\', this prevents players who directly join the mumble server from broadcasting to players.')
	end

	local radioVolume = GetConvarInt("voice_defaultRadioVolume", 30)
	local callVolume = GetConvarInt("voice_defaultCallVolume", 60)

	-- When casted to an integer these get set to 0 or 1, so warn on these values that they don't work
	if
		radioVolume == 0 or radioVolume == 1 or
		callVolume == 0 or callVolume == 1
	then
		SetConvarReplicated("voice_defaultRadioVolume", 30)
		SetConvarReplicated("voice_defaultCallVolume", 60)
		for i = 1, 5 do
			Wait(5000)
			logger.warn("`voice_defaultRadioVolume` or `voice_defaultCallVolume` have their value set as a float, this is going to automatically be fixed but please update your convars.")
		end
	end
end)

AddEventHandler('playerJoining', function()
	if not voiceData[source] then
		voiceData[source] = defaultTable(source)
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
