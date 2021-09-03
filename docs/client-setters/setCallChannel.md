## setCallChannel | addPlayerToCall | SetCallChannel

## Description

Sets the local players call channel.

## Parameters

* **callChannel**: the call channel to join


```lua
-- Joins call channel 1
exports['pma-voice']:setCallChannel(1)

-- This will remove them from the call channel
exports['pma-voice']:setCallChannel(0)
```

addPlayerToCall is provided as a 'easier to read' version of setCallChannel.

```lua
-- Joins call channel 1
exports['pma-voice']:addPlayerToCall(1)
```