Cfg = {
	voiceModes = {
		{3.0, "Whisper"}, -- Whisper speech distance in gta distance units
		{7.0, "Normal"}, -- Normal speech distance in gta distance units
		{15.0, "Shouting"} -- Shout speech distance in gta distance units
	},
}

function debug(message)
	if GetConvarInt('voice_debugMode', 0) == 1 then
		print(('[pma-voice:debug] %s'):format(message))
	end
end
