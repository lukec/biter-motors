local EndgamePresentation = {}

local MODEL = "item/bitermotors-agi-model"
local DATASET = "item/bitermotors-agi-training-dataset"
local CORE = "item/bitermotors-orbital-datacenter-core"
local TERRA = "item/bitermotors-terrestrial-datacenter"

local function number(value, fallback)
  if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
    return fallback or 0
  end
  return math.max(0, value)
end

local function fraction(value)
  return math.min(1, number(value))
end

local function count(value)
  return string.format("%.0f", number(value))
end

local function result(key, label, objective, detail, icon, status, color)
  return {stage_key = key, stage = label, objective = objective, detail = detail,
    icon = icon, status = status, color = color}
end

local MACHINE_STATES = {
  no_machine = {"No machine", "bad"},
  select_recipe = {"Select recipe", "warning"},
  needs_inputs = {"Awaiting inputs", "warning"},
  working = {"Working", "good"},
  no_power = {"Paused: no power", "warning"},
  low_power = {"Power limited", "warning"},
  cooling = {"Overheating", "warning"},
  full_output = {"Output full", "warning"}
}

local function machine_description(machine, activation, rebuilding)
  machine = machine or {}
  local state = machine.state or "no_machine"
  local progress = fraction(machine.progress)
  local committed = machine.committed == true or (machine.selected == true and progress > 0)
  local info = MACHINE_STATES[state] or {"Awaiting status", "neutral"}
  local view = result(activation and "activation" or "assembly",
    activation and "Ground activation" or "Model assembly",
    activation and "Activate the returned AGI Model on Nauvis."
      or (rebuilding and "Rebuild the lost AGI Model in Nauvis orbit."
        or "Assemble an AGI Model in Nauvis orbit."),
    "", activation and TERRA or CORE, info[1], info[2])
  local timing = activation and "Normal activation: 30 seconds at 8 MW."
    or "Normal assembly: 1 minute."

  if committed then
    view.payload_value = "Payload committed"
    view.payload_tooltip = "Inputs are already committed to this native craft; do not load them again."
    view.progress = progress
    view.detail = "Payload committed; " .. count(progress * 100) .. "% banked. "
    -- Empty input slots are expected after native crafting commits the payload.
    if state == "needs_inputs" then
      view.status, view.color = "Payload committed", "neutral"
    end
  elseif activation then
    view.payload_value = count(machine.models) .. " / 1 Model"
    view.payload_tooltip = "Load the returned Model at its delivered quality."
    view.detail = "Load the returned AGI Model into the Terrestrial Datacenter. "
  else
    local datasets = number(machine.required_datasets, 20000)
    local racks = number(machine.required_racks, 1)
    view.payload_value = count(machine.datasets) .. " / " .. count(datasets)
      .. " Datasets; " .. count(machine.racks) .. " / " .. count(racks) .. " Rack"
    view.payload_tooltip = "Physical inputs in this cluster, separate from earned compute. "
      .. "Packaging AI Tokens does not earn compute again."
    view.detail = "Load " .. count(datasets) .. " AGI Training Datasets and " .. count(racks)
      .. " Datacenter Rack. For Rack uplift, set minimum payload to 1. "
  end

  if state == "no_machine" then
    view.detail = activation and "Build a Terrestrial Datacenter on Nauvis. "
      or "Build an Orbital Compute Cluster on a platform in Nauvis orbit. "
  elseif state == "select_recipe" then
    view.detail = activation and "Select Activate AGI Model in the Nauvis Terrestrial Datacenter. "
      or "Select Assemble AGI Model in the orbital cluster. "
  elseif state == "no_power" then
    view.detail = view.detail .. "Restore power to resume. "
  elseif state == "low_power" then
    view.detail = view.detail .. "Increase available power. "
  elseif state == "cooling" then
    view.detail = view.detail .. "Repair the heat path or stop power: 130 C destroys the core and committed payload. "
  elseif state == "full_output" then
    view.detail = view.detail .. "Remove the Model from the output so crafting can finish. "
  end
  view.detail = view.detail .. timing
  return view
end

-- Inputs are bounded scalar summaries supplied by the caller, never game objects.
function EndgamePresentation.describe(agi)
  agi = agi or {}
  if agi.completed then
    local view = result("complete", "Complete", "AGI activated on Nauvis.",
      "Victory recorded. Continue playing.", MODEL, "Complete", "good")
    view.progress = 1
    return view
  end
  if number(agi.return_credits) > 0 then
    return machine_description(agi.activation, true, false)
  end
  if number(agi.models_in_transit) > 0 then
    return result("return", "Model return", "Return the AGI Model to Nauvis.",
      "The Model cargo pod is in flight to the Nauvis Cargo Landing Pad.",
      MODEL, "In flight", "warning")
  end
  if number(agi.assembly_credits) > 0 then
    return result("return", "Model return", "Return the AGI Model to Nauvis.",
      "Move the actual Model into the platform hub. Request that Model at its quality "
        .. "from the Nauvis Cargo Landing Pad to dispatch a cargo pod.",
      MODEL, "Awaiting hub dispatch", "warning")
  end
  if number(agi.models_assembled) > 0 then
    return machine_description(agi.assembly, false, true)
  end

  if not agi.unlocked then
    local required = number(agi.required_ai_tokens, 1000000000)
    local earned = number(agi.cumulative_ai_tokens)
    local research = agi.grid_scale_researched == true and ""
      or "Complete Grid-scale Energy research. "
    local view = result("compute", "Earned compute", "Run compute recipes to reach the required AI Token total.",
      count(earned) .. " / " .. count(required) .. " earned AI Token equivalents. "
        .. research .. "Packaging does not earn compute again; "
        .. "Hyperscale research is optional.",
      DATASET, "Earning compute", "neutral")
    view.progress = required > 0 and fraction(earned / required) or 1
    if earned >= required then
      if agi.grid_scale_researched == true then
        view.objective = "Wait for the assembly recipe to unlock."
        view.status = "Compute gate met"
      else
        view.objective = "Complete Grid-scale Energy research."
        view.status, view.color = "Awaiting research", "warning"
      end
    end
    return view
  end
  return machine_description(agi.assembly, false, false)
end

return EndgamePresentation
