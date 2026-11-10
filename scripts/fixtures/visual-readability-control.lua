-- Disposable graphical fixture. Never load this helper in a player campaign.
local function make(surface, name, x, y, force)
  return assert(surface.create_entity{name=name, position={x,y}, force=force, raise_built=true}, name)
end
local function setup(player)
  local force = game.forces["visual-readability"] or game.create_force("visual-readability")
  player.force = force
  force.research_all_technologies()
  local platform = force.create_space_platform{name="Readability QA", planet="nauvis", starter_pack="space-platform-starter-pack"}
  platform.apply_starter_pack(true)
  local s = platform.surface
  local tiles = {}
  for x=-16,24 do for y=-8,24 do tiles[#tiles+1]={name="space-platform-foundation",position={x,y}} end end
  s.set_tiles(tiles)
  local core=make(s,"bitermotors-orbital-datacenter-core",0.5,10.5,force)
  core.set_recipe("bitermotors-orbital-ai-dataset")
  core.get_inventory(defines.inventory.crafter_input).insert{name="bitermotors-dollar",count=1000}
  local rad=make(s,"bitermotors-orbital-radiator-panel",6.5,10.5,force)
  for x=2.5,4.5 do make(s,"bitermotors-orbital-heat-pipe",x,10.5,force) end
  for x=-6,6,3 do make(s,"bitermotors-high-density-space-solar-panel",x+0.5,17.5,force) end
  player.teleport({0,5},s)
  player.zoom=1.5
  player.opened=nil
  storage.qa={surface=s,core=core,rad=rad}
end
commands.add_command("bm-visual","Isolated readability QA: overview, night, far, core, radiator, progress, capture",function(event)
  local p=game.get_player(event.player_index)
  if not storage.qa then setup(p) end
  local q=storage.qa
  local mode=event.parameter or "overview"
  if mode=="capture" then
    game.take_screenshot{player=p,resolution=p.display_resolution,show_gui=true,path="readability/"..game.tick..".png"}
    p.print("Readability screenshot requested")
    return
  end
  p.opened=nil
  p.force=q.core.force
  if mode=="early" then
    local early=game.forces["visual-early"] or game.create_force("visual-early")
    p.force=early
    remote.call("bitermotors","open_progress",p.index)
  elseif mode=="assembly" then
    p.force.technologies["bitermotors-grid-scale-energy"].researched=true
    remote.call("bitermotors","test_set_ai_token_progress",p.force.name,0,1000000000)
    q.core.set_recipe("bitermotors-assemble-agi-model")
    local input=q.core.get_inventory(defines.inventory.crafter_input)
    input.insert{name="bitermotors-agi-training-dataset",count=20000}
    input.insert{name="bitermotors-datacenter-rack",count=1}
  elseif mode=="no-recipe" then q.core.set_recipe(nil) end
  q.surface.daytime=mode=="night" and 0.5 or 0
  q.surface.freeze_daytime=true
  p.zoom=mode=="far" and 0.65 or 1.5
  if mode=="core" or mode=="assembly" or mode=="no-recipe" then p.opened=q.core
  elseif mode=="radiator" then p.opened=q.rad
  elseif mode=="progress" then remote.call("bitermotors","open_progress",p.index) end
  helpers.write_file("readability-scenes.jsonl",helpers.table_to_json{mode=mode,tick=game.tick,
    resolution=p.display_resolution,scale=p.display_scale,zoom=p.zoom,core=q.core.name,
    scope="supplied isolated visual fixture; not natural campaign"}.."\n",true)
end)
