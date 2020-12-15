playerServerId = GetPlayerServerId(PlayerId())
voiceData = {
    mode = 2,
    radio = 0,
    call = 0
}
radioData = {}
callData = {}
local currentGrid = 0
local volume = 0.3
local zoneRadius = 128
local intialized = false
local voiceTarget = 1


RegisterCommand('vol', function(source, args)
    local vol = tonumber(args[1])

    if volume then
        volume = vol / 100
    end
end)

function toggleVoice(tgtId, enabled)
    MumbleSetVolumeOverrideByServerId(tgtId, (enabled and volume) or -1.0)
end

function playerTargets(...)
    local targets = { ... }

    MumbleClearVoiceTargetPlayers(voiceTarget)

	for i = 1, #targets do
		for id, _ in pairs(targets[i]) do
            MumbleAddVoiceTargetPlayerByServerId(voiceTarget, id)
		end
	end
end


function playMicClicks(channel, value)
	if channel <= mumbleConfig.radioClickMaxChannel then
		if mumbleConfig.micClicks then
			if (value and mumbleConfig.micClickOn) or (not value and mumbleConfig.micClickOff) then
				SendNUIMessage({ sound = (value and "audio_on" or "audio_off"), volume = (value and (volume) or 0.05) })
			end
		end
	end
end

RegisterCommand('+radiotalk', function()
    if not mumbleConfig.radioPressed and mumbleConfig.radioEnabled then
        if voiceData.radio > 0 then
            TriggerServerEvent('pma-voice:setTalkingOnRadio', true)
            mumbleConfig.radioPressed = true
            playMicClicks(voiceData.radio, true)
            Citizen.CreateThread(function()
                TriggerEvent("pma-voice:radioActive", true)
                while mumbleConfig.radioPressed do
                    Citizen.Wait(0)
                    SetControlNormal(0, 249, 1.0)
                    SetControlNormal(1, 249, 1.0)
                    SetControlNormal(2, 249, 1.0)
                end
            end)
        end
    end
end, false)

RegisterCommand('-radiotalk', function()
    if voiceData.radio > 0 and mumbleConfig.radioEnabled then
        mumbleConfig.radioPressed = false
        TriggerEvent("pma-voice:radioActive", false)
        playMicClicks(voiceData.radio, false)
        TriggerServerEvent('pma-voice:setTalkingOnRadio', false)
    end
end, false)
RegisterKeyMapping('+radiotalk', 'Talk over Radio', 'keyboard', 'LMENU')


RegisterCommand('+cycleproximity', function()
    local voiceMode = voiceData.mode
    local newMode = voiceMode + 1
    
    voiceMode = (newMode <= #mumbleConfig.voiceModes and newMode) or 1
    NetworkSetTalkerProximity(mumbleConfig.voiceModes[voiceMode][1] + 0.0)
    voiceData.mode = voiceMode
end, false)
RegisterCommand('-cycleproximity', function() end)
RegisterKeyMapping('+cycleproximity', 'Cycle Proximity', 'keyboard', 'f11')

function setVoiceProperty(type, value)
    if type == "radioEnabled" then
        mumbleConfig.radioEnabled = value
    elseif type == "micClick" then
        mumbleConfig.micClicks = value
    end
end
exports('setVoiceProperty', setVoiceProperty)


local function getGridZone()
    local plyPos = GetEntityCoords(PlayerPedId(), false)
    return 100 + math.ceil((plyPos.x + plyPos.y) / (zoneRadius * 2))
end

local function updateZone()
    local newGrid = getGridZone()
        
    if newGrid ~= currentGrid then
        currentGrid = newGrid
        NetworkSetVoiceChannel(currentGrid)
        MumbleClearVoiceTargetChannels(voiceTarget)
        MumbleAddVoiceTargetChannel(voiceTarget, currentGrid)
    end
end

Citizen.CreateThread(function()
    while not intialized do
        Citizen.Wait(100)
    end
    while true do
        updateZone()
        Citizen.Wait(0)
    end
end)


AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    while not NetworkIsSessionStarted() do
        Citizen.Wait(10)
    end

    TriggerServerEvent('pma-voice:registerVoiceInfo')

    NetworkSetTalkerProximity(3.0)

    if mumbleConfig.useExternalServer then
		MumbleSetServerAddress(mumbleConfig.externalAddress, mumbleConfig.externalPort)
    end
    
    while not MumbleIsConnected() do
        Citizen.Wait(250)
    end

    MumbleSetVoiceTarget(0)
    MumbleClearVoiceTarget(voiceTarget)
    MumbleSetVoiceTarget(voiceTarget)

    updateZone()

    intialized = true
end)
