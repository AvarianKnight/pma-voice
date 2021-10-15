## getPlayersInRadioChannel

## Description

Gets a list of all of the players in the specified radio channel.

## Parameters

* **radioChannel**: The channel to get all the members of

## Returns

Returns a table of all of the players in the specified radio channel

```lua
-- this will return all of the current players in radio channel 1
local players = exports['pma-voice']:getPlayersInRadioChannel(1)
for source, isTalking in pairs(players) do
	print(('%s is in radio channel 1, isTalking: %s'):format(GetPlayerName(source), isTalking))
end
```
