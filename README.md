### NOTICE: pma-voice 6.1.0+ requires you to use server build 4837+. It will fail to start on older builds.

# pma-voice
A voice system designed around the use of FiveM/RedM internal mumble server.

## Support

Please report any issues you have in the GitHub [Issues](https://github.com/AvarianKnight/pma-voice/issues)

### NOTE: It is expected for servers to be on the latest recommended version, which you can find [here for Windows](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) and [here for Linux](https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/).

# Compatibility Notice:

This script is not compatible with other voice systems (duh), that means if you have vMenus voice chat you will **have** to [disable](https://docs.vespura.com/vmenu/faq/#q-how-do-i-disable-voice-chat) it.

Please do not override `NetworkSetTalkerProximity`, `MumbleSetAudioInputDistance`, `MumbleSetAudioOutputDistance` or `NetworkSetVoiceActive` in any of your other scripts as there have been cases where it breaks pma-voice.

# Credits

- @Frazzle for mumble-voip (for which the concept came from)
- @pichotm for pVoice (where the grid concept came from)

# FiveM/RedM Config

### NOTE: Only use one of the Audio options (don't enable 3d Audio & Native Audio at the same time), its also recommended to always use voice_useSendingRangeOnly.

You only need to add the convar **if** you're changing the value.

All of the configs here are set using `setr [voice_configOption] [boolean]`

Native audio will not work on RedM, you will have to use 3d audio.

| ConVar                     | Default | Description                                                   | Parameter(s) |
|----------------------------|---------|---------------------------------------------------------------|--------------|
| voice_useNativeAudio       |  false  | **This will not work for RedM** Uses the games native audio, will add 3d sound, echo, reverb, and more. **Required for submixs**   | boolean      |
| voice_use2dAudio           |  false  | Uses 2d audio, will result in same volume sound no matter where they're at until they leave proximity. | boolean      
| voice_use3dAudio           |  false  | Uses 3d audio | boolean |
| voice_useSendingRangeOnly  |  false  | Only allows you to hear people within your hear/send range, prevents people from connecting to your mumble server and trolling. | boolean      |


# Config

### PLEASE NOTE: Any keybind changes only affect new players, if you want to change your key bind go to Key Bindings -> FiveM -> Look for keybinds under 'pma-voice'.

All of the config is done via ConVars in order to streamline the process.

The ints are used like a boolean to 0 would be false, 1 true.

All of the configs here are set using `setr [voice_configOption] [int]` OR `setr [voice_configOption] "[string]"`

#### Note: If a convar defaults to 1 (true) you don't have set it again unless you want to disable it.

### General Voice Settings

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_enableUi               |    1    | Enables the built in user interface                            | int          |
| voice_enableProximityCycle   |    1    | Enables the usage of the F11 proximity key, if disabled players are stuck on the first proximity  | int          |
| voice_defaultCycle           |   F11   | The default key to cycle the players proximity. You can find a list of valid keys [in the Cfx docs](https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/)                | string       |
| voice_defaultVolume          |   0.3   | The default volume to set the radio to (has to be between 0.0 and 1.0) *NOTE: Only new joins will have the new value, players that already joined will not.* | float       |


### Phone & Radio

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_enableRadios           |    1    | Enables the radio sub-modules                                 | int          |
| voice_enablePhones           |    1    | Enables the phone sub-modules                                 | int          |
| voice_enableSubmix      |    0    | Enables the submix which adds a radio/phone style submix to their voice **NOTE: Submixs require native audio** | int          |
| voice_enableRadioAnim        |   0     | Enables (grab shoulder mic) animation while talking on the radio.          | int          |
| voice_defaultRadio           |   LALT  | The default key to use the radio. You can find a list of valid keys [in the FiveM docs](https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/)                             | string       |

### Sync

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_refreshRate   |   200    | How often the UI/Proximity is refreshed | int     |

### External Server & Misc.
| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_allowSetIntent         |   1  | Whether or not to allow players to set their audio intents (you can see more [here](https://docs.fivem.net/natives/?_0x6383526B))  | int       |
| voice_externalAddress        |   none  | The external address to use to connect to the mumble server   | string       |
| voice_externalPort           |   0     | The external port to use                                      | int          |
| voice_debugMode              |   0     | 1 for basic logs, 4 for verbose logs                          | int          |
| voice_externalDisallowJoin   |   0     | Disables players being allowed to join the server, should only be used if you're using a FXServer as a external mumble server. | int          |
| voice_hideEndpoints     | 1   | Hides the mumble address in logs *NOTE: You should only care to hide this for a external server.* | int        |



### Aces

pma-voice comes with a built in /muteply (tgtPly) (duration) command, in order to allow your staff to use it you will have to grand them the ace!

Example:
`add_ace group.superadmin command.muteply allow;`

This would only allow the superadmin group to mute players.

### Exports

#### Client

##### Setters
 
| Export              | Description                 | Parameter(s) |
|---------------------|-----------------------------|--------------|
| [setVoiceProperty](docs/client-setters/setVoiceProperty.md)    | Set config options          | string, any  |
| [setRadioChannel](docs/client-setters/setRadioChannel.md)     | Set radio channel           | int          |
| [setCallChannel](docs/client-setters/setCallChannel.md)      | Set call channel            | int          |
| [setRadioVolume](docs/client-setters/setRadioVolume.md)      | Set radio volume for player | int          |
| [setCallVolume](docs/client-setters/setCallVolume.md)        | Set call volume for player  | int          |
| [addPlayerToRadio](docs/client-setters/setRadioChannel.md)      | Set radio channel        | int          |
| [addPlayerToCall](docs/client-setters/setCallChannel.md)       | Set call channel         | int          |
| [removePlayerFromRadio](docs/client-setters/removePlayerFromRadio.md) | Remove player from radio |              |
| [removePlayerFromCall](docs/client-setters/removePlayerFromCall.md)  | Remove player from call  |              |

##### Toggles

| Export              | Description                                            | Parameter(s) |
|---------------------|--------------------------------------------------------|--------------|
| toggleMutePlayer    | Toggles the selected player muted for the local client | int          |

Supported from mumble-voip / toko-voip

| Export                | Description              | Parameter(s) |
|-----------------------|--------------------------|--------------|
| [SetMumbleProperty](docs/client-setters/setVoiceProperty.md)     | Set config options       | string, any  |
| [SetTokoProperty](docs/client-setters/setVoiceProperty.md)       | Set config options       | string, any  |
| [SetRadioChannel](docs/client-setters/setRadioChannel.md)       | Set radio channel        | int          |
| [SetCallChannel](docs/client-setters/setCallChannel.md)        | Set call channel         | int          |

#### Getters

The majority of setters are done through player states, while a small 


| State Bag     | Description                                                  | Return Type  |
|---------------|--------------------------------------------------------------|--------------|
| [proximity](docs/state-getters/stateBagGetters.md)     | Returns a table with the mode index, distance, and mode name | table        |
| [radioChannel](docs/state-getters/stateBagGetters.md)  | Returns the players current radio channel, or 0 for none     | int          |
| [callChannel](docs/state-getters/stateBagGetters.md)   | Returns the players current call channel, or 0 for none      | int          |

#### Events

These are events designed for third-party resource integration. These are emitted only to the current client.

| Event                    | Description                                                  | Event Params   |
|--------------------------|--------------------------------------------------------------|----------------|
| [pma-voice:settingsCallback](docs/client-getters/events.md) | When emited it will return the current pma-voice settings. | cb(voiceSettings) |
| [pma-voice:radioActive](docs/client-getters/events.md) | Triggered when the radio is activated / deactivated | boolean |
| [pma-voice:setTalkingMode](docs/client-getters/events.md) | Triggered on proximity mode change with the voice mode id | int |


#### Server

##### Setters

| Export               | Description                          | Parameter(s) |
|----------------------|--------------------------------------|--------------|
| [setPlayerRadio](docs/server-setters/setPlayerRadio.md)       | Sets the players radio channel       | int, int     |
| [setPlayerCall](docs/server-setters/setPlayerCall.md)        | Sets the players call channel        | int, int     |
| [addChannelCheck](docs/server-setters/addChannelCheck.md)      | Adds a channel check to the players radio channel | int, function |


##### Getters

###### State Bags
You can access the state with `Player(source).state['state bag here']`

| State Bag     | Description                                                  | Return Type  |
|---------------|--------------------------------------------------------------|--------------|
| [proximity](docs/state-getters/stateBagGetters.md)     | Returns a table with the mode index, distance, and mode name | table        |
| [radioChannel](docs/state-getters/stateBagGetters.md)  | Returns the players current radio channel, or 0 for none     | int          |
| [callChannel](docs/state-getters/stateBagGetters.md)   | Returns the players current call channel, or 0 for none      | int          |


###### Exports

| Export                       | Description                                       | Parameter(s) |
|------------------------------|---------------------------------------------------|------|
| [getPlayersInRadioChannel](docs/server-getters/getPlayersInRadioChannel.md)     | Gets the current players in a radio channel       | int  |
