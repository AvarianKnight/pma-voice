--- removes a player from the specified channel
---@param source number the player to remove
---@param radioChannel number the current channel to remove them from
function removePlayerFromRadio(source, radioChannel)
	logger.info('[radio] Removed %s from radio %s', source, radioChannel)
	radioData[radioChannel] = radioData[radioChannel] or {}
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source)
	end
	radioData[radioChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].radio = 0
end

--- adds a player to the specified radion channel
---@param source number the player to add to the channel
---@param radioChannel number the channel to set them to
function addPlayerToRadio(source, radioChannel)
	logger.info('[radio] Added %s to radio %s', source, radioChannel)

	-- check if the channel exists, if it does set the varaible to it
	-- if not create it (basically if not radiodata make radiodata)
	radioData[radioChannel] = radioData[radioChannel] or {}
	for player, _ in pairs(radioData[radioChannel]) do
		TriggerClientEvent('pma-voice:addPlayerToRadio', player, source)
	end
	voiceData[source] = voiceData[source] or defaultTable(source)

	voiceData[source].radio = radioChannel
	radioData[radioChannel][source] = false
	TriggerClientEvent('pma-voice:syncRadioData', source, radioData[radioChannel])
end

-- TODO: Implement this in a way that allows players to be on multiple channels
--- sets the players current radio channel
---@param source number the player to set the channel of
---@param radioChannel number the radio channel to set them to (or 0 to remove them from radios)
function setPlayerRadio(source, radioChannel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	if GetInvokingResource() then
		-- got set in a export, need to update the client to tell them that their radio
		-- changed
		TriggerClientEvent('pma-voice:clSetPlayerRadio', source, radioChannel)
	end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local plyVoice = voiceData[source]
	local radioChannel = tonumber(radioChannel)
	if not radioChannel then error(('radioChannel was not a number. Got: %s Expected: Number'):format(type(radioChannel))) return end
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

RegisterNetEvent('pma-voice:setPlayerRadio', function(radioChannel)
	setPlayerRadio(source, radioChannel)
end)

--- syncs the player talking across all radio members
---@param talking boolean sets if the palyer is talking.
function setTalkingOnRadio(talking)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local plyVoice = voiceData[source]
	local radioTbl = radioData[plyVoice.radio]
	if radioTbl then
		logger.info('[radio] Set %s to talking: %s on radio %s',source, talking, plyVoice.radio)
		for player, _ in pairs(radioTbl) do
			if player ~= source then
				TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, talking)
				logger.verbose('[radio] Sync %s to let them know %s is %s',player, source, talking and 'talking' or 'not talking')
			end
		end
	end
end
RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

