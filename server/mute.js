let mutedPlayers = {}
// this is implemented in JS due to Lua's lack of a ClearTimeout
// muteply instead of mute because mute conflicts with rp-radio
RegisterCommand('muteply', (source, args) => {
	const mutePly = parseInt(args[0])
	const duration = parseInt(args[1]) || 900
	if (mutePly && exports[GetCurrentResourceName()].isValidPlayer(mutePly)) {
		const isMuted = !MumbleIsPlayerMuted(mutePly);
		Player(mutePly).state.muted = isMuted;
		MumbleSetPlayerMuted(mutePly, isMuted);
		emit('pma-voice:playerMuted', mutePly, source, isMuted, duration);
		// since this is a toggle, if theres a mutedPlayers entry it can be assumed
		// that they're currently muted, so we'll clear the timeout and unmute
		if (mutedPlayers[mutePly]) {
			clearTimeout(mutedPlayers[mutePly]);
			MumbleSetPlayerMuted(mutePly, isMuted)
			Player(mutePly).state.muted = isMuted;
			return;
		}
		mutedPlayers[mutePly] = setTimeout(() => {
			MumbleSetPlayerMuted(mutePly, !isMuted)
			Player(mutePly).state.muted = !isMuted;
			delete mutedPlayers[mutePly]
		}, duration * 1000)
	}
}, true)
