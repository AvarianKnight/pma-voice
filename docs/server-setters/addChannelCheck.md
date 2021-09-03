## addChannelCheck

## Description

Adds a channel check to radio channels.

## Parameters

* **channel**: The channel to add the check to.
* **function**: the function to call when the check is triggered, which should return a boolean of if the player is allowed to join the channel..


```lua
-- Example for addChannelCheck
-- this always has to return true/false
exports['pma-voice']:addChannelCheck(1, function(source)
	if IsPlayerAceAllowed(source, 'radio.police') then
		return true
	end
	return false
end)
```