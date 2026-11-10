#!/usr/bin/env python3
"""Bounded qualitative progression audit, not a runtime or throughput simulator."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "bitermotors-"


def bm(name):
    return PREFIX + name


def names(rows):
    return {row["name"] if isinstance(row, dict) else row[0] for row in rows}


def bootstrap(source):
    """Read only the four literal source tables; do not execute or parse general Lua."""
    def table(name):
        match = re.search(r"^" + name + r" = \{(.*?)^\}", source, re.M | re.S)
        if not match:
            raise ValueError("missing bootstrap table: " + name)
        return match[1]
    techs = set(re.findall(r'"([^"]+)"', table("BITERMOTORS_START_TECHNOLOGIES")))
    stock = set()
    for name in ("BITERMOTORS_START_SHIP_ITEMS", "BITERMOTORS_START_DEBRIS_ITEMS",
                 "BITERMOTORS_ENERGY_JUMPSTART_ITEMS"):
        stock.update(re.findall(r'\["([^"]+)"\]\s*=\s*\d+', table(name)))
    return techs, stock


def audit(raw, start_techs=(), start_items=(), runtime=True):
    recipes = {k: v for k, v in raw.get("recipe", {}).items()
               if not k.startswith("bitermotors-smoke")}
    technologies = raw.get("technology", {})
    items, techs, crafted, machines, gates = set(start_items), set(start_techs) & technologies.keys(), set(), set(), set()
    entities = {k: v for group in raw.values() if isinstance(group, dict)
                for k, v in group.items() if isinstance(v, dict) and
                ("crafting_categories" in v or v.get("type") in ("lab", "mining-drill", "offshore-pump"))}
    placements = {v["place_result"]: k for group in raw.values() if isinstance(group, dict)
                  for k, v in group.items() if isinstance(v, dict) and v.get("place_result")}
    nauvis = raw.get("planet", {}).get("nauvis", {})
    resources = nauvis.get("map_gen_settings", {}).get("autoplace_settings", {}).get("entity", {}).get("settings", {})
    props = {k: v.get("default_value", 0) for k, v in raw.get("surface-property", {}).items()}
    props.update(nauvis.get("surface_properties", {}))
    orbit = dict(props, gravity=0, pressure=0)
    def surface_ok(proto):
        return any(all(c.get("min", float("-inf")) <= p.get(c["property"], 0) <= c.get("max", float("inf"))
                       for c in proto.get("surface_conditions", []))
                   for p in ((props, orbit) if "space-platform" in techs else (props,)))
    def categories(recipe):
        return set(recipe.get("categories", [recipe.get("category", "crafting")]))
    def machine_for(name, recipe):
        required = categories(recipe)
        fluid = any(i.get("type") == "fluid" for i in recipe.get("ingredients", []) if isinstance(i, dict))
        for machine in machines:
            proto = entities[machine]
            if not required.intersection(proto.get("crafting_categories", [])):
                continue
            if proto.get("fixed_recipe") not in (None, name):
                continue
            if fluid and not proto.get("fluid_boxes"):
                continue
            return True
        return False
    def recipe_gate(name):
        requirements = {
            bm("prototype-roadster"): "service",
            bm("premium-ev"): "50-roadsters-sold", bm("sell-premium-ev"): "50-roadsters-sold",
            bm("biterfactory-module"): "100-premiums-produced", bm("biterfactory-building"): "100-premiums-produced",
            bm("mass-market-ev"): "250-premiums-sold", bm("sell-mass-market-ev"): "250-premiums-sold",
            bm("assemble-agi-model"): "billion-earned", bm("activate-agi-model"): "model-returned",
        }
        return requirements.get(name) in gates if name in requirements else True
    tech_gates = {bm("advanced-battery-chemistry"): "250-premiums-produced",
                  bm("orbital-cluster-training"): "million-earned",
                  bm("grid-scale-energy"): "10-million-earned",
                  bm("hyperscale-training"): "100-million-earned"}
    trace = []
    bound = len(recipes) + len(technologies) + len(entities) + 100
    for iteration in range(bound):
        before = (len(items), len(techs), len(crafted), len(machines), len(gates))
        for name, proto in entities.items():
            if (name == "character" or placements.get(name) in items) and surface_ok(proto):
                machines.add(name)
        for name in resources:
            resource = raw.get("resource", {}).get(name)
            if not resource:
                continue
            mine = resource.get("minable", {})
            category = resource.get("category", "basic-solid")
            if not any(category in entities[m].get("resource_categories", []) for m in machines):
                continue
            if mine.get("required_fluid") and mine["required_fluid"] not in items:
                continue
            items.update(names(mine.get("results", [])))
            if mine.get("result"):
                items.add(mine["result"])
        if "offshore-pump" in machines:
            items.add("water")
        if runtime:
            def gate(label, condition):
                if condition:
                    gates.add(label)
            gate("service", bm("sales-office") in machines and bm("ev-charging-station") in items)
            if "service" in gates:
                items.add(bm("ev-reservation"))
            gate("50-roadsters-sold", bm("sell-prototype-roadster") in crafted)
            gate("100-premiums-produced", bm("premium-ev") in crafted)
            gate("250-premiums-produced", bm("premium-ev") in crafted)
            gate("250-premiums-sold", bm("sell-premium-ev") in crafted)
            for label, recipe in (("million-earned", "orbital-ai-dataset"),
                                  ("10-million-earned", "orbital-ai-dataset-cluster"),
                                  ("100-million-earned", "orbital-ai-dataset-grid-scale"),
                                  ("billion-earned", "orbital-ai-dataset-grid-scale")):
                gate(label, bm(recipe) in crafted)
            gate("model-returned", bm("assemble-agi-model") in crafted and "cargo-landing-pad" in items)
        for name, tech in technologies.items():
            if name in techs or not set(tech.get("prerequisites", [])) <= techs:
                continue
            if name in tech_gates:
                if tech_gates[name] not in gates:
                    continue
            elif tech.get("enabled", True) is False:
                continue
            trigger = tech.get("research_trigger")
            if trigger:
                kind = trigger["type"]
                ready = ((kind == "craft-item" and trigger["item"] in items) or
                         (kind == "build-entity" and placements.get(trigger["entity"]) in items) or
                         (kind == "mine-entity" and any(e in resources for e in trigger.get("entities", []))) or
                         (kind == "create-space-platform" and {"rocket-silo", "space-platform-starter-pack", "rocket-part"} <= items))
                if not ready:
                    continue
            else:
                science = names(tech.get("unit", {}).get("ingredients", []))
                if not science <= items or not any(entities[m].get("type") == "lab" and science <= set(entities[m].get("inputs", [])) for m in machines):
                    continue
            techs.add(name)
        unlocked = {e["recipe"] for t in techs for e in technologies[t].get("effects", []) if e["type"] == "unlock-recipe"}
        if runtime:
            if "service" in gates:
                unlocked.add(bm("prototype-roadster"))
            if "100-premiums-produced" in gates and bm("premium-ev-program") in techs:
                unlocked.update((bm("biterfactory-module"), bm("biterfactory-building")))
            if "billion-earned" in gates and bm("grid-scale-energy") in techs:
                unlocked.update((bm("assemble-agi-model"), bm("activate-agi-model")))
        for name, recipe in recipes.items():
            if name in crafted or not (recipe.get("enabled", True) or name in unlocked):
                continue
            if runtime and not recipe_gate(name):
                continue
            if names(recipe.get("ingredients", [])) <= items and surface_ok(recipe) and machine_for(name, recipe):
                crafted.add(name)
                items.update(names(recipe.get("results", [])))
                if recipe.get("result"):
                    items.add(recipe["result"])
        after = (len(items), len(techs), len(crafted), len(machines), len(gates))
        trace.append(after)
        if after == before:
            break
    else:
        raise RuntimeError("fixed-point bound exceeded")
    required_recipes = {bm(n) for n in ("sell-prototype-roadster", "premium-ev", "premium-ev-cell-scale", "biterfactory-building", "mass-market-ev", "terrestrial-ai-token", "orbital-ai-dataset", "orbital-ai-dataset-cluster", "orbital-ai-dataset-grid-scale", "orbital-radiator-panel", "orbital-heat-pipe", "high-density-space-solar-panel", "assemble-agi-model", "activate-agi-model")}
    required_techs = {bm("grid-scale-energy"), bm("autonomous-logistics"), "space-platform"}
    pending = list(required_techs)
    while pending:
        for parent in technologies.get(pending.pop(), {}).get("prerequisites", []):
            if parent not in required_techs:
                required_techs.add(parent)
                pending.append(parent)
    missing = sorted((required_recipes - crafted) | (required_techs - techs))
    blocked = {name: {"inputs": sorted(names(recipes[name].get("ingredients", [])) - items),
                      "machine_available": machine_for(name, recipes[name])} for name in required_recipes - crafted if name in recipes}
    return {"ok": not missing, "missing": missing, "blocked_recipes": blocked,
            "iterations": len(trace), "reachable_items": sorted(items), "reachable_recipes": sorted(crafted),
            "reachable_technologies": sorted(techs), "reachable_machines": sorted(machines), "manual_runtime_gates": sorted(gates)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path)
    args = parser.parse_args()
    source = (ROOT / "mod/bitermotors_0.1.1/control.lua").read_text()
    techs, items = bootstrap(source)
    data = args.dump.read_bytes()
    result = audit(json.loads(data), techs, items)
    result["dump_sha256"] = hashlib.sha256(data).hexdigest()
    result["control_sha256"] = hashlib.sha256(source.encode()).hexdigest()
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
