# pma-voice
A voice system designed around the use if FiveM's interal mumble voip server.

## NOTE: If you have any issues please make an [Issue](https://github.com/AvarianKnight/pma-voice/issues), DO NOT MESSAGE ME FOR SUPPORT.

# This script is not compatible with other voice systems (duh), that means if you have vMenus voice chat you will **have** to [disable](https://docs.vespura.com/vmenu/faq/#q-how-do-i-disable-voice-chat) it.
# Please do not override NetworkSetTalkerProximity in any of your other scripts as it can break pma-voice.

### Credits

- @Frazzle for the original mumble-voip (for which this is rewritten off of, and some code adapted from)
- @picotm for pVoice (where the grid concept came from)


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
