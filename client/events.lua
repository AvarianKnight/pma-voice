AddEventHandler('mumbleConnected', function(address, isReconnecting)
	logger.debug('Connected to mumble server with address of %s, is this a reconnect %s', GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address, isReconnecting)
	-- don't try to set channel instantly, we're still getting data.
	Wait(1000)
	addNearybyPlayers()
end)

AddEventHandler('mumbleDisconnected', function(address)
	logger.debug('Disconnected from mumble server with address of %s', GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address)
end)

-- TODO: Convert the last Cfg to a Convar, while still keeping it simple.
AddEventHandler('pma-voice:settingsCallback', function(cb)
	cb(Cfg)
end)