-- Native GUI objects and public presentation callbacks, not synthetic GUI/join events.
-- Actual mouse/Escape dispatch and network joining require graphical acceptance.
local M = {}
function M.new(check, equal, enabled, single_player)
  if not enabled then
    local function noop() end
    return {init = noop, prewin = noop, queued = noop, reload = noop, tick = noop, progress = noop, progress_force_cache = noop,
      snapshot = noop, evidence = noop, done = function() return true end}
  end
  local function status(player)
    return remote.call("bitermotors", "epilogue_status", player.index)
  end
  local function call(name, player)
    if name == "open_epilogue" then
      -- These purpose-created players may receive the scenario's intro dialog.
      if not player.gui.screen.bitermotors_epilogue then player.opened = nil end
      for _, root in ipairs({player.gui.screen, player.gui.center}) do
        for _, child in pairs(root.children) do
          if child.name ~= "bitermotors_epilogue" then child.destroy() end
        end
      end
    end
    local speed, paused = game.speed, game.tick_paused
    local result = remote.call("bitermotors", name, player.index)
    equal(game.speed, speed, name .. " preserves game speed")
    equal(game.tick_paused, paused, name .. " preserves pause state")
    return result
  end
  local function find(root, name)
    if root.name == name then return root end
    for _, child in pairs(root.children) do
      local found = find(child, name)
      if found then return found end
    end
  end
  local function frame(player)
    local root = player.gui.screen.bitermotors_epilogue
    check(root and root.valid, "native epilogue screen frame exists")
    equal(player.opened, root, "native player.opened targets screen frame")
    check(find(root, "bitermotors_epilogue_close") ~= nil, "native close control exists")
    check(find(root, "bitermotors_epilogue_action") ~= nil, "native action control exists")
    check(find(root, "bitermotors_epilogue_prompt") ~= nil, "native request dialogue exists")
    return root
  end
  local function locked(player)
    local s = status(player)
    equal(s.eligible, false, "unwon force is ineligible")
    equal(s.phase, "locked", "unwon epilogue remains locked")
    equal(s.open, false, "unwon epilogue stays closed")
    equal(call("open_epilogue", player), false, "unwon force cannot open spoilers")
    equal(player.gui.screen.bitermotors_epilogue, nil, "no pre-victory prompt or reply GUI")
  end
  local function identity(player, victory_tick)
    local s = status(player)
    equal(s.force_index, player.force.index, "epilogue identifies player's current force")
    equal(s.victory_tick, victory_tick, "epilogue identifies original victory tick")
    equal(s.eligible, true, "native victory alone enables epilogue")
    return s
  end
  local function snapshot()
    local f = storage.epilogue_fixture
    return {first = status(f.first), second = f.second and status(f.second) or nil,
      outsider = f.outsider and status(f.outsider) or nil, victory_tick = f.victory_tick}
  end
  local api = {snapshot = snapshot}
  function api.progress_force_cache()
    local f = storage.epilogue_fixture
    local player, won_force = f.first, f.first.force
    local function open_progress()
      check(call("open_progress", player), "force-cache probe opens native Progress without clearing GUI")
      return assert(player.gui.screen.bitermotors_progress_panel)
    end
    local function first_label(root)
      if root.type == "label" then return root end
      for _, child in pairs(root.children) do
        local label = first_label(child)
        if label then return label end
      end
    end
    local function normal(panel)
      equal(status(player).eligible, false, "early force cannot inherit victory eligibility")
      local content = find(panel, "bitermotors_progress_content")
      check(content and content.visible, "early force normal Progress content exists")
      for _, name in ipairs({"bitermotors_ending_stage", "bitermotors_ending_objective",
        "bitermotors_ending_detail", "bitermotors_epilogue_open", "bitermotors_epilogue_prompt",
        "bitermotors_epilogue_reply"}) do
        equal(find(panel, name), nil, "early force has no ending spoiler: " .. name)
      end
      equal(player.gui.screen.bitermotors_epilogue, nil, "early force has no terminal reply frame")
      local label = first_label(content)
      check(label and type(label.caption) == "string" and label.caption ~= "Complete", "early force has normal stage label")
      return label.caption
    end
    local function complete(panel)
      local label = find(panel, "bitermotors_ending_stage")
      check(label ~= nil, "won force reinstates native ending renderer")
      equal(label.caption, "Complete", "won force Progress retains genuine completion")
      check(find(panel, "bitermotors_epilogue_open") ~= nil, "won force has epilogue replay control")
      equal(status(player).acknowledged, false, "Progress force switches cannot acknowledge epilogue")
      return label.caption
    end
    -- Retain the same panel across B -> A -> B -> A. In particular, never use
    -- open_epilogue/locked here: their fixture cleanup would hide stale content.
    player.force = f.unwon_force
    local panel = open_progress()
    local primed = normal(panel)
    player.force = won_force
    equal(open_progress(), panel, "won renderer reuses primed native panel")
    local won_stage = complete(panel)
    player.force = f.unwon_force
    equal(open_progress(), panel, "early renderer reuses native panel after Complete")
    local returned = normal(panel)
    equal(returned, primed, "return to early force restores original normal stage")
    player.force = won_force
    equal(open_progress(), panel, "return to won force retains native panel")
    local restored = complete(panel)
    f.progress_force_cache = {primed_stage = primed, won_stage = won_stage,
      returned_stage = returned, restored_won_stage = restored, same_frame = true, no_spoilers = true}
    panel.destroy()
  end
  function api.progress(phase, checkpoint_name)
    local f = storage.epilogue_fixture
    check(call("open_progress", f.first), "public Progress API instantiates native GUI")
    local panel = f.first.gui.screen.bitermotors_progress_panel
    check(panel and panel.valid, "native Progress frame exists")
    local content = find(panel, "bitermotors_progress_content")
    check(content and content.visible, "native Progress content is visible")
    local stage = find(content, "bitermotors_ending_stage")
    local expected = ({assembly = "Model assembly", activation = "Ground activation", won = "Complete"})[phase]
    check(stage and stage.visible, "native Progress stage label exists")
    equal(stage.caption, expected, "native Progress stage matches real route")
    local detail = find(content, "bitermotors_ending_detail")
    local objective = find(content, "bitermotors_ending_objective")
    check(detail and type(detail.caption) == "string" and detail.caption ~= "", "native Progress detail exists")
    check(objective and type(objective.caption) == "string" and objective.caption ~= "", "native Progress objective exists")
    local bar = find(content, "bitermotors_ending_progress")
    check(bar and type(bar.value) == "number", "native Progress bar is instantiated")
    local payload = find(content, "bitermotors_ending_payload")
    if phase == "won" then
      check(not storage.assembler.valid and not storage.terminal.valid, "completed Progress survives original machine removal")
      equal(bar.value, 1, "native completed Progress is full")
      equal(payload, nil, "completed Progress never asks for replacement inputs")
      check(detail.caption:find("Victory recorded", 1, true), "completed Progress retains victory authority")
    else
      local agi = remote.call("bitermotors", "agi_training_status", f.first.force.name)
      check(agi[phase].committed, "native craft has committed original payload")
      check(payload and payload.visible, "native committed payload label exists")
      equal(payload.caption, "Payload committed", "native GUI does not show empty ingredients as missing")
      check(detail.caption:find("Payload committed", 1, true), "native detail explains committed craft")
      check(not detail.caption:find("Load 20000", 1, true)
        and not detail.caption:find("Load the returned", 1, true), "native GUI never requests replacement committed ingredients")
      check(bar.value > 0 and bar.value < 1, "native GUI displays banked partial progress")
    end
    f.progress_gui_checks = f.progress_gui_checks or {}
    f.progress_gui_checks[checkpoint_name] = {stage = stage.caption, detail = detail.caption,
      payload = payload and payload.caption or nil, progress = bar.value}
    -- Keep subsequent epilogue checks independent of the fixture-opened panel.
    panel.destroy()
  end
  function api.init()
    local force = game.forces["epilogue-unwon"] or game.create_force("epilogue-unwon")
    local used = {}
    local named = {["Epilogue-first"] = true, ["Epilogue-second"] = true, ["Epilogue-unwon"] = true}
    local function fixture_player(name)
      local player = game.get_player(name)
      if not player then
        for _, candidate in pairs(game.players) do
          if not used[candidate.index] and not named[candidate.name] and candidate.name ~= "Epilogue-late" then
            player = candidate
            break
          end
        end
      end
      check(player ~= nil, "bootstrap save needs native offline player: " .. name
        .. "; LuaGameScript has no create_player API")
      used[player.index] = true
      return player
    end
    storage.epilogue_fixture = {first = fixture_player("Epilogue-first"), unwon_force = force}
    local f = storage.epilogue_fixture
    if not single_player then
      f.second, f.outsider = fixture_player("Epilogue-second"), fixture_player("Epilogue-unwon")
      equal(game.get_player("Epilogue-late"), nil, "late fixture player must be genuinely created after victory")
      f.second.force, f.outsider.force = game.forces.player, force
    end
    f.first.force = game.forces.player
    for _, p in ipairs(single_player and {f.first} or {f.first, f.second, f.outsider}) do
      equal(p.connected, false, "purpose-created fixture player is offline")
      locked(p)
    end
  end
  function api.prewin()
    local f = storage.epilogue_fixture
    locked(f.first)
    if not single_player then locked(f.second); locked(f.outsider) end
  end
  function api.queued()
    local f = storage.epilogue_fixture
    local s = status(f.first)
    check(type(s.victory_tick) == "number", "epilogue records real native victory tick")
    f.victory_tick = s.victory_tick
    for _, p in ipairs(single_player and {f.first} or {f.first, f.second}) do
      s = identity(p, f.victory_tick)
      equal(s.phase, "pending", "offline victory queues presentation")
      equal(s.acknowledged, false, "queued player has not acknowledged")
      equal(s.open, false, "automatic presentation excludes offline players")
    end
    if not single_player then locked(f.outsider) end
  end
  function api.reload(phase)
    local f = storage.epilogue_fixture
    local s = identity(f.first, f.victory_tick)
    if phase == "won" then
      equal(s.phase, "pending", "queued epilogue survives separate-process reload")
      check(call("open_epilogue", f.first), "explicit offline open consumes queue")
      if not single_player then check(call("open_epilogue", f.second), "second offline player opens independently") end
      f.speed, f.paused = game.speed, game.tick_paused
      f.step = "thinking"
    elseif phase == "epilogue_thinking" then
      equal(s.phase, "thinking", "mid-thinking session survives reload")
      check(s.elapsed_ticks >= f.saved_elapsed, "thinking reload preserves elapsed simulation ticks")
      equal(s.acknowledged, false, "thinking reload cannot acknowledge")
      local elapsed = s.elapsed_ticks
      frame(f.first).destroy()
      check(call("open_epilogue", f.first), "explicit open recreates missing GUI safely")
      equal(status(f.first).elapsed_ticks, elapsed, "GUI recreation cannot restart thinking")
      local existing = frame(f.first)
      local before_open = status(f.first)
      for _ = 1, 3 do
        check(call("open_epilogue", f.first), "repeated thinking open succeeds")
        equal(frame(f.first), existing, "repeated thinking open preserves same native frame")
        local after_open = status(f.first)
        equal(after_open.elapsed_ticks, before_open.elapsed_ticks, "repeated thinking open preserves elapsed ticks")
        equal(after_open.acknowledged, before_open.acknowledged, "repeated thinking open preserves acknowledgement")
        equal(after_open.phase, "thinking", "repeated thinking open cannot close session")
        equal(after_open.skipped, before_open.skipped, "repeated thinking open cannot Skip")
      end
      f.repeated_open_probe = {frame = existing, tick = game.tick, elapsed = before_open.elapsed_ticks}
      if not single_player then
        call("dismiss_epilogue", f.second)
        local second = identity(f.second, f.victory_tick)
        equal(second.acknowledged, true, "Skip acknowledges only second player")
        equal(second.skipped, true, "thinking dismissal records Skip")
        equal(second.phase, "acknowledged", "Skip ends presentation")
        equal(status(f.first).acknowledged, false, "Skip does not acknowledge first player")
      end
      f.step = "reply"
    elseif phase == "epilogue_reply" then
      equal(s.phase, "reply", "reply-before-ack survives reload")
      equal(s.acknowledged, false, "reply reload does not auto-acknowledge")
      call("dismiss_epilogue", f.first)
      s = status(f.first)
      equal(s.acknowledged, true, "Continue acknowledges first player")
      equal(s.skipped, false, "Continue after reply is not Skip")
      if not single_player then equal(status(f.second).skipped, true, "Continue preserves independent Skip") end
      f.step = "acknowledged"
    elseif phase == "epilogue_acknowledged" then
      equal(s.acknowledged, true, "acknowledgement survives separate-process reload")
      equal(s.open, false, "acknowledged session does not auto-reopen")
      if not single_player then equal(status(f.second).skipped, true, "independent Skip survives reload") end
      check(call("open_epilogue", f.first), "acknowledged player may replay")
      s = status(f.first)
      equal(s.replay, true, "explicit acknowledged open is replay")
      equal(s.acknowledged, true, "replay never resets acknowledgement")
      f.replay_preserved_ack = true
      frame(f.first)
      -- Force assignment raises the native force-change lifecycle event.
      f.first.force = f.unwon_force
      locked(f.first)
      f.first.force = game.forces.player
      check(call("open_epilogue", f.first), "return to original force resumes presentation")
      equal(status(f.first).acknowledged, true, "force roundtrip preserves original acknowledgement")
      f.force_isolated = true
      if single_player then
        equal(status(f.first).phase, "thinking", "single-player replay resumes thinking after force roundtrip")
        f.step = "replay"
        return
      end
      call("dismiss_epilogue", f.first)
      equal(status(f.first).open, false, "shared X/dismiss callback closes replay")
      equal(status(f.first).acknowledged, true, "closing replay preserves acknowledgement")
      check(call("open_epilogue", f.second), "skipped player may independently replay")
      equal(status(f.second).acknowledged, true, "second replay preserves acknowledgement")
      equal(status(f.second).skipped, true, "second replay preserves historical Skip")
      call("dismiss_epilogue", f.second)
      f.step = "late"
      helpers.write_file("bitermotors-epilogue-needs-player.json", helpers.table_to_json{
        status = "awaiting_late_player", tick = game.tick, player_name = "Epilogue-late",
        reason = "Connect then disconnect a purpose-created isolated test client without acknowledging the epilogue; native creation cannot be raised by Lua."}, false)
      log("BITERMOTORS_EPILOGUE_AWAITING_LATE_PLAYER: connect then disconnect Epilogue-late")
    elseif phase == "epilogue_late" then
      equal(status(f.late).acknowledged, true, "late acknowledgement survives reload")
      f.step, f.finished_tick = "done", game.tick
    elseif phase == "epilogue_replay" then
      check(single_player, "single-player replay checkpoint is explicit")
      equal(s.phase, "thinking", "replay thinking survives separate-process reload")
      equal(s.replay, true, "reloaded session is still a replay")
      equal(s.acknowledged, true, "replay reload preserves original Continue acknowledgement")
      check(s.elapsed_ticks >= f.saved_replay_elapsed and s.elapsed_ticks < 180,
        "replay reload preserves unfinished thinking")
      frame(f.first)
      call("dismiss_epilogue", f.first)
      s = status(f.first)
      equal(s.open, false, "thinking Skip callback closes single-player replay")
      equal(s.acknowledged, true, "thinking dismissal cannot undo original acknowledgement")
      equal(s.skipped, false, "replay Skip cannot rewrite original Continue history")
      f.thinking_dismiss_preserved_ack = true
      f.step, f.finished_tick = "done", game.tick
    end
  end
  function api.tick(checkpoint)
    local f = storage.epilogue_fixture
    if not f.step then return end
    equal(game.speed, f.speed, "epilogue animation preserves game speed")
    equal(game.tick_paused, f.paused, "epilogue animation preserves pause state")
    if f.repeated_open_probe and game.tick > f.repeated_open_probe.tick then
      equal(frame(f.first), f.repeated_open_probe.frame, "repeated open preserves frame on following simulation tick")
      local after_tick = status(f.first)
      equal(after_tick.acknowledged, false, "repeated open cannot queue a delayed acknowledgement")
      equal(after_tick.phase, "thinking", "repeated open cannot queue a delayed close")
      check(after_tick.elapsed_ticks >= f.repeated_open_probe.elapsed, "repeated open cannot reset elapsed ticks later")
      f.repeated_open_probe, f.repeated_open_idempotent = nil, true
    end
    if f.step == "late" then
      f.late = game.get_player("Epilogue-late")
      if not f.late or f.late.connected then return end
      local s = identity(f.late, f.victory_tick)
      equal(s.phase, "pending", "native late player creation queues epilogue")
      equal(s.acknowledged, false, "late player has independent acknowledgement")
      check(call("open_epilogue", f.late), "late offline player explicitly opens")
      frame(f.late)
      call("dismiss_epilogue", f.late)
      equal(status(f.late).acknowledged, true, "late player acknowledges once")
      f.late_created_once = true
      checkpoint("epilogue_late", 0)
      return
    end
    if f.step == "done" then
      for _, player in ipairs(single_player and {f.first} or {f.first, f.second, f.late}) do
        local s = identity(player, f.victory_tick)
        equal(s.acknowledged, true, "freeplay preserves per-player acknowledgement")
        equal(s.open, false, "acknowledged presentation never automatically reopens")
      end
      return
    end
    if f.step == "acknowledged" then
      checkpoint("epilogue_acknowledged", 0)
      return
    end
    if not single_player then locked(f.outsider) end
    local s = identity(f.first, f.victory_tick)
    equal(s.acknowledged, f.step == "replay", "presentation never changes acknowledgement itself")
    local root = frame(f.first)
    if s.phase == "thinking" then
      local reply = find(root, "bitermotors_epilogue_reply")
      check(reply and not reply.visible, "reply hidden before 180 simulation ticks")
      check(find(root, "bitermotors_epilogue_cursor") ~= nil, "thinking has native cursor")
      check(s.elapsed_ticks < 180, "thinking lasts exactly the simulation delay")
      if f.step == "thinking" and s.elapsed_ticks >= 60 then
        if not single_player then equal(status(f.second).phase, "thinking", "two offline presentations animate independently") end
        f.saved_elapsed = s.elapsed_ticks
        checkpoint("epilogue_thinking", 0)
      elseif f.step == "replay" and s.elapsed_ticks >= 60 then
        f.saved_replay_elapsed = s.elapsed_ticks
        checkpoint("epilogue_replay", 0)
      end
    elseif s.phase == "reply" then
      check(s.elapsed_ticks >= 180, "reply waits 180 actual simulation ticks")
      local reply = find(root, "bitermotors_epilogue_reply")
      check(reply and reply.visible, "native reply is visible after thinking")
      local cursor = find(root, "bitermotors_epilogue_cursor")
      check(cursor and not cursor.visible, "thinking cursor disappears after reply")
      check(f.step == "reply", "thinking checkpoint cannot be bypassed")
      checkpoint("epilogue_reply", 0)
    else
      equal(s.phase, "thinking", "explicit open begins or resumes thinking")
    end
  end
  function api.done()
    return storage.epilogue_fixture.step == "done"
  end
  function api.evidence()
    local f = storage.epilogue_fixture
    return {replay_preserved_ack = f.replay_preserved_ack, force_isolated = f.force_isolated,
      late_created_once = f.late_created_once, late = f.late and status(f.late) or nil,
      thinking_dismiss_preserved_ack = f.thinking_dismiss_preserved_ack,
      repeated_open_idempotent = f.repeated_open_idempotent,
      progress_gui_checks = f.progress_gui_checks, progress_force_cache = f.progress_force_cache}
  end
  return api
end
return M
