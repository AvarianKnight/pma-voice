voiceData = {}
radioData = {}
callData = {}
mumbleConfig = {
	debug = false, -- enable debug msgs
	voiceModes = {
		{2.5, "Whisper"}, -- Whisper speech distance in gta distance units
		{8.0, "Normal"}, -- Normal speech distance in gta distance units
		{20.0, "Shouting"}, -- Shout speech distance in gta distance units
	},
	speakerRange = 1.5, -- Speaker distance in gta distance units (how close you need to be to another player to hear other players on the radio or phone)
	callSpeakerEnabled = true, -- Allow players to hear all talking participants of a phone call if standing next to someone that is on the phone
	radioEnabled = true, -- Enable or disable using the radio
	micClicks = true, -- Are clicks enabled or not
	micClickOn = true, -- Is click sound on active
	micClickOff = true, -- Is click sound off active
	micClickVolume = 0.1, -- How loud a mic click is
	radioClickMaxChannel = 100, -- Set the max amount of radio channels that will have local radio clicks enabled
	controls = { -- Change default key binds
		proximity = {
			key = 20, -- Z
		}, -- Switch proximity mode
		radio = {
			pressed = false, -- don't touch
			key = 137, -- capital
		}, -- Use radio
		speaker = {
			key = 20, -- Z
			secondary = 21, -- LEFT SHIFT
		} -- Toggle speaker mode (phone calls)
	},
	radioChannelNames = { -- Add named radio channels (Defaults to [channel number] MHz)
		[1] = "LEO Tac 1",
		[2] = "LEO Tac 2",
		[3] = "EMS Tac 1",
		[4] = "EMS Tac 2",
		[500] = "Hurr Durr 500 Hurr Durr",
	},
	callChannelNames = { -- Add named call channels (Defaults to [channel number])

	},
	use3dAudio = true, -- Enable 3D Audio
	useSendingRangeOnly = true, -- Use sending range only for proximity voice (don't recommend setting this to false)
	useNativeAudio = false, -- Use native audio (audio occlusion in interiors)
	useExternalServer = false, -- Use an external voice server (bigger servers need this), tutorial: https://forum.cfx.re/t/how-to-host-fivems-voice-chat-mumble-in-another-server/1487449?u=frazzle
	externalAddress = "127.0.0.1",
	externalPort = 30120,
	use2dAudioInVehicles = true, -- Workaround for hearing vehicle passengers at high speeds
	showRadioList = false, -- Optional feature to show a list of players in a radio channel, to be used with server export `SetPlayerRadioName`
}
resourceName = GetCurrentResourceName()
phoneticAlphabet = {
	"Alpha",
	"Bravo",
	"Charlie",
	"Delta",
	"Echo",
	"Foxtrot",
	"Golf",
	"Hotel",
	"India",
	"Juliet",
	"Kilo",
	"Lima",
	"Mike",
	"November",
	"Oscar",
	"Papa",
	"Quebec",
	"Romeo",
	"Sierra",
	"Tango",
	"Uniform",
	"Victor",
	"Whisky",
	"XRay",
	"Yankee",
	"Zulu",
}

if IsDuplicityVersion() then
	function DebugMsg(msg)
		if mumbleConfig.debug then
			print("\x1b[32m[" .. resourceName .. "]\x1b[0m ".. msg)
		end
	end
else
	function DebugMsg(msg)
		if mumbleConfig.debug then
			print("[" .. resourceName .. "] ".. msg)
		end
	end

	-- Update config properties from another script
	function SetMumbleProperty(key, value)
		if mumbleConfig[key] ~= nil and mumbleConfig[key] ~= "controls" and mumbleConfig[key] ~= "radioChannelNames" then
			mumbleConfig[key] = value

			if key == "callSpeakerEnabled" then
				SendNUIMessage({ speakerOption = mumbleConfig.callSpeakerEnabled })
			end
		end
	end

	function SetRadioChannelName(channel, name)
		local channel = tonumber(channel)

		if channel ~= nil and name ~= nil and name ~= "" then
			if not mumbleConfig.radioChannelNames[channel] then
				mumbleConfig.radioChannelNames[channel] = tostring(name)
			end
		end
	end

	function SetCallChannelName(channel, name)
		local channel = tonumber(channel)

		if channel ~= nil and name ~= nil and name ~= "" then
			if not mumbleConfig.callChannelNames[channel] then
				mumbleConfig.callChannelNames[channel] = tostring(name)
			end
		end
	end

	-- Make exports available on first tick
	exports("SetMumbleProperty", SetMumbleProperty)
	exports("SetTokoProperty", SetMumbleProperty)
	exports("SetRadioChannelName", SetRadioChannelName)
	exports("SetCallChannelName", SetCallChannelName)
end

function GetRandomPhoneticLetter()
	math.randomseed(GetGameTimer())

	return phoneticAlphabet[math.random(1, #phoneticAlphabet)]
end

function GetPlayersInRadioChannel(channel)
	local channel = tonumber(channel)
	local players = false

	if channel ~= nil then
		if radioData[channel] ~= nil then
			players = radioData[channel]
		end
	end

	return players
end

function GetPlayersInRadioChannels(...)
	local channels = { ... }
	local players = {}

	for i = 1, #channels do
		local channel = tonumber(channels[i])

		if channel ~= nil then
			if radioData[channel] ~= nil then
				players[#players + 1] = radioData[channel]
			end
		end
	end

	return players
end

function GetPlayersInAllRadioChannels()
	return radioData
end

function GetPlayersInPlayerRadioChannel(serverId)
	local players = false

	if serverId ~= nil then
		if voiceData[serverId] ~= nil then
			local channel = voiceData[serverId].radio
			if channel > 0 then
				if radioData[channel] ~= nil then
					players = radioData[channel]
				end
			end
		end
	end

	return players
end

function GetPlayerRadioChannel(serverId)
	if serverId ~= nil then
		if voiceData[serverId] ~= nil then
			return voiceData[serverId].radio
		end
	end
end

function GetPlayerCallChannel(serverId)
	if serverId ~= nil then
		if voiceData[serverId] ~= nil then
			return voiceData[serverId].call
		end
	end
end

exports("GetPlayersInRadioChannel", GetPlayersInRadioChannel)
exports("GetPlayersInRadioChannels", GetPlayersInRadioChannels)
exports("GetPlayersInAllRadioChannels", GetPlayersInAllRadioChannels)
exports("GetPlayersInPlayerRadioChannel", GetPlayersInPlayerRadioChannel)
exports("GetPlayerRadioChannel", GetPlayerRadioChannel)
exports("GetPlayerCallChannel", GetPlayerCallChannel)