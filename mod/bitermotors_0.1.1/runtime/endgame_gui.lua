local Presentation = require("runtime.endgame_presentation")
local Terminal = require("runtime.terminal_epilogue")
local Gui = {}
local colors = {good = {r = 0.4, g = 0.85, b = 0.4}, warning = {r = 1, g = 0.75, b = 0.3},
  bad = {r = 1, g = 0.35, b = 0.3}, neutral = {r = 0.75, g = 0.75, b = 0.75}}
local CONTENT = "bitermotors_progress_content"

function Gui.relevant(force)
  local technology = force.technologies["bitermotors-grid-scale-energy"]
  return technology and technology.researched
    or (storage.bitermotors_victory_forces or {})[force.name] == true
end

local function grouped(value)
  return tostring(math.floor(value or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function text(parent, name, caption, width, color)
  local label = parent.add{type = "label", name = name, caption = caption, single_line = false}
  label.style.maximal_width = width
  if color then label.style.font_color = colors[color] end
  return label
end

local function metric(parent, name, sprite, caption, value, width, color, tooltip)
  local row = parent.add{type = "flow", name = name, direction = "horizontal", tooltip = tooltip}
  row.style.vertical_align = "center"
  row.style.horizontal_spacing = 8
  local icon = row.add{type = "sprite", sprite = sprite, tooltip = tooltip}
  icon.style.width, icon.style.height = 28, 28
  local label = text(row, nil, caption, width * 0.42)
  local label_width = math.floor((width - 44) * 0.45)
  label.style.width, label.style.maximal_width = label_width, label_width
  local number_width = width - 44 - label_width
  local number = text(row, name .. "_value", value, number_width, color)
  number.style.width = number_width
  number.style.horizontal_align = "right"
end

function Gui.render(player, panel, agi)
  local scale = math.max(0.5, player.display_scale or 1)
  local width = math.max(280, math.min(600, math.floor(player.display_resolution.width / scale) - 48))
  local height = math.max(160, math.min(780, math.floor(player.display_resolution.height / scale) - 150))
  local observed = agi.completed and {completed = true, victory = agi.victory} or agi
  local signature = tostring(player.force.index) .. ":" .. tostring(width) .. ":" .. tostring(height)
    .. ":" .. helpers.table_to_json(observed)
  if panel.tags.ending_signature == signature then return end
  panel.tags = {ending_signature = signature}
  panel.style.width = width
  local old = panel[CONTENT]
  local content = old
  if content then content.clear()
  else content = panel.add{type = "scroll-pane", name = CONTENT, direction = "vertical"} end
  content.style.width, content.style.maximal_height = width - 24, height
  content.horizontal_scroll_policy = "never"
  local body = width - 56
  local view = Presentation.describe(agi)
  local header = content.add{type = "flow", direction = "horizontal"}
  header.style.vertical_align = "center"
  header.style.horizontally_stretchable = true
  local icon = header.add{type = "sprite", sprite = view.icon}
  icon.style.width, icon.style.height = 40, 40
  local stage = text(header, "bitermotors_ending_stage", view.stage, body - 84, view.color)
  stage.style.font = "heading-1"
  stage.style.horizontally_stretchable = true
  if agi.completed then
    header.add{type = "sprite-button", name = Terminal.open_button, sprite = "item/bitermotors-agi-model",
      tooltip = {"bitermotors-epilogue.open"}}
  end
  local objective = text(content, "bitermotors_ending_objective", view.objective, body)
  objective.style.font, objective.style.top_margin = "default-bold", 8
  text(content, "bitermotors_ending_detail", view.detail, body)
  local status = text(content, "bitermotors_ending_status", view.status, body, view.color)
  status.style.top_margin, status.style.bottom_margin = 8, 8
  if view.progress then
    local bar = content.add{type = "progressbar", name = "bitermotors_ending_progress", value = view.progress}
    bar.style.width, bar.style.height, bar.style.color = body, 12, colors[view.color]
  end
  content.add{type = "line"}
  local thermal = agi.thermal
  if not agi.completed and thermal and thermal.cores > 0 then
    local hot = (thermal.warning_cores or 0) + (thermal.critical_cores or 0)
    metric(content, "bitermotors_orbital_heat", "item/bitermotors-orbital-radiator-panel", "Orbital heat",
      hot > 0 and string.format("%d overheating; %.1f C", hot, thermal.hottest_c)
        or string.format("%.1f C hottest", thermal.hottest_c), body,
      thermal.critical_cores > 0 and "bad" or hot > 0 and "warning" or "good",
      "Core -> Orbital Heat Pipes -> Radiator. Aim near 97 C. Warning at 105 C, critical at 120 C, destruction at 130 C. Map alerts locate overheating cores; stop their power or repair cooling before burnout.")
  end
  metric(content, "bitermotors_earned_compute", "item/bitermotors-ai-token", "Earned compute",
    grouped(agi.completed and agi.victory and agi.victory.cumulative_ai_tokens or agi.cumulative_ai_tokens)
      .. " / " .. grouped(agi.required_ai_tokens), body,
    agi.unlocked and "good" or "warning",
    "Native computation counts even when output is spent. Packaging and inventory transfers do not earn it again.")
  if agi.unlocked or agi.models_assembled > 0 or agi.models_returned > 0 then
    metric(content, "bitermotors_assembly_milestone", "item/bitermotors-agi-training-dataset", "Orbital assembly",
      agi.models_assembled > 0 and "Complete" or view.stage_key == "assembly" and view.status or "Pending",
      body, agi.models_assembled > 0 and "good" or view.color,
      "20,000 physical Datasets and one Rack. A native completion survives output extraction and machine removal.")
  end
  if view.payload_value then
    local payload = text(content, "bitermotors_ending_payload", view.payload_value, body,
      (view.stage_key == "assembly" and agi.assembly or agi.activation).committed and "good" or "warning")
    payload.tooltip = view.payload_tooltip
  end
  if agi.models_assembled > 0 then
    metric(content, "bitermotors_return_milestone", "item/bitermotors-agi-model", "Cargo return",
      agi.models_returned > 0 and "Complete" or view.stage_key == "return" and view.status or "Awaiting Model",
      body, agi.models_returned > 0 and "good" or "warning",
      "Return the actual Model from its platform hub to a Nauvis Cargo Landing Pad, at matching quality.")
  end
  if agi.models_returned > 0 then
    metric(content, "bitermotors_activation_milestone", "item/bitermotors-terrestrial-datacenter", "Ground activation",
      agi.completed and "Complete" or view.status, body, agi.completed and "good" or view.color,
      "30 normal seconds in an existing 8 MW datacenter. The Model and progress are retained during low power.")
  end
end

return Gui
