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
                                       REQUIRED_TECHNOLOGIES, EconomyCatalog, energy)

P = "bitermotors-"
CORE = P + "orbital-datacenter-core"
CONTROLLER = P + "planetary-grid-controller"
TERRESTRIAL = P + "terrestrial-datacenter"
ARRAY = P + "grid-battery-array"
TANDEM = P + "tandem-solar-array"
DEPOT = P + "bitertaxi-depot"
FLEET = P + "bitertaxi-fleet"
FINAL = P + "agi-training-run"
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
                  failed_fraction: float = 0) -> dict:
    if cores < 1:
        raise ValueError("at least one core is required")
    research_dollars = sum(catalog.research(name) for name in REQUIRED_TECHNOLOGIES)
    pre_orbit = (P + "autonomous-logistics", P + "orbital-compute")
    terrestrial_tokens = sum(catalog.research(name, TOKEN) for name in pre_orbit)
    terra_recipe = P + "terrestrial-ai-token"
    terra_batches = math.ceil(terrestrial_tokens / catalog.output(terra_recipe, TOKEN))
    later_tokens = sum(catalog.research(name, TOKEN) for name in REQUIRED_TECHNOLOGIES if name not in pre_orbit)
    generated = operating = core_seconds = physical_tokens = datasets = 0
    bands = []
    thresholds = [entry["threshold"] for entry in catalog.runtime["orbital_milestones"]]
    thresholds.append(catalog.runtime["agi_token_gate"])
    final_datasets = catalog.ingredient(FINAL, DATASET)
    dataset_tokens = catalog.runtime["dataset_tokens"]
    for index, (recipe, target) in enumerate(zip(ORBITAL_RECIPES, thresholds)):
        equivalents = catalog.output(recipe, TOKEN) + catalog.output(recipe, DATASET) * dataset_tokens
        batches = math.ceil((target - generated) / equivalents)
        if index == len(ORBITAL_RECIPES) - 1:
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
    power = energy(catalog.data["entities"][CONTROLLER]["energy_usage"])
    peak = energy(catalog.data["entities"][TANDEM]["production"])
    capacity = energy(catalog.data["entities"][ARRAY]["energy_source"]["buffer_capacity"])
    panels = math.ceil(power / (peak * catalog.data["assumptions"]["solar_average_fraction"]))
    arrays = math.ceil(panels * peak * catalog.data["assumptions"]["storage_seconds_per_peak_watt"] / capacity)
    consumed_arrays = catalog.ingredient(CONTROLLER, ARRAY) + catalog.ingredient(FINAL, ARRAY)
    capital_count = catalog.ingredient(FINAL, P + "capital-allocation")
    final_capital = capital_count * catalog.ingredient(P + "package-capital-allocation", DOLLAR)
    core_watts = energy(catalog.data["entities"][CORE]["energy_usage"])
    space_watts = energy(catalog.data["entities"][P + "high-density-space-solar-panel"]["production"])
    space_panels = math.ceil(cores * core_watts / (space_watts * catalog.data["nauvis_orbit_solar_multiplier"]))
    radiators = cores * catalog.runtime["radiators_per_core"]
    construction = sum(count * catalog.item_dollars(item) for item, count in (
        (P + "biterfactory-v2", 1), (TERRESTRIAL, 1), (CONTROLLER, 1),
        (ARRAY, arrays + catalog.ingredient(FINAL, ARRAY)), (TANDEM, panels), (CORE, cores),
        (P + "high-density-space-solar-panel", space_panels), (P + "orbital-radiator-panel", radiators)))
    terra_retry = retry_batches(terra_batches, failed_fraction)
    orbital_retry = retry_batches(sum(band["batches"] for band in bands), failed_fraction)
    retries = (terra_retry * catalog.ingredient(terra_recipe, DOLLAR)
               + orbital_retry * catalog.ingredient(ORBITAL_RECIPES[0], DOLLAR))
    terra_dollars = terra_batches * catalog.ingredient(terra_recipe, DOLLAR)
    direct = research_dollars + construction + terra_dollars + operating + final_capital + retries
    array_quantity = arrays + consumed_arrays
    return {
        "research_dollars": research_dollars, "research_science": {
            item: sum(catalog.research(name, item) for name in REQUIRED_TECHNOLOGIES)
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
        "capital_packaging_am3_seconds": capital_count * catalog.seconds(P + "package-capital-allocation", "assembling-machine-3"),
        "final_power_watts": power, "tandem_arrays": panels, "grid_battery_arrays": arrays,
        "consumed_grid_battery_arrays": consumed_arrays, "core_count": cores,
        "space_panels": space_panels, "radiators": radiators,
        "construction_dollars": construction, "final_capital_dollars": final_capital,
        "ordinary_ai_retry_dollars": retries, "direct_dollars": direct,
        "grid_battery_opportunity_dollars": array_quantity * sale_profit(catalog, "grid-battery"),
        "final_training_minutes": catalog.seconds(FINAL, CONTROLLER) / 60,
        "normal_final_run_energy_joules": power * catalog.seconds(FINAL, CONTROLLER),
        "power_material_bill": {
            "tandem_arrays": panels, "grid_battery_arrays_including_consumed": array_quantity,
            "hd_panels_for_tandem": panels * catalog.ingredient(TANDEM, P + "high-density-solar-array"),
            "lfp_packs_for_array_upgrades": array_quantity * catalog.ingredient(ARRAY, P + "lfp-battery-pack"),
            "processing_units_before_hd_panel_and_grid_battery_base_recipes": (
                panels * catalog.ingredient(TANDEM, "processing-unit")
                + array_quantity * catalog.ingredient(ARRAY, "processing-unit")
                + catalog.ingredient(FINAL, "processing-unit")),
            "low_density_structures_for_tandem": panels * catalog.ingredient(TANDEM, "low-density-structure"),
        },
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
    cases = [finite_market(catalog, scenario) for scenario in SCENARIOS]
    lines = ["# Biter Motors Economy Freeze Model", "",
        f"Captured engine: **{catalog.data['factorio_version']}**; mod **{catalog.data['mod_version']}**.",
        "Final prototypes and runtime policy: `docs/economy-prototypes.json`. Source freshness is",
        "checked by content hash, not string fragments. Budgets use normal quality, no modules,",
        "and zero research productivity. No infinite improvement is required.", "",
        "**Not a total campaign-time forecast.** Ore/chemistry throughput, building, science manufacture/",
        "research speed, combat, exploration, rocket uplifts, walking, and cargo congestion are not",
        "simulated. Native spawns/new nests are excluded from closed-market cases. Active building/",
        "exploration time is **unmeasured**, not zero. Intrinsic Biterfactory productivity can lower",
        "construction cash/material use; the unbonused budget is conservative, not an optimum.",
        "Recovered-capital credit is zero in these budgets: do not treat recycling as new business profit",
        "or fund purchases twice from the same returned capital.", "",
        "**Transport scope (2026-10-08):** critical cargo now has explicit portable weights.",
        "This model still excludes hardware uplift and cannot establish",
        "a finishable campaign. See [the orbital ending cost study](orbital-ending-cost-study.md).", "",
        "## Research And Gates", "", "| Required research | Science cycles | Dollars | AI Tokens |",
        "| --- | ---: | ---: | ---: |"]
    for name in REQUIRED_TECHNOLOGIES:
        lines.append(f"| {name.removeprefix(P)} | {n(catalog.data['technologies'][name]['unit']['count'])} | {n(catalog.research(name))} | {n(catalog.research(name, TOKEN))} |")
    lines += ["", "Optional Foundry, Megatruck, Cybertrain, eSpider, and infinite improvements are excluded.",
        "The 50-Roadster and 250-Premium sales gates still apply. The 2,000 Mass-market and 5,000",
        "consumer-sale gates unlock optional Megatruck and Bitertaxi production; neither gates orbital",
        "research. Each living customer may purchase each generation once, not unlimited repeat EVs.", "",
        "## Corrected AI Budget", "",
        f"Before orbit, {n(plan['terrestrial_research_tokens'])} research Tokens need **{n(plan['terrestrial_batches'])} terrestrial batches, {n(plan['terrestrial_operating_dollars'])} Dollars, and {plan['terrestrial_active_minutes']:.1f} active minutes at 8 MW**.",
        "Base terrestrial efficiency is used; optional efficiency research reduces later operation.", "",
        "| Orbital band | Normal cycle | Batches | Operating Dollars | One-core hours |",
        "| --- | ---: | ---: | ---: | ---: |"]
    for b in plan["bands"]:
        lines.append(f"| {b['recipe'].removeprefix(P)} | {b['normal_cycle_seconds']:g}s | {n(b['batches'])} | {n(b['dollars'])} | {b['one_core_hours']:.2f} |")
    lines += ["", f"The 30-second recipe runs every **{plan['bands'][0]['normal_cycle_seconds']:g} seconds** in a normal 1.5-speed core.",
        f"Total: **{n(plan['orbital_operating_dollars'])} operating Dollars, {plan['orbital_one_core_hours']:.2f} core-hours**. Research costs are counted once separately.",
        f"Later labs use {n(plan['orbital_research_tokens'])} Tokens. Package {n(plan['early_datasets_packaged'])} Datasets from early stock (one AM3: {plan['dataset_packaging_am3_minutes']:.2f} minutes); use direct Dataset recipes after Grid-scale Energy.",
        "The last batch replaces spent research payload; earned computation is not the same as physical inventory.",
        f"One AM3 packages capital in {plan['capital_packaging_am3_seconds']:g}s. The finale remains **20 uninterrupted minutes at 10 GW** ({plan['normal_final_run_energy_joules']/1e12:g} TJ).", "",
        "## Cash And Power", "", "| Cash sink | Dollars |", "| --- | ---: |",
        f"| Required research | {n(plan['research_dollars'])} |",
        f"| Terrestrial research compute | {n(plan['terrestrial_operating_dollars'])} |",
        f"| Orbital compute and replacement payload | {n(plan['orbital_operating_dollars'])} |",
        f"| Transition, controller, normal grid, and 8-core hardware | {n(plan['construction_dollars'])} |",
        f"| Final Capital Allocations | {n(plan['final_capital_dollars'])} |",
        f"| **Direct cash requirement** | **{n(plan['direct_dollars'])}** |", "",
        f"Solar-only finale supply: **{n(plan['tandem_arrays'])} Tandem Arrays and {n(plan['grid_battery_arrays'])} deployed Grid Battery Arrays**. Controller/final recipes consume {n(plan['consumed_grid_battery_arrays'])} more arrays, which cannot double as grid storage.",
        "HD and Tandem panels consume **no Dollars**; the previous report's panel cash charges were stale.",
        f"Forgone battery sales: up to {n(plan['grid_battery_opportunity_dollars'])} Dollars, **not another cash bill**, and only realizable with eligible buyers.", "",
        "Partial material bill, before HD/base-battery recipes, other industry, poles, and transport:", ""]
    lines.extend(f"- `{name}`: {n(count)}" for name, count in plan["power_material_bill"].items())
    lines += ["", "Solar/Array productivity makes **more items per craft**, not more watts/joules per placed",
        "entity. It saves materials, not placed counts. Quality and nuclear are optional alternatives.",
        "This report does not prove raw-material production can sustain a specific campaign cadence.", "",
        "## Finite-Market Scenarios", "",
        "Assume 200 living customers per developed settlement, all three required EV generations sold",
        "already, finite battery adoption (5% initially, then 5% of remaining eligibility every five",
        "minutes), and unique allocated taxi customers. No unlimited repeat battery sales or duplicate",
        "revenue from overlapping depots. Fleet replacement uses conservative initial wear, not mature safety.", "",
        "| Metric | Restricted market | Typical expansion | Taxi / energy heavy |",
        "| --- | ---: | ---: | ---: |"]
    metrics = (
        ("Settlements", lambda c: n(c["scenario"]["settlements"])),
        ("Living customers", lambda c: n(c["population"])),
        ("Consumer purchase capacity", lambda c: n(c["consumer_purchase_capacity"])),
        ("Finite EV + Grid Battery profit ceiling", lambda c: n(c["finite_profit_ceiling_without_taxis"])),
        ("Taxi gate from those sales", lambda c: "ready" if c["taxi_gate_ready_from_required_generations"] else "needs expansion"),
        ("Organic-only wait to fill taxi gate; no new nests", lambda c: f"{c['organic_only_taxi_gate_wait_hours']:.1f}h"),
        ("Allocated taxi fleet", lambda c: n(c["fleet_size"])),
        ("Fleet/depot capital", lambda c: n(c["depot_capex"])),
        ("Net recurring Dollars/hour", lambda c: n(c["net_taxi_dollars_per_hour"])),
        ("Full fleet cash payback", lambda c: f"{c['full_fleet_cash_payback_hours']:.2f}h" if c["full_fleet_cash_payback_hours"] is not None else "not unlocked"),
        ("Post-network funding window", lambda c: f"{c['funding_window_hours']:.2f}h" if c["funding_window_hours"] is not None else ">48h; finite ceiling"),
        ("Ideal EV selling time, before funding window", lambda c: f"{c['optimistic_parallel_consumer_sale_hours']:.2f}h"),
        ("Normal orbital cores", lambda c: n(c["plan"]["core_count"])),
        ("Core work / selected cores", lambda c: f"{c['plan']['orbital_parallel_compute_hours']:.2f}h"),
        ("Failed-batch cash sensitivity", lambda c: n(c["plan"]["ordinary_ai_retry_dollars"])),
    )
    lines.extend(f"| {label} | " + " | ".join(getter(c) for c in cases) + " |" for label, getter in metrics)
    lines += ["", "Funding and compute can overlap; adding these numbers is **not** a campaign-time estimate.",
        "Funding starts with EV cash already earned and assumes mature service can be financed. It",
        "counts fleet capex and finite battery adoption, but does not qualify natural bootstrapping.",
        "Core work excludes research waiting and idle cores at tier boundaries. Heavy sensitivity",
        "loses 10% of ordinary compute batches; retry time is not guessed. Extra manufacturing,",
        "charging, depot load, and existing industry require power above the 10 GW final load.", "",
        "## Remaining Balance Decisions", "",
        "- A closed five-settlement market cannot fund the ending from one-time purchases alone. Expand, allow natural customer/nest growth, or unlock recurring service. Organic virtual growth is not instant new demand.",
        f"- With two full depots, the {n(plan['final_capital_dollars'])}-Dollar finale bill alone needs about {plan['final_capital_dollars']/cases[1]['net_taxi_dollars_per_hour']:.1f} service hours. Evaluate a targeted capital adjustment against the 2-3-hour major-step target, not blanket cheaper research.",
        "- Measure actual panel/battery materials and transport throughput. Native delivery proves physical completion, not comfortable pacing.",
        "- Eight normal cores need about 6.25 active hours in the final compute band; sixteen need about 3.13. Compare practical core expansion and power/logistics throughput before changing Token yields.",
        "- Ordinary AI brownouts lose committed Dollars. Final AGI failure retains inputs: retry time/power, not another full capital package. Recycled capital and other inflows are not business profit.", "",
        "No balance values are changed by this simulator. Phase 4 remains open for targeted decisions,",
        "functional art, and native UI qualification.", "", "## Reproduce", "", "```bash",
        "scripts/validate-bitermotors-mod.sh  # prints an isolated artifact directory",
        "python3 scripts/bitermotors_economy_catalog.py --dump <artifacts>/script-output/data-raw-dump.json --runtime-contract <artifacts>/script-output/bitermotors-economy-contract.json",
        "python3 scripts/simulate_bitermotors_economy.py --check-source --output docs/economy-balance.md",
        "```", "", "Solar/storage equations: [Official Factorio Wiki](https://wiki.factorio.com/Power_production).",
        "The exporter verifies the validator's capture manifest, raw-dump/runtime hashes, and unchanged",
        "source before recording a catalog. It cannot legitimize a stale dump by hashing today's source.", "",
        "Standard orbital rocket payload arithmetic does not predict the number of downward cargo pods.", ""]
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
    if args.check_source and (errors := catalog.freshness_errors()):
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
