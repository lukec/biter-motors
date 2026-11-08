import re
import shutil
import subprocess
import unittest
from pathlib import Path

try:
    from lupa import LuaRuntime
except ImportError:
    LuaRuntime = None


ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod/bitermotors_0.1.1"
MODULE = MOD / "runtime/terminal_epilogue.lua"
LUA = shutil.which("lua") or shutil.which("lua5.4") or shutil.which("luajit")

# Only native GUI tree operations are mocked; all session policy runs in the module.
MOCKS = r"""
storage = {bitermotors_victory_forces={alpha=true}, bitermotors_agi_victory={alpha={tick=100}}}
local players = {}
game = {tick=100, finished=false, get_player=function(index) return players[index] end}
script = {mod_name='bitermotors'}
defines = {controllers={cutscene=3,character=1}}
local function node(parent, spec)
  local element = {parent=parent, name=spec.name, valid=true, style={}, tags={},
    player_index=parent and parent.player_index, visible=true, caption=spec.caption}
  element.get_mod = function() return 'bitermotors' end
  element.add = function(child)
    local added = node(element, child)
    if child.name then element[child.name] = added end
    return added
  end
  element.destroy = function()
    element.valid = false
    if parent and element.name then parent[element.name] = nil end
  end
  element.bring_to_front = function() end
  return element
end
local alpha, beta = {index=1,name='alpha'}, {index=2,name='beta'}
local function player(index, force)
  local p = {index=index, valid=true, force=force, connected=true,
    display_scale=1, display_resolution={width=1280,height=800}, gui={screen=node(nil,{})}}
  p.gui.screen.player_index = index
  players[index] = p
  return p
end
local p, other = player(1,alpha), player(2,alpha)
local function saved(who, force)
  return storage.bitermotors_epilogue.players[who.index][force.index]
end
local function serializable(value)
  local t = type(value)
  assert(t == 'table' or t == 'string' or t == 'number' or t == 'boolean')
  if t == 'table' then
    assert(getmetatable(value) == nil)
    for key, child in pairs(value) do
      assert(type(key) == 'string' or type(key) == 'number')
      serializable(child)
    end
  end
end
"""


class TerminalEpilogueContractTest(unittest.TestCase):
    def test_offline_module_never_controls_simulation_or_registers_events(self):
        source = MODULE.read_text()
        for forbidden in (r"game\s*\.\s*(?:tick_paused|speed)\s*=", r"set_game_state",
                          r"script\s*\.\s*(?:on_event|on_nth_tick)",
                          r"\brequire\s*\(", r"\b(?:http|https|socket|curl|openai)\b"):
            self.assertNotRegex(source.lower(), forbidden)
        self.assertIn("storage.bitermotors_epilogue", source)
        self.assertIn("return Terminal", source)
        for method in ("queue", "open", "dismiss", "replay", "status", "update",
                       "suspend", "reconcile", "remove_player", "handle_click", "handle_closed"):
            self.assertIn("function Terminal." + method + "(", source)

    def test_parent_uses_single_event_handlers(self):
        source = (MOD / "control.lua").read_text()
        for event in ("on_player_joined_game", "on_player_left_game", "on_player_removed",
                      "on_player_changed_force", "on_gui_click", "on_gui_closed"):
            pattern = r"script\.on_event\(defines\.events\." + event + r"\s*,"
            self.assertEqual(len(re.findall(pattern, source)), 1, event)
        self.assertEqual(source.count("TerminalEpilogue.update()"), 1)
        self.assertEqual(source.count("TerminalEpilogue.handle_click(event)"), 1)
        self.assertEqual(source.count("TerminalEpilogue.handle_closed(event)"), 1)


@unittest.skipUnless(LuaRuntime or LUA, "Lua mocks require Lua or optional lupa; native qualification is separate")
class TerminalEpilogueStateTest(unittest.TestCase):
    def lua(self, assertions):
        code = MOCKS + "\nlocal T = dofile(" + repr(str(MODULE)) + ")\n" + assertions
        if LuaRuntime:
            LuaRuntime().execute(code)
        else:
            run = subprocess.run([LUA, "-"], input=code, text=True, capture_output=True)
            self.assertEqual(run.returncode, 0, run.stderr)

    def test_victory_gate_pending_and_multiplayer_acknowledgement(self):
        self.lua("""
        local locked = player(3,beta)
        assert(not T.queue(locked) and not T.open(locked))
        assert(T.status(locked).phase == 'locked')
        assert(T.queue(p) and T.queue(other))
        game.finished = true
        T.update()
        assert(not T.status(p).open)
        game.finished = false
        p.opened = {unrelated=true}
        T.update()
        assert(not T.status(p).open and T.status(other).open)
        p.opened = nil
        T.update()
        assert(T.status(p).phase == 'thinking')
        assert(T.dismiss(p) and T.status(p).skipped)
        assert(not T.queue(p))
        assert(not T.status(other).acknowledged)
        assert(storage.bitermotors_victory_forces.alpha)
        serializable(storage.bitermotors_epilogue)
        """)

    def test_reply_replay_close_and_click_ownership(self):
        self.lua("""
        assert(T.open(p))
        game.tick = game.tick + T.thinking_ticks
        T.update()
        assert(T.status(p).phase == 'reply')
        local frame = p.gui.screen[T.frame_name]
        assert(frame.terminal.dialogue.computer_line.bitermotors_epilogue_reply.visible)
        local action = frame.footer.bitermotors_epilogue_action
        assert(not T.handle_click{element=action,player_index=other.index})
        local foreign = node(p.gui.screen,{name='bitermotors_epilogue_action'})
        assert(not T.handle_click{element=foreign,player_index=p.index})
        assert(T.handle_click{element=action,player_index=p.index})
        assert(T.status(p).acknowledged and not T.status(p).skipped)
        assert(T.replay(p) and T.status(p).replay)
        assert(T.status(p).phase == 'thinking')
        assert(T.handle_closed{player_index=p.index,element=p.gui.screen[T.frame_name]})
        assert(T.status(p).acknowledged and not T.status(p).skipped)
        """)

    def test_suspend_reload_resume_and_force_isolation(self):
        self.lua("""
        assert(T.open(p))
        game.tick = game.tick + 60
        T.suspend(p,true)
        assert(saved(p,alpha).session.elapsed_ticks == 60)
        serializable(storage.bitermotors_epilogue)
        game.tick = game.tick + 600
        T = dofile(""" + repr(str(MODULE)) + """)
        assert(T.reconcile(p))
        T.update()
        assert(T.status(p).elapsed_ticks == 60)
        p.force = beta
        assert(not T.reconcile(p))
        assert(T.status(p).phase == 'locked')
        assert(saved(p,alpha).session.elapsed_ticks == 60)
        storage.bitermotors_victory_forces.beta = true
        storage.bitermotors_agi_victory.beta = {tick=200}
        assert(T.open(p) and T.dismiss(p))
        assert(saved(p,beta).acknowledged and not saved(p,alpha).acknowledged)
        p.force = alpha
        assert(T.reconcile(p))
        T.update()
        assert(T.status(p).elapsed_ticks == 60)
        T.remove_player(p.index)
        assert(storage.bitermotors_epilogue.players[p.index] == nil)
        assert(storage.bitermotors_epilogue.active[p.index] == nil)
        assert(storage.bitermotors_epilogue.pending[p.index] == nil)
        """)

    def test_cutscene_defers_without_acknowledging_and_explicit_open_restores_focus(self):
        self.lua("""
        p.controller_type = defines.controllers.cutscene
        assert(T.queue(p))
        T.update()
        assert(not T.status(p).open and not T.open(p))
        assert(not T.status(p).acknowledged)
        p.controller_type = defines.controllers.character
        T.update()
        local frame = p.gui.screen[T.frame_name]
        assert(T.status(p).open and p.opened == frame)
        p.opened = nil
        assert(T.open(p) and p.opened == frame)
        assert(T.handle_closed{player_index=p.index,element=frame})
        assert(T.status(p).acknowledged)
        """)

    def test_new_victory_replaces_old_acknowledgement(self):
        self.lua("""
        assert(T.open(p) and T.dismiss(p))
        storage.bitermotors_agi_victory.alpha = {tick=999}
        assert(T.queue(p))
        assert(not T.status(p).acknowledged)
        assert(saved(p,alpha).victory_tick == 999)
        serializable(storage.bitermotors_epilogue)
        """)


if __name__ == "__main__":
    unittest.main()
