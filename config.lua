mumbleConfig = {
	voiceModes = {
		{3.0, "Whisper"}, -- Whisper speech distance in gta distance units
        {7.0, "Normal"}, -- Normal speech distance in gta distance units
		{15.0, "Shouting"}, -- Shout speech distance in gta distance units
	},
	radioEnabled = true, -- Enable or disable using the radio
	micClicks = true, -- Are clicks enabled or not
	micClickOn = true, -- Is click sound on active
	micClickOff = true, -- Is click sound off active
	micClickVolume = 0.05, -- How loud a mic click is
	radioPressed = false,
	radioClickMaxChannel = 1000, -- Set the max amount of radio channels that will have local radio clicks enabled
	useNativeAudio = false, -- Use native audio (audio occlusion in interiors)
	useExternalServer = false, -- if you use an external you have to manually make the 500 channels
	externalAddress = "127.0.0.1",
	externalPort = 64985,
}

if not IsDuplicityVersion() then
    AddEventHandler('pma-voice:settingsCallback', function(cb)
        cb(mumbleConfig)
    end)
end
