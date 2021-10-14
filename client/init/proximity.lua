-- used when muted
local disableUpdates = false
local isListenerEnabled = false

local currentVoiceTargets = {}

function addNearybyPlayers()
	if disableUpdates then return end
	local coords = GetEntityCoords(PlayerPedId())
	local voiceModeData = Cfg.voiceModes[mode]
	local distance = GetConvar('voice_useNativeAudio', 'false') == 'true' and voiceModeData[1] * 3 or voiceModeData[1]
	local players = GetActivePlayers()
	for i = 1, #players do
		local ply = players[i]
		local serverId = GetPlayerServerId(ply)

		if serverId == playerServerId then goto skip_loop end

		local ped = GetPlayerPed(ply)
		local isTarget = currentVoiceTargets[serverId]
		if #(coords - GetEntityCoords(ped)) < distance then
			if not isTarget then
				logger.verbose('Added %s as a voice target', serverId)
				MumbleAddVoiceTargetChannel(1, serverId)
				currentVoiceTargets[serverId] = true
			end
		elseif isTarget then
			logger.verbose('Removed %s from voice targets', serverId)
			MumbleRemoveVoiceTargetChannel(1, serverId)
			currentVoiceTargets[serverId] = nil
		end

		::skip_loop::
	end
end

function toggleSpectatorListen()
	isListenerEnabled = not isListenerEnabled
	local players = GetActivePlayers()
	if isListenerEnabled then
		for i = 1, #players do
			local ply = players[i]
			local serverId = GetPlayerServerId(ply)
			if serverId == playerServerId then goto skip_loop end
			MumbleAddVoiceChannelListen(serverId)
			::skip_loop::
		end
	else
		for i = 1, #players do
			local ply = players[i]
			local serverId = GetPlayerServerId(ply)
			if serverId == playerServerId then goto skip_loop end
			MumbleRemoveVoiceChannelListen(serverId)
			::skip_loop::
		end
	end
end
exports('toggleSpectatorListen', toggleSpectatorListen)

RegisterNetEvent('onPlayerJoining', function(serverId)
	if isListenerEnabled then
		MumbleAddVoiceChannelListen(serverId)
	end
end)

RegisterNetEvent('onPlayerDropped', function(serverId)
	if isListenerEnabled then
		MumbleRemoveVoiceChannelListen(serverId)
	end
	if currentVoiceTargets[serverId] then
		currentVoiceTargets[serverId] = nil
		MumbleRemoveVoiceChannelListen(serverId)
	end
end)

-- cache talking status so we only send a nui message when its not the same as what it was before
local lastTalkingStatus = false
local lastRadioStatus = false
Citizen.CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/mute', 'Mutes the player with the specified id', {
		{ name = "player id", help = "the player to toggle mute" }
	})
	while true do
		-- wait for mumble to reconnect
		while not MumbleIsConnected() do
			Wait(100)
		end
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
		addNearybyPlayers()
		Wait(GetConvarInt('voice_uiRefreshRate', 200))
	end
end)
