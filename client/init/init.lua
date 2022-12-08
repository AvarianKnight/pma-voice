
AddEventHandler('onClientResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	print('Starting script initialization')

	-- Some people modify pma-voice and mess up the resource Kvp, which means that if someone
	-- joins another server that has pma-voice, it will error out, this will catch and fix the kvp.
	local success = pcall(function()
		local micClicksKvp = GetResourceKvpString('pma-voice_enableMicClicks')
		if not micClicksKvp then
			SetResourceKvp('pma-voice_enableMicClicks', "true")
		else
			if micClicksKvp ~= 'true' and micClicksKvp ~= 'false' then
				error('Invalid Kvp, throwing error for automatic fix')
			end
			micClicks = micClicksKvp
		end
	end)

	if not success then
		logger.warn('Failed to load resource Kvp, likely was inappropriately modified by another server, resetting the Kvp.')
		SetResourceKvp('pma-voice_enableMicClicks', "true")
		micClicks = 'true'
	end
	sendUIMessage({
		uiEnabled = GetConvarInt("voice_enableUi", 1) == 1,
		voiceModes = json.encode(Cfg.voiceModes),
		voiceMode = mode - 1
	})

	local state = LocalPlayer.state
	local radioChannel = state.RadioChannel
	local secondaryRadioChannel = state.SecondaryRadioChannel
	local callChannel = state.callChannel

	-- Reinitialize channels if they're set.
	if radioChannel ~= 1 and radioChannel ~= nil then
		setRadioChannel(radioChannel)
	end

	if secondaryRadioChannel ~= 1 and secondaryRadioChannel ~= nil then
		setRadioChannel(secondaryRadioChannel, true)
	end

	if callChannel ~= 0 and callChannel ~= 0 then
		setCallChannel(callChannel)
	end

	print('Script initialization finished.')
end)
