local uiReady = promise.new()
function sendUIMessage(message)
    Citizen.Await(uiReady)
    SendNUIMessage(message)
end

RegisterNUICallback("uiReady", function(data, cb)
    uiReady:resolve(true)

    cb('ok')
end)
