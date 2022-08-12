RegisterNetEvent('pma-voice:addPlayerToSubmix', function(plySource, Value)
	SubmixTable[plySource] = Value
	if plySource ~= playerServerId then
		toggleVoice(plySource, Value.enabled, Value.submix)
	end
end)

RegisterNetEvent('pma-voice:removePlayerFromSubmix', function(plySource)
	SubmixTable[plySource] = nil
	if plySource ~= playerServerId then
		toggleVoice(plySource, false, SubmixTable[plySource].submix)
	end
end)

RegisterNetEvent('pma-voice:syncSubmixData', function(SubmixTable)
	SubmixTable = SubmixTable
	for tgt, Value in pairs(SubmixTable) do
		if tgt ~= playerServerId then
			toggleVoice(tgt, Value.enabled, Value.submix)
		end
	end
end)