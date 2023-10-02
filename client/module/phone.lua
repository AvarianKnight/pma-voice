local callChannel = 0

RegisterNetEvent('pma-voice:syncCallData', function(callTable, channel)
	callData = callTable
	handleRadioAndCallInit()
end)

RegisterNetEvent('pma-voice:addPlayerToCall', function(plySource)
	toggleVoice(plySource, true, 'call')
	callData[plySource] = true
end)

RegisterNetEvent('pma-voice:removePlayerFromCall', function(plySource)
	if plySource == playerServerId then
		for tgt, _ in pairs(callData) do
			if tgt ~= playerServerId then
				toggleVoice(tgt, false, 'call')
			end
		end
		callData = {}
		MumbleClearVoiceTargetPlayers(voiceTarget)
		addVoiceTargets(radioPressed and radioData or {}, callData)
	else
		callData[plySource] = nil
		toggleVoice(plySource, false, 'call')
		if MumbleIsPlayerTalking(PlayerId()) then
			MumbleClearVoiceTargetPlayers(voiceTarget)
			addVoiceTargets(radioPressed and radioData or {}, callData)
		end
	end
end)

function setCallChannel(channel)
	if GetConvarInt('voice_enableCalls', 1) ~= 1 then return end
	TriggerServerEvent('pma-voice:setPlayerCall', channel)
	callChannel = channel
	sendUIMessage({
		callInfo = channel
	})
end

exports('setCallChannel', setCallChannel)
exports('SetCallChannel', setCallChannel)

exports('addPlayerToCall', function(_call)
	local call = tonumber(_call)
	if call then
		setCallChannel(call)
	end
end)
exports('removePlayerFromCall', function()
	setCallChannel(0)
end)

RegisterNetEvent('pma-voice:clSetPlayerCall', function(_callChannel)
	if GetConvarInt('voice_enableCalls', 1) ~= 1 then return end
	callChannel = _callChannel
end)
