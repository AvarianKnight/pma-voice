local radioChannel = 0
local secondaryRadioChannel = 0
local currentActiveRadio = "primary"
local radioNames = {}
local secondaryRadioNames = {}
local disableRadioAnim = false


local radioAnim = {
	dict = "random@arrests",
	anim = "generic_radio_enter",
}

--- Helper function to combine primary and secondary radio data
--- Used by voice targeting system to enable listening to both channels
---@return table combinedData table containing all radio players from both channels
function getCombinedRadioData()
	local combinedData = {}
	if radioData then
		for playerId, enabled in pairs(radioData) do 
			combinedData[playerId] = enabled 
		end
	end
	if secondaryRadioData then
		for playerId, enabled in pairs(secondaryRadioData) do 
			combinedData[playerId] = enabled 
		end
	end
	return combinedData
end

--- Helper function to send consistent UI updates for radio state
--- Ensures all radio UI messages contain the same data structure
local function sendRadioUIUpdate()
	sendUIMessage({
		radioChannel = radioChannel,
		secondaryRadioChannel = secondaryRadioChannel,
		radioEnabled = isRadioEnabled(),
		currentActiveRadio = currentActiveRadio
	})
end

---@return boolean isEnabled if radioEnabled is true and LocalPlayer.state.disableRadio is 0 (no bits set)
function isRadioEnabled()
	return radioEnabled and LocalPlayer.state.disableRadio == 0
end

---@return boolean isEnabled if radioEnabled is true and LocalPlayer.state.disableRadio is 0 (no bits set) and has primary channel
function isPrimaryRadioEnabled()
	return isRadioEnabled() and radioChannel > 0
end

---@return boolean isEnabled if radioEnabled is true and LocalPlayer.state.disableRadio is 0 (no bits set) and has secondary channel
function isSecondaryRadioEnabled()
	return isRadioEnabled() and secondaryRadioChannel > 0
end

--- event syncRadioData
--- syncs the current players on the radio to the client
---@param radioTable table the table of the current players on the radio
---@param localPlyRadioName string the local players name
---@param radioType string optional radio type, "primary" or "secondary"
function syncRadioData(radioTable, localPlyRadioName, radioType)
	radioType = radioType or "primary"
	
	if radioType == "secondary" then
		secondaryRadioData = radioTable
		logger.info('[radio] Syncing secondary radio table.')
	else
		radioData = radioTable
		logger.info('[radio] Syncing primary radio table.')
	end
	
	if GetConvarInt('voice_debugMode', 0) >= 4 then
		print('-------- ' .. string.upper(radioType) .. ' RADIO TABLE --------')
		tPrint(radioTable)
		print('-----------------------------')
	end

	local isEnabled = isRadioEnabled()

	if isEnabled then
		handleRadioAndCallInit()
	end

	sendRadioUIUpdate()
	
	if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
		local playerServerId = GetPlayerServerId(PlayerId())
		if radioType == "secondary" then
			secondaryRadioNames[playerServerId] = localPlyRadioName
		else
			radioNames[playerServerId] = localPlyRadioName
		end
	end
	
	addVoiceTargets(getCombinedRadioData(), callData)
end

RegisterNetEvent('pma-voice:syncRadioData', syncRadioData)
RegisterNetEvent('pma-voice:syncSecondaryRadioData', function(radioTable, localPlyRadioName)
	syncRadioData(radioTable, localPlyRadioName, "secondary")
end)

--- event setTalkingOnRadio
--- sets the players talking status, triggered when a player starts/stops talking.
---@param plySource number the players server id.
---@param enabled boolean whether the player is talking or not.
function setTalkingOnRadio(plySource, enabled)
	-- Update the talking status in the appropriate data structure
	if radioData[plySource] ~= nil then
		radioData[plySource] = enabled
	end
	if secondaryRadioData[plySource] ~= nil then
		secondaryRadioData[plySource] = enabled
	end

	if not isRadioEnabled() then return logger.info("[radio] Ignoring setTalkingOnRadio. radioEnabled: %s disableRadio: %s", radioEnabled, LocalPlayer.state.disableRadio) end
	-- If we're on a call we don't want to toggle their voice disabled this will break calls.
	local finalEnabled = enabled or callData[plySource]
	toggleVoice(plySource, finalEnabled, 'radio')
	playMicClicks(enabled)
end
RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

--- event addPlayerToRadio
--- adds a player onto the radio.
---@param plySource number the players server id to add to the radio.
---@param plyRadioName string the players radio name
---@param channel number the radio channel they joined
function addPlayerToRadio(plySource, plyRadioName, channel)
	-- Determine if this is our primary or secondary channel
	if channel == radioChannel then
		radioData[plySource] = false
		if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
			radioNames[plySource] = plyRadioName
		end
	elseif channel == secondaryRadioChannel then
		secondaryRadioData[plySource] = false
		if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
			secondaryRadioNames[plySource] = plyRadioName
		end
	end
	
	logger.info('[radio] %s joined radio %s %s', plySource, channel or "unknown",
		radioPressed and " while we were talking, adding them to targets" or "")
	
	if radioPressed then
		addVoiceTargets(getCombinedRadioData(), callData)
	end
end
RegisterNetEvent('pma-voice:addPlayerToRadio', addPlayerToRadio)

--- event removePlayerFromRadio
--- removes the player (or self) from the radio
---@param plySource number the players server id to remove from the radio.
---@param channel number the radio channel they left
function removePlayerFromRadio(plySource, channel)
	if plySource == playerServerId then
		-- If it's us leaving, determine which channel and clean up accordingly
		if channel == radioChannel then
			logger.info('[radio] Left primary radio %s, cleaning up.', channel)
			for tgt, _ in pairs(radioData) do
				if tgt ~= playerServerId then
					toggleVoice(tgt, false, 'radio')
				end
			end
			radioNames = {}
			radioData = {}
			radioChannel = 0
		elseif channel == secondaryRadioChannel then
			logger.info('[radio] Left secondary radio %s, cleaning up.', channel)
			for tgt, _ in pairs(secondaryRadioData) do
				if tgt ~= playerServerId then
					toggleVoice(tgt, false, 'radio')
				end
			end
			secondaryRadioNames = {}
			secondaryRadioData = {}
			secondaryRadioChannel = 0
		end
		sendRadioUIUpdate()
		addVoiceTargets(getCombinedRadioData(), callData)
	else
		-- Someone else left, remove them from the appropriate channel
		if channel == radioChannel and radioData[plySource] then
			radioData[plySource] = nil
			if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
				radioNames[plySource] = nil
			end
		elseif channel == secondaryRadioChannel and secondaryRadioData[plySource] then
			secondaryRadioData[plySource] = nil
			if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
				secondaryRadioNames[plySource] = nil
			end
		end
		
		toggleVoice(plySource, false, 'radio')
		if radioPressed then
			logger.info('[radio] %s left radio %s while we were talking, updating targets.', plySource, channel)
			addVoiceTargets(getCombinedRadioData(), callData)
		else
			logger.info('[radio] %s has left radio %s', plySource, channel)
		end
	end
end

RegisterNetEvent('pma-voice:removePlayerFromRadio', removePlayerFromRadio)

RegisterNetEvent('pma-voice:radioChangeRejected', function()
	logger.info("The server rejected your radio change.")
	radioChannel = 0
end)

--- function setRadioChannel
--- sets the local players current radio channel and updates the server
---@param channel number the channel to set the player to, or 0 to remove them.
function setRadioChannel(channel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	type_check({ channel, "number" })
	TriggerServerEvent('pma-voice:setPlayerRadio', channel, "primary")
	radioChannel = channel
end

--- Sets the local player's secondary radio channel
--- Works identically to setRadioChannel but for the secondary radio
---@param channel number The channel to join (1-999) or 0 to leave current secondary channel
function setSecondaryRadioChannel(channel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	type_check({ channel, "number" })
	TriggerServerEvent('pma-voice:setPlayerRadio', channel, "secondary")
	secondaryRadioChannel = channel
end

--- Switches the active radio channel for transmission
--- Players can listen to both channels but only talk on the active one
--- Cycles between primary and secondary if both channels are active
function switchActiveRadio()
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	if radioPressed then return end -- Prevent switching while talking on radio
	
	if currentActiveRadio == "primary" and secondaryRadioChannel > 0 then
		currentActiveRadio = "secondary"
	elseif currentActiveRadio == "secondary" and radioChannel > 0 then
		currentActiveRadio = "primary"
	end
	
	sendRadioUIUpdate()
end

--- exports setRadioChannel
--- sets the local players current radio channel and updates the server
exports('setRadioChannel', setRadioChannel)
-- mumble-voip compatability
exports('SetRadioChannel', setRadioChannel)

--- exports setSecondaryRadioChannel
--- sets the local players current secondary radio channel and updates the server
exports('setSecondaryRadioChannel', setSecondaryRadioChannel)

--- exports switchActiveRadio
--- switches between primary and secondary radio for talking
exports('switchActiveRadio', switchActiveRadio)

--- exports removePlayerFromRadio
--- sets the local players current radio channel and updates the server
exports('removePlayerFromRadio', function()
	setRadioChannel(0)
end)

--- exports addPlayerToRadio
--- sets the local players current radio channel and updates the server
---@param _radio number the channel to set the player to, or 0 to remove them.
exports('addPlayerToRadio', function(_radio)
	local radio = tonumber(_radio)
	if radio then
		setRadioChannel(radio)
	end
end)

--- exports addPlayerToSecondaryRadio
--- sets the local players current secondary radio channel and updates the server
---@param _radio number the channel to set the player to, or 0 to remove them.
exports('addPlayerToSecondaryRadio', function(_radio)
	local radio = tonumber(_radio)
	if radio then
		setSecondaryRadioChannel(radio)
	end
end)

--- exports toggleRadioAnim
--- toggles whether the client should play radio anim or not, if the animation should be played or notvaliddance
exports('toggleRadioAnim', function()
	disableRadioAnim = not disableRadioAnim
	TriggerEvent('pma-voice:toggleRadioAnim', disableRadioAnim)
end)

exports("setDisableRadioAnim", function(shouldDisable)
	disableRadioAnim = shouldDisable
end)

-- exports disableRadioAnim
--- returns whether the client is undercover or not
exports('getRadioAnimState', function()
	return disableRadioAnim
end)

--- check if the player is dead
--- seperating this so if people use different methods they can customize
--- it to their need as this will likely never be changed
--- but you can integrate the below state bag to your death resources.
--- LocalPlayer.state:set('isDead', true or false, false)
function isDead()
	if LocalPlayer.state.isDead then
		return true
	elseif IsPlayerDead(PlayerId()) then
		return true
	end
	return false
end

function isRadioAnimEnabled()
	if
		GetConvarInt('voice_enableRadioAnim', 1) == 1
		and not (GetConvarInt('voice_disableVehicleRadioAnim', 0) == 1
			and IsPedInAnyVehicle(PlayerPedId(), false))
		and not disableRadioAnim then
		return true
	end
	return false
end

RegisterCommand('+radiotalk', function()
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	if isDead() then return end
	if not isRadioEnabled() then return end
	if not radioPressed then
		local activeChannel = (currentActiveRadio == "primary") and radioChannel or secondaryRadioChannel
		if activeChannel > 0 then
			logger.info('[radio] Start broadcasting on %s radio channel %s, update targets and notify server.', currentActiveRadio, activeChannel)
			-- Set voice targets to listen to both radios, but transmit only on active channel
			addVoiceTargets(getCombinedRadioData(), callData)
			TriggerServerEvent('pma-voice:setTalkingOnRadio', true, currentActiveRadio)
			radioPressed = true
			local shouldPlayAnimation = isRadioAnimEnabled()
			playMicClicks(true)
			-- localize here so in the off case someone changes this while its in use we
			-- still remove our dictionary down below here
			local dict = radioAnim.dict
			local anim = radioAnim.anim
			if shouldPlayAnimation then
				RequestAnimDict(dict)
			end
			CreateThread(function()
				TriggerEvent("pma-voice:radioActive", true)
				LocalPlayer.state:set("radioActive", true, true);
				local checkFailed = false
				while radioPressed do
					local activeChannel = (currentActiveRadio == "primary") and radioChannel or secondaryRadioChannel
					if activeChannel < 0 or isDead() or not isRadioEnabled() then
						checkFailed = true
						break
					end
					if shouldPlayAnimation and HasAnimDictLoaded(dict) then
						if not IsEntityPlayingAnim(PlayerPedId(), dict, anim, 3) then
							TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 2.0, -1, 50, 2.0, false,
								false,
							false)
						end
					end
					SetControlNormal(0, 249, 1.0)
					SetControlNormal(1, 249, 1.0)
					SetControlNormal(2, 249, 1.0)
					Wait(0)
				end


				if checkFailed then
					logger.info("Canceling radio talking as the checks have failed.")
					ExecuteCommand("-radiotalk")
				end
				if shouldPlayAnimation then
					RemoveAnimDict(dict)
				end
			end)
		else
			logger.info("Player tried to talk but was not on a radio channel")
		end
	end
end, false)

RegisterCommand('-radiotalk', function()
	local activeChannel = (currentActiveRadio == "primary") and radioChannel or secondaryRadioChannel
	if activeChannel > 0 and radioPressed then
		radioPressed = false
		MumbleClearVoiceTargetPlayers(voiceTarget)
		-- Restore voice targets to continue listening to both radio channels
		addVoiceTargets(getCombinedRadioData(), callData)
		TriggerEvent("pma-voice:radioActive", false)
		LocalPlayer.state:set("radioActive", false, true);
		playMicClicks(false)
		if GetConvarInt('voice_enableRadioAnim', 1) == 1 then
			StopAnimTask(PlayerPedId(), radioAnim.dict, radioAnim.anim, -4.0)
		end
		TriggerServerEvent('pma-voice:setTalkingOnRadio', false, currentActiveRadio)
	end
end, false)
if gameVersion == 'fivem' then
	RegisterKeyMapping('+radiotalk', 'Talk over Radio', 'keyboard', GetConvar('voice_defaultRadio', 'LMENU'))
	RegisterKeyMapping('+switchRadio', 'Switch Radio Channel', 'keyboard', GetConvar('voice_defaultRadioSwitch', 'J'))
end

RegisterCommand('+switchRadio', function()
	switchActiveRadio()
end, false)

local function setRadioTalkAnim(dict, anim)
    type_check({dict, "string"}, {anim, "string"})
    if not DoesAnimDictExist(dict) then
      return error(("Dict: %s did not exist"):format(dict))
    end
    radioAnim.dict = dict
    radioAnim.anim = anim
end

exports('setRadioTalkAnim', setRadioTalkAnim)

--- event syncRadio
--- syncs the players radio, only happens if the radio was set server side.
---@param _radioChannel number the radio channel to set the player to.
---@param radioType string the radio type, "primary" or "secondary"
function syncRadio(_radioChannel, radioType)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	radioType = radioType or "primary"
	
	if radioType == "secondary" then
		logger.info('[radio] secondary radio set serverside update to radio %s', _radioChannel)
		secondaryRadioChannel = _radioChannel
	else
		logger.info('[radio] primary radio set serverside update to radio %s', _radioChannel)
		radioChannel = _radioChannel
	end
end
RegisterNetEvent('pma-voice:clSetPlayerRadio', syncRadio)


--- handles "radioEnabled" changing
---@param wasRadioEnabled boolean whether radio is enabled or not
function handleRadioEnabledChanged(wasRadioEnabled)
	if wasRadioEnabled then
		syncRadioData(radioData, "", "primary")
		syncRadioData(secondaryRadioData, "", "secondary")
	else
		removePlayerFromRadio(playerServerId)
	end
end

--- adds the bit to the disableRadio bits
---@param bit number the bit to add
local function addRadioDisableBit(bit)
	local curVal = LocalPlayer.state.disableRadio or 0
	curVal = curVal | bit
	LocalPlayer.state:set("disableRadio", curVal, true)
end
exports("addRadioDisableBit", addRadioDisableBit)

--- removes the bit from disableRadio
---@param bit number the bit to remove
local function removeRadioDisableBit(bit)
	local curVal = LocalPlayer.state.disableRadio or 0
	curVal = curVal & (~bit)
	LocalPlayer.state:set("disableRadio", curVal, true)
end
exports("removeRadioDisableBit", removeRadioDisableBit)

