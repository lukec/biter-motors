local Terminal = {}
local closing = {}

Terminal.frame_name = "bitermotors_epilogue"
Terminal.thinking_ticks = 180
Terminal.interval_ticks = 15
Terminal.open_button = "bitermotors_epilogue_open"

local function state()
  storage.bitermotors_epilogue = storage.bitermotors_epilogue or {players = {}, active = {}, pending = {}}
  return storage.bitermotors_epilogue
end

local function victory(player)
  if not player or not player.valid then return nil end
  local force = player.force
  if not (storage.bitermotors_victory_forces or {})[force.name] then return nil end
  return (storage.bitermotors_agi_victory or {})[force.name]
end

local function record(player, create)
  local won = victory(player)
  if not won then return nil end
  local root = state()
  local records = root.players[player.index]
  local saved = records and records[player.force.index]
  if saved and saved.victory_tick == won.tick then return saved end
  if not create then return nil end
  records = records or {}
  root.players[player.index] = records
  saved = {victory_tick = won.tick, acknowledged = false, skipped = false}
  records[player.force.index] = saved
  return saved
end

local function active_record(player_index, active)
  local records = state().players[player_index]
  return records and records[active.force_index]
end

local function advance(active, saved)
  if saved and saved.session then
    saved.session.elapsed_ticks = math.min(Terminal.thinking_ticks,
      saved.session.elapsed_ticks + math.max(0, game.tick - active.last_tick))
    active.last_tick = game.tick
  end
end

local function destroy_frame(player)
  local frame = player and player.valid and player.gui.screen[Terminal.frame_name]
  if frame then
    closing[player.index] = true
    if player.opened == frame then player.opened = nil end
    if frame.valid then frame.destroy() end
    closing[player.index] = nil
  end
end

function Terminal.suspend(player, count_elapsed)
  if not player or not player.valid then return end
  local root = state()
  local active = root.active[player.index]
  if active and count_elapsed then advance(active, active_record(player.index, active)) end
  root.active[player.index], root.pending[player.index] = nil, nil
  destroy_frame(player)
end

function Terminal.queue(player)
  if not player or not player.valid then return false end
  local saved = record(player, true)
  if not saved then return false end
  if not saved.acknowledged or saved.session then
    state().pending[player.index] = player.force.index
    return true
  end
  return false
end

function Terminal.reconcile(player)
  Terminal.suspend(player, true)
  return Terminal.queue(player)
end

local function dimensions(player)
  local scale = math.max(0.5, player.display_scale or 1)
  local width = math.max(240, math.min(620, math.floor(player.display_resolution.width / scale) - 48))
  local height = math.max(240, math.min(380, math.floor(player.display_resolution.height / scale) - 48))
  return width, height
end

local function render(player, saved)
  local frame = player.gui.screen[Terminal.frame_name]
  if not frame then return end
  local width, height = dimensions(player)
  local dialogue = frame.terminal.dialogue
  local ready = saved.session.elapsed_ticks >= Terminal.thinking_ticks
  local cursor_visible = not ready and math.floor(saved.session.elapsed_ticks / 30) % 2 == 0
  local signature = tostring(width) .. ":" .. tostring(height) .. ":" .. tostring(ready) .. ":" .. tostring(cursor_visible)
  if frame.tags.presentation_signature == signature then return end
  frame.tags = {presentation_signature = signature}
  frame.style.width, frame.style.maximal_height = width, height
  dialogue.style.width = width - 32
  dialogue.style.maximal_height = height - 104
  dialogue.bitermotors_epilogue_prompt.style.maximal_width = width - 80
  local reply = dialogue.computer_line
  reply.bitermotors_epilogue_reply.style.maximal_width = math.max(72, width - 166)
  reply.bitermotors_epilogue_reply.visible = ready
  reply.bitermotors_epilogue_cursor.visible = cursor_visible
  local action = frame.footer.bitermotors_epilogue_action
  action.caption = {ready and "bitermotors-epilogue.continue" or "bitermotors-epilogue.skip"}
  action.style = ready and "confirm_button" or "button"
  frame.footer.bitermotors_epilogue_replay.visible = ready
end

local function build_frame(player, saved)
  destroy_frame(player)
  local frame = player.gui.screen.add{type = "frame", name = Terminal.frame_name, direction = "vertical"}
  frame.auto_center = true
  local titlebar = frame.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = frame
  titlebar.add{type = "label", caption = {"bitermotors-epilogue.title"}, style = "frame_title"}
  local drag = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
  drag.style.horizontally_stretchable = true
  drag.style.height, drag.drag_target = 24, frame
  titlebar.add{type = "sprite-button", name = "bitermotors_epilogue_close", sprite = "utility/close",
    style = "frame_action_button", tooltip = {"bitermotors-epilogue.close"}}
  local shell = frame.add{type = "frame", name = "terminal", direction = "vertical", style = "inside_deep_frame"}
  local dialogue = shell.add{type = "scroll-pane", name = "dialogue", direction = "vertical"}
  dialogue.horizontal_scroll_policy = "never"
  dialogue.style.padding = 20
  local online = dialogue.add{type = "flow", direction = "horizontal"}
  local icon = online.add{type = "sprite", sprite = "item/bitermotors-agi-model"}
  icon.style.width, icon.style.height = 32, 32
  local label = online.add{type = "label", caption = {"bitermotors-epilogue.online"}, style = "bold_label"}
  label.style.font_color = {r = 0.55, g = 0.8, b = 0.5}
  local prompt = dialogue.add{type = "label", name = "bitermotors_epilogue_prompt",
    caption = {"bitermotors-epilogue.prompt"}, single_line = false}
  prompt.style.top_margin, prompt.style.bottom_margin = 20, 12
  prompt.style.horizontally_stretchable = true
  local computer = dialogue.add{type = "flow", name = "computer_line", direction = "horizontal"}
  computer.style.minimal_height = 56
  computer.add{type = "label", caption = {"bitermotors-epilogue.computer"}, style = "bold_label"}
  local answer = computer.add{type = "label", name = "bitermotors_epilogue_reply", caption = {"bitermotors-epilogue.response"},
    single_line = false}
  answer.style.horizontally_stretchable = true
  answer.style.font_color = {r = 0.85, g = 0.87, b = 0.82}
  computer.add{type = "label", name = "bitermotors_epilogue_cursor", caption = "_", style = "bold_label"}
  local footer = frame.add{type = "flow", name = "footer", direction = "horizontal"}
  footer.style.top_margin = 8
  footer.add{type = "sprite-button", name = "bitermotors_epilogue_replay", sprite = "utility/reset",
    tooltip = {"bitermotors-epilogue.replay"}}
  local stretch = footer.add{type = "empty-widget"}
  stretch.style.horizontally_stretchable = true
  footer.add{type = "button", name = "bitermotors_epilogue_action"}
  player.opened = frame
  render(player, saved)
end

function Terminal.open(player)
  if not player or not player.valid then return false end
  local saved = record(player, true)
  if not saved then return false end
  if game.finished or player.controller_type == defines.controllers.cutscene then
    Terminal.queue(player)
    return false
  end
  local root = state()
  local active = root.active[player.index]
  if active and active.force_index == player.force.index and player.gui.screen[Terminal.frame_name] then
    local frame = player.gui.screen[Terminal.frame_name]
    if player.opened ~= frame then player.opened = frame end
    frame.bring_to_front()
    return true
  end
  saved.session = saved.session or {elapsed_ticks = 0, replay = saved.acknowledged}
  root.pending[player.index] = nil
  root.active[player.index] = {force_index = player.force.index, last_tick = game.tick,
    allow_offline = not player.connected}
  build_frame(player, saved)
  return true
end

function Terminal.dismiss(player)
  if not player or not player.valid then return false end
  local saved = record(player, false)
  if not saved then return false end
  local root = state()
  local active = root.active[player.index]
  if active and active.force_index == player.force.index then advance(active, saved) end
  if not saved.acknowledged then
    saved.skipped = not saved.session or saved.session.elapsed_ticks < Terminal.thinking_ticks
    saved.acknowledged = true
  end
  saved.session = nil
  root.active[player.index], root.pending[player.index] = nil, nil
  destroy_frame(player)
  return true
end

function Terminal.replay(player)
  if not Terminal.dismiss(player) then return false end
  return Terminal.open(player)
end

function Terminal.status(player)
  local won = victory(player)
  if not won then return {eligible = false, phase = "locked", acknowledged = false, open = false} end
  local saved = record(player, false)
  local session = saved and saved.session
  local frame = player.gui.screen[Terminal.frame_name]
  local active = state().active[player.index]
  local elapsed = session and session.elapsed_ticks or 0
  local is_open = frame ~= nil and active ~= nil and active.force_index == player.force.index
  return {eligible = true, force_index = player.force.index, victory_tick = won.tick,
    acknowledged = saved and saved.acknowledged == true or false,
    skipped = saved and saved.skipped == true or false,
    elapsed_ticks = elapsed, replay = session and session.replay == true or false, open = is_open,
    phase = is_open and (elapsed >= Terminal.thinking_ticks and "reply" or "thinking")
      or saved and saved.acknowledged and not session and "acknowledged" or "pending"}
end

function Terminal.handle_click(event)
  local element = event.element
  if not element or not element.valid or element.player_index ~= event.player_index
    or element.get_mod() ~= script.mod_name then return false end
  local player = game.get_player(event.player_index)
  if not player or not player.valid then return false end
  if element.name == Terminal.open_button then return Terminal.open(player) end
  if element.name ~= "bitermotors_epilogue_close" and element.name ~= "bitermotors_epilogue_action"
    and element.name ~= "bitermotors_epilogue_replay" then return false end
  local root = element
  while root.parent and root.name ~= Terminal.frame_name do root = root.parent end
  if root ~= player.gui.screen[Terminal.frame_name] then return false end
  if element.name == "bitermotors_epilogue_replay" then return Terminal.replay(player) end
  return Terminal.dismiss(player)
end

function Terminal.handle_closed(event)
  if closing[event.player_index] then return true end
  local player = game.get_player(event.player_index)
  local frame = player and player.gui.screen[Terminal.frame_name]
  if frame and event.element == frame then return Terminal.dismiss(player) end
  return false
end

function Terminal.update()
  local root = state()
  for player_index, active in pairs(root.active) do
    local player = game.get_player(player_index)
    if not player then root.active[player_index] = nil
    elseif active.force_index ~= player.force.index or not victory(player)
      or player.controller_type == defines.controllers.cutscene
      or (not player.connected and not active.allow_offline) then
      Terminal.suspend(player, false)
      Terminal.queue(player)
    else
      local saved = active_record(player_index, active)
      local frame = player.gui.screen[Terminal.frame_name]
      if not saved or not saved.session or not frame then
        Terminal.suspend(player, false)
        Terminal.queue(player)
      elseif not game.finished then
        advance(active, saved)
        render(player, saved)
      end
    end
  end
  if game.finished then return end
  for player_index, force_index in pairs(root.pending) do
    local player = game.get_player(player_index)
    if not player or player.force.index ~= force_index or not victory(player) then
      root.pending[player_index] = nil
    elseif player.connected and not player.opened and player.controller_type ~= defines.controllers.cutscene then
      Terminal.open(player)
    end
  end
end

function Terminal.remove_player(player_index)
  local root = state()
  root.players[player_index], root.active[player_index], root.pending[player_index] = nil, nil, nil
end

return Terminal
