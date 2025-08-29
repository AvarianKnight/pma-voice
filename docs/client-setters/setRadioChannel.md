# setRadioChannel | addPlayerToRadio | SetRadioChannel

## Description

Sets the local player's primary radio channel. This is the main radio channel and is backwards compatible with all existing scripts.

## Parameters

* **radioChannel** `number` - The primary radio channel to join (1-9999), or 0 to leave

## Usage

### Lua
```lua
exports['pma-voice']:setRadioChannel(channel)
exports['pma-voice']:addPlayerToRadio(channel)  -- Alternative naming
```

### JS
```js
exports['pma-voice'].setRadioChannel(channel);
exports['pma-voice'].SetRadioChannel(channel);  // mumble-voip compatibility
```

## Examples

```lua
-- Joins primary radio channel 1
exports['pma-voice']:setRadioChannel(1)

-- This will remove the player from the primary radio channel
exports['pma-voice']:setRadioChannel(0)

-- Alternative syntax (same functionality)
exports['pma-voice']:addPlayerToRadio(1)
```

## Dual Radio System

Players can now be on both a primary and secondary radio channel simultaneously:

```lua
-- Set primary radio channel
exports['pma-voice']:setRadioChannel(100)

-- Set secondary radio channel  
exports['pma-voice']:setSecondaryRadioChannel(200)

-- Switch which channel you talk on
exports['pma-voice']:switchActiveRadio()
```

## Notes

- **NOTE**: If the player fails the server side radio channel check they will be reset to no channel
- Players can listen to both primary and secondary channels simultaneously
- Use J key (default) to switch between channels for talking
- The primary channel is backwards compatible with all existing scripts
- `addPlayerToRadio` is provided as an 'easier to read' alternative to `setRadioChannel`
