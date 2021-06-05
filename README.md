# mumble-voip

A tokovoip replacement that uses fivems mumble voip

- Radios (one radio channel per player for now)
- Radio mic clicks
- Calls
- Facial animations when talking
- Phone Speaker mode toggle
- Hear nearby calls
- HTML UI
- Voice chat & Microphone disabled warning messages
- 3D Proximity base audio
- Onesync/Infinity/Beyond support
- Grid system for voice channels

### Exports

#### Client

##### Setters
 
| Export              | Description               | Parameter(s) |
|---------------------|---------------------------|--------------|
| SetMumbleProperty   | Set config options        | string, any  |
| SetRadioChannel     | Set radio channel         | int          |
| SetCallChannel      | Set call channel          | int          |
| SetRadioChannelName | Set name of radio channel | int, string  |
| SetCallChannelName  | Set name of call channel  | int, string  |

Supported TokoVOIP Exports

| Export                | Description              | Parameter(s) |
|-----------------------|--------------------------|--------------|
| SetTokoProperty       | Set config options       | string, any  |
| addPlayerToRadio      | Set radio channel        | int          |
| removePlayerFromRadio | Remove player from radio |              |
| addPlayerToCall       | Set call channel         | int          |
| removePlayerFromCall  | Remove player from call  |              |

##### Getters

| Export                         | Description                               | Parameter(s)  | Return type    |
|--------------------------------|-------------------------------------------|---------------|----------------|
| GetPlayersInRadioChannel       | Returns players in a radio channel        | int           | table or false |
| GetPlayersInRadioChannels      | Returns players in radio channels         | int, int, ... | table          |
| GetPlayersInAllRadioChannels   | Returns players in every radio channel    |               | table          |
| GetPlayersInPlayerRadioChannel | Returns players in a player radio channel | int           | table or false |
| GetPlayerRadioChannel          | Returns player radio channel              | int           | int            |
| GetPlayerCallChannel           | Returns player call channel               | int           | int            |

#### Server

##### Setters

| Export               | Description                          | Parameter(s) |
|----------------------|--------------------------------------|--------------|
| SetPlayerRadioName   | Set player name on radio list        | int, string  |

### Credits

- @Itokoyamato for TokoVOIP 
- @Nardah and @crunchFiveM for Testing
- @blattersturm for the grid concept
