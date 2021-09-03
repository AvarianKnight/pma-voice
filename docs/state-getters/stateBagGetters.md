## State Bag Getters/Setters

## Description

State bag getters are a little bit simpler, they just return the current value that is set in the state bag.

## Example for Proximity

```lua
local plyState = Player(source).state
local proximity = plyState.proximity
print(proximity.index) -- prints the index of the proximity as seen in Cfg.voiceModes
print(proximity.distance) -- prints the distance of the proximity
print(proximity.mode) -- prints the mode name of the proximity
```

## Example for routing bucket

## NOTE: The getting portion of this is applicable for `grid`, `radioChannel`, and `callChannel`, the setter portion is not.

```lua
local plyState = Player(source).state
local routing = plyState.routingbucket
print(routing) -- prints the routing bucket that is currently set
```

You can also set the routing bucket! This is useful if you want to change the routing bucket of a player without calling the export.

```lua
local plyState = Player(source).state
plyState:set('routingBucket', 1,--[[should be replicated to client]] true) -- sets the routing bucket to 1
-- You can also do this:
-- the main reason this isn't used in pma-voice is it doesn't show if you want it replicated.
plyState.routingBucket = 1 -- this is the same as the line above
```

