local Cfg = Cfg
local currentGrid = 0
-- we can't use GetConvarInt because its not a integer, and theres no way to get a float... so use a hacky way it is!
local volume = tonumber(GetConvar('voice_defaultVolume', '0.3'))
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
	local vol = tonumber(args[1])
	if vol then
		volume = vol / 100
	end
end)

--- function setVolume
--- Toggles the players volume
---@param vol number between 0 and 100
function setVolume(vol)
	local vol = tonumber(vol)
	if vol then
		volume = vol / 100
	end
end
exports("setVolume", setVolume)

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
SetAudioSubmixEffectParamFloat(phoneEffectId, 1, GetHashKey('freq_low'), 700.0)
SetAudioSubmixEffectParamFloat(phoneEffectId, 1, GetHashKey('freq_hi'), 15000.0)
AddAudioSubmixOutput(phoneEffectId, 1)

local submixFunctions = {
	['radio'] = function(plySource)
		MumbleSetSubmixForServerId(plySource, radioEffectId)
	end,
	['phone'] = function(plySource)
		MumbleSetSubmixForServerId(plySource, phoneEffectId)
	end
}

--- function toggleVoice
--- Toggles the players voice
---@param plySource number the players server id to override the volume for
---@param enabled boolean if the players voice is getting activated or deactivated
---@param submixType string what submix to use for the players voice, currently only supports 'radio'
function toggleVoice(plySource, enabled, submixType)
	logger.verbose(('[main] Updating %s to talking: %s with submix %s'):format(plySource, enabled, submixType))
	MumbleSetVolumeOverrideByServerId(plySource, enabled and volume or -1.0)
	if GetConvarInt('voice_enableRadioSubmix', 0) == 1 then
		if enabled and submixType then
			submixFunctions[submixType](plySource)
		else
			MumbleSetSubmixForServerId(plySource, -1)
		end
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
				logger.verbose(('[main] %s is already target don\'t re-add'):format(id))
				goto skip_loop
			end
			if not addedPlayers[id] then
				logger.verbose(('[main] Adding %s as a voice target'):format(id))
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
	MumbleSetAudioInputDistance(Cfg.voiceModes[voiceMode][1] + 0.0)
	mode = voiceMode
	LocalPlayer.state:set('proximity', Cfg.voiceModes[voiceMode][1], true)
	-- make sure we update the UI to the latest voice mode
	SendNUIMessage({
		voiceMode = voiceMode - 1
	})
	TriggerEvent('pma-voice:setTalkingMode', voiceMode)
end, false)
RegisterCommand('-cycleproximity', function()
end)
RegisterKeyMapping('+cycleproximity', 'Cycle Proximity', 'keyboard', GetConvar('voice_defaultCycle', 'F11'))

RegisterNetEvent('pma-voice:mutePlayer', function()
	playerMuted = not playerMuted
	if playerMuted then
		LocalPlayer.state:set('proximity', 0.1, true)
		MumbleSetAudioInputDistance(0.1)
	else
		LocalPlayer.state:set('proximity', Cfg.voiceModes[mode][1], true)
		MumbleSetAudioInputDistance(Cfg.voiceModes[mode][1])
	end
end)

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
-- compatability
exports('SetMumbleProperty', setVoiceProperty)
exports('SetTokoProperty', setVoiceProperty)

--- function getGridZone
--- calculate the players grid
---@return number returns the players current grid.
local function getGridZone()
	local plyPos = GetEntityCoords(PlayerPedId(), false)
	local zoneRadius = GetConvarInt('voice_zoneRadius', 16) * 2
	local zoneOffset = (256 / zoneRadius)
	-- this code might be hard to follow
	return (
		--[[ 31 is the initial offses]]
		math.floor( 31 * ( --[[ offset from the original zone should return a multiple]] zoneOffset) + 
	--[[ returns -6 * zoneOffset so we want to offset it ]]
	(zoneOffset * 6) - 6 )) 
	+ (--[[ Offset routing bucket by 5 (we listen to closest 5 channels) + 5 (routing starts at 0)]]((LocalPlayer.state.routingBucket or 0) * 5) + 5) + math.ceil((plyPos.x + plyPos.y) / (zoneRadius))
end

--- function updateZone
--- updates the players current grid, if they're in a different grid.
---@param forced boolean whether or not to force a grid refresh. default: false
local function updateZone(forced)
	local newGrid = getGridZone()
	if newGrid ~= currentGrid or forced then
        logger.info(('Updating zone from %s to %s and adding nearby grids.'):format(currentGrid, newGrid))
		currentGrid = newGrid
		MumbleClearVoiceTargetChannels(1)
		NetworkSetVoiceChannel(currentGrid)
		LocalPlayer.state:set('channel', currentGrid, true)
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
		Wait(100)
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

	-- sets how far the player can talk
	MumbleSetAudioInputDistance(Cfg.voiceModes[mode][1] + 0.0)
	LocalPlayer.state:set('proximity', Cfg.voiceModes[mode][1] + 0.0, true)

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

AddEventHandler('mumbleConnected', function(address, shouldReconnect)
	logger.log('Connected to mumble server with address of %s, should reconnect on disconnect is set to %s', GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address, shouldReconnect)
end)

AddEventHandler('mumbleDisconnected', function(address)
	logger.log('Disconnected from mumble server with address of %s', GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address)
end)
