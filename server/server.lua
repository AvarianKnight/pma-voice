voiceData = {}
radioData = {}
callData = {}

function defaultTable(source)
	return {
		radio = 0,
		call = 0,
		lastRadio = 0,
		lastCall = 0
	}
end

-- temp fix before an actual fix is added
CreateThread(function()
    for i = 1, 1024 do
        MumbleCreateChannel(i)
    end
	if GetConvarInt('voice_enableRadioSubmix', 0) == 1 then
		logger.warn('The convar \'voice_enableRadioSubmix\' is currently deprecated, please use \'voice_enableSubmix\' instead.')
	end
end)

RegisterNetEvent('playerJoined', function()
	if not voiceData[source] then
		voiceData[source] = defaultTable(source)
		Player(source).state:set('routingBucket', 0, true)
	end
end)

--- update/sets the players routing bucket
---@param source number the player to update/set
---@param routingBucket number the routing bucket to set them to
function updateRoutingBucket(source, routingBucket)
	local route
	-- make it optional to provide the routing bucket just incase 
	-- people use another resource to manage their routing buckets.
	if routingBucket then
		SetPlayerRoutingBucket(source, routingBucket)
	else
		route = GetPlayerRoutingBucket(source)
	end
	Player(source).state:set('routingBucket', route or routingBucket, true)
end
exports('updateRoutingBucket', updateRoutingBucket)

AddEventHandler("playerDropped", function()
	local source = source
	if voiceData[source] then
		local plyData = voiceData[source]

		if plyData.radio ~= 0 then
			removePlayerFromRadio(source, plyData.radio)
		end

		if plyData.call ~= 0 then
			removePlayerFromCall(source, plyData.call)
		end

		voiceData[source] = nil
	end
end)

AddEventHandler('onResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	if GetConvar('onesync') == 'on' then
		local players = GetPlayers()
		for i = 1, #players do
			local ply = players[i]
			if not voiceData[ply] then
				voiceData[ply] = defaultTable(ply)
				Player(ply).state:set('routingBucket', GetPlayerRoutingBucket(ply), true)
			end
		end
	end
end)

RegisterCommand('mute', function(source, args)
	local mutePly = tonumber(args[1])
	if mutePly then
		if voiceData[mutePly] then
			TriggerClientEvent('pma-voice:mutePlayer', mutePly)
		end
	end
end, true)

if GetConvarInt('voice_externalDisallowJoin', 0) == 1 then
	AddEventHandler('playerConnecting', function(playerName, kickReason, deferral)
		deferral.defer()
		Wait(0)
		deferral.done('This server is not accepting connections.')
	end)
end
