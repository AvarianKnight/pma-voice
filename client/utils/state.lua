--- Sets a replicated state bag value for the local player.
---
--- When `sv_stateBagStrictMode` is enabled clients are not allowed to replicate
--- their own state bags, so the write is routed through the server instead.
--- When strict mode is off (the default) this behaves exactly like calling
--- `LocalPlayer.state:set(key, value, true)` directly, so existing servers are
--- unaffected.
---@param key string the state bag key to set
---@param value any the value to replicate
function setReplicatedState(key, value)
	if stateBagStrictMode then
		TriggerServerEvent('pma-voice:setState', key, value)
	else
		LocalPlayer.state:set(key, value, true)
	end
end
