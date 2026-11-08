local AgiCompletion = {}

function AgiCompletion.ensure(state)
  state = state or {}
  state.forces = state.forces or {}
  state.pods = state.pods or {}
  state.registrations = state.registrations or {}
  return state
end

function AgiCompletion.force(state, force_index)
  local progress = state.forces[force_index]
  if not progress then
    progress = {models_assembled = 0, models_returned = 0, models_activated = 0,
      assembly_credits = {}, return_credits = {}}
    state.forces[force_index] = progress
  end
  return progress
end

function AgiCompletion.assemble(state, force_index, surface_index, quality)
  local progress = AgiCompletion.force(state, force_index)
  local credits = progress.assembly_credits[surface_index] or {}
  credits[quality] = (credits[quality] or 0) + 1
  progress.assembly_credits[surface_index] = credits
  progress.models_assembled = progress.models_assembled + 1
end

function AgiCompletion.depart(state, pod_id, registration, force_index, surface_index, cargo)
  if state.pods[pod_id] then return false end
  local progress = state.forces[force_index]
  local available = progress and progress.assembly_credits[surface_index]
  if not available then return false end
  local reserved = {}
  for quality, count in pairs(cargo) do
    local amount = math.min(count, available[quality] or 0)
    if amount > 0 then
      reserved[quality] = amount
      available[quality] = available[quality] - amount
      if available[quality] == 0 then available[quality] = nil end
    end
  end
  if not next(reserved) then return false end
  if not next(available) then progress.assembly_credits[surface_index] = nil end
  state.pods[pod_id] = {force_index = force_index, qualities = reserved,
    source_surface = surface_index, registration = registration}
  state.registrations[registration] = pod_id
  return true
end

function AgiCompletion.forget_pod(state, pod_id)
  local transit = state.pods[pod_id]
  if transit then
    state.registrations[transit.registration] = nil
    state.pods[pod_id] = nil
  end
  return transit
end

function AgiCompletion.deliver(state, pod_id, force_index)
  local transit = AgiCompletion.forget_pod(state, pod_id)
  if not transit or transit.force_index ~= force_index then return false end
  local progress = AgiCompletion.force(state, force_index)
  for quality, count in pairs(transit.qualities) do
    progress.return_credits[quality] = (progress.return_credits[quality] or 0) + count
    progress.models_returned = progress.models_returned + count
  end
  return true
end

function AgiCompletion.activate(state, force_index, quality)
  local progress = state.forces[force_index]
  if not progress or (progress.return_credits[quality] or 0) == 0 then return false end
  progress.return_credits[quality] = progress.return_credits[quality] - 1
  if progress.return_credits[quality] == 0 then progress.return_credits[quality] = nil end
  progress.models_activated = progress.models_activated + 1
  return true
end

return AgiCompletion
