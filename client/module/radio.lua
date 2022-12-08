local radioChannel = -10
local secondaryRadioChannel = -20
local disableRadioAnim = false
local talkingOnRadio = false
local CurrentRequestId = 0
local ServerCallbacks = {}

--- event syncRadioData
--- syncs the current players on the radio to the client
---@param radioTable table the table of the current players on the radio
---@param secondary boolean secondary
function syncRadioData(radioTable, secondary)
	if not secondary then
		radioData = radioTable
	else
		secondaryRadioData = radioData
	end

	logger.info('[radio] Syncing radio table.')
	if GetConvarInt('voice_debugMode', 0) >= 4 then
		print('-------- RADIO TABLE --------')
		tPrint(radioTable)
		print('-----------------------------')
	end
	for tgt, enabled in pairs(radioTable) do
		if tgt ~= playerServerId then
			toggleVoice(tgt, enabled, 'radio')
		end
	end
	sendUIMessage({
		radioChannel = radioChannel,
		radioEnabled = radioEnabled
	})
	if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
		radioNames[playerServerId] = localPlyRadioName
	end
end
RegisterNetEvent('pma-voice:syncRadioData', syncRadioData)

--- event setTalkingOnRadio
--- sets the players talking status, triggered when a player starts/stops talking.
---@param plySource number the players server id.
---@param enabled boolean whether the player is talking or not.
function setTalkingOnRadio(plySource, channel, enabled)
	toggleVoice(plySource, enabled, 'radio')

	if channel == radioChannel then
		radioData[plySource] = enabled
	else
		secondaryRadioData[plySource] = enabled
	end

	if not enabled then
		playExternalEnd(channel == secondaryRadioChannel)
	end
end
RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

--- event addPlayerToRadio
--- adds a player onto the radio.
---@param channel number channel number
function addPlayerToRadio(plySource, channel)
	if channel == radioChannel then
		radioData[plySource] = false
	else
		secondaryRadioData[plySource] = false
	end

	if radioPressed then
		logger.info('[radio] %s joined radio %s while we were talking, adding them to targets', plySource, channel == radioChannel and radioChannel or secondaryRadioChannel)
		playerTargets(channel == radioChannel and radioData or secondaryRadioData, MumbleIsPlayerTalking(PlayerId()) and callData or {})
	else
		logger.info('[radio] %s joined radio %s', plySource, radioChannel)
	end
end
RegisterNetEvent('pma-voice:addPlayerToRadio', addPlayerToRadio)

--- event removePlayerFromRadio
--- removes the player (or self) from the radio
---@param channel number channel id
function removePlayerFromRadio(plySource, channel)
	if plySource == playerServerId then
		logger.info('[radio] Left radio %s, cleaning up.', radioChannel)
		for tgt, _ in pairs(channel == radioChannel and radioData or secondaryRadioData) do
			if tgt ~= playerServerId then
				toggleVoice(tgt, false, 'radio')
			end
		end
		sendUIMessage({
			radioChannel = 0,
			radioEnabled = radioEnabled
		})
		if channel == radioChannel then
			radioData = {}
		else
			secondaryRadioData = {}
		end
		playerTargets(MumbleIsPlayerTalking(PlayerId()) and callData or {})
	else
		toggleVoice(plySource, false)
		if radioPressed then
			logger.info('[radio] %s left radio %s while we were talking, updating targets.', plySource, radioChannel)
			playerTargets(channel == radioChannel and radioData or secondaryRadioData, MumbleIsPlayerTalking(PlayerId()) and callData or {})
		else
			logger.info('[radio] %s has left radio %s', plySource, radioChannel)
		end
		if channel == radioChannel then
			radioData[plySource] = nil
		else
			secondaryRadioData[plySource] = nil
		end
	end
end
RegisterNetEvent('pma-voice:removePlayerFromRadio', removePlayerFromRadio)

--- function setRadioChannel
--- sets the local players current radio channel and updates the server
---@param channel number the channel to set the player to, or 0 to remove them.
function setRadioChannel(channel, secondary)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	type_check({channel, "number"})
	TriggerServerEvent('pma-voice:setPlayerRadio', channel, secondary or false)

	if not secondary then
		radioChannel = channel
	else
		secondaryRadioChannel = channel
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
---@param _radio number the channel to set the player to, or 0 to remove them.
exports('addPlayerToRadio', function(_radio)
	local radio = tonumber(_radio)
	if radio then
		setRadioChannel(radio)
	end
end)

--- exports toggleRadioAnim
--- toggles whether the client should play radio anim or not, if the animation should be played or notvaliddance
exports('toggleRadioAnim', function()
	disableRadioAnim = not disableRadioAnim
	TriggerEvent('pma-voice:toggleRadioAnim', disableRadioAnim)
end)

-- exports disableRadioAnim
--- returns whether the client is undercover or not
exports('getRadioAnimState', function()
	return disableRadioAnim
end)

--- check if the player is dead
--- seperating this so if people use different methods they can customize
--- it to their need as this will likely never be changed
--- but you can integrate the below state bag to your death resources.
--- LocalPlayer.state:set('isDead', true or false, false)
function isDead()
	if LocalPlayer.state.isDead then
		return true
	elseif IsPlayerDead(PlayerId()) then
		return true
	end
end

function TriggerServerCallback(name, cb, ...)
    ServerCallbacks[CurrentRequestId] = cb

    TriggerServerEvent('pma-voice:triggerServerCallback', name, CurrentRequestId, ...)
    CurrentRequestId = CurrentRequestId < 65535 and CurrentRequestId + 1 or 0
end

RegisterCommand('+radiotalk', function()
	startTalkingOnRadio(false)
end, false)

RegisterCommand('+radiotalksecondary', function()
	startTalkingOnRadio(true)
end, false)

function startTalkingOnRadio(secondary)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	if isDead() then return end
	if radioPressed or not radioEnabled then return end
	if (not secondary and radioChannel < 1) or (secondary and secondaryRadioChannel < 1) then return end

	radioPressed = true

	TriggerServerCallback('pma-voice:tryTalkingOnRadio', function(success)
		if success then
			playMicClicks(true, secondary)

			talkingOnRadio = true

			logger.info('[radio] Start broadcasting, update targets and notify server.')

			playerTargets(not secondary and radioData or secondaryRadioData, MumbleIsPlayerTalking(PlayerId()) and callData or {})

			if GetConvarInt('voice_enableRadioAnim', 0) == 1 and not (GetConvarInt('voice_disableVehicleRadioAnim', 0) == 1 and IsPedInAnyVehicle(PlayerPedId(), false)) then
				if not disableRadioAnim then
					RequestAnimDict('random@arrests')
					while not HasAnimDictLoaded('random@arrests') do
						Citizen.Wait(10)
					end
					TaskPlayAnim(PlayerPedId(), "random@arrests", "generic_radio_enter", 8.0, 2.0, -1, 50, 2.0, 0, 0, 0)
				end
			end
		else
			playMicDeny()
		end
	end, secondary)

	Citizen.CreateThread(function()
		while radioPressed do
			Wait(0)
			SetControlNormal(0, 249, 1.0)
			SetControlNormal(1, 249, 1.0)
			SetControlNormal(2, 249, 1.0)
		end
	end)
end

RegisterCommand('-radiotalk', function()
	stopTalkingOnRadio(false)
end, false)

RegisterCommand('-radiotalksecondary', function()
	stopTalkingOnRadio(true)
end, false)

function stopTalkingOnRadio(secondary)
	if ((not secondary and radioChannel < 1) or (secondary and secondaryRadioChannel < 1)) or not radioEnabled or not radioPressed then return end

	radioPressed = false

	if GetConvarInt('voice_enableRadioAnim', 0) == 1 then
		StopAnimTask(PlayerPedId(), "random@arrests", "generic_radio_enter", -4.0)
	end

	if not talkingOnRadio then return end

	talkingOnRadio = false

	playMicClicks(false, secondary)

	MumbleClearVoiceTargetPlayers(voiceTarget)

	playerTargets(MumbleIsPlayerTalking(PlayerId()) and callData or {})

	TriggerServerEvent('pma-voice:setNotTalkingOnRadio', secondary)
end

if gameVersion == 'fivem' then
	RegisterKeyMapping('+radiotalk', 'Talk over Radio', 'keyboard', GetConvar('voice_defaultRadio', 'LMENU'))
	RegisterKeyMapping('+radiotalksecondary', 'Talk over Radio (Secondary)', 'keyboard', GetConvar('voice_defaultSecondaryRadio', 'RMENU'))
end

--- event syncRadio
--- syncs the players radio, only happens if the radio was set server side.
---@param _radioChannel number the radio channel to set the player to.
function syncRadio(_radioChannel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	logger.info('[radio] radio set serverside update to radio %s', radioChannel)
	radioChannel = _radioChannel
end
RegisterNetEvent('pma-voice:clSetPlayerRadio', syncRadio)

-- https://github.com/esx-framework/esx-legacy/blob/7b3cd152542520e83d0a01d9efe8448490860d1a/%5Besx%5D/es_extended/client/functions.lua

RegisterNetEvent('pma-voice:serverCallback')
AddEventHandler('pma-voice:serverCallback', function(requestId, ...)
    ServerCallbacks[requestId](...)
    ServerCallbacks[requestId] = nil
end)