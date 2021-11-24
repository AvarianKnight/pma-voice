Cfg = {}

voiceTarget = 1
radioTarget = 2
callTarget = 3

gameVersion = GetGameName()

-- these are just here to satisfy linting
if not IsDuplicityVersion() then
	LocalPlayer = LocalPlayer
	playerServerId = GetPlayerServerId(PlayerId())
	-- TODO: Use MumbleIsPlayerTalking for everything, this was added before https://github.com/citizenfx/fivem/pull/1134/files was added.
	function isPlayerTalking(player)
		if gameVersion == 'fivem' then
			return NetworkIsPlayerTalking(player)
		else
			return MumbleIsPlayerTalking(player)
		end
	end

	function setTalkerProximity(distance)
		if gameVersion == 'fivem' then
			NetworkSetTalkerProximity(distance)
		else
			MumbleSetTalkerProximity(distance)
		end
	end

	function setVoiceChannel(channel)
		if gameVersion == 'fivem' then
			setVoiceChannel(channel)
		else
			MumbleSetVoiceChannel(channel)
		end
	end
end
Player = Player
Entity = Entity

if GetConvar('voice_useNativeAudio', 'false') == 'true' then
	-- native audio distance seems to be larger then regular gta units
	Cfg.voiceModes = {
		{1.5, "Whisper"}, -- Whisper speech distance in gta distance units
		{3.0, "Normal"}, -- Normal speech distance in gta distance units
		{6.0, "Shouting"} -- Shout speech distance in gta distance units
	}
else
	Cfg.voiceModes = {
		{3.0, "Whisper"}, -- Whisper speech distance in gta distance units
		{7.0, "Normal"}, -- Normal speech distance in gta distance units
		{15.0, "Shouting"} -- Shout speech distance in gta distance units
	}
end

logger = {
	['log'] = function(message, ...)
		print((message):format(...))
	end,
	['info'] = function(message, ...)
		if GetConvarInt('voice_debugMode', 0) >= 1 then
			print(('[info] ' .. message):format(...))
		end
	end,
	['warn'] = function(message, ...)
		print(('[^1WARNING^7] ' .. message):format(...))
	end,
	['error'] = function(message, ...)
		error((message):format(...))
	end,
	['verbose'] = function(message, ...)
		if GetConvarInt('voice_debugMode', 0) >= 4 then
			print(('[verbose] ' .. message):format(...))
		end
	end,
}


function tPrint(tbl, indent)
	indent = indent or 0
	for k, v in pairs(tbl) do
		local tblType = type(v)
		local formatting = string.rep("  ", indent) .. k .. ": "

		if tblType == "table" then
			print(formatting)
			tPrint(v, indent + 1)
		elseif tblType == 'boolean' then
			print(formatting .. tostring(v))
		elseif tblType == "function" then
			print(formatting .. tostring(v))
		else
			print(formatting .. v)
		end
	end
end