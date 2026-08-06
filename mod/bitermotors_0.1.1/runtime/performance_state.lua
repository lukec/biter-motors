local PerformanceState = {}

function PerformanceState.ensure(storage)
  storage.bitermotors_performance_state = storage.bitermotors_performance_state or {}
  local state = storage.bitermotors_performance_state
  state.registries = state.registries or {
    stations = {},
    sales_offices = {},
    bitertaxi_depots = {},
    ai_machines = {},
    energy_products = {}
  }
  state.registries.stations = state.registries.stations or {}
  state.registries.sales_offices = state.registries.sales_offices or {}
  state.registries.bitertaxi_depots = state.registries.bitertaxi_depots or {}
  state.registries.ai_machines = state.registries.ai_machines or {}
  state.registries.energy_products = state.registries.energy_products or {}
  state.market_cache = state.market_cache or {}
  state.market_generation = state.market_generation or {}
  state.invalidations = state.invalidations or {}
  state.reconciliation = state.reconciliation or {surface = 1, kind = 1}
  return state
end

function PerformanceState.track(state, kind, entity)
  if kind and entity and entity.valid and entity.unit_number then
    state.registries[kind][entity.unit_number] = entity
  end
end

function PerformanceState.untrack(state, entity_or_unit_number)
  local unit_number = type(entity_or_unit_number) == "number" and entity_or_unit_number
    or entity_or_unit_number and entity_or_unit_number.valid and entity_or_unit_number.unit_number
  if not unit_number then return end
  for _, registry in pairs(state.registries) do registry[unit_number] = nil end
end

function PerformanceState.entities(state, kind, force, surface)
  local result = {}
  local registry = state.registries[kind] or {}
  for unit_number, entity in pairs(registry) do
    if not entity or not entity.valid then
      registry[unit_number] = nil
    elseif (not force or entity.force == force) and (not surface or entity.surface == surface) then
      result[#result + 1] = entity
    end
  end
  return result
end

function PerformanceState.invalidate(state, force_index, reason)
  state.market_generation[force_index] = (state.market_generation[force_index] or 0) + 1
  state.market_cache[force_index] = nil
  reason = reason or "unspecified"
  state.invalidations[reason] = (state.invalidations[reason] or 0) + 1
end

return PerformanceState
