#!/usr/bin/env python3
"""Cost a proposed orbital ending without rewriting the native gameplay catalog."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
from collections import Counter, deque
from dataclasses import asdict, dataclass
from pathlib import Path

from bitermotors_economy_catalog import CATALOG, DATASET, DOLLAR, TOKEN, EconomyCatalog, amount, energy
from simulate_bitermotors_economy import CORE, ORBITAL_RECIPES, TERRESTRIAL, campaign_plan

P = "bitermotors-"
SOLAR = P + "high-density-space-solar-panel"
RADIATOR = P + "orbital-radiator-panel"
MODEL = P + "agi-model"
RESEARCH = (P + "autonomous-logistics", P + "orbital-compute",
            P + "orbital-cluster-training", P + "grid-scale-energy", P + "hyperscale-training")
SCIENCE = ("automation-science-pack", "logistic-science-pack", "chemical-science-pack",
           "production-science-pack", "utility-science-pack")
FRONTIER = frozenset((DOLLAR, "iron-plate", "copper-plate", "steel-plate", "stone-brick",
    "stone", "coal", "calcite", "processing-unit", "rocket-fuel", "electric-engine-unit",
    "water", "sulfuric-acid", "petroleum-gas", "lubricant", "space-science-pack",
    P + "nickel-ore", P + "lithium-brine"))
CLEAN_ROUTES = {
    P + "nickel-sulfate": P + "clean-nickel-refining",
    P + "lithium-carbonate": P + "clean-lithium-extraction",
    P + "phosphate": P + "clean-phosphate-extraction",
    P + "high-nickel-cell": P + "dry-high-nickel-cell",
    P + "lfp-cell": P + "dry-lfp-cell",
}


@dataclass(frozen=True)
class Proposal:
    """Explicit, hypothetical overrides. None are applied to mod Lua."""
    name: str = "Recommended orbital ending"
    phase_cores: tuple[int, ...] = (1, 4, 8, 12)
    token_yields: tuple[int, ...] = (10000, 50000, 100000, 200000)
    tier_cycles: tuple[int, ...] = (1000, 1500, 2000)
    tier_dollars_per_cycle: tuple[int, ...] = (2, 2, 3)
    solar_panels_per_core: int = 5
    solar_peak_watts: int = 20000000
    radiators_per_core: int = 1
    tiles_per_core: int = 100
    rack_count: int = 8
    low_density_structures: int = 40
    lfp_packs: int = 12
    core_weight_grams: int = 100000
    solar_weight_grams: int = 25000
    radiator_weight_grams: int = 100000
    dollar_weight_grams: int = 10
    model_weight_grams: int = 1000
    final_training_seconds: int = 60
    commissioning_seconds: int = 30

    def validate(self):
        if len(self.phase_cores) != 4 or len(self.token_yields) != 4:
            raise ValueError("four compute phases required")
        if len(self.tier_cycles) != 3 or len(self.tier_dollars_per_cycle) != 3:
            raise ValueError("three research tiers required")
        if any(value <= 0 for key, values in asdict(self).items() if key != "name"
               for value in (values if isinstance(values, tuple) else (values,))):
            raise ValueError("proposal quantities must be positive")
        if sorted(self.phase_cores) != list(self.phase_cores):
            raise ValueError("core ramp must not decrease")
        if sorted(self.token_yields) != list(self.token_yields):
            raise ValueError("compute yield must not decrease")


@dataclass(frozen=True)
class Business:
    name: str
    settlements: int
    population: int
    remaining_battery_buyers: int
    battery_offices: int
    taxi_depots: int
    allocated_fleet: int
    starting_dollars: int = 2000
    science_sets_per_minute: int = 60
    taxi_sales_gate_met: bool = True
    research_tiers: int = 3


BUSINESSES = (
    Business("Finite sales; skip Hyperscale", 5, 1000, 1000, 1, 0, 0,
             taxi_sales_gate_met=False, research_tiers=2),
    Business("Modest recurring business", 10, 2000, 500, 1, 1, 120),
    Business("Stronger recurring business", 10, 2000, 500, 2, 2, 300),
    Business("No remaining income", 5, 1000, 0, 0, 0, 0, taxi_sales_gate_met=False),
)


def proposed_catalog(catalog: EconomyCatalog, proposal: Proposal) -> EconomyCatalog:
    proposal.validate()
    data = copy.deepcopy(catalog.data)
    data["recipes"][CORE]["ingredients"] = [
        {"type": "item", "name": P + "datacenter-rack", "amount": proposal.rack_count},
        {"type": "item", "name": "low-density-structure", "amount": proposal.low_density_structures},
        {"type": "item", "name": P + "lfp-battery-pack", "amount": proposal.lfp_packs}]
    data["recipes"][SOLAR]["ingredients"] = [
        {"type": "item", "name": P + "high-density-solar-array", "amount": 2},
        {"type": "item", "name": "processing-unit", "amount": 10},
        {"type": "item", "name": "low-density-structure", "amount": 5},
        {"type": "item", "name": P + "high-energy-battery-pack", "amount": 2}]
    for name, weight in ((CORE, proposal.core_weight_grams), (SOLAR, proposal.solar_weight_grams),
                         (RADIATOR, proposal.radiator_weight_grams), (DOLLAR, proposal.dollar_weight_grams),
                         (MODEL, proposal.model_weight_grams)):
        data["launch"]["item_weights_grams"][name] = weight
    return EconomyCatalog(data)


def research_rows(catalog: EconomyCatalog, proposal: Proposal) -> list[dict]:
    rows = []
    for index, name in enumerate(RESEARCH):
        unit = catalog.data["technologies"][name]["unit"]
        cycles = unit["count"] if index < 2 else proposal.tier_cycles[index - 2]
        dollars = amount(unit["ingredients"], DOLLAR) if index < 2 else proposal.tier_dollars_per_cycle[index - 2]
        rows.append({"technology": name, "cycles": cycles, "dollars_per_cycle": dollars,
                     "tokens_per_cycle": amount(unit["ingredients"], TOKEN),
                     "science": {item: amount(unit["ingredients"], item) for item in SCIENCE}})
    return rows


def compute_budget(catalog: EconomyCatalog, proposal: Proposal) -> dict:
    rows = research_rows(catalog, proposal)
    pre_tokens = sum(row["cycles"] * row["tokens_per_cycle"] for row in rows[:2])
    research_tokens = sum(row["cycles"] * row["tokens_per_cycle"] for row in rows[2:])
    terra = P + "terrestrial-ai-token"
    terra_batches = math.ceil(pre_tokens / catalog.output(terra, TOKEN))
    cycle = catalog.seconds(ORBITAL_RECIPES[0], CORE)
    milestones = [row["threshold"] for row in catalog.runtime["orbital_milestones"]]
    target = catalog.ingredient(P + "agi-training-run", DATASET) * catalog.runtime["dataset_tokens"]
    targets = milestones + [max(catalog.runtime["agi_token_gate"], target + research_tokens)]
    generated = 0
    bands = []
    for index, threshold in enumerate(targets):
        batches = math.ceil(max(0, threshold - generated) / proposal.token_yields[index])
        generated += batches * proposal.token_yields[index]
        bands.append({"target": threshold, "yield": proposal.token_yields[index], "batches": batches,
                      "cores": proposal.phase_cores[index], "core_hours": batches * cycle / 3600,
                      "ramped_hours": batches * cycle / (3600 * proposal.phase_cores[index])})
    return {"research_dollars": sum(row["cycles"] * row["dollars_per_cycle"] for row in rows),
            "research_science": {item: sum(row["cycles"] * row["science"][item] for row in rows) for item in SCIENCE},
            "terrestrial_tokens": pre_tokens, "orbital_research_tokens": research_tokens,
            "terrestrial_batches": terra_batches,
            "terrestrial_dollars": terra_batches * catalog.ingredient(terra, DOLLAR),
            "terrestrial_minutes": terra_batches * catalog.seconds(terra, TERRESTRIAL) / 60,
            "physical_archive_target": target, "generated_equivalents": generated,
            "orbital_dollars": sum(row["batches"] for row in bands) * catalog.ingredient(ORBITAL_RECIPES[0], DOLLAR),
            "core_hours": sum(row["core_hours"] for row in bands),
            "normal_cycle_seconds": cycle,
            "ramped_compute_hours": sum(row["ramped_hours"] for row in bands), "bands": bands}


def shipments(catalog: EconomyCatalog, payload: dict[str, int]) -> dict:
    lift = catalog.data["launch"]
    flights, blocked, capacities = 0, [], {}
    for item, count in sorted(payload.items()):
        if count < 0 or int(count) != count:
            raise ValueError("payload counts must be nonnegative integers")
        if not count:
            continue
        weight = lift["item_weights_grams"][item]
        if weight <= 0:
            raise ValueError("item weights must be positive")
        capacity = min(math.floor(lift["capacity_grams"] / weight),
                       lift["inventory_slots"] * catalog.data["items"][item]["stack_size"])
        capacities[item] = capacity
        if not capacity:
            blocked.append(item)
        else:
            flights += math.ceil(count / capacity)
    return {"rockets": None if blocked else flights, "blocked_items": blocked,
            "capacity_per_rocket": capacities}


def hardware_plan(catalog: EconomyCatalog, proposal: Proposal, *, cores: int = 12,
                  platforms: int = 1, operating_dollars: int = 0,
                  include_final_model: bool = False) -> dict:
    if not 1 <= platforms <= cores or int(cores) != cores or int(platforms) != platforms:
        raise ValueError("integer cores >= platforms >= 1 required")
    proposed = proposed_catalog(catalog, proposal)
    totals, launches = Counter(), 0
    per_platform = []
    for index in range(platforms):
        count = cores // platforms + (index < cores % platforms)
        coins = operating_dollars // platforms + (index < operating_dollars % platforms)
        payload = {"space-platform-starter-pack": 1, "space-platform-foundation": count * proposal.tiles_per_core,
                   CORE: count, SOLAR: count * proposal.solar_panels_per_core,
                   RADIATOR: count * proposal.radiators_per_core,
                   "transport-belt": count * 12, "inserter": count * 4, DOLLAR: coins}
        transport = shipments(proposed, payload)
        if transport["blocked_items"]:
            raise ValueError("proposed hardware is not launchable: " + str(transport["blocked_items"]))
        per_platform.append({"cores": count, "payload": payload, **transport})
        launches += transport["rockets"]
        totals.update(payload)
    launch_ingredients = {entry["name"]: launches * catalog.data["launch"]["parts_per_rocket"] * entry["amount"]
                          for entry in catalog.recipe("rocket-part")["ingredients"]}
    roots = Counter(totals)
    del roots[DOLLAR]
    roots.update(launch_ingredients)
    roots.update({"rocket-silo": 1, "cargo-landing-pad": 1})
    if include_final_model:
        roots[P + "datacenter-rack"] += 1
    core_power = energy(catalog.data["entities"][CORE]["energy_usage"])
    power = cores * proposal.solar_panels_per_core * proposal.solar_peak_watts * catalog.data["nauvis_orbit_solar_multiplier"]
    if power < cores * core_power:
        raise ValueError("proposal solar cannot sustain its cores")
    return {"cores": cores, "platforms": platforms, "payload": dict(totals), "per_platform": per_platform,
            "rockets": launches, "launch_ingredients": launch_ingredients, "manufacturing_roots": dict(roots),
            "placed_foundation_tiles": cores * proposal.tiles_per_core + platforms * 100,
            "compute_watts": cores * core_power, "solar_watts": power,
            "assembly_only_silo_minutes": launches * catalog.data["launch"]["parts_per_rocket"] *
                catalog.recipe("rocket-part")["energy_required"] / catalog.data["launch"]["silo_crafting_speed"] / 60}


def staged_uplifts(catalog: EconomyCatalog, proposal: Proposal, budget: dict) -> dict:
    proposed = proposed_catalog(catalog, proposal)
    stages, rockets, previous = [], 0, 0
    for index, cores in enumerate(proposal.phase_cores):
        added = cores - previous
        payload = {CORE: added, SOLAR: added * proposal.solar_panels_per_core,
                   RADIATOR: added * proposal.radiators_per_core,
                   "space-platform-foundation": added * proposal.tiles_per_core,
                   "transport-belt": added * 12, "inserter": added * 4,
                   DOLLAR: budget["bands"][index]["batches"]}
        if not index:
            payload["space-platform-starter-pack"] = 1
        transport = shipments(proposed, payload)
        if transport["blocked_items"]:
            raise ValueError("staged shipment is blocked")
        rockets += transport["rockets"]
        stages.append({"cores": cores, "payload": payload, **transport})
        previous = cores
    return {"rockets": rockets, "stages": stages,
            "extra_launches_above_batched": rockets - hardware_plan(catalog, proposal,
                cores=proposal.phase_cores[-1], operating_dollars=int(budget["orbital_dollars"]))["rockets"]}


def supply_bill(catalog: EconomyCatalog, roots: dict[str, float]) -> dict:
    """Expand selected manufacturing routes jointly, crediting their co-products once."""
    if any(count < 0 or not math.isfinite(count) for count in roots.values()):
        raise ValueError("invalid manufacturing demand")
    recipes = catalog.data["manufacturing_recipes"] | catalog.data["recipes"]
    frontier = FRONTIER | frozenset(catalog.data["mined_items"])
    graph, item_routes = {}, {}

    def visit(item, visiting=frozenset()):
        if item in frontier:
            return None
        route = CLEAN_ROUTES.get(item, catalog.data["baseline_recipe_routes"].get(item, item))
        if route in visiting:
            raise ValueError("cyclic material route: " + route)
        if route not in recipes:
            raise ValueError("missing material route: " + item)
        if amount(recipes[route]["results"], item) <= 0:
            raise ValueError("route does not produce requested item: " + item)
        item_routes[item] = route
        if route not in graph:
            dependencies = set()
            graph[route] = dependencies
            for ingredient in recipes[route]["ingredients"]:
                child = visit(ingredient["name"], visiting | {route})
                if child:
                    dependencies.add(child)
        return route

    for item, count in roots.items():
        if count:
            visit(item)
    incoming = Counter(child for children in graph.values() for child in children)
    queue = deque(sorted(route for route in graph if not incoming[route]))
    demand, batches = Counter(roots), {}
    while queue:
        route = queue.popleft()
        recipe = recipes[route]
        outputs = {entry["name"]: amount(recipe["results"], entry["name"]) for entry in recipe["results"]}
        runs = max((math.ceil(max(0, demand[item]) / outputs[item])
                    for item, item_route in item_routes.items() if item_route == route), default=0)
        batches[route] = runs
        for item, count in outputs.items():
            demand[item] -= runs * count
        for ingredient in recipe["ingredients"]:
            demand[ingredient["name"]] += runs * ingredient["amount"]
        for child in sorted(graph[route]):
            incoming[child] -= 1
            if not incoming[child]:
                queue.append(child)
    if len(batches) != len(graph):
        raise ValueError("cyclic manufacturing graph")
    unresolved = {item: value for item, value in demand.items() if value > 0 and item not in frontier}
    if unresolved:
        raise ValueError("unresolved material demand: " + str(unresolved))
    return {"supplies": {item: count for item, count in sorted(demand.items()) if count > 0},
            "surplus": {item: -count for item, count in sorted(demand.items()) if count < 0},
            "recipe_batches": batches}


def simulate(catalog: EconomyCatalog, proposal: Proposal, business: Business, *, horizon_minutes=1440) -> dict:
    """Minute cash/research/compute flow; instant available hardware is an explicit bound."""
    proposal.validate()
    if horizon_minutes <= 0 or int(horizon_minutes) != horizon_minutes:
        raise ValueError("positive integer horizon required")
    if min(business.settlements, business.population, business.science_sets_per_minute) <= 0:
        raise ValueError("positive settlements, population and science throughput required")
    if min(business.starting_dollars, business.remaining_battery_buyers, business.battery_offices,
           business.taxi_depots, business.allocated_fleet) < 0:
        raise ValueError("negative business input")
    if business.remaining_battery_buyers > business.population:
        raise ValueError("battery buyers exceed population")
    if business.research_tiers not in (0, 1, 2, 3):
        raise ValueError("invalid optional research tier count")
    runtime = catalog.runtime
    if business.allocated_fleet > min(business.taxi_depots * runtime["bitertaxi_max_fleet"],
                                      business.population // runtime["bitertaxi_customers_per_vehicle"]):
        raise ValueError("taxi allocation exceeds unique customers or depot capacity")
    rows, budget = research_rows(catalog, proposal)[:business.research_tiers + 2], compute_budget(catalog, proposal)
    per_settlement = [business.remaining_battery_buyers // business.settlements +
                      (i < business.remaining_battery_buyers % business.settlements) for i in range(business.settlements)]
    eligible = [math.ceil(count * runtime["grid_battery_initial_adoption"]) for count in per_settlement]
    installed = [0] * business.settlements
    battery_rate = business.battery_offices * 60 / catalog.seconds(P + "sell-grid-battery", P + "sales-office")
    wallet, income, spent = float(business.starting_dollars), Counter(), Counter()
    terra_produced = terra_bank = orbital = 0
    recipe_index = -1
    research_index = 0
    research_progress = 0
    events, active_fleet, built_depots = [], 0, 0
    first_output = None
    research_tokens = sum(row["cycles"] * row["tokens_per_cycle"] for row in rows[2:])
    target = max(runtime["agi_token_gate"], budget["physical_archive_target"] + research_tokens)
    thresholds = [row["threshold"] for row in runtime["orbital_milestones"]]
    fleet_capex = (business.allocated_fleet * catalog.item_dollars(P + "bitertaxi-fleet") +
                   business.taxi_depots * catalog.item_dollars(P + "bitertaxi-depot"))
    vehicle_cost = catalog.item_dollars(P + "bitertaxi-fleet")
    depot_cost = catalog.item_dollars(P + "bitertaxi-depot")
    per_vehicle_gross = 60 / runtime["bitertaxi_vehicle_minutes_per_dollar"]
    per_vehicle_wear = vehicle_cost / runtime["bitertaxi_attrition_vehicle_hours"]
    cycle = catalog.seconds(ORBITAL_RECIPES[0], CORE)
    if 60 % cycle or 60 % catalog.seconds(P + "terrestrial-ai-token", TERRESTRIAL):
        raise ValueError("minute model requires whole native cycles; refine the step for changed speeds")
    for minute in range(1, horizon_minutes + 1):
        slots = math.floor(battery_rate * minute) - math.floor(battery_rate * (minute - 1))
        sold = 0
        for i in range(business.settlements):
            count = min(slots, eligible[i] - installed[i])
            installed[i] += count
            sold += count
            slots -= count
        earned = sold * catalog.output(P + "sell-grid-battery", DOLLAR)
        wallet += earned
        income["battery_sales"] += earned
        if minute % runtime["grid_battery_referral_minutes"] == 0:
            for i, count in enumerate(per_settlement):
                if installed[i] > 0:
                    eligible[i] = min(count, eligible[i] + math.ceil((count - eligible[i]) * runtime["grid_battery_referral_fraction"]))
        if active_fleet:
            wallet += active_fleet * (per_vehicle_gross - per_vehicle_wear) / 60
            income["taxi_service"] += active_fleet * per_vehicle_gross / 60
            spent["fleet_wear"] += active_fleet * per_vehicle_wear / 60
        if research_index >= 1 and active_fleet < business.allocated_fleet and business.taxi_sales_gate_met:
            # Finance service incrementally; waiting for a whole fleet can starve its own startup.
            reserve = catalog.ingredient(P + "terrestrial-ai-token", DOLLAR) if terra_produced < budget["terrestrial_tokens"] else 0
            if active_fleet == built_depots * runtime["bitertaxi_max_fleet"] and wallet >= depot_cost + vehicle_cost + reserve:
                wallet -= depot_cost
                spent["fleet_capital"] += depot_cost
                built_depots += 1
            new_fleet = min(10, business.allocated_fleet - active_fleet,
                            built_depots * runtime["bitertaxi_max_fleet"] - active_fleet,
                            max(0, math.floor((wallet - reserve) / vehicle_cost)))
            wallet -= new_fleet * vehicle_cost
            spent["fleet_capital"] += new_fleet * vehicle_cost
            if new_fleet and not active_fleet:
                events.append({"minute": minute, "technology": "fleet-started"})
            active_fleet += new_fleet
        if terra_produced < budget["terrestrial_tokens"]:
            recipe = P + "terrestrial-ai-token"
            cost, output = catalog.ingredient(recipe, DOLLAR), catalog.output(recipe, TOKEN)
            batches = min(int(60 / catalog.seconds(recipe, TERRESTRIAL)), math.floor(wallet / cost),
                          math.ceil((budget["terrestrial_tokens"] - terra_produced) / output))
            wallet -= batches * cost
            spent["terrestrial_compute"] += batches * cost
            terra_produced += batches * output
            terra_bank += batches * output
        if recipe_index >= 0 and orbital < target:
            cost = catalog.ingredient(ORBITAL_RECIPES[recipe_index], DOLLAR)
            batches = min(int(60 / cycle) * proposal.phase_cores[recipe_index], math.floor(wallet / cost),
                          math.ceil((target - orbital) / proposal.token_yields[recipe_index]))
            wallet -= batches * cost
            spent["orbital_compute"] += batches * cost
            orbital += batches * proposal.token_yields[recipe_index]
            if batches and first_output is None:
                first_output = minute
        if research_index < len(rows):
            row = rows[research_index]
            ready = research_index < 2 or orbital >= thresholds[research_index - 2]
            if ready:
                available_tokens = terra_bank if research_index < 2 else orbital - spent["orbital_research_tokens"]
                cycles = min(business.science_sets_per_minute, row["cycles"] - research_progress,
                             math.floor(wallet / row["dollars_per_cycle"]),
                             math.floor(available_tokens / row["tokens_per_cycle"]))
                wallet -= cycles * row["dollars_per_cycle"]
                spent["research"] += cycles * row["dollars_per_cycle"]
                if research_index < 2:
                    terra_bank -= cycles * row["tokens_per_cycle"]
                else:
                    spent["orbital_research_tokens"] += cycles * row["tokens_per_cycle"]
                research_progress += cycles
                if research_progress == row["cycles"]:
                    events.append({"minute": minute, "technology": row["technology"]})
                    if research_index >= 1:
                        recipe_index = research_index - 1
                    research_progress = 0
                    research_index += 1
        if research_index == len(rows) and orbital - spent["orbital_research_tokens"] >= budget["physical_archive_target"]:
            finished = minute + (proposal.final_training_seconds + proposal.commissioning_seconds) / 60
            break
    else:
        finished = None
    spent_cash = sum(value for key, value in spent.items() if key != "orbital_research_tokens")
    return {"business": asdict(business), "status": "complete under model assumptions" if finished else "not finished within horizon",
            "model_hours": finished / 60 if finished else None, "first_orbital_output_minute": first_output,
            "events": events, "wallet": wallet, "income": dict(income), "spent": dict(spent),
            "cash_spent": spent_cash, "batteries_sold": sum(installed), "fleet_active": bool(active_fleet),
            "active_fleet": active_fleet, "built_depots": built_depots,
            "fleet_capex": fleet_capex, "net_taxi_dollars_per_hour": active_fleet * (per_vehicle_gross - per_vehicle_wear),
            "orbital_generated": orbital, "archive_equivalents": orbital - spent["orbital_research_tokens"],
            "cash_conservation_error": business.starting_dollars + sum(income.values()) - spent_cash - wallet}


def model_fingerprint() -> str:
    digest = hashlib.sha256()
    for name in ("model_orbital_ending.py", "bitermotors_economy_catalog.py",
                 "simulate_bitermotors_economy.py"):
        path = Path(__file__).resolve().with_name(name)
        digest.update(name.encode() + b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()


def analysis(catalog: EconomyCatalog, proposal=Proposal()) -> dict:
    budget = compute_budget(catalog, proposal)
    proposed = proposed_catalog(catalog, proposal)
    layouts = [hardware_plan(catalog, proposal, cores=proposal.phase_cores[-1], platforms=count,
                             operating_dollars=int(budget["orbital_dollars"]),
                             include_final_model=True) for count in (1, 2, 3)]
    first = hardware_plan(catalog, proposal, cores=1, operating_dollars=100)
    staged = staged_uplifts(catalog, proposal, budget)
    roots = Counter(layouts[0]["manufacturing_roots"])
    for entry in catalog.recipe("rocket-part")["ingredients"]:
        roots[entry["name"]] += staged["extra_launches_above_batched"] * catalog.data["launch"]["parts_per_rocket"] * entry["amount"]
    supplies = supply_bill(proposed, dict(roots))
    with_science = Counter(roots)
    with_science.update(budget["research_science"])
    total_supplies = supply_bill(proposed, dict(with_science))
    native = campaign_plan(catalog, cores=12)
    native_lift = shipments(catalog, {CORE: 1, DOLLAR: 100})
    return {"schema": 1, "native_source_sha256": catalog.data["source_sha256"], "native_capture": catalog.data["capture"],
            "model_sha256": model_fingerprint(), "proposal": asdict(proposal),
            "budget": budget, "research": research_rows(catalog, proposal),
            "first_cluster": first, "layouts": layouts, "staged_uplifts": staged,
            "hardware_supplies": supplies,
            "hardware_and_science_supplies": total_supplies, "native_lift": native_lift,
            "native_ending": {"weights_grams": catalog.data["launch"]["item_weights_grams"],
                "rocket_limit_grams": catalog.data["launch"]["capacity_grams"],
                "direct_dollars_from_campaign": native["direct_dollars"],
                "research_dollars_after_terrestrial_ai": sum(catalog.research(name) for name in RESEARCH),
                "final_capital_dollars": native["final_capital_dollars"],
                "remaining_direct_dollars": native["direct_dollars"] -
                    (native["research_dollars"] - sum(catalog.research(name) for name in RESEARCH)) -
                    catalog.item_dollars(P + "biterfactory-v2") - catalog.item_dollars(TERRESTRIAL),
                "constant_12_core_compute_hours": native["orbital_parallel_compute_hours"],
                "tandem_arrays": native["tandem_arrays"], "grid_battery_arrays": native["grid_battery_arrays"]},
            "businesses": [simulate(catalog, proposal, business) for business in BUSINESSES]}


def report(result: dict) -> str:
    budget, first, layout = result["budget"], result["first_cluster"], result["layouts"][0]
    fmt = lambda value: f"{value:,.0f}"
    lines = ["# Orbital Ending Cost Study", "", "Date: **2026-10-07**. **Proposed balance, not implemented gameplay.**", "",
        "Native input: `economy-prototypes.json`, Factorio 2.1.20, normal quality, no modules or research productivity.",
        "Overrides are isolated in `scripts/model_orbital_ending.py`; the native capture is not relabeled as proposed data.",
        "This is **not a campaign-time prediction**. All existing terrestrial industry and one datacenter are assumed built.",
        "The minute model assumes hardware, colored science inputs, power and transport are available when needed.",
        "Construction/exploration, damaged grids, ore throughput, waste disposal and cargo delays are unmeasured.", "",
        "## Native Transport Blockers", "",
        f"The captured core weighs **{fmt(result['native_ending']['weights_grams'][CORE])} g** versus a **{fmt(result['native_ending']['rocket_limit_grams'])} g** rocket limit: it cannot be launched whole.",
        f"A native Dollar weighs **{fmt(result['native_ending']['weights_grams'][DOLLAR])} g**: only {result['native_lift']['capacity_per_rocket'][DOLLAR]} fit per rocket. The AGI Model weighs **{fmt(result['native_ending']['weights_grams'][MODEL])} g**.",
        "The old ground-produced Model need not fly, but the proposed orbital Model must have an explicit portable weight.",
        "Earlier native delivery fixtures place their cores directly on platforms. They qualify output return, not hardware uplift.",
        "Manufacturing a core in orbit is a possible workaround, not tested here; it does not cure the currency uplift cost.",
        "Actual silo-to-platform hardware and currency launches are a new mandatory release gate.", "",
        "## Candidate Research And Compute", "", "| Upgrade | Science sets | Dollars |", "| --- | ---: | ---: |"]
    for row in result["research"]:
        lines.append(f"| {row['technology'].removeprefix(P)} | {fmt(row['cycles'])} | {fmt(row['cycles'] * row['dollars_per_cycle'])} |")
    lines += ["", "No white science, planetary-controller research or final capital package is required in the candidate.",
        f"Before orbit: **{fmt(budget['terrestrial_dollars'])} Dollars**, {budget['terrestrial_minutes']:.1f} active minutes of one 8 MW datacenter.",
        "Research and Tokens can stream concurrently; two or more datacenters are optional, not a gate.", "",
        f"| Orbital tier | Tokens / {budget['normal_cycle_seconds']:g}s batch | Target online cores | Compute-only band |", "| --- | ---: | ---: | ---: |"]
    for i, row in enumerate(budget["bands"]):
        lines.append(f"| {i+1} | {fmt(row['yield'])} | {row['cores']} | {row['ramped_hours']:.2f}h |")
    total = budget["research_dollars"] + budget["terrestrial_dollars"] + budget["orbital_dollars"]
    lines += ["", f"Ideal direct AI/research cash: **{fmt(total)} Dollars**, including **{fmt(budget['orbital_dollars'])}** for successful orbital batches.",
        f"Comparable old remaining bill, after Terrestrial AI and initial datacenter/Biterfactory construction: **{fmt(result['native_ending']['remaining_direct_dollars'])} Dollars**.",
        "Both omit the existing factory and optional fleet, but the old bill includes its final controller/grid/capital. Old uplift remains unqualified.",
        "This excludes optional fleet/depot capital, fleet wear, prior terrestrial progression and existing factory costs.",
        "These proposed hardware recipes contain no Dollars; the expanded bill must agree, rather than assume that upstream ingredients are free.",
        f"Compute-only ramp: **{budget['ramped_compute_hours']:.2f}h**. The current yields need **{result['native_ending']['constant_12_core_compute_hours']:.2f}h even with twelve cores online from the start**.",
        "The candidate still consumes one billion physical training equivalents; labs' research Tokens are replaced, not counted twice.", "",
        "## Hardware And Launches", "", "| Metric | First cluster | 12 clusters, one platform |", "| --- | ---: | ---: |",
        f"| Compute units | 1 | {layout['cores']} |", f"| Space solar panels | 5 | {layout['payload'][SOLAR]} |",
        f"| Radiators | 1 | {layout['payload'][RADIATOR]} |",
        f"| Placed foundation tiles, including starter hub area | {first['placed_foundation_tiles']} | {layout['placed_foundation_tiles']} |",
        f"| Additional foundation uplift | {first['payload']['space-platform-foundation']} | {layout['payload']['space-platform-foundation']} |",
        f"| Batched automatic uplifts | {first['rockets']} | {layout['rockets']} |",
        f"| Rocket fuel, LDS, blue circuits for launches, each | {first['launch_ingredients']['rocket-fuel']} | {layout['launch_ingredients']['rocket-fuel']} |",
        f"| Assembly-only lower bound, one unmoduled silo | {first['assembly_only_silo_minutes']:.1f}min | {layout['assembly_only_silo_minutes']:.1f}min |",
        f"| Compute / solar generation | {first['compute_watts']/1e6:g} / {first['solar_watts']/1e6:g} MW | {layout['compute_watts']/1e9:g} / {layout['solar_watts']/1e9:g} GW |", "",
        "Automatic uplift counts sum whole rockets for each item and each platform, respect item weights and inventory slots,",
        "and assume custom minimum requests allow partial loads. They do not assume manually mixed cargo.",
        "They are batched budgets: phased deliveries and ongoing cash top-ups can require extra partial launches.",
        f"A single-platform 1/4/8/12 build ramp takes **{result['staged_uplifts']['rockets']}** separate-item launches versus **{layout['rockets']}** fully batched launches.",
        f"That adds **{result['staged_uplifts']['extra_launches_above_batched'] * 50}** of each launch ingredient; upgrade/research waits can require further currency top-ups.",
        "Silo construction, starter-pack manufacture, belts and inserters are included in the supply bill.",
        "Each starter pack manufactures 60 foundations but creates 100 placed tiles; those are not the same quantity.",
        "The 100-extra-tiles-per-cluster envelope is a layout assumption, not a tested platform blueprint.", "",
        "| Platforms for 12 clusters | Batched uplifts | Placed tiles |", "| --- | ---: | ---: |"]
    for row in result["layouts"]:
        lines.append(f"| {row['platforms']} | {row['rockets']} | {row['placed_foundation_tiles']} |")
    lines += ["", "## Factory Supply Bill", "",
        f"The following bill uses the **{result['staged_uplifts']['rockets']}-launch staged ramp**, not the cheaper fully batched shipment plan.",
        "Recipes are expanded through all intermediate components to a named supply frontier, not raw ore or a free-input assumption.",
        "Use clean/dry battery routes already unlocked by Capital Scaling. Native multi-output recipes run jointly: their co-products are credited once.",
        "No module/intrinsic machine productivity is applied; this is conservative on manufacture, not on missing build time.", "",
        "| Supply | Hardware + launches | Hardware + launches + remaining research |", "| --- | ---: | ---: |"]
    for item in sorted(result["hardware_and_science_supplies"]["supplies"]):
        lines.append(f"| {item.removeprefix(P)} | {fmt(result['hardware_supplies']['supplies'].get(item, 0))} | {fmt(result['hardware_and_science_supplies']['supplies'][item])} |")
    lines += ["", "Science totals assume no existing science stock. Blue circuits, electric engines, fuel, plates and fluids are frontier supplies,",
        "not their raw ore/oil totals. Manufacturing energy and neutralization of acidic tailings must still be provided.",
        f"Hardware-route tailings: **{fmt(result['hardware_supplies']['surplus'].get(P+'acidic-tailings', 0))}** fluid units.", "",
        "## Cash Flow Sensitivities", "",
        "All cases start with 2,000 Dollars and the first datacenter already built, at 60 effective science sets/minute.",
        "Only remaining Grid Battery adopters generate finite sales; no old EV profit or already-sold batteries are earned again.",
        "Taxi cases assume the 5,000-sale gate was earned earlier, but finance their fleet/depot incrementally only after Autonomy research completes.",
        "Taxi income is capped by unique living customers, native fleet limits and conservative initial wear. No mature fleet is free.",
        "During research/funding waits, existing orbital cores keep working if funded. The cumulative output is banked, not discarded at upgrades.",
        "The finite-market route deliberately skips Hyperscale: efficiency upgrades are optional, not permissions to win.", "",
        "| Case | Remaining battery buyers | Financed taxi vehicles | First orbital output | Model completion |", "| --- | ---: | ---: | ---: | ---: |"]
    for case in result["businesses"]:
        b = case["business"]
        first_time = f"{case['first_orbital_output_minute']}min" if case['first_orbital_output_minute'] else "not reached"
        end_time = f"{case['model_hours']:.2f}h" if case['model_hours'] else "not finished in 24h"
        lines.append(f"| {b['name']} | {b['remaining_battery_buyers']} | {case['active_fleet']} | {first_time} | {end_time} |")
    lines += ["", "These are ideal-input economic/compute clocks, not observed active playtime. A 4-6-hour chapter remains a design target.",
        "Compare it against science manufacture, materials, actual blueprints, native uplifts and player build time before freezing recipes.", "",
        "## Manufacture Sensitivity", "", "| Available incremental blue-circuit output | Hardware bill production floor |", "| --- | ---: |"]
    blue = result["hardware_supplies"]["supplies"].get("processing-unit", 0)
    for rate in (20, 60, 120):
        lines.append(f"| {rate}/min | {blue/rate/60:.2f}h |")
    lines += ["", "Those rates must be spare after other factory demand. The science bill also consumes blue circuits; no double allocation is permitted.",
        "Other commodities can bottleneck first. A factory that makes only 20 spare blue circuits/minute may need a supply upgrade, not more idle waiting.", "",
        "## Reproduce", "", "```bash", "python3 scripts/model_orbital_ending.py --output docs/orbital-ending-cost-study.md",
        "python3 scripts/model_orbital_ending.py --json", "python3 -m unittest tests.test_orbital_ending_model", "```", "",
        f"Native source SHA-256: `{result['native_source_sha256']}`.",
        "The model rejects stale native input and records a separate hash of all three model scripts in JSON. No gameplay values are changed.",
        "Launch rules: [Factorio Wiki](https://wiki.factorio.com/Rocket_silo).",
        "Platform construction/transport: [Factorio Wiki](https://wiki.factorio.com/Space_platform).", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=CATALOG)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    catalog = EconomyCatalog.load(args.catalog)
    if errors := catalog.freshness_errors():
        parser.exit(1, "ERROR: " + "; ".join(errors) + "\n")
    result = analysis(catalog)
    output = json.dumps(result, indent=2) if args.json else report(result)
    if args.output:
        args.output.write_text(output.rstrip() + "\n")
    else:
        print(output)


if __name__ == "__main__":
    main()
