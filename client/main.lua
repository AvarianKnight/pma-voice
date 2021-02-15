local Cfg = Cfg
local currentGrid = 0
local volume = 0.3
if GetConvar('voice_useNativeAudio', 'false') == 'true' and GetConvarInt('voice_enableRadioSubmix', 0) == 1  then
	volume = 0.5
end
local intialized = false
local voiceTarget = 1
playerServerId = GetPlayerServerId(PlayerId())

voiceData = {
	radioEnabled = false,
	radioPressed = false,
	mode = 2,
	radio = 0,
	call = 0,
	routingBucket = 0
}
radioData = {}
callData = {}

-- TODO: Convert the last Cfg to a Convar, while still keeping it simple.
AddEventHandler('pma-voice:settingsCallback', function(cb)
	cb(Cfg)
end)


RegisterNetEvent('pma-voice:updateRoutingBucket')
AddEventHandler('pma-voice:updateRoutingBucket', function(routingBucket)
	voiceData.routingBucket = routingBucket
end)

-- TODO: Better implementation of this?
RegisterCommand('vol', function(_, args)
	local vol = tonumber(args[1])
	if vol then
		volume = vol / 100
	end
end)

-- radio submix
local radioEffectId = CreateAudioSubmix('Radio')
SetAudioSubmixEffectRadioFx(radioEffectId, 0)
SetAudioSubmixEffectParamInt(radioEffectId, 0, GetHashKey('default'), 1)
AddAudioSubmixOutput(radioEffectId, 0)

local submixFunctions = {
	['radio'] = function(plySource)
		MumbleSetSubmixForServerId(plySource, radioEffectId)
	end,
	['phone'] = function(plySource)
		return 'not implemented'
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

--- function playerTargets
---Adds players voices to the local players listen channels allowing
---Them to communicate at long range, ignoring proximity range.
---@param any table* expects multiple tables to be sent over
function playerTargets(...)
	local targets = {...}

	MumbleClearVoiceTargetPlayers(voiceTarget)

	for i = 1, #targets do
		for id, _ in pairs(targets[i]) do
			MumbleAddVoiceTargetPlayerByServerId(voiceTarget, id)
		end
	end
end

--- function playMicClicks
---plays the mic click if the player has them enabled.
---@param clickType boolean whether to play the 'on' or 'off' click. 
function playMicClicks(clickType)
	local micClicks = GetResourceKvpString('pma-voice_enableMicClicks')
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

---toggles the mute on the local player, you can implement this event into your admin menu to mute players.
RegisterNetEvent('pma-voice:mutePlayer')
AddEventHandler('pma-voice:mutePlayer', function()
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
		SetResourceKvp('pma-voice_enableMicClicks', tostring(value))
	end
end
exports('setVoiceProperty', setVoiceProperty)

--- function getGridZone
--- calculate the players grid
---@return number returns the players current grid.
local function getGridZone()
	local plyPos = GetEntityCoords(PlayerPedId(), false)
	return 31 + (voiceData.routingBucket * 5) + math.ceil((plyPos.x + plyPos.y) / (GetConvarInt('voice_zoneRadius', 128) * 2))
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

-- 'cache' their external stuff so if it changes in runtime we update.
local externalAddress = GetConvar('voice_externalAddress', '')
local externalPort = GetConvar('voice_externalPort', '')

Citizen.CreateThread(function()
	while not intialized do
		Wait(100)
	end
	while true do
		-- wait for reconnection, trying to set your voice channel when theres nothing to set it to is useless.
		while not MumbleIsConnected() do
			currentGrid = -1 -- reset the grid to something out of bounds so it will resync their zone on disconnect.
			Wait(100)
		end
		updateZone()
		if GetConvarInt('voice_enableUi', 1) == 1 then
			SendNUIMessage({
				usingRadio = voiceData.radioPressed,
				talking = NetworkIsPlayerTalking(PlayerId()) == 1
			})
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
	debug(('[pma-voice] [vsync] Forcing zone from %s to %s and adding nearby grids.'):format(currentGrid, newGrid))
	if GetConvar('voice_externalAddress', '') ~= '' and GetConvar('voice_externalPort', '') ~= '' then
		MumbleSetServerAddress(GetConvar('voice_externalAddress', ''), GetConvar('voice_externalPort', ''))
		while not MumbleIsConnected() do
			Wait(250)
		end
	end
	MumbleClearVoiceTargetPlayers(voiceTarget)
	-- force a zone update.
	updateZone(true)
end)

AddEventHandler('onClientResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end

	local micClicks = GetResourceKvpString('pma-voice_enableMicClicks')
	if not micClicks then
		SetResourceKvp('pma-voice_enableMicClicks', tostring(true))
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

	print('[pma-voice] Intitalized voices.')
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
	print(('[pma-voice] Players current grid is %s'):format(currentGrid))
end)