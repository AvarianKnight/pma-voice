local Cfg = Cfg
local currentGrid = 0
-- we can't use GetConvarInt because its not a integer, and theres no way to get a float... so use a hacky way it is!
local volumes = {
	-- people are setting this to 1 instead of 1.0 and expecting it to work.
	['radio'] = tonumber(GetConvar('voice_defaultVolume', '0.3')) + 0.0,
	['phone'] = tonumber(GetConvar('voice_defaultVolume', '0.3')) + 0.0,
}
local voiceChannelListeners = {}
local micClicks = true
playerServerId = GetPlayerServerId(PlayerId())
radioEnabled, radioPressed, mode, radioChannel, callChannel = false, false, 2, 0, 0
radioData = {}
callData = {}

-- TODO: Convert the last Cfg to a Convar, while still keeping it simple.
AddEventHandler('pma-voice:settingsCallback', function(cb)
	cb(Cfg)
end)

-- TODO: Better implementation of this?
RegisterCommand('vol', function(_, args)
	if not args[1] then return end
	local volume = tonumber(args[1])
	if volume then
		setVolume(volume / 100)
	end
end)

--- function setVolume
--- Toggles the players volume
---@param volume number between 0 and 100
---@param volumeType string the volume type (currently radio & call) to set the volume of (opt)
function setVolume(volume, volumeType)
	local volume = tonumber(volume)
	local checkType = type(volume)
	if checkType ~= 'number' then
		return error(('setVolume expected type number, got %s'):format(checkType))
	end
	if volumeType then
		local volumeTbl = volumes[volumeType]
		if volumeTbl then
			LocalPlayer.state:set(volumeType, volume, GetConvarInt('voice_syncData', 1) == 1)
			volumes[volumeType] = volume
		else
			error(('setVolume got a invalid volume type %s'):format(volumeType))
		end
	else
		for types, vol in pairs(volumes) do
			volumes[types] = volume
			LocalPlayer.state:set(types, volume, GetConvarInt('voice_syncData', 1) == 1)
		end
	end
end

exports('setRadioVolume', function(vol)
	setVolume(vol, 'radio')
end)
exports('getRadioVolume', function()
	return volumes['radio']
end)
exports("setCallVolume", function(vol)
	setVolume(vol, 'phone')
end)
exports('getCallVolume', function()
	return volumes['phone']
end)


-- default submix incase people want to fiddle with it.
-- freq_low = 389.0
-- freq_hi = 3248.0
-- fudge = 0.0
-- rm_mod_freq = 0.0
-- rm_mix = 0.16
-- o_freq_lo = 348.0
-- 0_freq_hi = 4900.0

-- radio submix
local radioEffectId = CreateAudioSubmix('Radio')
SetAudioSubmixEffectRadioFx(radioEffectId, 0)
SetAudioSubmixEffectParamInt(radioEffectId, 0, GetHashKey('default'), 1)
AddAudioSubmixOutput(radioEffectId, 0)

local phoneEffectId = CreateAudioSubmix('Phone')
SetAudioSubmixEffectRadioFx(phoneEffectId, 1)
SetAudioSubmixEffectParamInt(phoneEffectId, 1, GetHashKey('default'), 1)
SetAudioSubmixEffectParamFloat(phoneEffectId, 1, GetHashKey('freq_low'), 300.0)
SetAudioSubmixEffectParamFloat(phoneEffectId, 1, GetHashKey('freq_hi'), 6000.0)
AddAudioSubmixOutput(phoneEffectId, 1)

local submixFunctions = {
	['radio'] = function(plySource)
		MumbleSetSubmixForServerId(plySource, radioEffectId)
	end,
	['phone'] = function(plySource)
		MumbleSetSubmixForServerId(plySource, phoneEffectId)
	end
}

-- used to prevent a race condition if they talk again afterwards, which would lead to their voice going to default.
local disableSubmixReset = {}
--- function toggleVoice
--- Toggles the players voice
---@param plySource number the players server id to override the volume for
---@param enabled boolean if the players voice is getting activated or deactivated
---@param moduleType string the volume & submix to use for the voice.
function toggleVoice(plySource, enabled, moduleType)
	logger.verbose('[main] Updating %s to talking: %s with submix %s', plySource, enabled, moduleType)
	if enabled then
		MumbleSetVolumeOverrideByServerId(plySource, enabled and volumes[moduleType])
		if GetConvarInt('voice_enableSubmix', 0) == 1 then
			if moduleType then
				disableSubmixReset[plySource] = true
				submixFunctions[moduleType](plySource)
			else
				MumbleSetSubmixForServerId(plySource, -1)
			end
		end
	else
		if GetConvarInt('voice_enableSubmix', 0) == 1 then
			-- garbage collect it
			disableSubmixReset[plySource] = nil
			SetTimeout(250, function()
				if not disableSubmixReset[plySource] then
					MumbleSetSubmixForServerId(plySource, -1)
				end
			end)
		end
		MumbleSetVolumeOverrideByServerId(plySource, -1.0)
	end
end

--- function playerTargets
---Adds players voices to the local players listen channels allowing
---Them to communicate at long range, ignoring proximity range.
---@param targets table expects multiple tables to be sent over
function playerTargets(...)
	local targets = {...}
	local addedPlayers = {
		[playerServerId] = true
	}

	for i = 1, #targets do
		for id, _ in pairs(targets[i]) do
			-- we don't want to log ourself, or listen to ourself
			if addedPlayers[id] and id ~= playerServerId then
				logger.verbose('[main] %s is already target don\'t re-add', id)
				goto skip_loop
			end
			if not addedPlayers[id] then
				logger.verbose('[main] Adding %s as a voice target', id)
				addedPlayers[id] = true
				MumbleAddVoiceTargetPlayerByServerId(1, id)
			end
			::skip_loop::
		end
	end
end

--- function playMicClicks
---plays the mic click if the player has them enabled.
---@param clickType boolean whether to play the 'on' or 'off' click. 
function playMicClicks(clickType)
	if micClicks ~= 'true' then return end
	SendNUIMessage({
		sound = (clickType and "audio_on" or "audio_off"),
		volume = (clickType and (volume) or 0.05)
	})
end

local playerMuted = false
RegisterCommand('+cycleproximity', function()
	if GetConvarInt('voice_enableProximity', 1) ~= 1 then return end
	if playerMuted then return end

	local voiceMode = mode
	local newMode = voiceMode + 1

	voiceMode = (newMode <= #Cfg.voiceModes and newMode) or 1
	local voiceModeData = Cfg.voiceModes[voiceMode]
	MumbleSetAudioInputDistance(voiceModeData[1] + 0.0)
	mode = voiceMode
	LocalPlayer.state:set('proximity', {
		index = voiceMode,
		distance =  voiceModeData[1],
		mode = voiceModeData[2],
	}, GetConvarInt('voice_syncData', 1) == 1)
	-- make sure we update the UI to the latest voice mode
	SendNUIMessage({
		voiceMode = voiceMode - 1
	})
	TriggerEvent('pma-voice:setTalkingMode', voiceMode)
end, false)
RegisterCommand('-cycleproximity', function()
end)
RegisterKeyMapping('+cycleproximity', 'Cycle Proximity', 'keyboard', GetConvar('voice_defaultCycle', 'F11'))

--- Toggles the current player muted 
function toggleMute() 
	playerMuted = not playerMuted
	
	if playerMuted then
		LocalPlayer.state:set('proximity', {
			index = 0,
			distance = 0.1,
			mode = 'Muted',
		}, GetConvarInt('voice_syncData', 1) == 1)
		MumbleSetAudioInputDistance(0.1)
	else
		local voiceModeData = Cfg.voiceModes[mode]
		LocalPlayer.state:set('proximity', {
			index = mode,
			distance =  voiceModeData[1],
			mode = voiceModeData[2],
		}, GetConvarInt('voice_syncData', 1) == 1)
		MumbleSetAudioInputDistance(Cfg.voiceModes[mode][1])
	end
end
exports('toggleMute', toggleMute)
RegisterNetEvent('pma-voice:toggleMute', toggleMute)

local mutedTbl = {}
--- toggles the targeted player muted
---@param source number the player to mute
function toggleMutePlayer(source)
	if mutedTbl[source] then
		mutedTbl[source] = nil
		MumbleSetVolumeOverrideByServerId(source, -1.0)
	else
		mutedTbl[source] = true
		MumbleSetVolumeOverrideByServerId(source, 0.0)
	end
end
exports('toggleMutePlayer', toggleMutePlayer)


--- function setVoiceProperty
--- sets the specified voice property
---@param type string what voice property you want to change (only takes 'radioEnabled' and 'micClicks')
---@param value any the value to set the type to.
function setVoiceProperty(type, value)
	if type == "radioEnabled" then
		radioEnabled = value
		SendNUIMessage({
			radioEnabled = value
		})
	elseif type == "micClicks" then
		local val = tostring(value)
		micClicks = val
		SetResourceKvp('pma-voice_enableMicClicks', val)
	end
end
exports('setVoiceProperty', setVoiceProperty)
-- compatibility
exports('SetMumbleProperty', setVoiceProperty)
exports('SetTokoProperty', setVoiceProperty)

local currentRouting = 0
local overrideCoords = false

--- function setOverrideCoords
--- overrides the players coords to a seperate coordinate, useful when spectating.
---@param coords vector3|boolean the coords to override with, or false to reset
function setOverrideCoords(coords) 
	local coordType = type(coords)
	-- if someone sets this to true it will break playerPos, error instead.
	if coordType ~= 'vector3' and (coordType ~= 'boolean' or coords == true) then
		return logger.error("setOverrideCoords expects a 'vector3' or 'boolean' (as false), got %s with the value of %s", coordType, coords)
	end
	overrideCoords = coords
end
exports('setOverrideCoords', setOverrideCoords)


function getMaxSize(zoneRadius)
	return math.floor(math.max(4500.0 + 8192.0, 0.0) / zoneRadius + math.max(8022.0 + 8192.0, 0.0) / zoneRadius)
end

local updatedRouting = false
--- function getGridZone
--- calculate the players grid
---@return number returns the players current grid.
local function getGridZone()
	local plyPos = overrideCoords or GetEntityCoords(PlayerPedId(), false)
	local zoneRadius = GetConvarInt('voice_zoneRadius', 256)
	local newRouting = LocalPlayer.state.routingBucket

	if newRouting ~= currentRouting then
		currentRouting = newRouting or 0
		updatedRouting = true
	end

	local sectorX = math.max(plyPos.x + 8192.0, 0.0) / zoneRadius
	local sectorY = math.max(plyPos.y + 8192.0, 0.0) / zoneRadius
	return (math.ceil(sectorX + sectorY) + (currentRouting * getMaxSize(zoneRadius)))
end

--- function getGridZoneAtCoords
--- gets the grid at the set coords
--- @param coords vector3 the coords to get the grid at
---@return number returns the grid that would be at the current coords
local function getGridZoneAtCoords(coords)
	local plyPos = coords
	local zoneRadius = GetConvarInt('voice_zoneRadius', 256)

	local sectorX = math.max(plyPos.x + 8192.0, 0.0) / zoneRadius
	local sectorY = math.max(plyPos.y + 8192.0, 0.0) / zoneRadius
	return (math.ceil(sectorX + sectorY) + (currentRouting * getMaxSize(zoneRadius)))
end
exports('getGridZoneAtCoords', getGridZoneAtCoords)

local lastGridChange = GetGameTimer()

--- function updateZone
--- updates the players current grid, if they're in a different grid.
---@param forced boolean whether or not to force a grid refresh. default: false
local function updateZone(forced)
	local newGrid = getGridZone()
	if newGrid ~= currentGrid or forced then
		logger.verbose('Time since last grid change: %s',  (GetGameTimer() - lastGridChange)/1000)
		logger.info('Updating zone from %s to %s and adding nearby grids, was forced: %s', currentGrid, newGrid, forced)
		lastGridChange = GetGameTimer()
		currentGrid = newGrid
		MumbleClearVoiceTargetChannels(1)
		NetworkSetVoiceChannel(currentGrid)
		-- Delay adding listener channels until NetworkSetVoiceChannel resolves
		if updatedRouting then
			Wait(GetConvarInt('voice_routingUpdateWait', 50))
			updatedRouting = false
		end
		LocalPlayer.state:set('grid', currentGrid, true)
		-- add nearby grids to voice targets
		for nearbyGrids = currentGrid - 3, currentGrid + 3 do
			MumbleAddVoiceTargetChannel(1, nearbyGrids)
		end
	end
end

-- cache talking status so we only send a nui message when its not the same as what it was before
local lastTalkingStatus = false
local lastRadioStatus = false
Citizen.CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/mute', 'Mutes the player with the specified id', {
		{ name = "player id", help = "the player to toggle mute" }
	})
	while true do
		-- wait for reconnection, trying to set your voice channel when theres nothing to set it to is useless.
		while not MumbleIsConnected() do
			currentGrid = -1 -- reset the grid to something out of bounds so it will resync their zone on disconnect.
			Wait(100)
		end
		updateZone()
		if GetConvarInt('voice_enableUi', 1) == 1 then
			if lastRadioStatus ~= radioPressed or lastTalkingStatus ~= (NetworkIsPlayerTalking(PlayerId()) == 1) then
				lastRadioStatus = radioPressed
				lastTalkingStatus = NetworkIsPlayerTalking(PlayerId()) == 1
				SendNUIMessage({
					usingRadio = lastRadioStatus,
					talking = lastTalkingStatus
				})
			end
		end
		Wait(GetConvarInt('voice_zoneRefreshRate', 200))
	end
end)

-- cache their external servers so if it changes in runtime we can reconnect the client.
local externalAddress = ''
local externalPort = 0
CreateThread(function()
	while true do
		Wait(500)
		-- only change if what we have doesn't match the cache
		if GetConvar('voice_externalAddress', '') ~= externalAddress or GetConvarInt('voice_externalPort', 0) ~= externalPort then
			externalAddress = GetConvar('voice_externalAddress', '')
			externalPort = GetConvarInt('voice_externalPort', 0)
			MumbleSetServerAddress(GetConvar('voice_externalAddress', ''), GetConvarInt('voice_externalPort', 0))
		end
	end
end)

--- forces the player to resync with the mumble server
--- sets their server address (if there is one) and forces their grid to update
RegisterCommand('vsync', function()
	local newGrid = getGridZone()
	print(('[vsync] Forcing zone from %s to %s and resetting voice targets.'):format(currentGrid, newGrid))
	if GetConvar('voice_externalAddress', '') ~= '' and GetConvarInt('voice_externalPort', 0) ~= 0 then
		MumbleSetServerAddress(GetConvar('voice_externalAddress', ''), GetConvarInt('voice_externalPort', 0))
		while not MumbleIsConnected() do
			Wait(250)
		end
	end
	NetworkSetVoiceChannel(newGrid + 100)
	-- reset the players voice targets
	MumbleSetVoiceTarget(0)
	MumbleClearVoiceTarget(1)
	MumbleSetVoiceTarget(1)
	MumbleClearVoiceTargetPlayers(1)
	-- force a zone update.
	updateZone(true)
end)

AddEventHandler('onClientResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	print('Starting script initialization')

	local micClicksKvp = GetResourceKvpString('pma-voice_enableMicClicks')
	if not micClicksKvp then
		SetResourceKvp('pma-voice_enableMicClicks', tostring(true))
	else
		micClicks = micClicksKvp
	end

	local voiceModeData = Cfg.voiceModes[mode]
	-- sets how far the player can talk
	MumbleSetAudioInputDistance(voiceModeData[1] + 0.0)
	LocalPlayer.state:set('proximity', {
		index = mode,
		distance =  voiceModeData[1],
		mode = voiceModeData[2],
	}, GetConvarInt('voice_syncData', 1) == 1)

	-- this sets how far the player can hear.
	MumbleSetAudioOutputDistance(Cfg.voiceModes[#Cfg.voiceModes][1] + 0.0)

	while not MumbleIsConnected() do
		Wait(250)
	end


	MumbleSetVoiceTarget(0)
	MumbleClearVoiceTarget(1)
	MumbleSetVoiceTarget(1)

	updateZone()

	print('Script initialization finished.')

	-- not waiting right here (in testing) let to some cases of the UI 
	-- just not working at all.
	Wait(1000)
	if GetConvarInt('voice_enableUi', 1) == 1 then
		SendNUIMessage({
			voiceModes = json.encode(Cfg.voiceModes),
			voiceMode = mode - 1
		})
	end
end)

RegisterCommand("grid", function()
	print(('Players current grid is %s'):format(currentGrid))
end)

RegisterCommand('setvoiceintent', function(source, args)
	if GetConvarInt('voice_allowSetIntent', 1) == 1 then
		local intent = args[1]
		if intent == 'speech' then
			MumbleSetAudioInputIntent(GetHashKey('speech'))
		elseif intent == 'music' then
			MumbleSetAudioInputIntent(GetHashKey('music'))
		end
	end
end)

AddEventHandler('mumbleConnected', function(address, isReconnecting)
	logger.log('Connected to mumble server with address of %s, is this a reconnect %s', GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address, isReconnecting)
	-- don't try to set channel instantly, we're still getting data.
	Wait(1000)
	updateZone(true)
end)

AddEventHandler('mumbleDisconnected', function(address)
	logger.log('Disconnected from mumble server with address of %s', GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address)
	currentGrid = -1
end)
