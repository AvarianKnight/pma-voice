# pma-voice
A voice system designed around the use if FiveM's interal mumble voip server.

# Compatability Notice:

### This script is not compatible with other voice systems (duh), that means if you have vMenus voice chat you will **have** to [disable](https://docs.vespura.com/vmenu/faq/#q-how-do-i-disable-voice-chat) it.
### Please do not override NetworkSetTalkerProximity in any of your other scripts as it can break pma-voice.


### NOTE: If you have any issues please make an [Issue](https://github.com/AvarianKnight/pma-voice/issues), DO NOT MESSAGE ME FOR SUPPORT.

# Credits

- @Frazzle for the original mumble-voip (for which this is rewritten off of, and some code adapted from)
- @picotm for pVoice (where the grid concept came from)

# Config

All of the config is done via ConVars in order to streamline the process.

The ints are used like a boolean to 0 would be false, 1 true.

| ConVar                | Default | Description                                                 | Paramater(s) |
|-----------------------|---------|-------------------------------------------------------------|--------------|
| voice_enableUi        |    1    | Wheter or not to enable the built in Voice UI               | int          |
| voice_defaultCycle    |   F11   | The default key to cycle the players proximity              | string       |
| voice_defaultRadio    |   LALT  | The default key to use the radio                            | string       |
| voice_externalAddress |	none  | The external address to use to connect to the mumble server | string       |
| voice_externalPort    |   none  | The external port to use                                    | string       |


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
| updateRoutingBucket  | Updates the players routing bucket   | int          |
