## getInteriorsWithDisabledAudioOcclusion

## Description

Returns a table with all the interiors with the disabled audio occlusion

```lua
local disabledInteriors = exports['pma-voice']:getInteriorsWithDisabledAudioOcclusion()
print(json.encode(disabledInteriors)) -- {1538445: true, 9304534: true, -134356: true} (interiorId: disabled)

for interiorId, _ in pairs(disabledInteriors) do
    print(interiorId.." has audio occlusion turned off.")
end
```