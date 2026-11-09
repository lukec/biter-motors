local P = require("thermal-policy")
local PREFIX = "bitermotors-thermal-"
local CORE, BUFFER, RADIATOR = PREFIX .. "core", PREFIX .. "buffer", PREFIX .. "radiator"

local function neutral_heat(entity)
  entity.set_heat_setting{mode = "at-least", temperature = P.floor_c}
  entity.temperature = P.floor_c
end

local function register(entity)
  if not entity or not entity.valid or not entity.surface.platform then return end
  if entity.name == CORE and not storage.cores[entity.unit_number] then
    local buffer = assert(entity.surface.create_entity{name = BUFFER, position = entity.position,
      force = entity.force, quality = entity.quality}, "thermal component")
    buffer.destructible = false
    neutral_heat(buffer)
    storage.cores[entity.unit_number] = {entity = entity, buffer = buffer,
      completed_seconds = 0, previous_work = 0, last_tick = game.tick,
      heat_joules = 0, work_seconds = 0, last_watts = 0}
  elseif entity.name == RADIATOR and not storage.radiators[entity.unit_number] then
    neutral_heat(entity)
    storage.radiators[entity.unit_number] = {entity = entity, last_tick = game.tick,
      removed_joules = 0, last_watts = 0}
  end
end

local function initialize()
  storage.cores, storage.radiators = storage.cores or {}, storage.radiators or {}
  storage.burnouts = storage.burnouts or 0
  storage.burnout_events = storage.burnout_events or {}
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = {CORE, RADIATOR}}) do register(entity) end
  end
end
script.on_init(initialize)
script.on_configuration_changed(initialize)

local build_events = {defines.events.on_built_entity, defines.events.on_robot_built_entity,
  defines.events.script_raised_built, defines.events.script_raised_revive,
  defines.events.on_space_platform_built_entity, defines.events.on_entity_cloned}
script.on_event(build_events, function(event) register(event.destination or event.entity) end)

local function remove(entity)
  if not entity or not entity.valid then return end
  local entry = storage.cores[entity.unit_number]
  if entry then
    if entry.buffer.valid then entry.buffer.destroy() end
    storage.cores[entity.unit_number] = nil
  end
  storage.radiators[entity.unit_number] = nil
end
script.on_event({defines.events.on_entity_died, defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity, defines.events.script_raised_destroy,
  defines.events.on_space_platform_mined_entity}, function(event) remove(event.entity) end)

for name, recipe in pairs(prototypes.recipe) do
  if string.find(name, "bitermotors-orbital-ai-", 1, true) == 1 then
    script.on_event(recipe.on_crafted_event, function(event)
      local entry = storage.cores[event.entity.unit_number]
      if entry and not event.bonus then
        entry.completed_seconds = entry.completed_seconds + prototypes.recipe[event.recipe].energy / event.entity.crafting_speed
      end
    end)
  end
end

local function update_radiator(entry)
  local entity = entry.entity
  local elapsed = (game.tick - entry.last_tick) / 60
  local temperature, removed = P.cool(entity.temperature, elapsed)
  entity.temperature = temperature
  entry.removed_joules, entry.last_tick = entry.removed_joules + removed, game.tick
  entry.last_watts = elapsed > 0 and removed / elapsed or 0
  entity.custom_status = {diode = defines.entity_status_diode.green,
    label = {"thermal-prototype.radiator", string.format("%.1f", temperature), string.format("%.1f", entry.last_watts / 1000000)}}
end

local function update_core(unit, entry)
  local entity, buffer = entry.entity, entry.buffer
  if not entity.valid then
    if buffer.valid then buffer.destroy() end
    storage.cores[unit] = nil
    return
  end
  assert(buffer.valid, "lost experimental thermal component")
  local elapsed = (game.tick - entry.last_tick) / 60
  local recipe = entity.get_recipe()
  local cycle = recipe and recipe.energy / entity.crafting_speed or 0
  local work = entry.completed_seconds + entity.crafting_progress * cycle
  if entry.recipe and entry.recipe ~= (recipe and recipe.name) then entry.previous_work = work end
  local active = P.work_delta(entry.previous_work, work, elapsed)
  local joules = active * P.core_watts
  buffer.temperature = buffer.temperature + joules / P.core_joules_per_c
  entry.heat_joules, entry.work_seconds = entry.heat_joules + joules, entry.work_seconds + active
  entry.last_watts = elapsed > 0 and joules / elapsed or 0
  entry.previous_work, entry.last_tick, entry.recipe = work, game.tick, recipe and recipe.name
  local state, temperature = P.state(buffer.temperature), buffer.temperature
  if state == "burnout" then
    storage.burnouts = storage.burnouts + 1
    storage.burnout_events[#storage.burnout_events + 1] = {unit = unit, tick = game.tick,
      temperature = temperature, position = entity.position, surface = entity.surface.name,
      heat_joules = entry.heat_joules, work_seconds = entry.work_seconds}
    entity.die(entity.force)
    return
  end
  entity.custom_status = {diode = state == "critical" and defines.entity_status_diode.red
    or state == "warning" and defines.entity_status_diode.yellow or defines.entity_status_diode.green,
    label = {"thermal-prototype." .. state, string.format("%.1f", temperature)}}
end

local function snapshot()
  local result = {cores = {}, radiators = {}, burnouts = storage.burnouts,
    burnout_events = storage.burnout_events, tick = game.tick}
  for unit, entry in pairs(storage.cores) do
    if entry.entity.valid and entry.buffer.valid then
      result.cores[#result.cores + 1] = {unit = unit, temperature = entry.buffer.temperature,
        watts = entry.last_watts, heat_joules = entry.heat_joules, work_seconds = entry.work_seconds,
        progress = entry.entity.crafting_progress, products = entry.entity.products_finished,
        state = P.state(entry.buffer.temperature), position = entry.entity.position,
        buffer_unit = entry.buffer.unit_number}
    end
  end
  for unit, entry in pairs(storage.radiators) do
    if entry.entity.valid then result.radiators[#result.radiators + 1] = {unit = unit,
      temperature = entry.entity.temperature, watts = entry.last_watts, removed_joules = entry.removed_joules} end
  end
  table.sort(result.cores, function(a, b) return a.unit < b.unit end)
  table.sort(result.radiators, function(a, b) return a.unit < b.unit end)
  return result
end
remote.add_interface("bitermotors_thermal_prototype", {status = snapshot})

script.on_nth_tick(P.interval_ticks, function()
  if game.tick == 0 then return end
  for unit, entry in pairs(storage.radiators) do
    if entry.entity.valid then update_radiator(entry) else storage.radiators[unit] = nil end
  end
  for unit, entry in pairs(storage.cores) do update_core(unit, entry) end
end)
