--- validator helper for state values that are expected to be a number
---@param value any the value to check
---@return boolean isNumber whether the value is a number
local function isNumber(value)
	return type(value) == 'number'
end

--- the keys a client is allowed to set on its own state bag, mapped to a
--- validator that returns true if the value is the expected type
---@type table<string, fun(value: any): boolean>
local allowedStates = {
	radioActive = function(value) return type(value) == 'boolean' end,
	proximity   = function(value) return type(value) == 'table' end,
	voiceIntent = function(value) return type(value) == 'string' end,
	radio       = isNumber,
	call        = isNumber,
	click_on    = isNumber,
	click_off   = isNumber,
}

--- server-authoritative state bag write, used when sv_stateBagStrictMode stops
--- clients from replicating their own state bags. validates the key and value
--- type so it can't be abused to write arbitrary state.
---@param key string the state bag key the client wants to set
---@param value any the value to set; nil clears the key, any other value is type checked against allowedStates
RegisterNetEvent('pma-voice:setState', function(key, value)
	local src = source
	local validator = allowedStates[key]
	if not validator then
		return logger.warn("%s sent an invalid state update for an unknown key: %s", src, tostring(key))
	end
	if value ~= nil and not validator(value) then
		return logger.warn("%s sent an invalid value for state '%s' (type: %s)", src, key, type(value))
	end
	Player(src).state:set(key, value, true)
end)

--- updates the players disableRadio bitmask server-side so the read-modify-write
--- can't race between concurrent bit changes.
---@param bit number the bit to add or remove
---@param shouldAdd boolean true to set the bit, false to clear it
RegisterNetEvent('pma-voice:setRadioDisableBit', function(bit, shouldAdd)
	local src = source
	if type(bit) ~= 'number' then
		return logger.warn("%s sent an invalid radio disable bit (type: %s)", src, type(bit))
	end

	-- done against the server's authoritative value so rapid add/remove calls
	-- build on the current value, not a stale client copy (see applyRadioDisableBit)
	local curVal = applyRadioDisableBit(Player(src).state.disableRadio or 0, bit, shouldAdd)
	Player(src).state:set('disableRadio', curVal, true)
end)
