local AiAccounting = {}

AiAccounting.dataset_tokens = 50000
AiAccounting.recipes = {
  ["bitermotors-terrestrial-ai-token"] = {track = "terrestrial", tokens = 20},
  ["bitermotors-orbital-ai-token"] = {track = "orbital", tokens = 10000},
  ["bitermotors-orbital-ai-token-cluster"] = {track = "orbital", tokens = 25000},
  ["bitermotors-orbital-ai-token-grid-scale"] = {track = "orbital", tokens = 50000},
  ["bitermotors-orbital-ai-token-hyperscale"] = {track = "orbital", tokens = 100000},
  ["bitermotors-orbital-ai-dataset-grid-scale"] = {track = "orbital", tokens = 50000},
  ["bitermotors-orbital-ai-dataset-hyperscale"] = {track = "orbital", tokens = 100000}
}

function AiAccounting.ensure(track)
  track = track or {}
  track.generated = track.generated or 0
  track.native_generated = track.native_generated or 0
  track.bonus_generated = track.bonus_generated or 0
  track.pending_bonus = track.pending_bonus or {}
  track.pending_bonus_total = track.pending_bonus_total or 0
  track.bonus_remainder = track.bonus_remainder or {}
  return track
end

function AiAccounting.record(track, recipe_name, unit_number, quality, native_bonus, level)
  local recipe = AiAccounting.recipes[recipe_name]
  if not recipe then return false end
  AiAccounting.ensure(track)
  track.generated = track.generated + recipe.tokens
  track.native_generated = track.native_generated + recipe.tokens
  -- Research adds to base computation, not to native productivity bonus crafts.
  if recipe.track == "terrestrial" and not native_bonus and (level or 0) > 0 then
    quality = quality or "normal"
    local remainder = track.bonus_remainder[unit_number] or {}
    local amount = (remainder[quality] or 0) + recipe.tokens * level / 10
    local whole = math.floor(amount + 0.000001)
    remainder[quality] = amount - whole
    if remainder[quality] < 0.000001 then remainder[quality] = nil end
    track.bonus_remainder[unit_number] = next(remainder) and remainder or nil
    if whole > 0 then
      local pending = track.pending_bonus[unit_number] or {}
      pending[quality] = (pending[quality] or 0) + whole
      track.pending_bonus[unit_number] = pending
      track.pending_bonus_total = track.pending_bonus_total + whole
    end
  end
  return true
end

function AiAccounting.deliver_bonus(track, unit_number, quality, count)
  local pending = track.pending_bonus[unit_number]
  local delivered = math.min(math.max(0, count), pending and pending[quality] or 0)
  if delivered == 0 then return 0 end
  pending[quality] = pending[quality] - delivered
  if pending[quality] == 0 then pending[quality] = nil end
  if not next(pending) then track.pending_bonus[unit_number] = nil end
  track.pending_bonus_total = track.pending_bonus_total - delivered
  track.generated = track.generated + delivered
  track.bonus_generated = track.bonus_generated + delivered
  return delivered
end

function AiAccounting.discard_pending(track, unit_number)
  local discarded = 0
  for _, count in pairs(track.pending_bonus[unit_number] or {}) do
    discarded = discarded + count
  end
  track.pending_bonus_total = track.pending_bonus_total - discarded
  track.pending_bonus[unit_number] = nil
  track.bonus_remainder[unit_number] = nil
  return discarded
end

return AiAccounting
