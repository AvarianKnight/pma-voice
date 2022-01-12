local uiReady = promise.new()
function sendUIMessage(message, respectConvar)
	Citizen.Await(uiReady)
	if respectConvar and GetConvarInt('voice_enableUi', 1) ~= 1 then return end
	SendNUIMessage(message)
end

RegisterNUICallback("uiReady", function(data, cb)
	uiReady:resolve(true)

	cb('ok')
end)