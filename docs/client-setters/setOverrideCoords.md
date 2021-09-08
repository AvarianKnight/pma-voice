## setOverrideCoords

## Description

Overrides the voice coordinates of the player, useful for spectating a player.

## Parameters

* **coords**: The coordinates to set the player to as a vector3, or false to reset the override.


```lua
-- Set the override to a random coodinate
exports['pma-voice']:setOverrideCoords(vector3(2555.0, -1601.0, 13.0))
-- Reset the override
exports['pma-voice']:setOverrideCoords(false)
-- Sets the override to a specific players coordinates
exports['pma-voice']:setOverrideCoords(GetEntityCoords(GetPlayerPed(3 --[[Player ID]])))
```