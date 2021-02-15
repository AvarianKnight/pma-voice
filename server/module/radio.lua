-- micro optimize
local defaultTable = defaultTable

function removePlayerFromRadio(source, currentChannel)
	radioData[currentChannel] = radioData[currentChannel] or {}
	for player, _ in pairs(radioData[currentChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source)
	end
	radioData[currentChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].radio = 0
end

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

RegisterNetEvent('pma-voice:setPlayerRadio')
AddEventHandler('pma-voice:setPlayerRadio', function(radioChannel)
	setPlayerRadio(source, radioChannel)
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio')
AddEventHandler('pma-voice:setTalkingOnRadio', function(talking)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local plyVoice = voiceData[source]
	local radioTbl = radioData[plyVoice.radio]
	if radioTbl then
		for player, _ in pairs(radioTbl) do
			TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, talking)
		end
	end
end)
