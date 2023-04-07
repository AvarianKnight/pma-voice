## getMuffledPlayers

## Description

Returns a table with all current muffled players

```lua
local muffledPlayers = exports['pma-voice']:getMuffledPlayers()
print(json.encode(muffledPlayers)) -- {10: true, 1: true, 32: true} (serverId: active)

for serverId, _ in pairs(muffledPlayers) do
    print(serverId.." its muffled")
end
```