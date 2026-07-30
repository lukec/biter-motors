local PowerQueue = {}

function PowerQueue.ensure(state)
  state = state or {}
  state.units = state.units or {}
  state.index = state.index or 1
  state.members = state.members or {}
  return state
end

function PowerQueue.track(state, unit_number)
  if not unit_number or state.members[unit_number] then return end
  state.units[#state.units + 1] = unit_number
  state.members[unit_number] = true
end

function PowerQueue.remove_current(state, unit_number)
  state.members[unit_number] = nil
  local remove_index = state.index - 1
  local last = table.remove(state.units)
  if remove_index <= #state.units then
    state.units[remove_index] = last
    state.index = remove_index
  end
end

function PowerQueue.next(state)
  if #state.units == 0 then return nil end
  if state.index > #state.units then state.index = 1 end
  local unit_number = state.units[state.index]
  state.index = state.index + 1
  return unit_number
end

return PowerQueue
