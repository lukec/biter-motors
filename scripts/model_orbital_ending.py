#!/usr/bin/env python3
"""Cost the native orbital Model ending with explicit economic and pacing limits."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import Counter, deque
from dataclasses import asdict, dataclass
from pathlib import Path

from bitermotors_economy_catalog import CATALOG, DATASET, DOLLAR, TOKEN, EconomyCatalog, amount, energy, ASSEMBLE
from simulate_bitermotors_economy import CORE, ORBITAL_RECIPES, TERRESTRIAL, campaign_plan

P = "bitermotors-"
SOLAR = P + "high-density-space-solar-panel"
RADIATOR = P + "orbital-radiator-panel"
HEAT_PIPE = P + "orbital-heat-pipe"
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
class ModelPlan:
    """Layout assumptions only; recipes, research, masses and timing are native."""
    name: str = "Native orbital Model ending"
    phase_cores: tuple[int, ...] = (1, 4, 8, 12)
    solar_panels_per_core: int = 5
    tiles_per_core: int = 100
    heat_pipes_per_core: int = 2

    def validate(self):
        if len(self.phase_cores) != 4 or any(value <= 0 or int(value) != value for value in self.phase_cores):
            raise ValueError("four positive integer compute phases required")
        if sorted(self.phase_cores) != list(self.phase_cores):
            raise ValueError("core ramp must not decrease")
        if any(isinstance(value, bool) or value <= 0 or int(value) != value
               for value in (self.solar_panels_per_core, self.tiles_per_core, self.heat_pipes_per_core)):
            raise ValueError("layout quantities must be positive integers")


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


def research_rows(catalog: EconomyCatalog, plan: ModelPlan) -> list[dict]:
    rows = []
    for name in RESEARCH:
        unit = catalog.data["technologies"][name]["unit"]
        cycles = unit["count"]
        dollars = amount(unit["ingredients"], DOLLAR)
        rows.append({"technology": name, "cycles": cycles, "dollars_per_cycle": dollars,
                     "tokens_per_cycle": amount(unit["ingredients"], TOKEN),
                     "science": {item: amount(unit["ingredients"], item) for item in SCIENCE}})
    return rows


def compute_budget(catalog: EconomyCatalog, plan: ModelPlan) -> dict:
    plan.validate()
    ending = catalog.model_ending()
    rows = research_rows(catalog, plan)
    pre_tokens = sum(row["cycles"] * row["tokens_per_cycle"] for row in rows[:2])
    research_tokens = sum(row["cycles"] * row["tokens_per_cycle"] for row in rows[2:])
    terra = P + "terrestrial-ai-token"
    terra_batches = math.ceil(pre_tokens / catalog.output(terra, TOKEN))
    milestones = [row["threshold"] for row in catalog.runtime["orbital_milestones"]]
    target = catalog.ingredient(ASSEMBLE, DATASET) * catalog.runtime["dataset_tokens"]
    targets = milestones + [max(catalog.runtime["agi_token_gate"], target + research_tokens)]
    yields = [catalog.output(recipe, TOKEN) + catalog.output(recipe, DATASET) * catalog.runtime["dataset_tokens"] for recipe in ORBITAL_RECIPES]
    generated = 0
    bands = []
    for index, threshold in enumerate(targets):
        cycle = catalog.seconds(ORBITAL_RECIPES[index], CORE)
        batches = math.ceil(max(0, threshold - generated) / yields[index])
        generated += batches * yields[index]
        bands.append({"target": threshold, "yield": yields[index], "batches": batches,
                      "cores": plan.phase_cores[index], "core_hours": batches * cycle / 3600,
                      "ramped_hours": batches * cycle / (3600 * plan.phase_cores[index])})
    return {"research_dollars": sum(row["cycles"] * row["dollars_per_cycle"] for row in rows),
            "research_science": {item: sum(row["cycles"] * row["science"][item] for row in rows) for item in SCIENCE},
            "terrestrial_tokens": pre_tokens, "orbital_research_tokens": research_tokens,
            "terrestrial_batches": terra_batches,
            "terrestrial_dollars": terra_batches * catalog.ingredient(terra, DOLLAR),
            "terrestrial_minutes": terra_batches * catalog.seconds(terra, TERRESTRIAL) / 60,
            "model_ending": ending, "physical_archive_target": target, "generated_equivalents": generated,
            "orbital_dollars": sum(row["batches"] * catalog.ingredient(recipe, DOLLAR) for row, recipe in zip(bands, ORBITAL_RECIPES)),
            "core_hours": sum(row["core_hours"] for row in bands),
            "normal_cycle_seconds": catalog.seconds(ORBITAL_RECIPES[0], CORE),
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


def hardware_plan(catalog: EconomyCatalog, plan: ModelPlan, *, cores: int = 12,
                  platforms: int = 1, operating_dollars: int = 0,
                  include_final_model: bool = False) -> dict:
    if not 1 <= platforms <= cores or int(cores) != cores or int(platforms) != platforms:
        raise ValueError("integer cores >= platforms >= 1 required")
    plan.validate()
    totals, launches = Counter(), 0
    per_platform = []
    for index in range(platforms):
        count = cores // platforms + (index < cores % platforms)
        coins = operating_dollars // platforms + (index < operating_dollars % platforms)
        payload = {"space-platform-starter-pack": 1, "space-platform-foundation": count * plan.tiles_per_core,
                   CORE: count, SOLAR: count * plan.solar_panels_per_core,
                   RADIATOR: count * catalog.runtime["radiators_per_core"],
                   HEAT_PIPE: count * plan.heat_pipes_per_core,
                   "transport-belt": count * 12, "inserter": count * 4, DOLLAR: coins}
        if include_final_model and index == 0:
            payload[P + "datacenter-rack"] = catalog.ingredient(ASSEMBLE, P + "datacenter-rack")
        transport = shipments(catalog, payload)
        if transport["blocked_items"]:
            raise ValueError("native hardware is not launchable: " + str(transport["blocked_items"]))
        per_platform.append({"cores": count, "payload": payload, **transport})
        launches += transport["rockets"]
        totals.update(payload)
    launch_ingredients = {entry["name"]: launches * catalog.data["launch"]["parts_per_rocket"] * entry["amount"]
                          for entry in catalog.recipe("rocket-part")["ingredients"]}
    roots = Counter(totals)
    del roots[DOLLAR]
    roots.update(launch_ingredients)
    roots.update({"rocket-silo": 1, "cargo-landing-pad": 1})
    core_power = energy(catalog.data["entities"][CORE]["energy_usage"])
    power = cores * plan.solar_panels_per_core * energy(catalog.data["entities"][SOLAR]["production"]) * catalog.data["nauvis_orbit_solar_multiplier"]
    if power < cores * core_power:
        raise ValueError("plan solar cannot sustain its cores")
    return {"cores": cores, "platforms": platforms, "payload": dict(totals), "per_platform": per_platform,
            "rockets": launches, "launch_ingredients": launch_ingredients, "manufacturing_roots": dict(roots),
            "placed_foundation_tiles": cores * plan.tiles_per_core + platforms * 100,
            "compute_watts": cores * core_power, "solar_watts": power,
            "assembly_only_silo_minutes": launches * catalog.data["launch"]["parts_per_rocket"] *
                catalog.recipe("rocket-part")["energy_required"] / catalog.data["launch"]["silo_crafting_speed"] / 60}


def staged_uplifts(catalog: EconomyCatalog, plan: ModelPlan, budget: dict) -> dict:
    plan.validate()
    stages, rockets, previous = [], 0, 0
    for index, cores in enumerate(plan.phase_cores):
        added = cores - previous
        payload = {CORE: added, SOLAR: added * plan.solar_panels_per_core,
                   RADIATOR: added * catalog.runtime["radiators_per_core"],
                   HEAT_PIPE: added * plan.heat_pipes_per_core,
                   "space-platform-foundation": added * plan.tiles_per_core,
                   "transport-belt": added * 12, "inserter": added * 4,
                   DOLLAR: budget["bands"][index]["batches"] * catalog.ingredient(ORBITAL_RECIPES[index], DOLLAR)}
        if not index:
            payload["space-platform-starter-pack"] = 1
        if index == len(plan.phase_cores) - 1:
            payload[P + "datacenter-rack"] = catalog.ingredient(ASSEMBLE, P + "datacenter-rack")
        transport = shipments(catalog, payload)
        if transport["blocked_items"]:
            raise ValueError("staged shipment is blocked")
        rockets += transport["rockets"]
        stages.append({"cores": cores, "payload": payload, **transport})
        previous = cores
    return {"rockets": rockets, "stages": stages,
            "extra_launches_above_batched": rockets - hardware_plan(catalog, plan,
                cores=plan.phase_cores[-1], operating_dollars=int(budget["orbital_dollars"]),
                include_final_model=True)["rockets"]}


def supply_bill(catalog: EconomyCatalog, roots: dict[str, float], *,
                opening_stock: dict[str, float] | None = None) -> dict:
    """Expand selected manufacturing routes jointly, crediting their co-products once."""
    if any(count < 0 or not math.isfinite(count) for count in roots.values()):
        raise ValueError("invalid manufacturing demand")
    stock = Counter(opening_stock or {})
    if any(isinstance(count, bool) or count < 0 or not math.isfinite(count)
           for count in stock.values()):
        raise ValueError("invalid opening stock")
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
    demand, batches, credited = Counter(roots), {}, Counter()
    def credit(item):
        used = min(max(0, demand[item]), stock[item])
        demand[item] -= used
        stock[item] -= used
        credited[item] += used

    while queue:
        route = queue.popleft()
        recipe = recipes[route]
        outputs = {entry["name"]: amount(recipe["results"], entry["name"]) for entry in recipe["results"]}
        for item in outputs:
            credit(item)
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
    for item in frontier:
        credit(item)
    unresolved = {item: value for item, value in demand.items() if value > 0 and item not in frontier}
    if unresolved:
        raise ValueError("unresolved material demand: " + str(unresolved))
    return {"supplies": {item: count for item, count in sorted(demand.items()) if count > 0},
            "surplus": {item: -count for item, count in sorted(demand.items()) if count < 0},
            "recipe_batches": batches,
            **({"stock_credited": {item: count for item, count in sorted(credited.items()) if count}}
               if opening_stock is not None else {})}


def simulate(catalog: EconomyCatalog, plan: ModelPlan, business: Business, *, horizon_minutes=1440) -> dict:
    """Minute cash/research/compute flow; instant available hardware is an explicit bound."""
    plan.validate()
    if horizon_minutes <= 0 or int(horizon_minutes) != horizon_minutes:
        raise ValueError("positive integer horizon required")
    if min(business.settlements, business.population, business.science_sets_per_minute) <= 0:
        raise ValueError("positive settlements, population and science throughput required")
    if min(business.starting_dollars, business.remaining_battery_buyers, business.battery_offices,
           business.taxi_depots, business.allocated_fleet) < 0:
        raise ValueError("negative business input")
    if business.remaining_battery_buyers > business.population:
        raise ValueError("battery buyers exceed population")
    runtime = catalog.runtime
    if business.allocated_fleet > min(business.taxi_depots * runtime["bitertaxi_max_fleet"],
                                      business.population // runtime["bitertaxi_customers_per_vehicle"]):
        raise ValueError("taxi allocation exceeds unique customers or depot capacity")
    if business.research_tiers not in (2, 3):
        raise ValueError("Grid-scale research is required; Hyperscale is optional")
    rows, budget = research_rows(catalog, plan)[:business.research_tiers + 2], compute_budget(catalog, plan)
    yields = [catalog.output(recipe, TOKEN) + catalog.output(recipe, DATASET) * runtime["dataset_tokens"] for recipe in ORBITAL_RECIPES]
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
            cycle = catalog.seconds(ORBITAL_RECIPES[recipe_index], CORE)
            if 60 % cycle:
                raise ValueError("minute model requires whole native cycles; refine the step for changed speeds")
            cost = catalog.ingredient(ORBITAL_RECIPES[recipe_index], DOLLAR)
            batches = min(int(60 / cycle) * plan.phase_cores[recipe_index], math.floor(wallet / cost),
                          math.ceil((target - orbital) / yields[recipe_index]))
            wallet -= batches * cost
            spent["orbital_compute"] += batches * cost
            orbital += batches * yields[recipe_index]
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
        if (research_index == len(rows) and orbital >= runtime["agi_token_gate"]
                and orbital - spent["orbital_research_tokens"] >= budget["physical_archive_target"]):
            finished = minute + (budget["model_ending"]["assembly_seconds"] + budget["model_ending"]["activation_seconds"]) / 60
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


def analysis(catalog: EconomyCatalog, plan=ModelPlan()) -> dict:
    budget = compute_budget(catalog, plan)
    plan.validate()
    layouts = [hardware_plan(catalog, plan, cores=plan.phase_cores[-1], platforms=count,
                             operating_dollars=int(budget["orbital_dollars"]),
                             include_final_model=True) for count in (1, 2, 3)]
    first = hardware_plan(catalog, plan, cores=1, operating_dollars=100)
    staged = staged_uplifts(catalog, plan, budget)
    roots = Counter(layouts[0]["manufacturing_roots"])
    for entry in catalog.recipe("rocket-part")["ingredients"]:
        roots[entry["name"]] += staged["extra_launches_above_batched"] * catalog.data["launch"]["parts_per_rocket"] * entry["amount"]
    supplies = supply_bill(catalog, dict(roots))
    with_science = Counter(roots)
    with_science.update(budget["research_science"])
    total_supplies = supply_bill(catalog, dict(with_science))
    native = campaign_plan(catalog, cores=12)
    native_lift = shipments(catalog, {CORE: 1, DOLLAR: 100})
    return {"schema": 1, "native_source_sha256": catalog.data["source_sha256"], "native_capture": catalog.data["capture"],
            "model_sha256": model_fingerprint(), "plan": asdict(plan),
            "budget": budget, "research": research_rows(catalog, plan),
            "first_cluster": first, "layouts": layouts, "staged_uplifts": staged,
            "hardware_supplies": supplies,
            "hardware_and_science_supplies": total_supplies, "native_lift": native_lift,
            "native_ending": {"weights_grams": catalog.data["launch"]["item_weights_grams"],
                "rocket_limit_grams": catalog.data["launch"]["capacity_grams"],
                "direct_dollars_from_campaign": native["direct_dollars"],
                **catalog.model_ending()},
            "businesses": [simulate(catalog, plan, business) for business in BUSINESSES]}


def report(result: dict) -> str:
    budget = result["budget"]
    ending = result["native_ending"]
    lines = ["# Orbital Ending Cost Study", "",
        "Native Model ending; normal quality, no modules or research productivity.",
        "This is **not a campaign-time prediction**. Existing terrestrial industry/datacenter are assumed built.",
        "Manufacturing, construction, exploration, power and cargo delays are unmeasured.",
        "The 4-6-hour chapter is a target, not observed active playtime.", "",
        "## Native Ending", "",
        f"Normal assembly: **{ending['assembly_seconds']:g}s**; ground activation: **{ending['activation_seconds']:g}s at {ending['activation_watts']/1e6:g} MW**.",
        "20,000 physical Datasets plus one Rack assemble the Model; return it and activate on Nauvis.",
        "Earned 1B and physical payload are separate. Research-consumed Tokens must be replaced.",
        "Hyperscale is optional. No controller, Capital Allocation or required white science remains.",
        f"Ideal orbital-chapter AI/research cash **with optional Hyperscale**: **{budget['research_dollars'] + budget['terrestrial_dollars'] + budget['orbital_dollars']:,.0f} Dollars**.",
        "This starts after earlier terrestrial EV research and initial factory/datacenter construction are paid; it still includes pre-orbit Autonomy/Orbital research and terrestrial compute. The economy report starts earlier and skips Hyperscale by default, so its direct-cash total has a different scope.",
        "Research uses automation (red), logistic (green), chemical (blue), production (purple) and utility (yellow) science; no space (white).",
        f"Compute-only ramp: {budget['ramped_compute_hours']:.2f}h.", "",
        "## Hardware And Logistics", "",
        "Automatic uplifts round separately by item/platform and respect both mass and inventory slots.",
        "Silo-to-platform native qualification is separate from this arithmetic; return cargo delays are not modeled.",
        "Starter manufacture consumes 60 foundations but creates 100 placed tiles.",
        "The 100-extra-tiles-per-cluster envelope is not a tested platform blueprint.",
        f"Native Rack mass: **{ending['weights_grams'][P + 'datacenter-rack']:,} g**; Model mass: **{ending['weights_grams'][MODEL]:,} g**.",
        f"Rocket lift limit: **{ending['rocket_limit_grams']:,} g**; both rocket and cargo-pod inventory limits apply.",
        f"First cluster: {result['first_cluster']['rockets']} launches.",
        f"Fully batched twelve-cluster payload, including final Rack: {result['layouts'][0]['rockets']} launches.",
        f"Staged ramp: {result['staged_uplifts']['rockets']} launches.", "",
        "## Factory Supply Frontier", "",
        "Hardware includes launches, final Rack, silo and landing pad. Prior factory is not charged again.",
        "Joint co-products are credited once; no machine productivity is assumed.",
        "| Supply | Hardware + launches | With remaining science |", "| --- | ---: | ---: |"]
    for item, count in sorted(result["hardware_and_science_supplies"]["supplies"].items()):
        lines.append(f"| {item} | {result['hardware_supplies']['supplies'].get(item, 0):,.0f} | {count:,.0f} |")
    lines += ["", "Plates, fluids, blue circuits, engines and fuel are frontier supplies, not raw ore or free inputs.",
        "Tailings disposal, manufacturing energy and existing factory demand remain outside this bill.", "",
        "## Finite Cash Flow", "",
        "Cases start with 2,000 Dollars and 60 effective science sets/minute; science stock/manufacture is not free evidence.",
        "Only remaining battery buyers pay. Unique living customers cap taxis; fleets/depots and wear are financed after Autonomy.",
        "No limitless new nests, repeated EV generations or mature free fleet are assumed.",
        "| Case | Batteries sold | Fleet | Ideal model hours |", "| --- | ---: | ---: | ---: |"]
    for case in result["businesses"]:
        hours = f"{case['model_hours']:.2f}" if case["model_hours"] is not None else "not finished in 24h"
        lines.append(f"| {case['business']['name']} | {case['batteries_sold']} | {case['active_fleet']} | {hours} |")
    lines += ["", "## Shared Blue-Circuit Capacity", "",
        "| Spare blue circuits/min | Hardware floor | Hardware + science floor |", "| --- | ---: | ---: | ---: |"]
    for rate in (20, 60, 120):
        hardware = result["hardware_supplies"]["supplies"].get("processing-unit", 0)
        total = result["hardware_and_science_supplies"]["supplies"].get("processing-unit", 0)
        lines.append(f"| {rate} | {hardware/rate/60:.2f}h | {total/rate/60:.2f}h |")
    lines += ["", "Do not allocate the same blue-circuit production twice. Other materials can bottleneck first.",
        "These elapsed ideal-input clocks exclude practical I/O, build time and transport; they cannot qualify campaign pacing.",
        "Prototype capture does not qualify native Model return, activation, victory persistence or a complete campaign.", "",
        f"Native source SHA-256: `{result['native_source_sha256']}`.",
        f"Model SHA-256: `{result['model_sha256']}`.", ""]
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
