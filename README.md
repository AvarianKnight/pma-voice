# pma-voice
A voice system designed around the use if FiveM's internal mumble server.

## Support

### Please report any issues you have in the GitHub [Issues](https://github.com/AvarianKnight/pma-voice/issues)

### NOTE: It is expected for players to be on the latest recommended version (which you can find [here for Windows](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) and [here for Linux](https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/).

# Compatibility Notice:

### This script is not compatible with other voice systems (duh), that means if you have vMenus voice chat you will **have** to [disable](https://docs.vespura.com/vmenu/faq/#q-how-do-i-disable-voice-chat) it.
### Please do not override `NetworkSetTalkerProximity`, `MumbleSetAudioInputDistance`, `MumbleSetAudioOutputDistance` and `NetworkSetVoiceActive` in any of your other scripts as it can break pma-voice.

# Credits

- @Frazzle for mumble-voip (for which the concept came from)
- @pichotm for pVoice (where the grid concept came from)

# FiveM Config

### NOTE: Only use one of the Audio options (don't enable 3d Audio & Native Audio at the same time), its also recommended to always use voice_useSendingRangeOnly.
### You only need to add the convar **if** you're changing the value.

All of the configs here are set using `setr [voice_configOption] [boolean]`

| ConVar                     | Default | Description                                                   | Parameter(s) |
|----------------------------|---------|---------------------------------------------------------------|--------------|
| voice_useNativeAudio       |  false  | Uses the games native audio, will add 3d sound, echo, reverb, and more. Required for submixs   | boolean      |
| voice_use3dAudio           |  false  | Uses 3d audio, will base voices dependent where the player(s) are. | boolean      |
| voice_use2dAudio           |  false  | Uses 2d audio, will result in same volume sound no matter where they're at until they leave proximity. | boolean      |
| voice_useSendingRangeOnly  |  false  | Only allows you to hear people within your hear/send range, prevents people from connecting to your mumble server and trolling. | boolean      |


# Config

All of the config is done via ConVars in order to streamline the process.

The ints are used like a boolean to 0 would be false, 1 true.

| ConVar                  | Default | Description                                                   | Parameter(s) |
|-------------------------|---------|---------------------------------------------------------------|--------------|
| voice_zoneRadius             |   128   | Sets the zone radius size, on bigger servers you might need to set this lower. | int          |
| voice_enableUi               |    1    | Enable the built in user interface                            | int          |
| voice_enableProximityCycle   |    1    | Enables the usage of the F11 proximity key, if disabled players are stuck on the first proximity  | int          |
| voice_enableRadios           |    1    | Enables the radio sub-modules                                 | int          |
| voice_enablePhones           |    1    | Enables the phone sub-modules                                 | int          |
| voice_enableRadioSubmix      |    0    | Enable the radio submix which adds a radio style to the voice | int          |
| voice_defaultCycle           |   F11   | The default key to cycle the players proximity                | string       |
| voice_defaultRadio           |   LALT  | The default key to use the radio                              | string       |
| voice_externalAddress        |   none  | The external address to use to connect to the mumble server   | string       |
| voice_externalPort           |   none  | The external port to use                                      | string       |
| voice_debugMode              |   0     | Enables the debug prints (currently doesn't really do anything, need to add more debugs) | string       |


### Exports

#### Client

##### Setters
 
| Export              | Description               | Parameter(s) |
|---------------------|---------------------------|--------------|
| setVoiceProperty    | Set config options        | string       |
| setRadioChannel     | Set radio channel         | int          |
| setCallChannel      | Set call channel          | int          |

Supported from mumble-voip

| Export                | Description              | Parameter(s) |
|-----------------------|--------------------------|--------------|
| addPlayerToRadio      | Set radio channel        | int          |
| removePlayerFromRadio | Remove player from radio |              |
| addPlayerToCall       | Set call channel         | int          |
| removePlayerFromCall  | Remove player from call  |              |

#### Server

##### Setters

| Export               | Description                          | Parameter(s) |
|----------------------|--------------------------------------|--------------|
| setPlayerRadio       | Sets the players radio channel       | int, int     |
| setPlayerCall        | Sets the players call channel        | int, int     |
| updateRoutingBucket  | Updates the players routing bucket, if provided a secondary option it will set & update the players routing bucket.   | int, int (opt) |
