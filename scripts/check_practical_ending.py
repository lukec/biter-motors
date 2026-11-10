#!/usr/bin/env python3
"""Fail-closed evidence checker and configuration for the native finite route."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bitermotors_economy_catalog import source_fingerprint

P = "bitermotors-"
DATASET, RACK, MODEL, DOLLAR = (P + n for n in ("agi-training-dataset", "datacenter-rack", "agi-model", "dollar"))
DEFAULTS = {
    "cores": 12, "labs": 9, "lab_speed_modifier": 2.5, "bulk_inserter_capacity_bonus": 9,
    "ramp": [1, 4, 8, 12], "robots": 100, "rocket_budget": 160,
    "cash_buffers": [200, 500, 1000, 1000], "lab_supply_reserve": 40,
    "max_ticks": 4_000_000, "speed": 100,
    "tiers": [
        {"recipe": P + "orbital-ai-dataset"},
        {"recipe": P + "orbital-ai-dataset-cluster", "technology": P + "orbital-cluster-training"},
        {"recipe": P + "orbital-ai-dataset-grid-scale", "technology": P + "grid-scale-energy"},
        {"recipe": P + "orbital-ai-dataset-hyperscale", "technology": P + "hyperscale-training"},
    ],
}
STATUSES = ["setup", "starter_delivered", "built", "payload_retained", "loading_checkpoint",
            "loading_reload", "assembly_started", "model_returned", "victory_checkpoint", "victory_reload", "complete"]


def require(ok, why):
    if not ok:
        raise ValueError(why)


def integer(value, minimum=0):
    return type(value) is int and value >= minimum


def number(value, minimum=0):
    return type(value) in (int, float) and math.isfinite(value) and value >= minimum


def counts(value, label):
    require(isinstance(value, dict) and all(isinstance(k, str) and integer(v) for k, v in value.items()), label)
    return value


def configuration(overrides=None):
    config = json.loads(json.dumps(DEFAULTS))
    overrides = overrides or {}
    require(isinstance(overrides, dict), "config must be an object")
    require(not set(overrides) - (set(DEFAULTS) | {"operating_dollars", "factory_sample"}), "unknown config keys")
    config.update(overrides)
    require(type(config["cores"]) is int and config["cores"] in (1, 4, 8, 12), "unsupported core count")
    for key, upper in (("labs", 96), ("robots", 350), ("rocket_budget", 1000), ("max_ticks", 20_000_000)):
        require(integer(config[key], 1) and config[key] <= upper, f"invalid {key}")
    require(number(config["speed"], 1) and config["speed"] <= 1000, "invalid speed")
    require(number(config["lab_speed_modifier"]) and config["lab_speed_modifier"] <= 10, "invalid lab speed modifier")
    require(integer(config["bulk_inserter_capacity_bonus"]) and config["bulk_inserter_capacity_bonus"] <= 13, "invalid bulk capacity bonus")
    require(config["ramp"] == [1, 4, 8, 12], "qualification requires the 1/4/8/12 compute ramp")
    require(isinstance(config["cash_buffers"], list) and len(config["cash_buffers"]) == 4
            and all(integer(n, 1) and n <= 2000 for n in config["cash_buffers"]), "invalid hub cash buffers")
    require(integer(config["lab_supply_reserve"]) and config["lab_supply_reserve"] <= 100, "invalid finite lab reserve")
    if "operating_dollars" in config:
        require(integer(config["operating_dollars"], 1), "invalid finite operating budget")
    tiers = config["tiers"]
    require(isinstance(tiers, list) and 3 <= len(tiers) <= 4, "entry, cluster and grid tiers required")
    require(tiers == DEFAULTS["tiers"][:len(tiers)], "tiers must follow native entry/cluster/grid[/hyper] sequence")
    if "factory_sample" in config:
        require(isinstance(config["factory_sample"], dict), "factory_sample must be disclosed metadata")
    return config


def validate_rows(rows, expected_source_sha256=None):
    require(isinstance(rows, list) and all(isinstance(r, dict) for r in rows), "milestones must be objects")
    require([r.get("status") for r in rows] == STATUSES, "missing, duplicate or out-of-order milestones")
    first = rows[0]
    config = configuration({k: v for k, v in first.get("config", {}).items() if k != "source_sha256"})
    sha = first.get("source_sha256")
    require(isinstance(sha, str) and len(sha) == 64 and all(c in "0123456789abcdef" for c in sha), "source hash")
    require(expected_source_sha256 is None or sha == expected_source_sha256, "unexpected source fingerprint")
    previous = -1
    for row in rows:
        require(integer(row.get("tick")) and row["tick"] > previous, "actual simulation time did not advance")
        previous = row["tick"]
        require(row.get("scope") == "native-practical-ending" and bool(row.get("limits")), "scope/limits missing")
        require(row.get("source_sha256") == sha and row.get("config") == first.get("config"), "configuration/source changed")
        require(row.get("paused") is False and row.get("game_finished") is False, "paused/finished benchmark is not elapsed play")
        require(row.get("cores") == config["cores"], "core count mismatch")
        require(type(row.get("bulk_inserter_capacity_bonus")) is int and row["bulk_inserter_capacity_bonus"] == config["bulk_inserter_capacity_bonus"], "bulk capacity mismatch")
        for key in ("produced", "datasets_returned", "compute_dollars", "earned", "rockets", "native_assemblies", "native_activations",
                    "models_assembled", "models_returned", "models_activated", "low_power_samples", "full_output_samples", "burnouts"):
            require(integer(row.get(key)), f"invalid {key}")
        for key in ("initial_stock", "shipped", "delivered", "ground_stock_remaining", "timings"):
            counts(row.get(key), key)
        require(integer(row.get("rocket_parts")) and integer(row.get("parts_per_rocket"), 1)
                and row["parts_per_rocket"] == first["parts_per_rocket"], "native rocket part counters")
        counts(row.get("rocket_consumed"), "native rocket ingredient consumption")
        if "hub" in row:
            counts(row["hub"], "invalid physical hub counts")
        require(row["initial_stock"] == first["initial_stock"], "stock changed after bootstrap")
        for name, n in row["shipped"].items():
            require(n <= first["initial_stock"].get(name, 0), "cargo exceeds supplied stock")
        require(row["earned"] == row["produced"] * 50_000, "native earned compute conservation")
        budget = config.get("operating_dollars", 8000 if len(config["tiers"]) == 4 else 12000)
        require(row["compute_dollars"] <= budget and row["shipped"].get(DOLLAR, 0) <= budget, "finite orbital cash cap exceeded")
        require(row["low_power_samples"] == row["full_output_samples"] == row["burnouts"] == 0, "power, output or burnout bottleneck")
        require(number(row.get("max_temperature")) and row["max_temperature"] < 105, "thermal warning boundary exceeded")
        if row["status"] not in ("setup", "starter_delivered"):
            require(row.get("orbital_eei") == 0 and type(row.get("orbital_eei")) is int and number(row.get("solar_multiplier")) and row["solar_multiplier"] == 1,
                    "supplied orbital power")
            require(type(row.get("ghosts")) is int and row["ghosts"] == 0, "unfinished construction at a final milestone")
    by = {r["status"]: r for r in rows}
    require(first["earned"] == first["produced"] == first["native_assemblies"] == first["native_activations"] == 0, "injected opening progress")
    require(DATASET not in first["initial_stock"] and MODEL not in first["initial_stock"] and P + "ai-token" not in first["initial_stock"], "injected payload/research Tokens")
    require(first["initial_stock"].get(RACK) == 1 and first["initial_stock"].get("space-platform-starter-pack") == 1, "opening physical hardware")
    manifest = counts(first.get("manifest"), "missing hardware manifest")
    starter = counts(first.get("starter_prototype_items"), "missing native starter prototype stock")
    require(starter == {"space-platform-foundation": 10} and integer(first.get("starter_prototype_tiles"))
            and first["starter_prototype_tiles"] == 100, "native starter prototype contract")
    deployed = by["starter_delivered"]
    require(counts(deployed.get("starter_hub_items"), "missing fresh native starter hub observation") == starter
            and integer(deployed.get("starter_surface_tiles")) and deployed["starter_surface_tiles"] == 100,
            "actual freshly deployed starter must match runtime prototype")
    for name, multiple in (("orbital-datacenter-core", 1), ("orbital-radiator-panel", 1),
                           ("orbital-heat-pipe", 2), ("high-density-space-solar-panel", 5)):
        require(manifest.get(P + name) == config["cores"] * multiple, "incomplete native orbital layout")
    payload = by["payload_retained"]
    require(integer(payload.get("retained_datasets"), 20_000) and payload.get("hub", {}).get(DATASET) == payload["retained_datasets"], "20k physical Datasets must be retained in hub")
    require(payload["earned"] >= 1_000_000_000 and payload["delivered"].get(RACK) == 1 and payload.get("hub", {}).get(RACK) == 1, "earned gate and rocket Rack")
    require(integer(payload.get("orbital_datasets")) and payload["orbital_datasets"] == payload["retained_datasets"] == payload["produced"] - payload["datasets_returned"], "physical preassembly Dataset conservation")
    checkpoint, reload = by["loading_checkpoint"], by["loading_reload"]
    require(integer(checkpoint.get("input_datasets"), 1) and checkpoint["input_datasets"] < 20_000, "genuine partially loaded batch")
    require(checkpoint.get("assembly_progress") == 0 and checkpoint["native_assemblies"] == 0, "loading checkpoint must precede committed craft")
    require(reload.get("saved_tick") == checkpoint["tick"] and reload["tick"] > reload["saved_tick"], "separate loading reload time")
    require(integer(reload.get("input_datasets"), 1) and reload["input_datasets"] == checkpoint["input_datasets"], "partial input changed across reload")
    require(all(r.get("assembler_unit") == payload.get("assembler_unit") for r in rows[3:]), "assembly must reuse the same existing core")
    require(all(r.get("terminal_unit") == first.get("terminal_unit") for r in rows), "activation must reuse existing DC")
    assembly = by["assembly_started"]
    require(assembly.get("committed_datasets") == 20_000 and number(assembly.get("assembly_progress")) and 0 < assembly["assembly_progress"] < 1,
            "native full physical batch did not start")
    final = rows[-1]
    built = counts(final.get("built"), "missing native construction counts")
    for name, n in manifest.items():
        if name == "space-platform-foundation":
            continue
        require(final["delivered"].get(name, 0) == n, "hardware not delivered by rocket")
        if name != "space-platform-foundation":
            require(built.get(name, 0) == n, "hardware not natively constructed")
    require(integer(final.get("foundation_required_tiles")) and final["foundation_required_tiles"] == manifest["space-platform-foundation"],
            "nonunique/overlapping foundation plan")
    require(integer(final.get("foundation_surface_tiles")) and final["foundation_surface_tiles"] ==
            deployed["starter_surface_tiles"] + final["foundation_required_tiles"], "required native floor coverage")
    require(final["delivered"].get("space-platform-foundation", 0) + starter["space-platform-foundation"] -
            final.get("hub", {}).get("space-platform-foundation", 0) == final["foundation_required_tiles"],
            "rocket plus verified native starter foundation conservation")
    require(final["native_assemblies"] == final["native_activations"] == final["models_assembled"] == final["models_returned"] == final["models_activated"] == 1, "one real ending required")
    require(final.get("completed") is True and isinstance(final.get("victory"), dict) and final["victory"], "no persistent native victory")
    require(integer(final.get("activation_output")) and final["activation_output"] == 1, "native physical Model activation output missing")
    require(integer(final.get("orbital_datasets")) and final["orbital_datasets"] == final["produced"] - final["datasets_returned"] - 20_000, "physical assembly consumption conservation")
    won, won_reload = by["victory_checkpoint"], by["victory_reload"]
    require(won_reload.get("saved_tick") == won["tick"] < won_reload["tick"], "victory reload time")
    require(final.get("victory") == won.get("victory") == won_reload.get("victory"), "victory changed on reload")
    require(integer(final.get("freeplay_ticks"), 2400) and final["tick"] - won_reload["tick"] >= final["freeplay_ticks"], "paused bench cannot prove freeplay")
    require(final["tick"] - first["tick"] <= config["max_ticks"], "simulation budget exceeded")
    require(integer(final.get("datasets_returned"), 1) and final.get("unpacked") == final["datasets_returned"], "native returned Dataset unpacking")
    # Shipment ledgers, not aggregate assertions, establish native physical route.
    shipped, delivered, returned = {}, {}, {}
    require(isinstance(final.get("shipments"), list) and final["shipments"], "no rocket manifest")
    require(isinstance(final.get("returns"), list) and final["returns"], "no cargo pod return")
    pods = set()
    catalog = first.get("item_catalog")
    require(isinstance(catalog, dict) and catalog, "missing runtime item weights/stacks")
    for outbound, ledger in ((True, final["shipments"]), (False, final["returns"])):
        for shipment in ledger:
            require(isinstance(shipment, dict), "bad shipment")
            cargo = counts(shipment.get("cargo"), "bad cargo counts")
            require(cargo and all(integer(n, 1) for n in cargo.values()), "empty/invalid cargo")
            require(integer(shipment.get("pod"), 1) and shipment["pod"] not in pods, "duplicate native pod")
            pods.add(shipment["pod"])
            require(shipment.get("origin") == ("ground-rocket" if outbound else "orbital-hub") and shipment.get("destination") == ("orbital-hub" if outbound else "ground-pad"), "wrong cargo route")
            require(all(integer(shipment.get(k), 1) for k in ("tick", "descended_tick", "delivered_tick", "mass", "slots", "capacity")), "shipment measures")
            require(first["tick"] < shipment["tick"] <= shipment["descended_tick"] <= shipment["delivered_tick"] <= final["tick"], "cargo timing/order")
            require(shipment["slots"] <= shipment["capacity"] and (not outbound or shipment["mass"] <= 1_000_000), "cargo capacity")
            mass, slots = 0, 0
            for name, n in cargo.items():
                item = catalog.get(name, {})
                require(integer(item.get("weight"), 1) and integer(item.get("stack_size"), 1), "invalid runtime cargo prototype")
                mass += item["weight"] * n
                slots += math.ceil(n / item["stack_size"])
            require(shipment["mass"] == mass and shipment["slots"] == slots, "forged cargo mass/slots")
            target = shipped if outbound else returned
            for name, n in cargo.items():
                target[name] = target.get(name, 0) + n
                if outbound:
                    delivered[name] = delivered.get(name, 0) + n
    require(shipped == final["shipped"] and delivered == final["delivered"], "rocket ledger conservation")
    require(len(final["shipments"]) == final["rockets"] <= config["rocket_budget"], "finite real rocket budget")
    require(final["rocket_parts"] >= final["rockets"] * first["parts_per_rocket"], "launches exceed manufactured rocket parts")
    require(set(final["rocket_consumed"]) == {"processing-unit", "low-density-structure", "rocket-fuel"}
            and all(final["rocket_parts"] <= n <= final["rocket_parts"] + 1
                    for n in final["rocket_consumed"].values()), "rocket material consumption does not match native part production")
    require(returned == {DATASET: final["datasets_returned"], MODEL: 1}, "return cargo conservation")
    research = final.get("research")
    require(isinstance(research, list) and [r.get("name") for r in research] == [t["technology"] for t in config["tiers"] if "technology" in t], "all scale tiers require native research")
    for r in research:
        require(r.get("by_script") is False and integer(r.get("started_tick"), 1) and integer(r.get("tick"), 1)
                and first["tick"] < r["started_tick"] < r["tick"] <= payload["tick"], "scripted or impossible research")
        tech = first.get("research_catalog", {}).get(r["name"], {})
        require(integer(tech.get("cycles"), 1) and number(tech.get("seconds"), 1), "missing runtime research catalog")
        minimum_ticks = tech["cycles"] * tech["seconds"] * 60 / (config["labs"] * (1 + config["lab_speed_modifier"]))
        require(r["tick"] - r["started_tick"] >= minimum_ticks - 1, "research faster than native lab cap")
    expected_research_cash = sum(first["research_catalog"][r["name"]]["cycles"] *
                                 first["research_catalog"][r["name"]]["ingredients"].get(DOLLAR, 0) for r in research)
    require(first["initial_stock"].get(DOLLAR) == budget + expected_research_cash
            + config["labs"] * config["lab_supply_reserve"], "opening cash exceeds the declared finite project and lab reserve")
    # Parallel labs can commit a final partial pack each when a technology ends.
    research_commit_bound = config["labs"] * sum(first["research_catalog"][r["name"]]["ingredients"].get(DOLLAR, 0)
                                                for r in research)
    require(integer(final.get("research_dollars_consumed")) and expected_research_cash <=
            final["research_dollars_consumed"] <= expected_research_cash + research_commit_bound,
            "native research cash outside nominal bill plus bounded lab commitments")
    require(integer(final.get("compute_dollars_native")) and final["compute_dollars"] <= final["compute_dollars_native"] <= budget,
            "native operating cash consumption")
    require(integer(final.get("recipe_change_discarded_dollars")) and
            final["compute_dollars_native"] + final["recipe_change_discarded_dollars"] <= budget,
            "recipe selection cash losses exceed finite budget")
    ramp = final.get("ramp_history")
    expected_ramp = sorted(set(min(config["cores"], n) for n in config["ramp"]))
    require(isinstance(ramp, list) and [r.get("cores") for r in ramp] == expected_ramp, "not a native 1/4/8/12 compute ramp")
    milestones = [0, 1_000_000, 10_000_000, 100_000_000]
    research_by_name = {r["name"]: r for r in research}
    for index, r in enumerate(ramp):
        require(integer(r.get("tick"), 1) and integer(r.get("earned")) and integer(r.get("tier"), 1), "invalid ramp evidence")
        require(r["earned"] >= milestones[index], "premature compute expansion")
        if index and index < len(config["tiers"]):
            require(r["tick"] >= research_by_name[config["tiers"][index]["technology"]]["tick"], "compute expanded before research")
    require(integer(final["timings"].get("loading"), 1) and final["timings"].get("assembly", 0) > 0 and final["timings"].get("activation", 0) > 0, "missing phase measurements")
    return rows


def read_report(path):
    text = Path(path).read_text()
    require(text.endswith("\n"), "unterminated report")
    return [json.loads(line) for line in text.splitlines() if line.strip()]


def evidence_summary(rows, report, archive=None):
    """Keep qualified counters/provenance, not raw runtime inventories or logs."""
    first, last = rows[0], rows[-1]
    root = Path(__file__).resolve().parents[1]
    files = {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in (
        "scripts/fixtures/practical-ending-control.lua", "scripts/fixtures/orbital-layout.lua",
        "scripts/validate-bitermotors-practical-ending.sh", "scripts/check_practical_ending.py")}
    result = {"schema": 1, "scope": "qualified finite-ground-stock native physical ending",
              "source_sha256": first["source_sha256"], "config": first["config"],
              "report_sha256": hashlib.sha256(Path(report).read_bytes()).hexdigest(),
              "harness_sha256": files, "limits": last["limits"],
              "total_minutes_including_freeplay": (last["tick"] - first["tick"]) / 3600,
              "phase_minutes": {k: v / 3600 for k, v in last["timings"].items()},
              "milestones": [{k: row[k] for k in ("status", "tick", "input_datasets", "earned")}
                             for row in rows],
              "research": last["research"], "ramp": last["ramp_history"],
              "manifest": first["manifest"], "rockets": last["rockets"],
              "native_rocket_parts": last["rocket_parts"], "rocket_ingredients_consumed": last["rocket_consumed"],
              "compute_dollars_native": last["compute_dollars_native"],
              "recipe_change_discarded_dollars": last["recipe_change_discarded_dollars"],
              "operating_dollars_used": last["compute_dollars_native"] + last["recipe_change_discarded_dollars"],
              "research_dollars_consumed": last["research_dollars_consumed"],
              "max_temperature_c": last["max_temperature"], "burnouts": last["burnouts"],
              "low_power_samples": last["low_power_samples"], "full_output_samples": last["full_output_samples"],
              "native_assemblies": last["native_assemblies"], "native_activations": last["native_activations"],
              "models_returned": last["models_returned"], "victory": last["victory"],
              "starter_prototype_items": first["starter_prototype_items"],
              "starter_prototype_tiles": first["starter_prototype_tiles"],
              "foundation_required_tiles": last["foundation_required_tiles"],
              "freeplay_ticks": last["freeplay_ticks"]}
    if archive:
        result["archive_sha256"] = hashlib.sha256(Path(archive).read_bytes()).hexdigest()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", nargs="?")
    parser.add_argument("--prepare", metavar="HELPER")
    parser.add_argument("--config")
    parser.add_argument("--source", type=Path)
    parser.add_argument("--expected-source-sha256")
    parser.add_argument("--summary-json", type=Path)
    parser.add_argument("--archive", type=Path)
    args = parser.parse_args()
    try:
        if args.prepare:
            config = configuration(json.loads(Path(args.config).read_text()) if args.config else None)
            config["source_sha256"] = source_fingerprint(args.source)
            dest = Path(args.prepare)
            data = json.dumps(config, sort_keys=True)
            require("]=]" not in data, "unsafe configuration delimiter")
            (dest / "practical-config.lua").write_text("return helpers.json_to_table([=[" + data + "]=])\n")
            (dest / "practical-config.json").write_text(data + "\n")
            return
        rows = validate_rows(read_report(args.report), args.expected_source_sha256)
        if args.summary_json:
            args.summary_json.write_text(json.dumps(evidence_summary(rows, args.report, args.archive), indent=2) + "\n")
        final = rows[-1]
        print(json.dumps({"qualified": "finite-ground-stock native physical ending", "tick": final["tick"],
                          "phase_minutes": {k: round(v / 3600, 2) for k, v in final["timings"].items()},
                          "compute_dollars": final["compute_dollars"], "rockets": final["rockets"],
                          "compute_dollars_native": final.get("compute_dollars_native"),
                          "recipe_change_discarded_dollars": final.get("recipe_change_discarded_dollars"),
                          "operating_dollars_used": final["compute_dollars_native"] + final["recipe_change_discarded_dollars"],
                          "research_dollars_consumed": final.get("research_dollars_consumed"),
                          "rocket_parts": final.get("rocket_parts"), "rocket_consumed": final.get("rocket_consumed"),
                          "source_sha256": final["source_sha256"],
                          "limits": final["limits"]}, indent=2))
    except (OSError, ValueError, TypeError, KeyError, AttributeError) as error:
        raise SystemExit(f"Practical ending validation failed: {error}") from error


if __name__ == "__main__":
    main()
