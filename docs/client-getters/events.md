## setTalkingMode | settingsCallback | radioACtive

## Description

These event is designed to allow third part applications (like a hud) use the current voice mode of the player, radio state, etc.

```lua
-- default voice mode is 2
local voiceMode = 2
local voiceModes = {}
local usingRadio = false
-- sets the current radio state boolean
AddEventHandler("pma-voice:radioActive", function(radioTalking) usingRadio = radioTalking end)
-- changes the current voice range index
AddEventHandler('pma-voice:setTalkingMode', function(newTalkingRange) voiceMode = newTalkingRange end)
-- returns registered voice modes from shared.lua's `Cfg.voiceModes`
TriggerEvent("pma-voice:settingsCallback", function(voiceSettings)
	local voiceTable = voiceSettings.voiceModes

	-- loop through all voice modes and add them to the table
	-- the percentage is used for the voice mode slider if this was an actual UI
	for i = 1, #voiceTable do
		local distance = math.ceil(((i/#voiceTable) * 100))
		voiceModes[i] = ("%s"):format(distance)
	end
end)
```