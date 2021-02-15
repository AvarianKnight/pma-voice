voiceData = {}
radioData = {}
callData = {}

function defaultTable(source)
	return {
		radio = 0,
		call = 0,
		lastRadio = 0,
		lastCall = 0,
		routingBucket = 0
	}
end

-- micro optimize, local function calls are quite a bit faster.
local defaultTable = defaultTable

-- temp fix before an actual fix is added
CreateThread(function()
    for i = 1, 1024 do
        MumbleCreateChannel(i)
    end
end)

RegisterNetEvent('playerJoined', function()
	if not voiceData[source] then
		voiceData[source] = defaultTable(source)
		TriggerClientEvent('pma-voice:setRoutingBucket', source, 0)
	end
end)

function updateRoutingBucket(source, routingBucket)
	local route = 0
	-- make it optional to provide the routing bucket just incase 
	-- people use another resource to manage their routing buckets.
	if routingBucket then
		SetPlayerRoutingBucket(source, routingBucket)
		route = routingBucket
	else
		route = GetPlayerRoutingBucket(source)
	end
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].routingBucket = route
	TriggerClientEvent('pma-voice:updateRoutingBucket', source, route)
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
				TriggerClientEvent('pma-voice:setRoutingBucket', ply, GetPlayerRoutingBucket(ply))
			end
		end
	end
end)