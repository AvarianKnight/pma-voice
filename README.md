### Disclaimer: Code in the main repo is considered to be 'dev', please use the [Latest Release](https://github.com/AvarianKnight/pma-voice/releases) for a stable version.

# pma-voice
A voice system designed around the use if FiveM's internal mumble server.

## Support

Please report any issues you have in the GitHub [Issues](https://github.com/AvarianKnight/pma-voice/issues)

### NOTE: It is expected for servers to be on the latest recommended version, which you can find [here for Windows](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) and [here for Linux](https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/).

# Compatibility Notice:

This script is not compatible with other voice systems (duh), that means if you have vMenus voice chat you will **have** to [disable](https://docs.vespura.com/vmenu/faq/#q-how-do-i-disable-voice-chat) it.

Please do not override `NetworkSetTalkerProximity`, `MumbleSetAudioInputDistance`, `MumbleSetAudioOutputDistance` or `NetworkSetVoiceActive` in any of your other scripts as there have been cases where it breaks pma-voice.

# Credits

- @Frazzle for mumble-voip (for which the concept came from)
- @pichotm for pVoice (where the grid concept came from)

# FiveM Config

### NOTE: Only use one of the Audio options (don't enable 3d Audio & Native Audio at the same time), its also recommended to always use voice_useSendingRangeOnly.

You only need to add the convar **if** you're changing the value.

All of the configs here are set using `setr [voice_configOption] [boolean]`

| ConVar                     | Default | Description                                                   | Parameter(s) |
|----------------------------|---------|---------------------------------------------------------------|--------------|
| voice_useNativeAudio       |  false  | Uses the games native audio, will add 3d sound, echo, reverb, and more. Required for submixs   | boolean      |
| voice_use3dAudio           |  false  | DEPRECATED: Use `voice_useNativeAudio` instead. Uses 3d audio, will base voices dependent where the player(s) are. | boolean      |
| voice_use2dAudio           |  false  | Uses 2d audio, will result in same volume sound no matter where they're at until they leave proximity. | boolean      |
| voice_useSendingRangeOnly  |  false  | Only allows you to hear people within your hear/send range, prevents people from connecting to your mumble server and trolling. | boolean      |


# Config

All of the config is done via ConVars in order to streamline the process.

The ints are used like a boolean to 0 would be false, 1 true.

All of the configs here are set using `setr [voice_configOption] [int]` OR `setr [voice_configOption] "[string]"`

#### Note: If a convar defaults to 1 (true) you don't have set it again unless you want to disable it.

### General Voice Settings

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_enableUi               |    1    | Enables the built in user interface                            | int          |
| voice_enableProximityCycle   |    1    | Enables the usage of the F11 proximity key, if disabled players are stuck on the first proximity  | int          |
| voice_defaultCycle           |   F11   | The default key to cycle the players proximity                | string       |
| voice_defaultVolume          |   0.3   | The default volume to set the radio to (has to be between 0.0 and 1.0) *NOTE: Only new joins will have the new value, players that already joined will not.* | float       |


### Phone & Radio

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_enableRadios           |    1    | Enables the radio sub-modules                                 | int          |
| voice_enablePhones           |    1    | Enables the phone sub-modules                                 | int          |
| voice_enableSubmix      |    0    | Enables the submix which adds a radio/phone style submix to their voice | int          |
| voice_enableRadioAnim        |   0     | Enables (grab shoulder mic) animation while talking on the radio.          | int          |
| voice_defaultRadio           |   LALT  | The default key to use the radio                              | string       |

### Grid & Sync

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_zoneRadius        |   256    | Sets the zone radius size, setting this below 256 can cause voice loss among other issues. | int          |
| voice_zoneRefreshRate   |   200    | How often to refresh the grid, higher value leads to issues when in the same car | int     |
| voice_syncData          | 0   | enables state bags to be sync'd server side & to other clients, has to be enabled on startup *NOTE: Requires OneSync (not legacy)* | int        |

### External Server & Misc.
| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_externalAddress        |   none  | The external address to use to connect to the mumble server   | string       |
| voice_externalPort           |   0     | The external port to use                                      | int          |
| voice_debugMode              |   0     | 1 for basic logs, 4 for verbose logs                          | int          |
| voice_externalDisallowJoin   |   0     | Disables players being allowed to join the server, should only be used if you're using a FXServer as a external mumble server. | int          |
| voice_hideEndpoints     | 1   | Hides the mumble address in logs *NOTE: You should only care to hide this for a external server.* | int        |



### Aces
pma-voice comes with a built in /mute command, in order to allow your staff to use it you will have to grand them the ace!

Example:
`add_ace group.superadmin command.mute allow;`

This would only allow the superadmin group to mute players.

### Exports

#### Client

##### Setters
 
| Export              | Description                 | Parameter(s) |
|---------------------|-----------------------------|--------------|
| setVoiceProperty    | Set config options          | string, any  |
| setRadioChannel     | Set radio channel           | int          |
| setCallChannel      | Set call channel            | int          |
| setRadioVolume      | Set radio volume for player | int          |
| setCallVolume       | Set call volume for player  | int          |
| setVolume           | Sets the specified strings volume (currently 'radio' and 'call'), not providing a argument sets both.   | int, string (opt) |
| addPlayerToRadio      | Set radio channel        | int          |
| addPlayerToCall       | Set call channel         | int          |
| removePlayerFromRadio | Remove player from radio |              |
| removePlayerFromCall  | Remove player from call  |              |
| setOverrideCoords  | Overrides the player coords, resets when set to false  | vector3, boolean |

##### Toggles
| Export              | Description                                            | Parameter(s) |
|---------------------|--------------------------------------------------------|--------------|
| toggleMute          | Toggles the current client muted                       |              |
| toggleMutePlayer    | Toggles the selected player muted for the local client | int          |


Supported from mumble-voip / toko-voip

| Export                | Description              | Parameter(s) |
|-----------------------|--------------------------|--------------|
| SetMumbleProperty     | Set config options       | string, any  |
| SetTokoProperty       | Set config options       | string, any  |
| SetRadioChannel       | Set radio channel        | int          |
| SetCallChannel        | Set call channel         | int          |

#### Getters

All getters are done through player states, which requires you to use OneSync Infinity.

You can get the Local Players state with `LocalPlayer.state['state bag here']`, if you want to be able to get the state bags on the server you will have to set `setr voice_syncData 1`, which will enable you to get the clients data on the server & on other clients.

| State Bag     | Description                                                  | Return Type  |
|---------------|--------------------------------------------------------------|--------------|
| proximity     | Returns a table with the mode index, distance, and mode name | table        |
| routingBucket | Returns the players current routing bucket                   | int          |
| grid          | Returns the players current grid                             | int          |
| radioChannel  | Returns the players current radio channel, or 0 for none     | int          |
| callChannel   | Returns the players current call channel, or 0 for none      | int          |


#### Server

##### Setters

| Export               | Description                          | Parameter(s) |
|----------------------|--------------------------------------|--------------|
| setPlayerRadio       | Sets the players radio channel       | int, int     |
| setPlayerCall        | Sets the players call channel        | int, int     |
| updateRoutingBucket  | Updates the players routing bucket, if provided a secondary option it will set & update the players routing bucket.   | int, int (opt) |

##### Getters

###### State Bags
Server side state getters require the voice_syncData convar to be set to 1. You can access the state with `Player(source).state['state bag here']`

| State Bag     | Description                                                  | Return Type  |
|---------------|--------------------------------------------------------------|--------------|
| proximity     | Returns a table with the mode index, distance, and mode name | table        |
| routingBucket | Returns the players current routing bucket                   | int          |
| grid          | Returns the players current grid                             | int          |
| radioChannel  | Returns the players current radio channel, or 0 for none     | int          |
| callChannel   | Returns the players current call channel, or 0 for none      | int          |

###### Exports

| Export                       | Description                                       | Parameter(s) |
|------------------------------|---------------------------------------------------|------|
| getPlayersInRadioChannel     | Gets the current players in a radio channel       | int  |
