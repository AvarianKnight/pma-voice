## setInteriorAudioOcclusionDisabled

## Description

Sets whether the interior has audio occlusion disabled

## Parameters

* **interiorId**: The id of the interior to which we need to set audio occlusion disabled or not

```lua
local interiorId = GetInteriorAtCoords(vector3(436.31, -981.93, 30.75)) -- Los santos police station

exports['pma-voice']:setInteriorAudioOcclusionDisabled(interiorId, true) -- Audio occlusion will NOT be present in this interior.
```