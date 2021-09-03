## updateRoutingBucket

## Description

Updates the routing bucket of the player.

## Notes

If provided a second argument it will also set the player's routing bucket.

## Parameters

* **source**: The player to update the routing bucket of
* (opt) **routingBucket**: the routing bucket to set the player to

```lua
-- this will only update the routing bucket for pma-voice
exports['pma-voice']:updateRoutingBucket(source)
print(Player(source).state.routingBucket) -- this will return what the routing bucket was set to, default is 0
```

```lua
-- this will also set the routing bucket
exports['pma-voice']:updateRoutingBucket(source, 2)
print(Player(source).state.routingBucket) -- this will return 2
```