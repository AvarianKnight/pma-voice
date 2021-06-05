------------------------------------------------------------
------------------------------------------------------------
---- Author: Dylan 'Itokoyamato' Thuillier              ----
----                                                    ----
---- Email: itokoyamato@hotmail.fr                      ----
----                                                    ----
---- Resource: tokovoip_script                          ----
----                                                    ----
---- File: s_utils.lua                                  ----
------------------------------------------------------------
------------------------------------------------------------

--------------------------------------------------------------------------------
--	Server_utils: Data system functions
--------------------------------------------------------------------------------

local playersData = {};

function setPlayerData(playerServerId, key, data, shared)
	if (shared) then
		if (not playersData[playerServerId]) then
			playersData[playerServerId] = {};
		end
		playersData[playerServerId][key] = data;
		TriggerClientEvent("Tokovoip:setPlayerData", -1, playerServerId, key, data);
	else
		TriggerClientEvent("Tokovoip:setPlayerData", playerServerId, playerServerId, key, data);
	end
end
RegisterNetEvent("Tokovoip:setPlayerData");
AddEventHandler("Tokovoip:setPlayerData", setPlayerData);

function refreshAllPlayerData(toEveryone)
	if (toEveryone) then
		TriggerClientEvent("Tokovoip:doRefreshAllPlayerData", -1, playersData);
	else
		TriggerClientEvent("Tokovoip:doRefreshAllPlayerData", source, playersData);
	end
end
RegisterNetEvent("Tokovoip:refreshAllPlayerData");
AddEventHandler("Tokovoip:refreshAllPlayerData", refreshAllPlayerData);

AddEventHandler("playerDropped", function()
	playersData[source] = nil;
	refreshAllPlayerData(true);
end);

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

local charset = {}  do -- [0-9a-zA-Z]
	for c = 48, 57  do table.insert(charset, string.char(c)) end
	for c = 65, 90  do table.insert(charset, string.char(c)) end
	for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function randomString(length)
	if not length or length <= 0 then return '' end
	math.randomseed(os.clock()^5)
	return randomString(length - 1) .. charset[math.random(1, #charset)]
end
