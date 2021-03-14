collectgarbage('generational')
local Cfg = Cfg
local currentGrid = 0
local volume = 0.3
if GetConvar('voice_useNativeAudio', 'false') == 'true' and GetConvarInt('voice_enableRadioSubmix', 0) == 1  then
	volume = 0.5
end
local intialized = false
local voiceTarget = 1
local micClicks = true
playerServerId = GetPlayerServerId(PlayerId())

-- is there really a reason to next these under a table?
voiceData = {
	radioEnabled = false,
	radioPressed = false,
	mode = 2,
	radio = 0,
	call = 0
}
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
	if GetConvarInt('voice_enableRadioSubmix', 0) == 1 then
		if enabled and submixType then
			submixFunctions[submixType](plySource)
		else
			MumbleSetSubmixForServerId(plySource, -1)
		end
	end
	MumbleSetVolumeOverrideByServerId(plySource, enabled and volume or -1.0)
end

local currentlyTalking = {}
--- function playerTargets
---Adds players voices to the local players listen channels allowing
---Them to communicate at long range, ignoring proximity range.
---@param targets table expects multiple tables to be sent over
function playerTargets(...)
	local targets = {...}

	currentlyTalking = {}
	MumbleClearVoiceTargetPlayers(voiceTarget)

	for i = 1, #targets do
		for id, _ in pairs(targets[i]) do
			if id == playerServerId or currentlyTalking[id] then
				goto skip_loop
			end
			if not currentlyTalking[id] then
				currentlyTalking[id] = true
				MumbleAddVoiceTargetPlayerByServerId(voiceTarget, id)
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

	local voiceMode = voiceData.mode
	local newMode = voiceMode + 1

	voiceMode = (newMode <= #Cfg.voiceModes and newMode) or 1
	MumbleSetAudioInputDistance(Cfg.voiceModes[voiceMode][1] + 0.0)
	voiceData.mode = voiceMode
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
		MumbleSetAudioInputDistance(0.1)
	else
		MumbleSetAudioInputDistance(Cfg.voiceModes[voiceData.mode][1])
	end
end)

--- function setVoiceProperty
--- sets the specified voice property
---@param type string what voice property you want to change (only takes 'radioEnabled' and 'micClicks')
---@param value any the value to set the type to.
function setVoiceProperty(type, value)
	if type == "radioEnabled" then
		voiceData.radioEnabled = value
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
		debug(('Updating zone from %s to %s and adding nearby grids.'):format(currentGrid, newGrid))
		currentGrid = newGrid
		MumbleClearVoiceTargetChannels(voiceTarget)
		NetworkSetVoiceChannel(currentGrid)
		LocalPlayer.state:set('channel', currentGrid, true)
		-- add nearby grids to voice targets
		for nearbyGrids = currentGrid - 3, currentGrid + 3 do
			MumbleAddVoiceTargetChannel(voiceTarget, nearbyGrids)
		end
	end
end

-- cache their external servers so if it changes in runtime we can reconnect the client.
local externalAddress = GetConvar('voice_externalAddress', '')
local externalPort = GetConvar('voice_externalPort', '')

-- cache talking status so we only send a nui message when its not the same as what it was before
local lastTalkingStatus = false
local lastRadioStatus = false
Citizen.CreateThread(function()
	while not intialized do
		Wait(100)
	end
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
			if lastRadioStatus ~= voiceData.radioPressed or lastTalkingStatus ~= (NetworkIsPlayerTalking(PlayerId()) == 1) then
				lastRadioStatus = voiceData.radioPressed
				lastTalkingStatus = NetworkIsPlayerTalking(PlayerId()) == 1
				SendNUIMessage({
					usingRadio = lastRadioStatus,
					talking = lastTalkingStatus
				})
			end
		end
		-- only set this is its changed previously, as we dont want to set the address every frame.
		if GetConvar('voice_externalAddress', '') ~= externalAddress and GetConvar('voice_externalPort', '') ~= externalPort then
			externalAddress = GetConvar('voice_externalAddress', '')
			externalPort = GetConvar('voice_externalPort', '')
			MumbleSetServerAddress(GetConvar('voice_externalAddress', ''), GetConvar('voice_externalPort', ''))
		end
		Wait(0)
	end
end)


--- forces the player to resync with the mumble server
--- sets their server address (if there is one) and forces their grid to update
RegisterCommand('vsync', function()
	local newGrid = getGridZone()
	print(('[vsync] Forcing zone from %s to %s and resetting voice targets.'):format(currentGrid, newGrid))
	if GetConvar('voice_externalAddress', '') ~= '' and GetConvar('voice_externalPort', '') ~= '' then
		MumbleSetServerAddress(GetConvar('voice_externalAddress', ''), GetConvar('voice_externalPort', ''))
		while not MumbleIsConnected() do
			Wait(250)
		end
	end
	-- reset the players voice targets
	MumbleSetVoiceTarget(0)
	MumbleClearVoiceTarget(voiceTarget)
	MumbleSetVoiceTarget(voiceTarget)
	MumbleClearVoiceTargetPlayers(voiceTarget)
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
	MumbleSetAudioInputDistance(Cfg.voiceModes[voiceData.mode][1] + 0.0)

	-- this sets how far the player can hear.
	MumbleSetAudioOutputDistance(Cfg.voiceModes[#Cfg.voiceModes][1] + 0.0)

	while not MumbleIsConnected() do
		Wait(250)
	end


	MumbleSetVoiceTarget(0)
	MumbleClearVoiceTarget(voiceTarget)
	MumbleSetVoiceTarget(voiceTarget)

	updateZone()

	print('Script initialization finished.')
	intialized = true

	-- not waiting right here (in testing) let to some cases of the UI 
	-- just not working at all.
	Wait(1000)
	if GetConvarInt('voice_enableUi', 1) == 1 then
		SendNUIMessage({
			voiceModes = json.encode(Cfg.voiceModes),
			voiceMode = voiceData.mode - 1
		})
	end
end)

RegisterCommand("grid", function()
	print(('Players current grid is %s'):format(currentGrid))
end)

AddEventHandler('mumbleConnected', function(mumbleServer, reconnecting)
	print(('Successfully connected to mumble server, should reconnect on disconnect: %s'):format(reconnecting))
end)

AddEventHandler('mumbleDisconnected', function(mumbleServer)
	print(('Disconnected from mumble server'):format(mumbleServer or 'undefined'))
end)