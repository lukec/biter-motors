local CONFIG = require("sample-config")
local REPORT = "bitermotors-save-sample.jsonl"
local function add(to, name, quality, count)
  quality = quality or "normal"
  to[name] = to[name] or {}
  to[name][quality] = (to[name][quality] or 0) + count
end
local function inventory_contents(inventory, target)
  if not inventory or not inventory.valid then return end
  for _, stack in pairs(inventory.get_contents()) do add(target, stack.name, stack.quality, stack.count) end
end
local function flow(statistics, category, fluid, electric)
  local result = {}
  local qualities = category == "input" and statistics.input_quality_counts or statistics.output_quality_counts
  for quality, counts in pairs(qualities) do
    for name, total in pairs(counts) do
      local id = fluid and name or {name = name, quality = quality}
      local rate_key = electric and "watts" or "per_minute"
      local row = {total = total, [rate_key] = {}}
      for _, period in ipairs({"one_minute", "ten_minutes", "one_hour"}) do
        local rate = statistics.get_flow_count{
          name = id, category = category, precision_index = defines.flow_precision_index[period]}
        -- Native electrical rates are joules/tick, unlike item/fluid rates.
        row[rate_key][period] = electric and rate * 60 or rate
      end
      result[name] = result[name] or {}
      result[name][quality] = row
    end
  end
  return result
end
local function remote_status(method)
  if not remote.interfaces.bitermotors or not remote.interfaces.bitermotors[method] then return nil end
  return remote.call("bitermotors", method, "player")
end
local function capture(kind)
  local force = game.forces.player
  local result = {kind = kind, tick = game.tick, play_ticks = game.ticks_played,
    factorio_version = script.active_mods.base, mod_version = script.active_mods.bitermotors,
    scope = "isolated-copy-current-mod-sample", elapsed_ticks = game.tick - storage.started,
    limits = "No supplied resources or research. Current mod configuration reconciliation may change old-save behavior. Inventory excludes belts, robots in flight and committed craft inputs; outputs and uncommitted inputs are separate categories.",
    technologies = {}, entities = {}, machines = {}, inventory = {containers = {}, machine_inputs = {}, machine_outputs = {}, labs = {}, players = {}, cargo = {}},
    surfaces = {}, electric_networks = {}, force_modifiers = {
      laboratory_speed_modifier = force.laboratory_speed_modifier,
      laboratory_productivity_bonus = force.laboratory_productivity_bonus,
      bulk_inserter_capacity_bonus = force.bulk_inserter_capacity_bonus}}
  for name, technology in pairs(force.technologies) do
    if technology.researched or technology.enabled or string.find(name, "bitermotors-", 1, true) then
      result.technologies[name] = {researched = technology.researched, enabled = technology.enabled,
        level = technology.level}
      if name == "space-platform" or name == "rocket-silo" then
        local row = result.technologies[name]
        row.unit = {count = technology.research_unit_count, time = technology.research_unit_energy / 60,
          ingredients = {}}
        for _, ingredient in pairs(technology.research_unit_ingredients) do
          row.unit.ingredients[#row.unit.ingredients + 1] = {ingredient.name, ingredient.amount}
        end
      end
    end
  end
  result.current_research = force.current_research and force.current_research.name
  result.research_progress = force.research_progress
  local seen_networks = {}
  for _, surface in pairs(game.surfaces) do
    local data = {name = surface.name, platform = surface.platform ~= nil,
      items_produced = flow(force.get_item_production_statistics(surface), "input"),
      items_consumed = flow(force.get_item_production_statistics(surface), "output"),
      fluids_produced = flow(force.get_fluid_production_statistics(surface), "input", true),
      fluids_consumed = flow(force.get_fluid_production_statistics(surface), "output", true)}
    result.surfaces[#result.surfaces + 1] = data
    for _, entity in pairs(surface.find_entities_filtered{force = force}) do
      if entity.valid then
        add(result.entities, entity.name, entity.quality and entity.quality.name, 1)
        local kind_type = entity.type
        if kind_type == "container" or kind_type == "logistic-container" then
          inventory_contents(entity.get_inventory(defines.inventory.chest), result.inventory.containers)
        elseif kind_type == "cargo-wagon" then
          inventory_contents(entity.get_inventory(defines.inventory.cargo_wagon), result.inventory.cargo)
        elseif kind_type == "space-platform-hub" then
          inventory_contents(entity.get_inventory(defines.inventory.hub_main), result.inventory.cargo)
        elseif kind_type == "cargo-landing-pad" then
          inventory_contents(entity.get_inventory(defines.inventory.cargo_landing_pad_main), result.inventory.cargo)
        elseif kind_type == "assembling-machine" or kind_type == "furnace" or kind_type == "rocket-silo" then
          local recipe, quality = entity.get_recipe()
          local key = entity.name .. ":" .. entity.quality.name .. ":" .. (recipe and recipe.name or "none")
          local group = result.machines[key]
          if not group then
            group = {name = entity.name, quality = entity.quality.name,
              recipe = recipe and recipe.name, recipe_quality = quality and quality.name,
              count = 0, working = 0, disabled = 0, total_crafting_speed = 0,
              total_effective_speed = 0, total_products_finished = 0, statuses = {}}
            result.machines[key] = group
          end
          group.count = group.count + 1
          group.working = group.working + (entity.status == defines.entity_status.working and 1 or 0)
          group.disabled = group.disabled + (entity.disabled_by_script and 1 or 0)
          group.total_crafting_speed = group.total_crafting_speed + entity.crafting_speed
          group.total_effective_speed = group.total_effective_speed + entity.crafting_speed * (1 + entity.productivity_bonus)
          group.total_products_finished = group.total_products_finished + entity.products_finished
          local status = tostring(entity.status)
          group.statuses[status] = (group.statuses[status] or 0) + 1
          local input_id = kind_type == "furnace" and defines.inventory.furnace_source or defines.inventory.crafter_input
          local output_id = kind_type == "furnace" and defines.inventory.furnace_result or defines.inventory.crafter_output
          inventory_contents(entity.get_inventory(input_id), result.inventory.machine_inputs)
          inventory_contents(entity.get_inventory(output_id), result.inventory.machine_outputs)
        elseif kind_type == "lab" then
          inventory_contents(entity.get_inventory(defines.inventory.lab_input), result.inventory.labs)
        elseif kind_type == "electric-pole" then
          local id = entity.electric_network_id
          if id and not seen_networks[id] then
            seen_networks[id] = true
            local stats = entity.electric_network_statistics
            result.electric_networks[#result.electric_networks + 1] = {
              id = id, surface = surface.name, consumed = flow(stats, "input", false, true),
              generated = flow(stats, "output", false, true)}
          end
        end
      end
    end
  end
  for _, player in pairs(force.players) do inventory_contents(player.get_main_inventory(), result.inventory.players) end
  result.progress = remote_status("progress_status")
  result.endgame = remote_status("endgame_status")
  result.grid_battery_adoption = remote_status("grid_battery_adoption_status")
  result.business = remote_status("bitertaxi_depot_status")
  helpers.write_file(REPORT, helpers.table_to_json(result) .. "\n", true)
end
script.on_init(function() game.tick_paused = false; storage.started = game.tick end)
script.on_configuration_changed(function() game.tick_paused = false; storage.started = game.tick end)
script.on_event(defines.events.on_tick, function()
  if not storage.initial then
    storage.initial = game.tick
    capture("initial")
  elseif not storage.done and game.tick >= storage.initial + CONFIG.ticks - 1 then
    capture("final")
    storage.done = true
  end
end)
