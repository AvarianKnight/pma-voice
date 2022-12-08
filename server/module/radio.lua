local radioChecks = {}
local ServerCallbacks = {}

--- checks if the player can join the channel specified
--- @param source number the source of the player
--- @param radioChannel number the channel they're trying to join
--- @return boolean if the user can join the channel
function canJoinChannel(source, radioChannel)
	if radioChecks[radioChannel] then
		return radioChecks[radioChannel](source)
	end
	return true
end

--- adds a check to the channel, function is expected to return a boolean of true or false
---@param channel number the channel to add a check to
---@param cb function the function to execute the check on
function addChannelCheck(channel, cb)
	local channelType = type(channel)
	local cbType = type(cb)
	if channelType ~= "number" then
		error(("'channel' expected 'number' got '%s'"):format(channelType))
	end
	if cbType ~= 'table' or not cb.__cfx_functionReference then
		error(("'cb' expected 'function' got '%s'"):format(cbType))
	end
	radioChecks[channel] = cb
	logger.info("%s added a check to channel %s", GetInvokingResource(), channel)
end
exports('addChannelCheck', addChannelCheck)

local function radioNameGetter_orig(source)
	return GetPlayerName(source)
end
local radioNameGetter = radioNameGetter_orig

--- adds a check to the channel, function is expected to return a boolean of true or false
---@param cb function the function to execute the check on
function overrideRadioNameGetter(channel, cb)
	local cbType = type(cb)
	if cbType == 'table' and not cb.__cfx_functionReference then
		error(("'cb' expected 'function' got '%s'"):format(cbType))
	end
	radioNameGetter = cb
	logger.info("%s added a check to channel %s", GetInvokingResource(), channel)
end
exports('overrideRadioNameGetter', overrideRadioNameGetter)

--- adds a player to the specified radion channel
---@param source number the player to add to the channel
---@param radioChannel number the channel to set them to
function addPlayerToRadio(source, radioChannel, secondary)
	if not canJoinChannel(source, radioChannel) then
		-- remove the player from the radio client side
		return TriggerClientEvent('pma-voice:removePlayerFromRadio', source, source)
	end
	logger.verbose('[radio] Added %s to radio %s', source, radioChannel)

	-- check if the channel exists, if it does set the varaible to it
	-- if not create it (basically if not radiodata make radiodata)
	radioData[radioChannel] = radioData[radioChannel] or {}
	local plyName = radioNameGetter(source)
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:addPlayerToRadio', player, source, radioChannel)
	end
	voiceData[source] = voiceData[source] or defaultTable(source)

	if not secondary then
		voiceData[source].radio = radioChannel
	else
		voiceData[source].secondaryRadio = radioChannel
	end

	radioData[radioChannel][source] = false
	TriggerClientEvent('pma-voice:syncRadioData', source, radioData[radioChannel], secondary)
end

--- removes a player from the specified channel
---@param source number the player to remove
---@param radioChannel number the current channel to remove them from
function removePlayerFromRadio(source, radioChannel, secondary)
	logger.verbose('[radio] Removed %s from radio %s', source, radioChannel)
	radioData[radioChannel] = radioData[radioChannel] or {}
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source, radioChannel)
	end
	radioData[radioChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)

	if not secondary then
		voiceData[source].radio = 0
	else
		voiceData[source].secondaryRadio = 0
	end
end

-- TODO: Implement this in a way that allows players to be on multiple channels
--- sets the players current radio channel
---@param source number the player to set the channel of
---@param _radioChannel number the radio channel to set them to (or 0 to remove them from radios)
function setPlayerRadio(source, _radioChannel, secondary)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local isResource = GetInvokingResource()
	local plyVoice = voiceData[source]
	local radioChannel = tonumber(_radioChannel)
	if not radioChannel then
		-- only full error if its sent from another server-side resource
		if isResource then
			error(("'radioChannel' expected 'number', got: %s"):format(type(_radioChannel))) 
		else
			return logger.warn("%s sent a invalid radio, 'radioChannel' expected 'number', got: %s", source,type(_radioChannel))
		end
	end
	if isResource then
		-- got set in a export, need to update the client to tell them that their radio
		-- changed
		TriggerClientEvent('pma-voice:clSetPlayerRadio', source, radioChannel)
	end

	local state = Player(source).state
	local stateRadio = state.RadioChannel
	local stateSecondaryRadio = state.SecondaryRadioChannel

	if (stateRadio > 0 and stateSecondaryRadio > 0 and (state.RadioChannel or -10) == (state.SecondaryRadioChannel or -20)) then
		return logger.warn("%s tried setting their primary and secondary radio channels to the same channel", source)
	end

	if not secondary then
		state.RadioChannel = radioChannel
	else
		state.SecondaryRadioChannel = radioChannel
	end

	if radioChannel >= 0 and (not secondary and plyVoice.radio or plyVoice.secondaryRadio) < 0 then
		addPlayerToRadio(source, radioChannel, secondary)
	elseif radioChannel < 0 then
		removePlayerFromRadio(source, not secondary and plyVoice.radio or plyVoice.secondaryRadio, secondary)
	elseif (not secondary and plyVoice.radio or plyVoice.secondaryRadio) >= 0 then
		removePlayerFromRadio(source, not secondary and plyVoice.radio or plyVoice.secondaryRadio, secondary)
		addPlayerToRadio(source, radioChannel, secondary)
	end
end
exports('setPlayerRadio', setPlayerRadio)

RegisterNetEvent('pma-voice:setPlayerRadio', function(radioChannel, secondary)
	setPlayerRadio(source, radioChannel, secondary or false)
end)

--- syncs the player talking across all radio members
---@param talking boolean sets if the palyer is talking.
function setNotTalkingOnRadio(secondary)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end

	voiceData[source] = voiceData[source] or defaultTable(source)

	local plyVoice = voiceData[source]
	local radioTbl = radioData[not secondary and plyVoice.radio or plyVoice.secondaryRadio]

	if not radioTbl then return end

	radioTbl[source] = false

	if not secondary then
		plyVoice.secondaryRadio = plyVoice.lastSecondaryRadio

		addPlayerToRadio(source, plyVoice.secondaryRadio, true)
	else
		plyVoice.radio = plyVoice.lastRadio

		addPlayerToRadio(source, plyVoice.radio)
	end

	logger.verbose('[radio] Set %s to talking: %s on radio %s', source, false, not secondary and plyVoice.radio or plyVoice.secondaryRadio)

	for player, _ in pairs(radioTbl) do
		if player ~= source then
			TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, not secondary and plyVoice.radio or plyVoice.secondaryRadio, false)
			logger.verbose('[radio] Sync %s to let them know %s is %s', player, source, 'not talking')
		end
	end
end
RegisterNetEvent('pma-voice:setNotTalkingOnRadio', setNotTalkingOnRadio)

function RegisterServerCallback(name, cb)
	ServerCallbacks[name] = cb
end

RegisterServerCallback('pma-voice:tryTalkingOnRadio', function(source, cb, secondary)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return cb(false) end

	voiceData[source] = voiceData[source] or defaultTable(source)

	local plyVoice = voiceData[source]
	local radioTbl = radioData[not secondary and plyVoice.radio or plyVoice.secondaryRadio]

	if not radioTbl then return cb(false) end

	for _, talking in pairs(radioTbl) do
		if player ~= source then
			if (talking) then return cb(false) end
		end
	end

	radioTbl[source] = true

	if not secondary then
		plyVoice.lastSecondaryRadio = plyVoice.secondaryRadio

		removePlayerFromRadio(source, plyVoice.secondaryRadio, true)
	else
		plyVoice.lastRadio = plyVoice.radio

		removePlayerFromRadio(source, plyVoice.radio)
	end

	cb(true)

	logger.verbose('[radio] Set %s to talking: %s on radio %s', source, true, not secondary and plyVoice.radio or plyVoice.secondaryRadio)

	for player, _ in pairs(radioTbl) do
		if player ~= source then
			TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, not secondary and plyVoice.radio or plyVoice.secondaryRadio, true)
			logger.verbose('[radio] Sync %s to let them know %s is %s', player, source, 'talking')
		end
	end
end)

AddEventHandler("onResourceStop", function(resource)
	for channel, cfxFunctionRef in pairs(radioChecks) do
		local functionRef = cfxFunctionRef.__cfx_functionReference
		local functionResource = string.match(functionRef, resource)
		if functionResource then
			radioChecks[channel] = nil
			logger.warn('Channel %s had its radio check removed because the resource that gave the checks stopped', channel)
		end
	end

	if type(radioNameGetter) == "table" then
		local radioRef = radioNameGetter.__cfx_functionReference
		if radioRef then
			local isResource = string.match(functionRef, resource)
			if isResource then
				radioNameGetter = radioNameGetter_orig
				logger.warn('Radio name getter is resetting to default because the resource that gave the cb got turned off')
			end
		end
	end

end)

-- https://github.com/esx-framework/esx-legacy/blob/3d569b3e9a22b4c6ed71250868052976fccb2241/%5Besx%5D/es_extended/server/common.lua

function TriggerServerCallback(name, requestId, source, cb, ...)
	if ServerCallbacks[name] then
		ServerCallbacks[name](source, cb, ...)
	else
		print(('[^3WARNING^7] Server callback ^5"%s"^0 does not exist!^0'):format(name))
	end
end

RegisterServerEvent('pma-voice:triggerServerCallback')
AddEventHandler('pma-voice:triggerServerCallback', function(name, requestId, ...)
	local playerId = source

	TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent('pma-voice:serverCallback', playerId, requestId, ...)
	end, ...)
end)