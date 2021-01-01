Cfg = {
    debugMode = true,
    -- enable support for routing buckets, it just offsets the players channel by their routing bucket.
	enableRouteSupport = true,
	-- setting this too high will lead to your server crashing on startup as it makes more channels 
	-- based off of the max routing buckets, going over 1000 channels will lead to the server taking 
	-- longer to make each channel and shortly after, crashing the entire server because it happens on main thread.
	maxRoutingBuckets = 63,
	-- you can change these to whatever key you want, Jaymo released a bunch of the input mappings on the Cfx.re discord
	-- https://cdn.discordapp.com/attachments/553235301632573459/780729758408245258/inputmappings-info.txt
	defaultCycle = 'F11',
	defaultRadio = 'LMENU',
	-- if you change this you also have to change the base offset from 31!
    -- you have to go to the bottom right corner of the map and print what the current grid
	-- is there and add or subtract till the value is 0.
    zoneRadius = 128,
    zoneOffset = 31,
    voiceModes = {
		{3.0, "Whisper"}, -- Whisper speech distance in gta distance units
    	{7.0, "Normal"}, -- Normal speech distance in gta distance units
    	{15.0, "Shouting"} -- Shout speech distance in gta distance units
    },
    -- default on false because every change is pushed from my servers repo where we have our own UI, which we aren't releasing :(
    enableUi = false,
    radioEnabled = true, -- Enable or disable using the radio
    micClicks = true, -- Are clicks enabled or not
    radioPressed = false,
    radioClickMaxChannel = 1000, -- Set the max amount of radio channels that will have local radio clicks enabled
    use3dAudio = true, -- use 3d sound
    useNativeAudio = false, -- Use native audio
    useExternalServer = false, -- if you use an external you have to manually make the channels (80 + (64 with route support))
    externalAddress = "127.0.0.1",
    externalPort = 64985
}

function Cfg.debug(message)
	if Cfg.debugMode then
		print(('[pma-voice:debug] %s'):format(message))
	end
end