# switchActiveRadio

Switches between primary and secondary radio channels for talking.

## Usage

### Lua
```lua
exports['pma-voice']:switchActiveRadio()
```

### JS
```js
exports['pma-voice'].switchActiveRadio();
```

## Parameters
None

## Description
This function switches which radio channel the player will talk on when using the radio talk key. Players can listen to both primary and secondary channels simultaneously, but can only talk on the currently active channel.

The function automatically switches between:
- Primary → Secondary (if secondary channel is active)
- Secondary → Primary (if primary channel is active)

## Examples

### Lua
```lua
-- Switch between primary and secondary radio for talking
exports['pma-voice']:switchActiveRadio()
```

### JS
```js
// Switch between primary and secondary radio for talking
exports['pma-voice'].switchActiveRadio();
```

## Keybind
By default, players can press **J** to switch between radio channels. This can be configured with the `voice_defaultRadioSwitch` convar.

## Notes
- Players always hear transmissions from both channels regardless of active channel
- Only affects which channel you talk on, not which channels you hear
- The active channel is highlighted in yellow in the voice UI
- If only one channel is active, switching has no effect
- Switching is instant with no delay