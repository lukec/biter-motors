#!/usr/bin/env python3
"""Prototype-backed budgets and finite-market sensitivities, not a campaign-time forecast."""

from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bitermotors_economy_catalog import (CATALOG, DATASET, DOLLAR, TOKEN,
                                       ASSEMBLE, ACTIVATE, MODEL, OPTIONAL_TECHNOLOGIES,
                                       REQUIRED_TECHNOLOGIES, EconomyCatalog, energy)

P = "bitermotors-"
CORE = P + "orbital-datacenter-core"
TERRESTRIAL = P + "terrestrial-datacenter"
ARRAY = P + "grid-battery-array"
TANDEM = P + "tandem-solar-array"
DEPOT = P + "bitertaxi-depot"
FLEET = P + "bitertaxi-fleet"
FINAL = ASSEMBLE
ORBITAL_RECIPES = tuple(P + name for name in (
    "orbital-ai-token", "orbital-ai-token-cluster",
    "orbital-ai-dataset-grid-scale", "orbital-ai-dataset-hyperscale"))


@dataclass(frozen=True)
class Scenario:
    name: str
    settlements: int
    population_per_settlement: int
    sales_offices: int
    depot_limit: int
    cores: int
    failed_compute_fraction: float = 0


SCENARIOS = (
    Scenario("Restricted market", 5, 200, 5, 1, 4),
    Scenario("Typical expansion", 10, 200, 10, 2, 8),
    Scenario("Taxi / energy heavy", 20, 200, 20, 4, 16, 0.10),
)


def sale_profit(catalog: EconomyCatalog, product: str) -> float:
    return catalog.output(P + "sell-" + product, DOLLAR)


def retry_batches(successful: int, failed_fraction: float) -> int:
    if not 0 <= failed_fraction < 1:
        raise ValueError("failed fraction must be in [0, 1)")
    return math.ceil(successful * failed_fraction / (1 - failed_fraction))


def campaign_plan(catalog: EconomyCatalog, *, cores: int = 8,
                  failed_fraction: float = 0, hyperscale: bool = False) -> dict:
    if cores < 1:
        raise ValueError("at least one core is required")
    if catalog.runtime["compute_progress_policy"] != {
            "terrestrial": "scrap", "orbital": "banked", "activation": "banked"}:
        raise ValueError("unsupported native compute-progress policy; refresh the economy model")
    ending = catalog.model_ending()
    technologies = REQUIRED_TECHNOLOGIES + (OPTIONAL_TECHNOLOGIES if hyperscale else ())
    recipes = ORBITAL_RECIPES if hyperscale else ORBITAL_RECIPES[:-1]
    research_dollars = sum(catalog.research(name) for name in technologies)
    pre_orbit = (P + "autonomous-logistics", P + "orbital-compute")
    terrestrial_tokens = sum(catalog.research(name, TOKEN) for name in pre_orbit)
    terra_recipe = P + "terrestrial-ai-token"
    terra_batches = math.ceil(terrestrial_tokens / catalog.output(terra_recipe, TOKEN))
    later_tokens = sum(catalog.research(name, TOKEN) for name in technologies if name not in pre_orbit)
    generated = operating = core_seconds = physical_tokens = datasets = 0
    bands = []
    thresholds = [entry["threshold"] for entry in catalog.runtime["orbital_milestones"]][:len(recipes) - 1]
    thresholds.append(catalog.runtime["agi_token_gate"])
    final_datasets = catalog.ingredient(FINAL, DATASET)
    dataset_tokens = catalog.runtime["dataset_tokens"]
    for index, (recipe, target) in enumerate(zip(recipes, thresholds)):
        equivalents = catalog.output(recipe, TOKEN) + catalog.output(recipe, DATASET) * dataset_tokens
        batches = math.ceil((target - generated) / equivalents)
        if index == len(recipes) - 1:
            remaining = final_datasets - datasets - math.floor((physical_tokens - later_tokens) / dataset_tokens)
            batches = max(batches, math.ceil(remaining / catalog.output(recipe, DATASET)))
        seconds = catalog.seconds(recipe, CORE)
        spent = batches * catalog.ingredient(recipe, DOLLAR)
        generated += batches * equivalents
        physical_tokens += batches * catalog.output(recipe, TOKEN)
        datasets += batches * catalog.output(recipe, DATASET)
        operating += spent
        core_seconds += batches * seconds
        bands.append({"recipe": recipe, "target": target, "batches": batches,
                      "dollars": spent, "normal_cycle_seconds": seconds,
                      "one_core_hours": batches * seconds / 3600})
    packed_early = math.floor((physical_tokens - later_tokens) / catalog.ingredient(P + "package-agi-training-dataset", TOKEN))
    assert datasets + packed_early >= final_datasets
    core_watts = energy(catalog.data["entities"][CORE]["energy_usage"])
    space_watts = energy(catalog.data["entities"][P + "high-density-space-solar-panel"]["production"])
    space_panels = math.ceil(cores * core_watts / (space_watts * catalog.data["nauvis_orbit_solar_multiplier"]))
    radiators = cores * catalog.runtime["radiators_per_core"]
    construction = sum(count * catalog.item_dollars(item) for item, count in (
        (P + "biterfactory-v2", 1), (TERRESTRIAL, 1),
        (P + "datacenter-rack", catalog.ingredient(ASSEMBLE, P + "datacenter-rack")), (CORE, cores),
        (P + "high-density-space-solar-panel", space_panels), (P + "orbital-radiator-panel", radiators),
        (P + "orbital-heat-pipe", cores * 2)))
    terra_retry = retry_batches(terra_batches, failed_fraction)
    retries = terra_retry * catalog.ingredient(terra_recipe, DOLLAR)
    terra_dollars = terra_batches * catalog.ingredient(terra_recipe, DOLLAR)
    direct = research_dollars + construction + terra_dollars + operating + retries
    return {
        "research_dollars": research_dollars, "research_science": {
            item: sum(catalog.research(name, item) for name in technologies)
            for item in ("automation-science-pack", "logistic-science-pack", "chemical-science-pack",
                         "production-science-pack", "utility-science-pack", "space-science-pack")},
        "terrestrial_research_tokens": terrestrial_tokens, "terrestrial_batches": terra_batches,
        "terrestrial_operating_dollars": terra_dollars,
        "terrestrial_active_minutes": terra_batches * catalog.seconds(terra_recipe, TERRESTRIAL) / 60,
        "orbital_research_tokens": later_tokens, "bands": bands,
        "orbital_generated_equivalents": generated, "orbital_operating_dollars": operating,
        "orbital_one_core_hours": core_seconds / 3600,
        "orbital_parallel_compute_hours": core_seconds / (3600 * cores),
        "physical_datasets": datasets, "early_datasets_packaged": packed_early,
        "dataset_packaging_am3_minutes": packed_early * catalog.seconds(P + "package-agi-training-dataset", "assembling-machine-3") / 60,
        "model_ending": ending, "core_count": cores, "hyperscale": hyperscale,
        "space_panels": space_panels, "radiators": radiators,
        "construction_dollars": construction,
        "ordinary_ai_retry_dollars": retries, "terrestrial_ai_retry_dollars": retries,
        "orbital_ai_retry_dollars": 0, "direct_dollars": direct,
    }


def finite_market(catalog: EconomyCatalog, scenario: Scenario, *, horizon_hours: int = 48) -> dict:
    if min(scenario.settlements, scenario.population_per_settlement, scenario.sales_offices, scenario.cores) < 1:
        raise ValueError("positive population, offices, and cores required")
    if scenario.depot_limit < 0:
        raise ValueError("negative depot count")
    population = scenario.settlements * scenario.population_per_settlement
    gate = catalog.runtime["consumer_sales_gates"]["bitertaxi"]["threshold"]
    vehicles = ("prototype-roadster", "premium-ev", "mass-market-ev")
    consumer_cash = population * sum(sale_profit(catalog, product) for product in vehicles)
    purchase_capacity = population * len(vehicles)
    per_vehicle = catalog.runtime["bitertaxi_customers_per_vehicle"]
    depot_capacity = catalog.runtime["bitertaxi_max_fleet"]
    fleet = min(scenario.depot_limit * depot_capacity, math.ceil(population / per_vehicle)) if purchase_capacity >= gate else 0
    allocated = min(fleet, math.ceil(population / per_vehicle))
    capex = fleet * catalog.item_dollars(FLEET) + math.ceil(fleet / depot_capacity) * catalog.item_dollars(DEPOT)
    revenue = allocated * 60 / catalog.runtime["bitertaxi_vehicle_minutes_per_dollar"]
    wear = allocated / catalog.runtime["bitertaxi_attrition_vehicle_hours"] * catalog.item_dollars(FLEET)
    net = revenue - wear
    plan = campaign_plan(catalog, cores=scenario.cores, failed_fraction=scenario.failed_compute_fraction)
    # This clock begins after the EV market is sold, not at the crash landing.
    wallet = consumer_cash - capex
    eligible = [math.ceil(scenario.population_per_settlement * catalog.runtime["grid_battery_initial_adoption"])] * scenario.settlements
    installed = [0] * scenario.settlements
    per_minute = scenario.sales_offices * 60 / catalog.seconds(P + "sell-grid-battery", P + "sales-office")
    sale_remainder = 0.0
    finished = None
    for minute in range(1, horizon_hours * 60 + 1):
        sale_remainder += per_minute
        slots = math.floor(sale_remainder)
        sold = 0
        for i in range(scenario.settlements):
            count = min(slots, eligible[i] - installed[i])
            installed[i] += count
            slots -= count
            sold += count
        sale_remainder -= math.floor(sale_remainder)
        wallet += sold * sale_profit(catalog, "grid-battery") + net / 60
        if minute % catalog.runtime["grid_battery_referral_minutes"] == 0:
            for i in range(scenario.settlements):
                if installed[i] > 0:
                    eligible[i] = min(scenario.population_per_settlement, eligible[i] + math.ceil(
                        (scenario.population_per_settlement - eligible[i]) * catalog.runtime["grid_battery_referral_fraction"]))
        if wallet >= plan["direct_dollars"]:
            finished = minute
            break
    growth_needed = max(0, math.ceil(gate / len(vehicles)) - population)
    growth_rate = scenario.settlements * 60 / catalog.runtime["organic_prospect_interval_minutes"]
    office_work = population * sum(catalog.seconds(P + "sell-" + p, P + "sales-office") for p in vehicles) / 3600
    return {
        "scenario": asdict(scenario), "population": population,
        "consumer_purchase_capacity": purchase_capacity, "consumer_profit_ceiling": consumer_cash,
        "grid_battery_sale_ceiling": population,
        "finite_profit_ceiling_without_taxis": consumer_cash + population * sale_profit(catalog, "grid-battery"),
        "taxi_gate_ready_from_required_generations": purchase_capacity >= gate,
        "new_customers_needed_for_taxi_gate": growth_needed,
        "organic_only_taxi_gate_wait_hours": growth_needed / growth_rate,
        "fleet_size": fleet, "depot_capex": capex, "net_taxi_dollars_per_hour": net,
        "full_fleet_cash_payback_hours": capex / net if net else None,
        "consumer_sales_office_work_hours": office_work,
        "optimistic_parallel_consumer_sale_hours": office_work / scenario.sales_offices,
        "funding_window_hours": finished / 60 if finished else None,
        "grid_batteries_sold_in_window": sum(installed),
        "funding_status": "funded" if finished else "expand market or unlock recurring service", "plan": plan,
    }


def n(value: float) -> str:
    return f"{value:,.0f}"


def report(catalog: EconomyCatalog) -> str:
    plan = campaign_plan(catalog)
    ending = plan["model_ending"]
    lines = ["# Biter Motors Economy Freeze Model", "",
        f"Captured engine: **{catalog.data['factorio_version']}**; mod **{catalog.data['mod_version']}**.", "",
        "Native Model assembly and ground activation; Hyperscale is optional.",
        "**Default cash budget skips Hyperscale.** It includes the listed terrestrial EV/energy research, initial Biterfactory V2/datacenter construction, and the AI route through Model activation; it is not a full crash-landing budget.",
        "The orbital study starts later: earlier terrestrial EV research and initial factory/datacenter construction are already paid, while its ideal AI/research subtotal includes optional Hyperscale. These are different scopes, not competing totals.",
        "No controller, final capital package or required white science is included.",
        "**Not a total campaign-time forecast.** Active construction, exploration, science manufacture and cargo delays are unmeasured.",
        "Normal quality, no modules/research productivity; prior factory power is assumed available.",
        "Recovered capital is not new business profit and cannot fund purchases twice.", "",
        "## Cash", "", "| Sink | Dollars |", "| --- | ---: |"]
    for label, key in (("Required research (including terrestrial EV/energy)", "research_dollars"),
                       ("Initial factories and ending hardware", "construction_dollars"),
                       ("Terrestrial research compute", "terrestrial_operating_dollars"),
                       ("Orbital compute and replacement payload", "orbital_operating_dollars"),
                       ("Terrestrial failure allowance", "ordinary_ai_retry_dollars"),
                       ("**Direct cash total (no Hyperscale)**", "direct_dollars")):
        lines.append(f"| {label} | {n(plan[key])} |")
    science = plan["research_science"]
    lines += ["", f"Required science: automation (red), logistic (green) and chemical (blue), **{n(science['automation-science-pack'])} each**; production (purple) and utility (yellow), **{n(science['production-science-pack'])} each**; **no space (white)**. No existing science stock or research productivity is credited.", "",
        f"Native assembly: **{ending['assembly_seconds']:g}s** in the normal orbital cluster; ground activation: **{ending['activation_seconds']:g}s at {ending['activation_watts']/1e6:g} MW**.",
        "The 1B earned gate and physical 20,000-Dataset payload are separate; research Tokens are replaced.",
        "Orbital work is banked; terrestrial failures alone add retry cash.",
        "Hardware uplift is excluded; see the orbital ending cost study for material frontiers and launches.", "",
        "## Finite Markets", "", "| Case | Finite profit ceiling | Taxi fleet | Funding hours |", "| --- | ---: | ---: | ---: |"]
    for scenario in SCENARIOS:
        case = finite_market(catalog, scenario)
        lines.append(f"| {scenario.name} | {n(case['finite_profit_ceiling_without_taxis'])} | {case['fleet_size']} | {case['funding_window_hours']} |")
    lines += ["", "Finite battery adoption and unique living customers cap demand; overlapping depots cannot duplicate service.",
        "EV cash is already earned at this checkpoint; fleets/depots are paid, not free.",
        "Funding and compute can overlap; their sum is not a campaign clock. New nests/growth are excluded.",
        "Phase 4 remains open: practical I/O, shared blue-circuit capacity and active player time need evidence.",
        "No balance values are changed by this simulator. Prototype capture is not native ending or campaign qualification.", "",
        f"Native source SHA-256: `{catalog.data['source_sha256']}`.", ""]
    return "\n".join(lines)


def validate_source_snapshot(path: Path = CATALOG) -> list[str]:
    return EconomyCatalog.load(path).freshness_errors()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=CATALOG)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--check-source", action="store_true")
    args = parser.parse_args()
    catalog = EconomyCatalog.load(args.catalog)
    if errors := catalog.freshness_errors():
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    output = json.dumps({"baseline": campaign_plan(catalog), "finite_markets": [
        finite_market(catalog, case) for case in SCENARIOS]}, indent=2) if args.json else report(catalog)
    if args.output:
        args.output.write_text(output.rstrip() + "\n")
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
