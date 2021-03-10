--- removes a player from the specified channel
---@param source number the player to remove
---@param currentChannel number the current channel to remove them from
function removePlayerFromRadio(source, currentChannel)
	radioData[currentChannel] = radioData[currentChannel] or {}
	for player, _ in pairs(radioData[currentChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source)
	end
	radioData[currentChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].radio = 0
end

--- adds a player to the specified radion channel
---@param source number the player to add to the channel
---@param channel number the channel to set them to
function addPlayerToRadio(source, channel)
	-- check if the channel exists, if it does set the varaible to it
	-- if not create it (basically if not radiodata make radiodata)
	radioData[channel] = radioData[channel] or {}
	for player, _ in pairs(radioData[channel]) do
		TriggerClientEvent('pma-voice:addPlayerToRadio', player, source)
	end
	voiceData[source] = voiceData[source] or defaultTable(source)

	voiceData[source].radio = channel
	radioData[channel][source] = false
	TriggerClientEvent('pma-voice:syncRadioData', source, radioData[channel])
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
		for player, _ in pairs(radioTbl) do
			if player ~= source then
				TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, talking)
			end
		end
	end
end
RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

