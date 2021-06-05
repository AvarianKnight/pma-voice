------------------------------------------------------------
------------------------------------------------------------
---- Author: Dylan 'Itokoyamato' Thuillier              ----
----                                                    ----
---- Email: itokoyamato@hotmail.fr                      ----
----                                                    ----
---- Resource: tokovoip_script                          ----
----                                                    ----
---- File: c_utils.lua                                  ----
------------------------------------------------------------
------------------------------------------------------------

--------------------------------------------------------------------------------
--	Utils: Data system functions
--------------------------------------------------------------------------------

local playersData = {};
function setPlayerData(playerServerId, key, data, shared)
	if (not key or data == nil) then return end
	if (not playersData[playerServerId]) then
		playersData[playerServerId] = {};
	end
	playersData[playerServerId][key] = {data = data, shared = shared};
	if (shared) then
		TriggerServerEvent("Tokovoip:setPlayerData", playerServerId, key, data, shared);
	end
end
RegisterNetEvent("Tokovoip:setPlayerData");
AddEventHandler("Tokovoip:setPlayerData", setPlayerData);

function getPlayerData(playerServerId, key)
	if (not playersData[playerServerId] or playersData[playerServerId][key] == nil) then return false; end
	return playersData[playerServerId][key].data;
end

function refreshAllPlayerData(toEveryone)
	TriggerServerEvent("Tokovoip:refreshAllPlayerData", toEveryone);
end
RegisterNetEvent("onClientPlayerReady");
AddEventHandler("onClientPlayerReady", refreshAllPlayerData);

function doRefreshAllPlayerData(serverData)
	for playerServerId, playerData in pairs(serverData) do
		for key, data in pairs(playerData) do
			if (not playersData[playerServerId]) then
				playersData[playerServerId] = {};
			end
			playersData[playerServerId][key] = {data = data, shared = true};
		end
	end
	for playerServerId, playerData in pairs(playersData) do
		for key, data in pairs(playerData) do
			if (not serverData[playerServerId]) then
				playersData[playerServerId] = nil;
			elseif (serverData[playerServerId][key] == nil) then
				playersData[playerServerId][key] = nil;
			end
		end
	end
end
RegisterNetEvent("Tokovoip:doRefreshAllPlayerData");
AddEventHandler("Tokovoip:doRefreshAllPlayerData", doRefreshAllPlayerData);

--------------------------------------------------------------------------------
--	Utils: Drawing functions
--------------------------------------------------------------------------------

function drawTxt(x,y ,width,height,scale, text, r,g,b,a)
	SetTextFont(0);
	SetTextProportional(0);
	SetTextScale(scale, scale);
	SetTextColour(r, g, b, a);
	SetTextDropShadow(0, 0, 0, 0,255);
	SetTextEdge(1, 0, 0, 0, 255);
	SetTextDropShadow();
	SetTextOutline();
	SetTextEntry("STRING");
	AddTextComponentString(text);
	DrawText(x - width / 2, y - height / 2 + 0.005);
end

function draw3dtext(text, posX, posY, posZ, r, g, b, a)
	local _, x, y = World3dToScreen2d(posX, posY, posZ);
	local localPos = GetEntityCoords(GetPlayerPed(localPlayer));
	local dist = GetDistanceBetweenCoords(localPos, posX, posY, posZ);
	local maxDist = 100;
	local size = 0.2;
	local scale = size - size * (dist / maxDist);
	local offsetX = 0.07 + 0.0235 * (dist / maxDist);
	local offsetY = 0.07 + 0.0235 * (dist / maxDist);

	if (dist < maxDist) then
		if (x and y) then
			drawTxt(x + offsetX, y + offsetY, 0.185,0.206, scale, text, r, g, b, a);
		end
	end
end


--------------------------------------------------------------------------------
--	Utils: Table functions
--------------------------------------------------------------------------------

function table.val_to_str (v)
	if ("string" == type(v)) then
		v = string.gsub(v, "\n", "\\n");
		if (string.match(string.gsub(v, "[^'\"]", ""), '^"+$')) then
			return ("'"..v.."'");
		end
		return ('"'..string.gsub(v, '"', '\\"')..'"');
	else
		return ("table" == type(v) and table.tostring(v) or tostring(v));
	end
end

function table.key_to_str (k)
	if ("string" == type(k) and string.match(k, "^[_%a][_%a%d]*$")) then
		return (k);
	else
		return ("["..table.val_to_str(k).."]");
	end
end

function table.tostring(tbl)
	local result, done = {}, {};
	for k, v in ipairs(tbl) do
		table.insert(result, table.val_to_str(v));
		done[k] = true;
	end
	for k, v in pairs(tbl) do
		if (not done[k]) then
			table.insert(result, table.key_to_str(k).."="..table.val_to_str(v));
		end
	end
	return ("{"..table.concat(result, ",").."}");
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end


--------------------------------------------------------------------------------
--	Utils: Printing functions
--------------------------------------------------------------------------------

function notification(str)
	
end

local functionSeen={}
function printFunctions(t,i)
	functionSeen[t]=true;
	local s={};
	local n=0;
	for k in pairs(t) do
		n=n+1 s[n]=k;
	end
	table.sort(s);
	for k,v in ipairs(s) do
		Citizen.Trace(i.." "..v.."\n");
		v=t[v];
		if (type(v)=="table" and not functionSeen[v]) then
			printFunctions(v,i.."\t");
		end
	end
end

function printAllFunctions()
	printFunctions(_G,"")
end


--------------------------------------------------------------------------------
--	Utils: Random functions
--------------------------------------------------------------------------------

function escape(str)
	return str:gsub( "%W", "");
end

Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

-- Make exports available on first tick
exports("getPlayerData", getPlayerData);
exports("setPlayerData", setPlayerData);
exports("refreshAllPlayerData", refreshAllPlayerData);