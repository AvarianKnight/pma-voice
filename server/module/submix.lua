AddEventHandler('playerJoining', function()
	TriggerClientEvent("pma-voice:syncSubmixData", source, SubmixData)
end)

removePlayerFromSubmix = function(source)
	if SubmixData[source] then
		SubmixData[source] = nil
		TriggerClientEvent("pma-voice:removePlayerFromSubmix", -1, source)
	end
end
exports('removePlayerFromSubmix', removePlayerFromSubmix)

addPlayerToSubmix = function(source, submix)
	if not SubmixData[source] then
		local PlayerData = {
			enabled = true,
			submix = submix
		}
		SubmixData[source] = PlayerData
		TriggerClientEvent("pma-voice:addPlayerToSubmix", -1, source, PlayerData)
	end
end
exports('addPlayerToSubmix', addPlayerToSubmix)