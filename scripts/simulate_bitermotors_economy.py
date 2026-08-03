#!/usr/bin/env python3
"""Reproducible Biter Motors campaign-economy model.

The model intentionally stays at the strategic layer. It measures Dollars,
sale-equivalent products, sales-office time, AI compute time, and solar-only
power infrastructure. It does not attempt to model ore throughput, customer
growth randomness, quality, modules, or factory crafting throughput.
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[1]
DATA_LUA = REPO_ROOT / "mod/bitermotors_0.1.1/data.lua"
CONTROL_LUA = REPO_ROOT / "mod/bitermotors_0.1.1/control.lua"

DOLLAR_USD = 10_000


@dataclass(frozen=True)
class Sale:
    name: str
    dollars: float
    seconds: float

    @property
    def dollars_per_hour(self) -> float:
        return self.dollars * 3600 / self.seconds


SALES = {
    "roadster": Sale("Prototype Roadster", 2, 60),
    "premium": Sale("Premium EV", 1, 30),
    "mass_market": Sale("Mass-market EV", 1, 5),
    "megatruck": Sale("Megatruck", 2, 10),
    "grid-battery": Sale("Grid Battery", 20, 30),
}


@dataclass(frozen=True)
class ProgressionStage:
    milestone: str
    incremental_dollars: float
    gate: str
    practical_funding: str


PROGRESSION = (
    ProgressionStage(
        "Premium EV",
        250,
        "50 Roadsters sold",
        "125 Roadsters fund the research, so capital dominates the 50-sale gate.",
    ),
    ProgressionStage(
        "Advanced Battery Chemistry",
        300,
        "Premium EV production and the battery branch",
        "300 Dollars funds the first chemistry upgrade without requiring a Grid Battery economy.",
    ),
    ProgressionStage(
        "Energy Products",
        200,
        "Advanced Battery Chemistry",
        "200 Dollars opens the Grid Battery branch before large-scale EV expansion.",
    ),
    ProgressionStage(
        "V2 Charging Network",
        150,
        "Premium EV program and powered V1 charging",
        "The cheaper V2 path lets the player reach distant colonies without hoarding research capital.",
    ),
    ProgressionStage(
        "Capital Scaling",
        600,
        "250 Premium EVs sold",
        "600 Dollars opens the Biterfactory V2 and mass-market production path.",
    ),
    ProgressionStage(
        "Terrestrial AI",
        750,
        "Capital Scaling and Energy Products",
        "750 Dollars funds terrestrial compute without making the first datacenter a dead end.",
    ),
    ProgressionStage(
        "Autonomous Logistics",
        750,
        "Terrestrial AI and logistics science",
        "750 Dollars unlocks Bitertaxi service and the V4 charging tier.",
    ),
    ProgressionStage(
        "Orbital Compute",
        1_500,
        "5,000 cumulative consumer EV sales and rocket prerequisites",
        "1,500 Dollars funds the orbital transition; the 5,000-sale gate remains unchanged.",
    ),
    ProgressionStage(
        "Cluster Training",
        5_000,
        "1,000,000 cumulative orbital tokens",
        "Research unlocks 25,000-token orbital batches.",
    ),
    ProgressionStage(
        "Grid-scale Energy",
        15_000,
        "10,000,000 cumulative orbital tokens",
        "Research unlocks 50,000-token batches and the late power assets.",
    ),
    ProgressionStage(
        "Hyperscale Training",
        30_000,
        "100,000,000 cumulative orbital tokens",
        "Research unlocks 100,000-token orbital batches.",
    ),
    ProgressionStage(
        "Planetary Grid",
        0,
        "Hyperscale Training, Autonomous Logistics, and nuclear power",
        "Science and AI Tokens only; Planetary Grid no longer consumes Dollars.",
    ),
    ProgressionStage(
        "Grid Controller",
        11_050,
        "Planetary Grid researched",
        "10,000 Dollars, 100 capital-funded Biterfactory Modules, and the 5-Dollar upgrades for 10 Grid Battery Arrays.",
    ),
)


@dataclass(frozen=True)
class Balance:
    name: str
    ai_target: float
    final_capital_dollars: float
    final_power_watts: float
    bitertaxi_vehicle_minutes_per_dollar: float
    solar_productivity: float


CURRENT = Balance(
    name="Approved rebalance",
    ai_target=1_000_000_000,
    final_capital_dollars=50_000,
    final_power_watts=10_000_000_000,
    bitertaxi_vehicle_minutes_per_dollar=2,
    solar_productivity=0,
)

RELEASE_CANDIDATE = Balance(
    name="Higher-power sensitivity",
    ai_target=1_000_000_000,
    final_capital_dollars=50_000,
    final_power_watts=12_000_000_000,
    bitertaxi_vehicle_minutes_per_dollar=2,
    solar_productivity=0.40,
)

DEMANDING_RELEASE = Balance(
    name="Higher-power and capital sensitivity",
    ai_target=1_000_000_000,
    final_capital_dollars=60_000,
    final_power_watts=12_000_000_000,
    bitertaxi_vehicle_minutes_per_dollar=4,
    solar_productivity=0.40,
)

ORBITAL_AI_MILESTONES = (
    (1_000_000, 10_000, 1, 5_000),
    (10_000_000, 25_000, 1, 15_000),
    (100_000_000, 50_000, 1, 30_000),
    (1_000_000_000, 100_000, 1, 0),
)

HD_SOLAR_PEAK_WATTS = 300_000
TANDEM_SOLAR_PEAK_WATTS = 3_000_000
NAUVIS_SOLAR_AVERAGE_FRACTION = 0.70
HD_SOLAR_BATCH_INPUT_DOLLARS = 3
HD_SOLAR_BATCH_OUTPUT = 4
GRID_BATTERY_CAPACITY_JOULES = 100_000_000
GRID_BATTERY_ARRAY_CAPACITY_JOULES = 1_000_000_000
GRID_BATTERY_SALE_DOLLARS = 20
BASE_SOLAR_PANEL_PEAK_WATTS = 60_000
BASE_ACCUMULATOR_CAPACITY_JOULES = 5_000_000
BASE_ACCUMULATORS_PER_PANEL = 0.84

GRID_CONTROLLER_CONSUMED_GRID_BATTERIES = 10
FINAL_RUN_CONSUMED_GRID_BATTERIES = 100
CONSUMED_GRID_BATTERIES = GRID_CONTROLLER_CONSUMED_GRID_BATTERIES + FINAL_RUN_CONSUMED_GRID_BATTERIES
FINAL_RUN_GRID_BATTERY_ARRAY_RECIPE_DOLLARS = FINAL_RUN_CONSUMED_GRID_BATTERIES * 5
FINAL_CAPITAL_ALLOCATIONS = 100
CAPITAL_ALLOCATION_DOLLARS = 500
FINAL_DATASETS = 20_000
FINAL_PROCESSING_UNITS = 10_000
RECOMMENDED_PROGRESSION_CONSTRUCTION_DOLLARS = 275
PRE_ENDGAME_DOLLARS = (
    sum(stage.incremental_dollars for stage in PROGRESSION)
    + RECOMMENDED_PROGRESSION_CONSTRUCTION_DOLLARS
)

BITERTAXI_FLEET_DOLLARS = 100
BITERTAXI_FLEETS_PER_CENTER = 200
BITERTAXI_CENTER_FIXED_DOLLARS = 75 + 200 + 200 + 4
BITERTAXI_CENTER_CAPEX = (
    BITERTAXI_FLEETS_PER_CENTER * BITERTAXI_FLEET_DOLLARS
    + BITERTAXI_CENTER_FIXED_DOLLARS
)
BITERTAXI_CUSTOMERS_PER_FLEET = 5
ORBITAL_CORE_WATTS = 250_000_000
ORBITAL_PANEL_PEAK_WATTS = 50_000_000
NAUVIS_ORBIT_SOLAR_MULTIPLIER = 3
RADIATORS_PER_CORE = 8

CONSUMER_REPLACEMENT_MODELS = (
    "Prototype Roadster",
    "Premium EV",
    "Mass-market EV",
    "Megatruck",
)
ORGANIC_PROSPECT_CAP_MULTIPLIER = 3
ORGANIC_PROSPECT_INTERVAL_MINUTES = 15
GROWTH_SUSPENSION_SCOPE = "affected settlement only"
CHARGER_RADII = (64, 128, 192, 256)


@dataclass(frozen=True)
class MarketPlan:
    replacement_models: tuple[str, ...]
    purchases_per_customer: int
    organic_cap_multiplier: int
    organic_prospect_interval_minutes: int
    growth_suspension_scope: str
    charger_radii: tuple[int, ...]


MARKET = MarketPlan(
    replacement_models=CONSUMER_REPLACEMENT_MODELS,
    purchases_per_customer=len(CONSUMER_REPLACEMENT_MODELS),
    organic_cap_multiplier=ORGANIC_PROSPECT_CAP_MULTIPLIER,
    organic_prospect_interval_minutes=ORGANIC_PROSPECT_INTERVAL_MINUTES,
    growth_suspension_scope=GROWTH_SUSPENSION_SCOPE,
    charger_radii=CHARGER_RADII,
)


@dataclass(frozen=True)
class AiPlan:
    milestone_level: int
    milestone_research_dollars: float
    operating_dollars: float
    total_dollars: float
    one_core_hours: float
    dollars_by_band: tuple[float, ...]


@dataclass(frozen=True)
class PowerPlan:
    watts: float
    panels: int
    grid_batteries: int
    panel_recipe_dollars: float
    solar_research_dollars: float
    grid_battery_opportunity_dollars: float
    panel_tiles: int
    grid_battery_tiles: int
    tandem_arrays: int
    grid_battery_arrays: int
    tandem_recipe_dollars: float
    grid_battery_array_recipe_dollars: float
    grid_battery_array_upgrade_opportunity_dollars: float


@dataclass(frozen=True)
class CampaignPlan:
    balance: str
    ai: AiPlan
    power: PowerPlan
    pre_endgame_dollars: float
    final_capital_dollars: float
    orbital_panel_dollars: float
    consumed_grid_battery_opportunity_dollars: float
    direct_dollars: float
    economic_burden_dollars: float
    grid_batteries_sold_to_fund_direct_cost: float
    grid_batteries_manufactured: float
    mass_market_ev_equivalent: float


def ai_plan(balance: Balance, max_efficiency_level: int) -> AiPlan:
    """Model the four cumulative-token orbital production bands."""
    if not 0 <= max_efficiency_level <= len(ORBITAL_AI_MILESTONES) - 1:
        raise ValueError("invalid orbital AI milestone level")

    generated = 0.0
    operating_dollars = 0.0
    research_dollars = 0.0
    dollars_by_band: list[float] = []
    for index, (threshold, _tokens, band_dollars, research_cost) in enumerate(
        ORBITAL_AI_MILESTONES
    ):
        if index > max_efficiency_level:
            break
        segment_target = min(float(threshold), balance.ai_target)
        segment_dollars = max(0.0, segment_target - generated) / _tokens * band_dollars
        dollars_by_band.append(segment_dollars)
        operating_dollars += segment_dollars
        generated = segment_target
        if generated < threshold:
            break
        research_dollars += research_cost

    milestone_level = min(max_efficiency_level, len(dollars_by_band) - 1)
    if generated < balance.ai_target:
        threshold, tokens, band_dollars, _ = ORBITAL_AI_MILESTONES[milestone_level]
        segment_dollars = (balance.ai_target - generated) / tokens * band_dollars
        dollars_by_band.append(segment_dollars)
        operating_dollars += segment_dollars

    one_core_hours = 0.0
    previous = 0
    for threshold, tokens, _band_dollars, _research_cost in ORBITAL_AI_MILESTONES:
        target = min(balance.ai_target, threshold)
        if target <= previous:
            break
        one_core_hours += (target - previous) / tokens / 120
        previous = target
        if previous >= balance.ai_target:
            break
    return AiPlan(
        milestone_level=milestone_level,
        milestone_research_dollars=research_dollars,
        operating_dollars=operating_dollars,
        total_dollars=research_dollars + operating_dollars,
        one_core_hours=one_core_hours,
        dollars_by_band=tuple(dollars_by_band),
    )


def optimal_ai_plan(balance: Balance) -> AiPlan:
    # The higher bands are cumulative-token unlocks, not optional efficiency
    # research. A 1B-token campaign must reach the final band.
    return ai_plan(balance, len(ORBITAL_AI_MILESTONES) - 1)


def power_plan(balance: Balance) -> PowerPlan:
    average_panel_watts = TANDEM_SOLAR_PEAK_WATTS * NAUVIS_SOLAR_AVERAGE_FRACTION
    panels = math.ceil(balance.final_power_watts / average_panel_watts)
    grid_batteries = math.ceil(panels * TANDEM_SOLAR_PEAK_WATTS * 70 / GRID_BATTERY_ARRAY_CAPACITY_JOULES)
    tandem_recipe_dollars = panels * 1
    grid_battery_array_recipe_dollars = grid_batteries * 5
    grid_battery_array_upgrade_opportunity_dollars = grid_batteries * GRID_BATTERY_SALE_DOLLARS
    productivity_levels = round(balance.solar_productivity / 0.10)
    solar_research_dollars = sum(750 * 1.5**level for level in range(productivity_levels))
    return PowerPlan(
        watts=balance.final_power_watts,
        panels=panels,
        grid_batteries=grid_batteries,
        panel_recipe_dollars=tandem_recipe_dollars,
        solar_research_dollars=solar_research_dollars,
        grid_battery_opportunity_dollars=grid_batteries * GRID_BATTERY_SALE_DOLLARS,
        panel_tiles=panels * 9,
        grid_battery_tiles=grid_batteries * 4,
        tandem_arrays=panels,
        grid_battery_arrays=grid_batteries,
        tandem_recipe_dollars=tandem_recipe_dollars,
        grid_battery_array_recipe_dollars=grid_battery_array_recipe_dollars,
        grid_battery_array_upgrade_opportunity_dollars=grid_battery_array_upgrade_opportunity_dollars,
    )


def campaign_plan(balance: Balance) -> CampaignPlan:
    ai = optimal_ai_plan(balance)
    power = power_plan(balance)
    cores = cores_for_ai_hours(ai, 10)
    space_panels = orbital_panel_count(cores)
    hd_panel_dollars_per_item = min(
        HD_SOLAR_BATCH_INPUT_DOLLARS / HD_SOLAR_BATCH_OUTPUT,
        1 / (1 + balance.solar_productivity),
    )
    orbital_panel_dollars = space_panels * 4 * hd_panel_dollars_per_item
    consumed_grid_battery_opportunity = CONSUMED_GRID_BATTERIES * GRID_BATTERY_SALE_DOLLARS
    direct_dollars = (
        PRE_ENDGAME_DOLLARS
        # The 50,000 milestone-research Dollars are already in PROGRESSION.
        + ai.operating_dollars
        + balance.final_capital_dollars
        + power.tandem_recipe_dollars
        + power.grid_battery_array_recipe_dollars
        + FINAL_RUN_GRID_BATTERY_ARRAY_RECIPE_DOLLARS
        + power.solar_research_dollars
        + orbital_panel_dollars
    )
    economic_burden = (
        direct_dollars
        + power.grid_battery_opportunity_dollars
        + consumed_grid_battery_opportunity
    )
    grid_batteries_sold = direct_dollars / SALES["grid-battery"].dollars
    return CampaignPlan(
        balance=balance.name,
        ai=ai,
        power=power,
        pre_endgame_dollars=PRE_ENDGAME_DOLLARS,
        final_capital_dollars=balance.final_capital_dollars,
        orbital_panel_dollars=orbital_panel_dollars,
        consumed_grid_battery_opportunity_dollars=consumed_grid_battery_opportunity,
        direct_dollars=direct_dollars,
        economic_burden_dollars=economic_burden,
        grid_batteries_sold_to_fund_direct_cost=grid_batteries_sold,
        grid_batteries_manufactured=grid_batteries_sold + power.grid_battery_arrays + CONSUMED_GRID_BATTERIES,
        mass_market_ev_equivalent=economic_burden / SALES["mass_market"].dollars,
    )


def bitertaxi_revenue_per_hour(balance: Balance, centers: int) -> float:
    vehicle_minutes_per_minute = (
        centers * BITERTAXI_FLEETS_PER_CENTER
    )
    return vehicle_minutes_per_minute / balance.bitertaxi_vehicle_minutes_per_dollar * 60


def bitertaxi_hours_to_net(balance: Balance, centers: int, target_dollars: float) -> float:
    capex = centers * BITERTAXI_CENTER_CAPEX
    return (target_dollars + capex) / bitertaxi_revenue_per_hour(balance, centers)


def bitertaxi_payback_hours(balance: Balance) -> float:
    """Return the full-center capex payback at the target allocation rate."""
    return BITERTAXI_CENTER_CAPEX / bitertaxi_revenue_per_hour(balance, 1)


def replacement_purchase_capacity(customers: int) -> int:
    """Count one possible purchase for each consumer model per customer."""
    if customers < 0:
        raise ValueError("customers must be non-negative")
    return customers * MARKET.purchases_per_customer


def organic_prospect_cap(initial_represented_population: int) -> int:
    """Bound represented local growth without spawning unbounded visible units."""
    if initial_represented_population < 0:
        raise ValueError("initial represented population must be non-negative")
    return initial_represented_population * MARKET.organic_cap_multiplier


def cores_for_ai_hours(plan: AiPlan, target_hours: float) -> int:
    return math.ceil(plan.one_core_hours / target_hours)


def orbital_panel_count(cores: int) -> int:
    effective_panel_watts = ORBITAL_PANEL_PEAK_WATTS * NAUVIS_ORBIT_SOLAR_MULTIPLIER
    return math.ceil(cores * ORBITAL_CORE_WATTS / effective_panel_watts)


def fmt(value: float, decimals: int = 0) -> str:
    if decimals:
        return f"{value:,.{decimals}f}"
    return f"{value:,.0f}"


def fmt_power(watts: float) -> str:
    for divisor, suffix in ((1e12, "TW"), (1e9, "GW"), (1e6, "MW"), (1e3, "kW")):
        if watts >= divisor:
            return f"{watts / divisor:g} {suffix}"
    return f"{watts:g} W"


def progression_markdown() -> str:
    lines = [
        "| Milestone | Incremental Dollars | Cumulative | Physical gate | Practical funding lower bound |",
        "|---|---:|---:|---|---|",
    ]
    cumulative = 0.0
    for stage in PROGRESSION:
        cumulative += stage.incremental_dollars
        lines.append(
            f"| {stage.milestone} | {fmt(stage.incremental_dollars)} | {fmt(cumulative)} | "
            f"{stage.gate} | {stage.practical_funding} |"
        )
    return "\n".join(lines)


def sale_markdown() -> str:
    lines = [
        "| Product | Profit per sale | Nominal sale time | One-office profit rate |",
        "|---|---:|---:|---:|",
    ]
    for sale in SALES.values():
        lines.append(
            f"| {sale.name} | {fmt(sale.dollars)} | {fmt(sale.seconds)} sec | "
            f"{fmt(sale.dollars_per_hour)} Dollars/hour |"
        )
    return "\n".join(lines)


def market_markdown() -> str:
    models = ", ".join(MARKET.replacement_models)
    radii = " / ".join(str(radius) for radius in MARKET.charger_radii)
    return f"""## Customer Network Assumptions

Each living customer can buy one of each consumer vehicle generation over the
campaign: {models}. A replacement purchase changes the customer's active
vehicle and has about a 5% chance to create a Wrecked EV, so a developed settlement can keep
producing demand without requiring a new biter for every sale. Bitertaxi fleet
service is recurring revenue and is not part of this consumer replacement
count.

- Purchase opportunities per represented customer: {MARKET.purchases_per_customer}
- Replacement purchases: one per consumer vehicle generation
- 5,000 consumer-sale Bitertaxi gate: unchanged
- Organic represented-population cap: {MARKET.organic_cap_multiplier}x each settlement's starting representation
- Organic prospect interval: one represented prospect about every {MARKET.organic_prospect_interval_minutes} minutes while locally served
- Growth suspension: {MARKET.growth_suspension_scope}; other settlements continue growing
- V1/V2/V3/V4 charger radii: {radii} tiles

The model treats represented populations as aggregate settlement state. It does
not require one Lua unit per simulated customer, and it does not make distant
colonies mandatory once the player has developed a bounded network of local
settlements.
"""


def campaign_markdown(plans: Iterable[CampaignPlan]) -> str:
    plans = tuple(plans)
    lines = [
        "| Metric | " + " | ".join(plan.balance for plan in plans) + " |",
        "|---|" + "|".join("---:" for _ in plans) + "|",
    ]
    rows = (
        ("Final grid", lambda p: fmt_power(p.power.watts)),
        ("Orbital AI milestone band", lambda p: f"Band {p.ai.milestone_level + 1} of 4"),
        ("AI operating + milestone research Dollars", lambda p: fmt(p.ai.total_dollars)),
        ("One-core AI time", lambda p: f"{fmt(p.ai.one_core_hours, 1)} hours"),
        ("Cores for a 10-hour AI build", lambda p: fmt(cores_for_ai_hours(p.ai, 10))),
        (
            "Orbital compute power for that build",
            lambda p: fmt_power(cores_for_ai_hours(p.ai, 10) * ORBITAL_CORE_WATTS),
        ),
        (
            "Orbital solar panels for that build",
            lambda p: fmt(orbital_panel_count(cores_for_ai_hours(p.ai, 10))),
        ),
        (
            "Orbital radiators for that build",
            lambda p: fmt(cores_for_ai_hours(p.ai, 10) * RADIATORS_PER_CORE),
        ),
        ("Mandatory path + transition construction", lambda p: fmt(p.pre_endgame_dollars)),
        ("Final capital Dollars", lambda p: fmt(p.final_capital_dollars)),
        ("Tandem Solar Arrays", lambda p: fmt(p.power.tandem_arrays)),
        ("Grid Battery Arrays", lambda p: fmt(p.power.grid_battery_arrays)),
        ("Tandem recipe Dollars", lambda p: fmt(p.power.tandem_recipe_dollars)),
        ("Grid Battery Array recipe Dollars", lambda p: fmt(p.power.grid_battery_array_recipe_dollars)),
        ("Solar productivity research Dollars", lambda p: fmt(p.power.solar_research_dollars)),
        ("Orbital solar recipe Dollars", lambda p: fmt(p.orbital_panel_dollars)),
        (
            "Unsold Grid Battery opportunity cost",
            lambda p: fmt(
                p.power.grid_battery_opportunity_dollars
                + p.consumed_grid_battery_opportunity_dollars
            ),
        ),
        ("Direct Dollars required", lambda p: fmt(p.direct_dollars)),
        ("Total economic burden", lambda p: fmt(p.economic_burden_dollars)),
        ("Grid Batteries sold to fund direct Dollars", lambda p: fmt(p.grid_batteries_sold_to_fund_direct_cost)),
        ("Total Grid Batteries manufactured", lambda p: fmt(p.grid_batteries_manufactured)),
        ("One-Dollar EV equivalent", lambda p: fmt(p.mass_market_ev_equivalent)),
    )
    for label, getter in rows:
        lines.append(f"| {label} | " + " | ".join(getter(plan) for plan in plans) + " |")
    return "\n".join(lines)


def timing_markdown(plans: Iterable[CampaignPlan]) -> str:
    plans = tuple(plans)
    lines = [
        "| Funding system | " + " | ".join(plan.balance for plan in plans) + " |",
        "|---|" + "|".join("---:" for _ in plans) + "|",
    ]
    for offices in (10, 25, 100):
        hours = [
            plan.grid_batteries_sold_to_fund_direct_cost
            / (SALES["grid-battery"].dollars_per_hour / SALES["grid-battery"].dollars * offices)
            for plan in plans
        ]
        lines.append(
            f"| {offices} saturated Grid Battery Sales Offices | "
            + " | ".join(f"{fmt(value, 1)} h" for value in hours)
            + " |"
        )
    for centers in (10, 50, 100):
        lines.append(
            f"| {centers} full Bitertaxi Depots, net of fleet capex | "
            + " | ".join(
                f"{fmt(bitertaxi_hours_to_net(balance, centers, plan.direct_dollars), 1)} h"
                for balance, plan in zip((CURRENT, RELEASE_CANDIDATE, DEMANDING_RELEASE), plans)
            )
            + " |"
        )
    return "\n".join(lines)


def construction_markdown() -> str:
    rows = (
        ("Biterfactory V1", "100", "10 Biterfactory Modules"),
        ("Biterfactory V2 upgrade", "150", "Structural Casting plus the V2 recipe"),
        ("V3 Rapid Charger upgrade", "75", "Direct recipe capital"),
        (
            "V4 Solar Charging Hub upgrade",
            "204 direct / 284 effective",
            "200 Dollars, 4 HD panels, and 4 unsold Grid Batteries",
        ),
        (
            "Full Bitertaxi Depot",
            f"{fmt(BITERTAXI_CENTER_CAPEX)} direct / {fmt(BITERTAXI_CENTER_CAPEX + 80)} effective",
            "200 fleets, charger chain, center, and four unsold Grid Batteries",
        ),
        (
            "Planetary Grid Controller",
            "11,050 direct / 11,250 effective",
            "10,000 direct, 100 capital-funded Biterfactory Modules, and 10 Grid Battery Array upgrades",
        ),
        (
            "AGI final-run storage",
            "500 direct / 2,500 effective",
            "100 Grid Battery Arrays, separate from the 1,001-grid-asset target",
        ),
    )
    lines = [
        "| Construction sink | Dollar burden | What the model counts |",
        "|---|---:|---|",
    ]
    lines.extend(f"| {name} | {cost} | {detail} |" for name, cost, detail in rows)
    return "\n".join(lines)


def practical_progression_markdown() -> str:
    mixed_rows = (
        ("Premium EV", "50 Roadsters sold", 250, 250, 0),
        ("Advanced Battery Chemistry", "Premium EV production", 300, 300, 0),
        ("Energy Products", "Advanced Battery Chemistry", 200, 200, 0),
        ("V2 Charging Network", "Powered V1 charging", 150, 150, 0),
        ("Capital Scaling", "250 Premium EVs sold", 600, 600, 0),
        ("Terrestrial AI", "Capital Scaling and Energy Products", 750, 750, 0),
        ("Autonomous Logistics", "Terrestrial AI and logistics science", 750, 750, 0),
        ("Bitertaxi", "5,000 cumulative consumer sales", 0, 0, 0),
        ("Orbital Compute", "Rocket and orbital prerequisites", 1_500, 1_500, 0),
        ("Orbital milestone research", "1M / 10M / 100M tokens", 50_000, 50_000, 0),
        ("Planetary Grid", "Hyperscale and science", 0, 0, 0),
        ("Grid Controller", "10 Grid Battery Arrays and modules", 11_050, 11_050, 0),
        ("Final capital package", "100 allocations", 50_000, 50_000, 0),
    )
    lines = [
        "| Milestone | Requirement | Illustrative capital raised | Spend | Cash after |",
        "|---|---:|---:|---:|---:|",
    ]
    lines.extend(
        f"| {milestone} | {products} | {fmt(raised)} | {fmt(spend)} | {fmt(cash)} |"
        for milestone, products, raised, spend, cash in mixed_rows
    )
    return "\n".join(lines)


def report() -> str:
    balances = (CURRENT, RELEASE_CANDIDATE, DEMANDING_RELEASE)
    plans = tuple(campaign_plan(balance) for balance in balances)
    return f"""# Biter Motors Economy Simulation

This is a strategic lower-bound model of the approved late-game rebalance and
two sensitivity cases. It models current recipe profits, required Dollars,
cumulative orbital AI bands, final power, and solar storage. It excludes raw ore throughput,
customer-acquisition delay, quality, modules, and factory build time, so real
playtime will be longer.

One in-game Dollar represents `${DOLLAR_USD:,}` USD of profit.

## Sale Economics

{sale_markdown()}

## Terrestrial Progression

{progression_markdown()}

The physical sales gates remain important, but the early capital curve is now
deliberately forgiving: the first terrestrial research sequence totals 4,500
Dollars through Orbital Compute, excluding optional branches and construction.
Once Energy Products unlocks, 20-Dollar Grid Battery sales can fund later research
much more efficiently than one-Dollar EV sales.

{market_markdown()}

### Practical Mixed-Sales Path

{practical_progression_markdown()}

This terrestrial path still uses the required consumer sales to open Bitertaxi
and orbital play, then uses Grid Battery sales as the scalable capital source. The
late path adds three explicit orbital research bills of 5,000, 15,000, and
30,000 Dollars. It excludes raw ore throughput, customer acquisition, quality,
modules, and factory build time, so real playtime will be longer.

Recommended construction around the mass-market transition adds about 275
Dollars: 100 for Biterfactory V1, 150 more for V2, and 25 for the solar-panel
production gate. A fully stocked Bitertaxi Depot costs about
{fmt(BITERTAXI_CENTER_CAPEX)} Dollars, serves {fmt(BITERTAXI_FLEETS_PER_CENTER * BITERTAXI_CUSTOMERS_PER_FLEET)}
customers, earns {fmt(bitertaxi_revenue_per_hour(CURRENT, 1))} Dollars/hour at
the target rate, and pays back its full center-and-fleet capex in about
{fmt(bitertaxi_payback_hours(CURRENT), 1)} hours before other operating costs.

Optional finite branches add 1,250 Dollars: 250 for Megatruck Engineering, 250
for Battery Material Recovery, and 750 for Cybertrain Logistics. Infinite
improvement research is intentionally excluded.

## Capital Construction

{construction_markdown()}

## Endgame Scenarios

{campaign_markdown(plans)}

The approved 10 GW grid is approximately
{fmt(plans[0].power.panel_tiles + plans[0].power.grid_battery_tiles)} occupied tiles
before substations, access, and factory logistics: {fmt(plans[0].power.tandem_arrays)}
Tandem Solar Arrays and {fmt(plans[0].power.grid_battery_arrays)} Grid Battery Arrays. The
Grid Battery Arrays also represent {fmt(plans[0].power.grid_battery_array_upgrade_opportunity_dollars)}
Dollars of normal Grid Batteries that were upgraded rather than sold.

The approved design keeps the 1-billion-token objective while changing four
pressure points:

- orbital compute costs 1 Dollar per 30-second batch at every band;
- output rises from 10,000 to 25,000, 50,000, and 100,000 tokens at 1M, 10M,
  100M, and 1B cumulative tokens;
- final packaged capital is 100 allocations at 500 Dollars each, or 50,000 Dollars;
- the final sustained grid is 10 GW, with 3 MW Tandem Arrays and 1 GJ Grid Battery Arrays;
- Bitertaxi service earns 1 Dollar per 2 allocated vehicle-minutes, targeting a
  roughly 3-4 hour full-center capex payback.

At 10 GW the ending asks for about {fmt(plans[0].power.tandem_arrays)} Tandem
Arrays and {fmt(plans[0].power.grid_battery_arrays)} Grid Battery Arrays. That is still a
major factory-scale objective, but it is thousands of late assets rather than
millions of HD panels.

## Nominal Funding Time

{timing_markdown(plans)}

These times assume every office or service center is continuously saturated.
Customer growth, reservations, production, transport, and power shortages all
increase elapsed playtime. The simulator and live mod share the approved
Bitertaxi target rate.

## Recommendation

The terrestrial sequence is in the right order of magnitude: hundreds of early
sales, thousands of mass-market sales, then a 5,000-customer Bitertaxi gate. The
approved late game turns the 1-billion-token objective into a staged capital
and power campaign without requiring millions of placed power entities.

The approved case and sensitivities bound the effective ending at roughly
{fmt(plans[1].economic_burden_dollars)}-{fmt(plans[2].economic_burden_dollars)}
Dollars. The approved case is about {fmt(plans[0].economic_burden_dollars)}
Dollars, or roughly {fmt(plans[0].grid_batteries_sold_to_fund_direct_cost)} Grid Battery
sales before Bitertaxi income. Ten well-utilized Bitertaxi Depots can
meaningfully offset this capital burden, making
customer-network scale useful without making it mandatory.

## Physical Token Caveat

The one-billion milestone is cumulative production, while the final recipe
physically consumes 20,000 datasets of 50,000 Tokens each. Tokens spent on
research must therefore be replaced before the final run can be loaded. The
additional requirement is small relative to one billion, but the logistics are
deliberately physical.

## Model Sources

- Biter Motors recipes and technologies:
  `mod/bitermotors_0.1.1/data.lua`
- Runtime sales gates and Bitertaxi constants:
  `mod/bitermotors_0.1.1/control.lua`
- Nauvis orbit solar multiplier:
  <https://wiki.factorio.com/Nauvis>
- Base solar average and accumulator ratio:
  <https://wiki.factorio.com/Power_production>
"""


def recipe_block(source: str, recipe_name: str) -> str:
    marker = f'recipe("{recipe_name}"'
    start = source.find(marker)
    if start < 0:
        raise AssertionError(f"missing recipe {recipe_name}")
    next_recipe = source.find('\n  recipe("', start + len(marker))
    return source[start : next_recipe if next_recipe >= 0 else len(source)]


def validate_source_snapshot() -> list[str]:
    """Catch model drift when a modeled Lua constant changes."""
    data = DATA_LUA.read_text()
    control = CONTROL_LUA.read_text()
    errors: list[str] = []

    recipe_checks = {
        "bitermotors-sell-prototype-roadster": (
            'name = "bitermotors-dollar", amount = 2',
            "}}, 60,",
        ),
        "bitermotors-sell-premium-ev": (
            'name = "bitermotors-dollar", amount = 1',
            "}}, 30,",
        ),
        "bitermotors-sell-mass-market-ev": (
            'name = "bitermotors-dollar", amount = 1',
            "}}, 5,",
        ),
        "bitermotors-sell-megatruck": (
            'name = "bitermotors-dollar", amount = 2',
            "}}, 10,",
        ),
        "bitermotors-sell-grid-battery": (
            'name = "bitermotors-dollar", amount = 20',
            "}}, 30,",
        ),
        "bitermotors-orbital-ai-token": (
            'name = "bitermotors-dollar", amount = 1',
            'name = "bitermotors-ai-token", amount = 10000',
        ),
        "bitermotors-orbital-ai-token-cluster": (
            'name = "bitermotors-dollar", amount = 1',
            'name = "bitermotors-ai-token", amount = 25000',
        ),
        "bitermotors-orbital-ai-token-grid-scale": (
            'name = "bitermotors-dollar", amount = 1',
            'name = "bitermotors-ai-token", amount = 50000',
        ),
        "bitermotors-orbital-ai-token-hyperscale": (
            'name = "bitermotors-dollar", amount = 1',
            'name = "bitermotors-ai-token", amount = 50000',
        ),
        "bitermotors-package-capital-allocation": (
            'name = "bitermotors-dollar", amount = 500',
            'name = "bitermotors-capital-allocation", amount = 1',
        ),
        "bitermotors-planetary-grid-controller": (
            'name = "bitermotors-grid-battery-array", amount = 10',
            'name = "bitermotors-dollar", amount = 10000',
        ),
        "bitermotors-agi-training-run": (
            'name = "bitermotors-grid-battery-array", amount = 100',
            'name = "bitermotors-agi-training-dataset", amount = 20000',
            'name = "bitermotors-capital-allocation", amount = 100',
            'name = "processing-unit", amount = 10000',
        ),
    }
    for name, expected_fragments in recipe_checks.items():
        block = recipe_block(data, name)
        for fragment in expected_fragments:
            if fragment not in block:
                errors.append(f"{name} no longer contains {fragment!r}")

    source_fragments = (
        'local planetary_grid_controller = copied_assembler(\n'
        '  "assembling-machine-2",\n'
        '  "bitermotors-planetary-grid-controller",\n'
        '  planetary_grid_controller_icon,\n'
        '  "bitermotors-planetary-grid-controller",\n'
        '  {"bitermotors-planetary-grid"},\n'
        '  "10GW"',
        'tandem_solar_array.production = "3MW"',
        'grid_battery_array.energy_source.buffer_capacity = "1GJ"',
        'grid_battery_array.energy_source.input_flow_limit = "50MW"',
        'threshold = 1000000,\n    technology = "bitermotors-orbital-cluster-training"',
        '["bitermotors-orbital-ai-token-hyperscale"] = 100000',
        'high_density_space_solar_panel.production = "50MW"',
        '"750*1.5^(L-1)"',
        "BITERTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR = 2",
        "BITERTAXI_CUSTOMERS_PER_VEHICLE = 5",
    )
    combined = data + "\n" + control
    for fragment in source_fragments:
        if fragment not in combined:
            errors.append(f"modeled source fragment changed: {fragment!r}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="write the Markdown report to this path")
    parser.add_argument("--json", action="store_true", help="emit machine-readable campaign plans")
    parser.add_argument(
        "--check-source",
        action="store_true",
        help="fail if modeled Lua values no longer match the current mod",
    )
    args = parser.parse_args()

    if args.check_source:
        errors = validate_source_snapshot()
        if errors:
            for error in errors:
                print(f"ERROR: {error}")
            return 1

    if args.json:
        payload = {
            "current": asdict(campaign_plan(CURRENT)),
            "balanced_release": asdict(campaign_plan(RELEASE_CANDIDATE)),
            "demanding_release": asdict(campaign_plan(DEMANDING_RELEASE)),
        }
        output = json.dumps(payload, indent=2)
    else:
        output = report()

    if args.output:
        args.output.write_text(output.rstrip() + "\n")
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
