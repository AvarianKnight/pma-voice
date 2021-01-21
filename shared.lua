Cfg = {
    voiceModes = {
		{3.0, "Whisper"}, -- Whisper speech distance in gta distance units
    	{7.0, "Normal"}, -- Normal speech distance in gta distance units
    	{15.0, "Shouting"} -- Shout speech distance in gta distance units
    },
    radioEnabled = true, -- Enable or disable using the radio
    micClicks = true, -- Are clicks enabled or not
    radioPressed = false,
}

function debug(message)
	if GetConvarInt('voice_debugMode', 0) == 1 then
		print(('[pma-voice:debug] %s'):format(message))
	end
end