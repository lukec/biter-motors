local ProductionHistory = {}

function ProductionHistory.ensure(state)
  state = state or {}
  state.offset = math.max(0, tonumber(state.offset) or 0)
  state.last_raw = math.max(0, tonumber(state.last_raw) or 0)
  state.total = math.max(0, tonumber(state.total) or 0)
  state.reset_count = math.max(0, tonumber(state.reset_count) or 0)
  state.reconciled = state.reconciled == true
  return state
end

function ProductionHistory.observe(state, raw_count, proven_floor)
  state = ProductionHistory.ensure(state)
  local raw = math.max(0, tonumber(raw_count) or 0)
  local floor = math.max(0, tonumber(proven_floor) or 0)

  if state.reconciled and raw < state.last_raw then
    state.offset = math.max(state.offset, state.total - raw)
    state.reset_count = state.reset_count + 1
  end

  local total = math.max(state.total, raw + state.offset, floor)
  state.offset = math.max(state.offset, total - raw)
  state.last_raw = raw
  state.total = total
  state.last_proven_floor = floor
  state.reconciled = true
  return total, state
end

return ProductionHistory
