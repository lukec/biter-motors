local TimingWheel = {}

function TimingWheel.ensure(state, slot_count)
  state = state or {}
  state.slot_count = state.slot_count or slot_count or 3600
  state.buckets = state.buckets or {}
  state.due_by_key = state.due_by_key or {}
  state.tokens = state.tokens or {}
  state.size = state.size or 0
  return state
end

local function slot_for(state, due_tick)
  return math.ceil(due_tick / 60) % state.slot_count + 1
end

function TimingWheel.schedule(state, key, due_tick)
  if not key or not due_tick then return end
  local replacing = state.due_by_key[key] ~= nil
  local token = (state.tokens[key] or 0) + 1
  state.tokens[key] = token
  state.due_by_key[key] = due_tick
  if not replacing then state.size = state.size + 1 end
  local slot = slot_for(state, due_tick)
  state.buckets[slot] = state.buckets[slot] or {}
  state.buckets[slot][#state.buckets[slot] + 1] = {key = key, token = token}
end

function TimingWheel.cancel(state, key)
  if state.due_by_key[key] ~= nil then
    state.due_by_key[key] = nil
    state.tokens[key] = (state.tokens[key] or 0) + 1
    state.size = math.max(0, state.size - 1)
  end
end

function TimingWheel.pop_due(state, now_tick, limit)
  local due = {}
  local current_second = math.floor(now_tick / 60)
  local start_second = state.last_second and state.last_second + 1 or current_second
  if current_second - start_second >= state.slot_count then
    start_second = current_second - state.slot_count + 1
  end
  for second = start_second, current_second do
    local slot = second % state.slot_count + 1
    local bucket = state.buckets[slot] or {}
    state.buckets[slot] = nil
    for _, entry in pairs(bucket) do
      if state.tokens[entry.key] == entry.token then
        local due_tick = state.due_by_key[entry.key]
        if due_tick and due_tick <= now_tick and #due < limit then
          state.due_by_key[entry.key] = nil
          state.size = math.max(0, state.size - 1)
          due[#due + 1] = entry.key
        elseif due_tick then
          TimingWheel.schedule(state, entry.key, due_tick <= now_tick and now_tick + 60 or due_tick)
        end
      end
    end
  end
  state.last_second = current_second
  return due
end

return TimingWheel
