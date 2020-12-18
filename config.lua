Cfg = {
    -- enable support for routing buckets, it just offsets the players channel by their routing bucket.
    enableRouteSupport = true,
    -- if you change this you also have to change the base offset from 31!
    -- you have to go to the bottom right corner of the map and print what the current grid
    -- is there and add or subtract till the value is 0.
    zoneRadius = 128,
    zoneOffset = 31,
	voiceModes = {
		{3.0, "Whisper"}, -- Whisper speech distance in gta distance units
        {7.0, "Normal"}, -- Normal speech distance in gta distance units
		{15.0, "Shouting"}, -- Shout speech distance in gta distance units
	},
	radioEnabled = true, -- Enable or disable using the radio
	micClicks = true, -- Are clicks enabled or not
	radioPressed = false, 
    radioClickMaxChannel = 1000, -- Set the max amount of radio channels that will have local radio clicks enabled
    use3dAudio = true, -- use 3d sound
	useNativeAudio = false, -- Use native audio
	useExternalServer = false, -- if you use an external you have to manually make the channels (80 + (64 with route support))
	externalAddress = "127.0.0.1",
	externalPort = 64985,
}