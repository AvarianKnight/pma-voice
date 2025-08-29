# setSecondaryRadioChannel

Sets the local player's secondary radio channel.

## Usage

### Lua
```lua
exports['pma-voice']:setSecondaryRadioChannel(channel)
```

### JS
```js
exports['pma-voice'].setSecondaryRadioChannel(channel);
```

## Parameters
- **channel** `number` - The secondary radio channel to join (1-9999), or 0 to leave secondary radio

## Description
This function allows players to join a secondary radio channel while maintaining their primary radio channel. Players can listen to both channels simultaneously but can only talk on the currently active channel (switchable with the radio switch key).

## Examples

### Lua
```lua
-- Join secondary radio channel 200
exports['pma-voice']:setSecondaryRadioChannel(200)

-- Leave secondary radio channel
exports['pma-voice']:setSecondaryRadioChannel(0)
```

### JS
```js
// Join secondary radio channel 200
exports['pma-voice'].setSecondaryRadioChannel(200);

// Leave secondary radio channel
exports['pma-voice'].setSecondaryRadioChannel(0);
```

## Notes
- Players can be on both primary and secondary channels simultaneously
- Players hear transmissions from both channels
- Use `switchActiveRadio()` to change which channel you talk on
- The secondary radio channel is independent of the primary channel
- Backwards compatible - existing scripts using `setRadioChannel()` will still work for primary channel