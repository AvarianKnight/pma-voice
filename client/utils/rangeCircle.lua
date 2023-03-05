AddEventHandler('pma-voice:setTalkingMode', function(mode)
    local distance = Cfg.voiceModes[mode][1]
    DrawVoiceDistanceMarker(distance, Cfg.voiceModes[mode][3], 150)
    ShowNotification(string.format('New Range: ~h~%s', distance .. 'm'))
end)


function DrawVoiceDistanceMarker(distance, color, alpha)
    local r, g, b = color[1], color[2], color[3]
    local pedCoords = GetEntityCoords(PlayerPedId())

    for i = alpha, 0, -5 do
      local a = math.floor((i * alpha) / 150)
        DrawMarker(28, pedCoords.x, pedCoords.y, pedCoords.z - 0.825, 0, 0, 0, 0, 0, 0, distance, distance, 0.02, r, g, b, a, false, true, 2, nil, nil, false)
        Citizen.Wait(750 / alpha)
    end
end

function ShowNotification(text)
	SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
	DrawNotification(false, true)
end
