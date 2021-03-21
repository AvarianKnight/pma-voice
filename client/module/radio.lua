--- event syncRadioData
--- syncs the current players on the radio to the client
---@param radioTable table the table of the current players on the radio
function syncRadioData(radioTable)
	radioData = radioTable
	debug(('Syncing radio table.'))
	if GetConvarInt('voice_debugMode', 0) == 1 then
		tPrint(radioData)
	end
	for tgt, enabled in pairs(radioTable) do
		if tgt ~= playerServerId then
			toggleVoice(tgt, enabled, 'radio')
		end
	end
end
RegisterNetEvent('pma-voice:syncRadioData', syncRadioData)

--- event setTalkingOnRadio
--- sets the players talking status, triggered when a player starts/stops talking.
---@param plySource number the players server id.
---@param enabled boolean whether the player is talking or not.
function setTalkingOnRadio(plySource, enabled)
	debug(('%s has %s talking on the radio'):format(plySource, enabled and 'started' or 'stopped'))
	radioData[plySource] = enabled
	toggleVoice(plySource, enabled, 'radio')
	playMicClicks(enabled)
end
RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

--- event addPlayerToRadio
--- adds a player onto the radio.
---@param plySource number the players server id to add to the radio.
function addPlayerToRadio(plySource)
	debug(('%s has joined the radio'):format(plySource))
	radioData[plySource] = false
	if voiceData.radioPressed then
		playerTargets(radioData, NetworkIsPlayerTalking(PlayerId()) and callData or {})
	end
end
RegisterNetEvent('pma-voice:addPlayerToRadio', addPlayerToRadio)

--- event removePlayerFromRadio
--- removes the player (or self) from the radio
---@param plySource number the players server id to remove from the radio.
function removePlayerFromRadio(plySource)
	if plySource == playerServerId then
		debug(('We have left the radio channel'))
		for tgt, enabled in pairs(radioData) do
			if tgt ~= playerServerId then
				toggleVoice(tgt, false)
			end
		end
		radioData = {}
		-- only update the call data if they're talking
		playerTargets(radioData, NetworkIsPlayerTalking(PlayerId()) and callData or {})
	else
		radioData[plySource] = nil
		toggleVoice(plySource, false)
		-- update our targets if we were talking
		if voiceData.radioPressed then
			debug(('We were talking when %s left, resetting targets.'):format(plySource))
			playerTargets(radioData, NetworkIsPlayerTalking(PlayerId()) and callData or {})
		else
			debug(('%s has left the radio'):format(plySource))
		end
	end
end
RegisterNetEvent('pma-voice:removePlayerFromRadio', removePlayerFromRadio)

--- function setRadioChannel
--- sets the local players current radio channel and updates the server
---@param channel number the channel to set the player to, or 0 to remove them.
function setRadioChannel(channel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	debug(('Setting radio channel to %s'):format(channel))
	TriggerServerEvent('pma-voice:setPlayerRadio', channel)
	voiceData.radio = channel
	if GetConvarInt('voice_enableUi', 1) == 1 then
		SendNUIMessage({
			radioChannel = channel,
			radioEnabled = voiceData.radioEnabled
		})
	end
end

--- exports setRadioChannel
--- sets the local players current radio channel and updates the server
---@param channel number the channel to set the player to, or 0 to remove them.
exports('setRadioChannel', setRadioChannel)
-- mumble-voip compatability
exports('SetRadioChannel', setRadioChannel)

--- exports removePlayerFromRadio
--- sets the local players current radio channel and updates the server
exports('removePlayerFromRadio', function()
	setRadioChannel(0)
end)

--- exports addPlayerToRadio
--- sets the local players current radio channel and updates the server
---@param radio number the channel to set the player to, or 0 to remove them.
exports('addPlayerToRadio', function(radio)
	local radio = tonumber(radio)
	if radio then
		setRadioChannel(radio)
	end
end)

--- check if the player is dead
--- seperating this so if people use different methods they can customize
--- it to their need as this will likely never be changed.
function isDead()
	if GetResourceState("pma-ambulance") ~= "missing" then
		if LocalPlayer.state.isDead then
			return true
		end
	elseif IsPlayerDead(PlayerId()) then
		return true
	end
end

RegisterCommand('+radiotalk', function()
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	if isDead() then return end

	if not voiceData.radioPressed and voiceData.radioEnabled then
		if voiceData.radio > 0 then
			playerTargets(radioData, NetworkIsPlayerTalking(PlayerId()) and callData or {})
			TriggerServerEvent('pma-voice:setTalkingOnRadio', true)
			voiceData.radioPressed = true
			playMicClicks(true)
			Citizen.CreateThread(function()
				TriggerEvent("pma-voice:radioActive", true)
				while voiceData.radioPressed do
					Wait(0)
					SetControlNormal(0, 249, 1.0)
					SetControlNormal(1, 249, 1.0)
					SetControlNormal(2, 249, 1.0)
				end
			end)
		end
	end
end, false)

RegisterCommand('-radiotalk', function()
	if voiceData.radio > 0 or voiceData.radioEnabled then
		voiceData.radioPressed = false
		MumbleClearVoiceTargetPlayers(1)
		TriggerEvent("pma-voice:radioActive", false)
		playMicClicks(false)
		TriggerServerEvent('pma-voice:setTalkingOnRadio', false)
	end
end, false)
RegisterKeyMapping('+radiotalk', 'Talk over Radio', 'keyboard', GetConvar('voice_defaultRadio', 'LMENU'))

--- event syncRadio
--- syncs the players radio, only happens if the radio was set server side.
---@param radioChannel number the radio channel to set the player to.
function syncRadio(radioChannel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	voiceData.radio = radioChannel
	debug(('Radio set server side, syncing radio to channel %s'):format(radioChannel))
end
RegisterNetEvent('pma-voice:clSetPlayerRadio', syncRadio)
