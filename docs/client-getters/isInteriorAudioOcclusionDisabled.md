## isInteriorAudioOcclusionDisabled

## Description

Returns true if the interior as the audio occlusion disabled

## Parameters

* **interiorId**: The id of the interior to which we need to set audio occlusion disabled or not

```lua
local interiorId = GetInteriorAtCoords(vector3(436.31, -981.93, 30.75)) -- Los santos police station
local audioOcclusionDisabled = exports['pma-voice']:isInteriorAudioOcclusionDisabled(interiorId)

if audioOcclusionDisabled then
    print("Audio occlusion in the police station is turned off.")
end
```