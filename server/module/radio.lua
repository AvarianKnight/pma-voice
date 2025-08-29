local radioChecks = {}

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
---@return boolean wasAdded if the player was successfuly added to the radio channel, or if it failed.
function addPlayerToRadio(source, radioChannel)
	if not canJoinChannel(source, radioChannel) then
		-- remove the player from the radio client side
		TriggerClientEvent("pma-voice:radioChangeRejected", source)
		TriggerClientEvent('pma-voice:removePlayerFromRadio', source, source, radioChannel)
		return false
	end
	logger.verbose('[radio] Added %s to radio %s', source, radioChannel)

	-- Initialize channel data structure if it doesn't exist
	radioData[radioChannel] = radioData[radioChannel] or {}
	local plyName = radioNameGetter(source)
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:addPlayerToRadio', player, source, plyName, radioChannel)
	end
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].radio = radioChannel
	radioData[radioChannel][source] = false
	TriggerClientEvent('pma-voice:syncRadioData', source, radioData[radioChannel],
		GetConvarInt("voice_syncPlayerNames", 0) == 1 and plyName)
	return true
end

--- adds a player to the secondary radio channel
---@param source number the player to add to the channel
---@param radioChannel number the channel to add them to
function addPlayerToSecondaryRadio(source, radioChannel)
	if not canJoinChannel(source, radioChannel) then
		-- remove the player from the secondary radio client side
		TriggerClientEvent("pma-voice:radioChangeRejected", source)
		TriggerClientEvent('pma-voice:removePlayerFromRadio', source, source, radioChannel)
		return false
	end
	logger.verbose('[radio] Added %s to secondary radio %s', source, radioChannel)

	-- Initialize channel data structure if it doesn't exist
	radioData[radioChannel] = radioData[radioChannel] or {}
	local plyName = radioNameGetter(source)
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:addPlayerToRadio', player, source, plyName, radioChannel)
	end
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].secondaryRadio = radioChannel
	radioData[radioChannel][source] = false
	TriggerClientEvent('pma-voice:syncSecondaryRadioData', source, radioData[radioChannel],
		GetConvarInt("voice_syncPlayerNames", 0) == 1 and plyName)
	return true
end

--- removes a player from the specified channel
---@param source number the player to remove
---@param radioChannel number the current channel to remove them from
function removePlayerFromRadio(source, radioChannel)
	logger.verbose('[radio] Removed %s from radio %s', source, radioChannel)
	radioData[radioChannel] = radioData[radioChannel] or {}
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source, radioChannel)
	end
	radioData[radioChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].radio = 0
end

--- removes a player from the specified secondary channel
---@param source number the player to remove
---@param radioChannel number the current channel to remove them from
function removePlayerFromSecondaryRadio(source, radioChannel)
	logger.verbose('[radio] Removed %s from secondary radio %s', source, radioChannel)
	radioData[radioChannel] = radioData[radioChannel] or {}
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source, radioChannel)
	end
	radioData[radioChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].secondaryRadio = 0
end

--- sets the players current radio channel
---@param source number the player to set the channel of
---@param _radioChannel number the radio channel to set them to (or 0 to remove them from radios)  
---@param radioType string optional radio type, "primary" or "secondary" (defaults to "primary")
function setPlayerRadio(source, _radioChannel, radioType)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local isResource = GetInvokingResource()
	local plyVoice = voiceData[source]
	local radioChannel = tonumber(_radioChannel)
	radioType = radioType or "primary"
	
	if not radioChannel then
		-- only full error if its sent from another server-side resource
		if isResource then
			error(("'radioChannel' expected 'number', got: %s"):format(type(_radioChannel)))
		else
			return logger.warn("%s sent a invalid radio, 'radioChannel' expected 'number', got: %s", source,
				type(_radioChannel))
		end
	end
	
	if isResource then
		-- got set in a export, need to update the client to tell them that their radio
		-- changed
		TriggerClientEvent('pma-voice:clSetPlayerRadio', source, radioChannel, radioType)
	end
	
	if radioType == "secondary" then
		-- Handle secondary radio
		voiceData[source] = voiceData[source] or defaultTable(source)
		if not voiceData[source].secondaryRadio then
			voiceData[source].secondaryRadio = 0
		end
		
		if radioChannel ~= 0 then
			if voiceData[source].secondaryRadio > 0 then
				removePlayerFromSecondaryRadio(source, voiceData[source].secondaryRadio)
			end
			local wasAdded = addPlayerToSecondaryRadio(source, radioChannel)
			Player(source).state.secondaryRadioChannel = wasAdded and radioChannel or 0
		elseif radioChannel == 0 then
			if voiceData[source].secondaryRadio > 0 then
				removePlayerFromSecondaryRadio(source, voiceData[source].secondaryRadio)
			end
			Player(source).state.secondaryRadioChannel = 0
		end
	else
		-- Handle primary radio (backwards compatibility)
		if radioChannel ~= 0 then
			if plyVoice.radio > 0 then
				removePlayerFromRadio(source, plyVoice.radio)
			end
			local wasAdded = addPlayerToRadio(source, radioChannel)
			Player(source).state.radioChannel = wasAdded and radioChannel or 0
		elseif radioChannel == 0 then
			removePlayerFromRadio(source, plyVoice.radio)
			Player(source).state.radioChannel = 0
		end
	end
end

exports('setPlayerRadio', setPlayerRadio)
exports('addPlayerToSecondaryRadio', addPlayerToSecondaryRadio)
exports('removePlayerFromSecondaryRadio', removePlayerFromSecondaryRadio)

RegisterNetEvent('pma-voice:setPlayerRadio', function(radioChannel, radioType)
	setPlayerRadio(source, radioChannel, radioType)
end)

--- syncs the player talking across all radio members
---@param talking boolean sets if the palyer is talking.
---@param radioType string the radio type they're talking on
function setTalkingOnRadio(talking, radioType)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local plyVoice = voiceData[source]
	radioType = radioType or "primary"
	
	local radioChannel = (radioType == "secondary") and plyVoice.secondaryRadio or plyVoice.radio
	local radioTbl = radioData[radioChannel]
	
	if radioTbl then
		radioTbl[source] = talking
		logger.verbose('[radio] Set %s to talking: %s on %s radio %s', source, talking, radioType, radioChannel)
		for player, _ in pairs(radioTbl) do
			if player ~= source then
				TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, talking)
				logger.verbose('[radio] Sync %s to let them know %s is %s', player, source,
					talking and 'talking' or 'not talking')
			end
		end
	end
end

RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

AddEventHandler("onResourceStop", function(resource)
	for channel, cfxFunctionRef in pairs(radioChecks) do
		local functionRef = cfxFunctionRef.__cfx_functionReference
		local functionResource = string.match(functionRef, resource)
		if functionResource then
			radioChecks[channel] = nil
			logger.warn('Channel %s had its radio check removed because the resource that gave the checks stopped',
				channel)
		end
	end

	if type(radioNameGetter) == "table" then
		local radioRef = radioNameGetter.__cfx_functionReference
		if radioRef then
			local isResource = string.match(radioRef, resource)
			if isResource then
				radioNameGetter = radioNameGetter_orig
				logger.warn(
					'Radio name getter is resetting to default because the resource that gave the cb got turned off')
			end
		end
	end
end)
