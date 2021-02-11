Cfg = {}
if GetConvar('voice_useNativeAudio', 'false') == 'true' then
	Cfg.voiceModes = {
		{0.5, "Whisper"}, -- Whisper speech distance in gta distance units
		{2.0, "Normal"}, -- Normal speech distance in gta distance units
		{5.0, "Shouting"} -- Shout speech distance in gta distance units
	}
else
	Cfg.voiceModes = {
		{3.0, "Whisper"}, -- Whisper speech distance in gta distance units
		{7.0, "Normal"}, -- Normal speech distance in gta distance units
		{15.0, "Shouting"} -- Shout speech distance in gta distance units
	}
end
function debug(message)
	if GetConvarInt('voice_debugMode', 0) == 1 then
		print(('[pma-voice:debug] %s'):format(message))
	end
end
