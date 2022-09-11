AddStateBagChangeHandler("submix", "", function(bagName, _, value)
  local tgtId = tonumber(bagName:gsub('player:', ''), 10)
  if not tgtId then return end
  logger.info("%s had their submix set to %s", tgtId, value)
  -- We got an invalid submix, discard we don't care about it
  if value and not submixIndicies[value] then return logger.warn("Player %s applied submix %s but it isn't valid", tgtId, value) end
  -- we don't want to reset submix if the player is talking on the radio
  if not value and not radioData[tgtId] and not callData[tgtId] then
    logger.info("Resetting submix for player %s", tgtId)
    MumbleSetSubmixForServerId(tgtId, -1)
    return
  end
  MumbleSetSubmixForServerId(tgtId, submixIndicies[value])
end)
