## isPlayerMuffled

## Description

Returns true if the player is muffled

## Parameters

* **serverId**: The server id of the player we need to check

```lua
local player = GetPlayerFromIndex(2) -- we get a random nearby player
local serverId = GetPlayerServerId(player) -- we get the server id of that player

local muffled = exports['pma-voice']:isPlayerMuffled(serverId)

if muffled then
    print(GetPlayerName(player).." is muffled")
end
```