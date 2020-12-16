local Cfg = Cfg -- micro optimzation

-- this is used for my hud, if you don't want it you can delete it 
AddEventHandler('pma-voice:settingsCallback', function(cb)
    cb(Cfg)
end)

playerServerId = GetPlayerServerId(PlayerId())
voiceData = {
    mode = 2,
    radio = 0,
    call = 0,
    routingBucket = 0
}
radioData = {}
callData = {}
local currentGrid = 0
local volume = 0.3
local zoneRadius = Cfg.zoneRadius -- faster to access than a table
local zoneOffzet = Cfg.zoneOffset
local intialized = false
local voiceTarget = 1

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    while not NetworkIsSessionStarted() do
        Citizen.Wait(10)
    end

    TriggerServerEvent('pma-voice:registerVoiceInfo')

    NetworkSetTalkerProximity(3.0)

    if Cfg.useExternalServer then
		MumbleSetServerAddress(Cfg.externalAddress, Cfg.externalPort)
    end
    
    while not MumbleIsConnected() do
        Citizen.Wait(250)
        print('[pma-voice] Can\'t connect to external server.')
    end

    MumbleSetVoiceTarget(0)
    MumbleClearVoiceTarget(voiceTarget)
    MumbleSetVoiceTarget(voiceTarget)

    updateZone()

    intialized = true
end)

RegisterNetEvent('pma-voice:updateRoutingBucket')
AddEventHandler('pma-voice:updateRoutingBucket', function(routingBucket)
    voiceData.routingBucket = routingBucket
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
	if channel <= Cfg.radioClickMaxChannel then
        if Cfg.micClicks then
            SendNUIMessage({ sound = (value and "audio_on" or "audio_off"), volume = (value and (volume) or 0.05) })
		end
	end
end

RegisterCommand('+cycleproximity', function()
    local voiceMode = voiceData.mode
    local newMode = voiceMode + 1
    
    voiceMode = (newMode <= #Cfg.voiceModes and newMode) or 1
    NetworkSetTalkerProximity(Cfg.voiceModes[voiceMode][1] + 0.0)
    voiceData.mode = voiceMode
end, false)
RegisterCommand('-cycleproximity', function() end)
RegisterKeyMapping('+cycleproximity', 'Cycle Proximity', 'keyboard', 'f11')

function setVoiceProperty(type, value)
    if type == "radioEnabled" then
        Cfg.radioEnabled = value
    elseif type == "micClick" then
        Cfg.micClicks = value
    end
end
exports('setVoiceProperty', setVoiceProperty)

local function getGridZone()
    local plyPos = GetEntityCoords(PlayerPedId(), false)
    local offset = zoneOffzet
    -- just increase offset so players can't be in the same zone (so they can't hear eachother)
    if Cfg.enableRouteSupport then
        offset = zoneOffzet + voiceData.routingBucket
    end
    local grid = offset + math.ceil((plyPos.x + plyPos.y) / (zoneRadius * 2))
    return grid
end

local function updateZone()
    local newGrid = getGridZone()
    if newGrid ~= currentGrid then
        currentGrid = newGrid
        MumbleClearVoiceTargetChannels(voiceTarget)
        NetworkSetVoiceChannel(currentGrid)
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
