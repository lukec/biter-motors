local P = require("runtime.orbital_thermal_policy")
local Queue = require("runtime.power_queue")
local M = {policy = P}

local function state()
  local s = storage.bitermotors_orbital_thermals
  if not s then
    s = {cores = {}, radiators = {}, registrations = {}, burnouts = 0,
      core_queue = Queue.ensure(), radiator_queue = Queue.ensure(),
      updates = 0, visited = 0, max_visited = 0}
    storage.bitermotors_orbital_thermals = s
  end
  return s
end

local function passive(entity, fresh)
  entity.set_heat_setting{mode = "at-least", temperature = P.floor_c}
  if fresh then entity.temperature = P.floor_c end
end

local function clear_visual(entry)
  if entry.visual and entry.visual.valid then entry.visual.destroy() end
  entry.visual = nil
end

local function clear_alerts(entry)
  if entry.entity and entry.entity.valid then
    for _, player in pairs(game.players) do
      player.remove_alert{entity = entry.entity, type = defines.alert_type.custom}
    end
  end
  clear_visual(entry)
  entry.alert_state = nil
end

local function forget_registration(s, registration)
  if registration then s.registrations[registration] = nil end
end

function M.remove(entity_or_unit)
  local unit = type(entity_or_unit) == "number" and entity_or_unit
    or (entity_or_unit and entity_or_unit.valid and entity_or_unit.unit_number)
  if not unit then return end
  local s = state()
  local entry = s.cores[unit]
  if entry then
    s.cores[unit] = nil
    s.core_queue.members[unit] = nil
    clear_alerts(entry)
    forget_registration(s, entry.registration)
    forget_registration(s, entry.buffer_registration)
    if entry.buffer and entry.buffer.valid then entry.buffer.destroy() end
  end
  entry = s.radiators[unit]
  if entry then
    s.radiators[unit] = nil
    s.radiator_queue.members[unit] = nil
    forget_registration(s, entry.registration)
  end
end

local function register_buffer(s, unit, entry, temperature)
  local core = entry.entity
  local buffer = assert(core.surface.create_entity{name = P.buffer, position = core.position,
    force = core.force, quality = core.quality}, "Orbital thermal buffer creation failed")
  buffer.destructible = false
  passive(buffer, true)
  buffer.temperature = temperature or P.floor_c
  entry.buffer = buffer
  entry.buffer_registration = script.register_on_object_destroyed(buffer)
  s.registrations[entry.buffer_registration] = {kind = "buffer", unit = unit}
end

function M.register(entity)
  if not entity or not entity.valid or not entity.unit_number
    or not entity.surface.platform then return end
  local s, unit = state(), entity.unit_number
  if entity.name == P.core then
    if s.cores[unit] then return end
    local recipe = entity.get_recipe()
    local entry = {entity = entity, completed_energy = 0,
      previous_work = (recipe and recipe.energy or 0) * entity.crafting_progress,
      recipe = recipe and recipe.name, speed = entity.crafting_speed,
      last_tick = game.tick, heat_joules = 0, work_seconds = 0, last_watts = 0}
    s.cores[unit] = entry
    entry.registration = script.register_on_object_destroyed(entity)
    s.registrations[entry.registration] = {kind = "core", unit = unit}
    register_buffer(s, unit, entry)
    Queue.track(s.core_queue, unit)
  elseif entity.name == P.radiator and not s.radiators[unit] then
    passive(entity, false)
    local entry = {entity = entity, last_tick = game.tick, removed_joules = 0, last_watts = 0}
    entry.registration = script.register_on_object_destroyed(entity)
    s.registrations[entry.registration] = {kind = "radiator", unit = unit}
    s.radiators[unit] = entry
    Queue.track(s.radiator_queue, unit)
  end
end

function M.destroyed(event)
  local s = state()
  local registration = s.registrations[event.registration_number]
  if not registration then return end
  s.registrations[event.registration_number] = nil
  local entry = s.cores[registration.unit]
  if registration.kind == "buffer" then
    -- A removed hidden component must not silently replace a hot buffer with a cold one.
    if entry then entry.lost_temperature = entry.last_temperature or P.burnout_c end
  else M.remove(registration.unit) end
end

function M.cloned(event)
  local entity = event.destination
  if not entity or not entity.valid then return end
  if entity.name == P.buffer then entity.destroy(); return end
  M.register(entity)
  local s = state()
  local source = event.source and event.source.valid and s.cores[event.source.unit_number]
  local destination = s.cores[entity.unit_number]
  if source and destination and source.buffer.valid then
    destination.buffer.temperature = source.buffer.temperature
  end
end

function M.rebuild()
  local s, owned = state(), {}
  for unit, entry in pairs(s.cores) do
    if not entry.entity.valid then M.remove(unit) end
  end
  for unit, entry in pairs(s.radiators) do
    if not entry.entity.valid then M.remove(unit) end
  end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = {P.core, P.radiator}}) do
      M.register(entity)
    end
  end
  for _, entry in pairs(s.cores) do
    if entry.buffer.valid then owned[entry.buffer.unit_number] = true end
  end
  for _, surface in pairs(game.surfaces) do
    for _, buffer in pairs(surface.find_entities_filtered{name = P.buffer}) do
      if not owned[buffer.unit_number] then buffer.destroy() end
    end
  end
end

function M.completed(event)
  local entity = event.entity
  if event.bonus or not entity or not entity.valid or entity.name ~= P.core then return end
  local entry = state().cores[entity.unit_number]
  local recipe = prototypes.recipe[event.recipe]
  if entry and recipe then entry.completed_energy = entry.completed_energy + recipe.energy end
end

local function warning(entry, temperature)
  local entity = entry.entity
  local current = P.state(temperature)
  if current == "normal" then
    if entry.alert_state then clear_alerts(entry) end
    return
  end
  if entry.alert_state ~= current or entry.alert_force ~= entity.force.index
    or game.tick >= (entry.next_alert_tick or 0) then
    clear_alerts(entry)
    for _, player in pairs(entity.force.players) do
      player.add_custom_alert(entity, {type = "item", name = P.radiator},
        {"bitermotors-thermal.alert-" .. current, string.format("%.1f", temperature), P.burnout_c}, true)
    end
    entry.visual = rendering.draw_sprite{sprite = "utility/warning_icon", surface = entity.surface,
      target = {entity = entity, offset = {0, -1.2}}, x_scale = 0.75, y_scale = 0.75,
      tint = current == "critical" and {1, 0.2, 0.1, 1} or {1, 0.75, 0.1, 1},
      forces = {entity.force}, render_layer = "light-effect", only_in_alt_mode = false}
    entry.alert_state, entry.alert_force = current, entity.force.index
    entry.next_alert_tick = game.tick + P.alert_interval_ticks
  end
end

local function radiator_update(entry, elapsed)
  local entity = entry.entity
  local temperature, removed = P.cool(entity.temperature, elapsed)
  entity.temperature = temperature
  entry.removed_joules = entry.removed_joules + removed
  entry.last_watts = elapsed > 0 and removed / elapsed or 0
  entity.custom_status = {diode = defines.entity_status_diode.green,
    label = {"bitermotors-thermal.radiator", string.format("%.1f", temperature),
      string.format("%.1f", entry.last_watts / 1000000)}}
end

local function core_update(unit, entry, elapsed)
  local s, entity = state(), entry.entity
  if not entry.buffer.valid then register_buffer(s, unit, entry, entry.lost_temperature or P.burnout_c) end
  local buffer = entry.buffer
  if buffer.surface ~= entity.surface or buffer.position.x ~= entity.position.x
    or buffer.position.y ~= entity.position.y then
    local temperature = buffer.temperature
    forget_registration(s, entry.buffer_registration)
    buffer.destroy()
    register_buffer(s, unit, entry, temperature)
    buffer = entry.buffer
  end
  if buffer.force ~= entity.force then buffer.force = entity.force end
  local recipe = entity.get_recipe()
  local work = entry.completed_energy + (recipe and recipe.energy or 0) * entity.crafting_progress
  local active = P.work_seconds(entry.previous_work, work, entry.speed, elapsed)
  -- Recipe/speed edits can straddle a sample, but cannot invent more than elapsed work.
  if entry.recipe ~= (recipe and recipe.name) then
    active = math.min(elapsed, entity.is_crafting() and elapsed or 0)
  end
  local powered = entity.electric_buffer_size > 0
    and math.min(1, entity.energy / entity.electric_buffer_size) or 0
  local joules = P.heat_joules(active, elapsed, entity.consumption_bonus or 0, powered)
  buffer.temperature = buffer.temperature + joules / P.core_joules_per_c
  local temperature = buffer.temperature
  entry.last_temperature = temperature
  entry.heat_joules, entry.work_seconds = entry.heat_joules + joules, entry.work_seconds + active
  entry.last_watts = elapsed > 0 and joules / elapsed or 0
  entry.previous_work, entry.recipe, entry.speed = work, recipe and recipe.name, entity.crafting_speed
  if temperature >= P.burnout_c then
    s.burnouts = s.burnouts + 1
    s.last_burnout = {unit = unit, tick = game.tick, temperature = temperature,
      position = entity.position, surface = entity.surface.name}
    clear_alerts(entry)
    entity.die(entity.force)
    M.remove(unit)
    return
  end
  warning(entry, temperature)
  local current = P.state(temperature)
  entity.custom_status = {diode = current == "critical" and defines.entity_status_diode.red
    or current == "warning" and defines.entity_status_diode.yellow or defines.entity_status_diode.green,
    label = {"bitermotors-thermal." .. current, string.format("%.1f", temperature)}}
end

local function update_queue(entries, queue, update)
  local visited = 0
  for _ = 1, math.min(P.batch_limit, #queue.units) do
    local unit = Queue.next(queue)
    local entry = entries[unit]
    if not entry or not entry.entity.valid then
      M.remove(unit)
      Queue.remove_current(queue, unit)
    else
      local elapsed = (game.tick - entry.last_tick) / 60
      if elapsed > 0 then update(unit, entry, elapsed); entry.last_tick = game.tick end
      visited = visited + 1
    end
  end
  return visited
end

function M.update()
  if game.tick == 0 then return end
  local s = state()
  local visited = update_queue(s.radiators, s.radiator_queue,
    function(_, entry, elapsed) radiator_update(entry, elapsed) end)
  visited = visited + update_queue(s.cores, s.core_queue, core_update)
  s.updates, s.visited = s.updates + 1, s.visited + visited
  s.max_visited = math.max(s.max_visited, visited)
end

function M.core_status(entity)
  local entry = entity and entity.valid and state().cores[entity.unit_number]
  if not entry or not entry.buffer.valid then return nil end
  return {unit = entity.unit_number, temperature = entry.buffer.temperature,
    watts = entry.last_watts, heat_joules = entry.heat_joules, work_seconds = entry.work_seconds,
    progress = entity.crafting_progress, products = entity.products_finished,
    state = P.state(entry.buffer.temperature), position = entity.position,
    surface = entity.surface.name, buffer_unit = entry.buffer.unit_number,
    warning_visible = entry.visual and entry.visual.valid or false}
end

function M.status(force)
  local s = state()
  local result = {cores = {}, radiators = {}, burnouts = s.burnouts, last_burnout = s.last_burnout,
    tick = game.tick, updates = s.updates, visited = s.visited, max_visited = s.max_visited,
    target_c = P.target_c, warning_c = P.warning_c, critical_c = P.critical_c, burnout_c = P.burnout_c}
  for _, entry in pairs(s.cores) do
    if entry.entity.valid and (not force or entry.entity.force == force) then
      local row = M.core_status(entry.entity)
      if row then result.cores[#result.cores + 1] = row end
    end
  end
  for unit, entry in pairs(s.radiators) do
    if entry.entity.valid and (not force or entry.entity.force == force) then
      result.radiators[#result.radiators + 1] = {unit = unit, temperature = entry.entity.temperature,
        watts = entry.last_watts, removed_joules = entry.removed_joules}
    end
  end
  table.sort(result.cores, function(a, b) return a.unit < b.unit end)
  table.sort(result.radiators, function(a, b) return a.unit < b.unit end)
  return result
end

return M
