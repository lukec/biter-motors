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
DATA_LUA = REPO_ROOT / "mod/bitermotors_0.1.0/data.lua"
CONTROL_LUA = REPO_ROOT / "mod/bitermotors_0.1.0/control.lua"

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
    "megapack": Sale("Megapack", 20, 30),
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
        "Energy Products",
        500,
        "250 Premium EVs produced before battery research appears",
        "500 Premium EV sales fund Advanced Battery Chemistry and Energy Products.",
    ),
    ProgressionStage(
        "Mass-market EV",
        1_300,
        "250 Premium EVs sold",
        "1,300 Premium EVs, or 65 Megapack sales after Energy Products unlocks.",
    ),
    ProgressionStage(
        "Robotaxi",
        3_000,
        "5,000 cumulative consumer EVs sold",
        "Terrestrial AI research, 1,000 terrestrial tokens, and Autonomous Logistics.",
    ),
    ProgressionStage(
        "Orbital Compute",
        4_000,
        "Rocket and orbital prerequisites",
        "2,000 terrestrial tokens plus 2,000 Dollars of research.",
    ),
    ProgressionStage(
        "Planetary Grid",
        2_525,
        "Orbital Compute and Autonomous Logistics",
        "2,500 Dollars of research plus about 25 Dollars for 2,500 orbital tokens.",
    ),
    ProgressionStage(
        "Grid Controller",
        11_000,
        "Planetary Grid researched",
        "10,000 Dollars directly plus 100 Gigafactory Modules worth 1,000 Dollars.",
    ),
)


@dataclass(frozen=True)
class Balance:
    name: str
    ai_target: float
    orbital_tokens_per_cycle: float
    orbital_dollars_per_cycle: float
    final_capital_dollars: float
    final_power_watts: float
    robotaxi_vehicle_minutes_per_dollar: float
    solar_productivity: float


CURRENT = Balance(
    name="Current alpha",
    ai_target=1_000_000_000,
    orbital_tokens_per_cycle=10_000,
    orbital_dollars_per_cycle=100,
    final_capital_dollars=10_000_000,
    final_power_watts=1_000_000_000_000,
    robotaxi_vehicle_minutes_per_dollar=100,
    solar_productivity=0,
)

RELEASE_CANDIDATE = Balance(
    name="Balanced release",
    ai_target=1_000_000_000,
    orbital_tokens_per_cycle=10_000,
    orbital_dollars_per_cycle=1,
    final_capital_dollars=100_000,
    final_power_watts=10_000_000_000,
    robotaxi_vehicle_minutes_per_dollar=5,
    solar_productivity=0.40,
)

DEMANDING_RELEASE = Balance(
    name="Demanding release",
    ai_target=1_000_000_000,
    orbital_tokens_per_cycle=10_000,
    orbital_dollars_per_cycle=2,
    final_capital_dollars=250_000,
    final_power_watts=25_000_000_000,
    robotaxi_vehicle_minutes_per_dollar=10,
    solar_productivity=0.40,
)

AI_EFFICIENCY_THRESHOLDS = (1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000)
AI_EFFICIENCY_RESEARCH_DOLLARS = tuple(value / 10 for value in AI_EFFICIENCY_THRESHOLDS)

HD_SOLAR_PEAK_WATTS = 300_000
NAUVIS_SOLAR_AVERAGE_FRACTION = 0.70
HD_SOLAR_BATCH_INPUT_DOLLARS = 3
HD_SOLAR_BATCH_OUTPUT = 4
MEGAPACK_CAPACITY_JOULES = 100_000_000
MEGAPACK_SALE_DOLLARS = 20
BASE_SOLAR_PANEL_PEAK_WATTS = 60_000
BASE_ACCUMULATOR_CAPACITY_JOULES = 5_000_000
BASE_ACCUMULATORS_PER_PANEL = 0.84

GRID_CONTROLLER_CONSUMED_MEGAPACKS = 100
FINAL_RUN_CONSUMED_MEGAPACKS = 1_000
CONSUMED_MEGAPACKS = GRID_CONTROLLER_CONSUMED_MEGAPACKS + FINAL_RUN_CONSUMED_MEGAPACKS
RECOMMENDED_PROGRESSION_CONSTRUCTION_DOLLARS = 275
PRE_ENDGAME_DOLLARS = (
    sum(stage.incremental_dollars for stage in PROGRESSION)
    + RECOMMENDED_PROGRESSION_CONSTRUCTION_DOLLARS
)

ROBOTAXI_FLEET_DOLLARS = 100
ROBOTAXI_FLEETS_PER_CENTER = 200
ROBOTAXI_CENTER_FIXED_DOLLARS = 75 + 200 + 200 + 4
ROBOTAXI_CENTER_CAPEX = (
    ROBOTAXI_FLEETS_PER_CENTER * ROBOTAXI_FLEET_DOLLARS
    + ROBOTAXI_CENTER_FIXED_DOLLARS
)
ROBOTAXI_CUSTOMERS_PER_FLEET = 5
ORBITAL_CORE_WATTS = 250_000_000
ORBITAL_PANEL_PEAK_WATTS = 50_000_000
NAUVIS_ORBIT_SOLAR_MULTIPLIER = 3
RADIATORS_PER_CORE = 8


@dataclass(frozen=True)
class AiPlan:
    efficiency_level: int
    efficiency_research_dollars: float
    operating_dollars: float
    total_dollars: float
    final_multiplier: float
    one_core_hours: float


@dataclass(frozen=True)
class PowerPlan:
    watts: float
    panels: int
    megapacks: int
    panel_recipe_dollars: float
    solar_research_dollars: float
    megapack_opportunity_dollars: float
    panel_tiles: int
    megapack_tiles: int


@dataclass(frozen=True)
class CampaignPlan:
    balance: str
    ai: AiPlan
    power: PowerPlan
    pre_endgame_dollars: float
    final_capital_dollars: float
    orbital_panel_dollars: float
    consumed_megapack_opportunity_dollars: float
    direct_dollars: float
    economic_burden_dollars: float
    megapacks_sold_to_fund_direct_cost: float
    megapacks_manufactured: float
    mass_market_ev_equivalent: float


def ai_plan(balance: Balance, max_efficiency_level: int) -> AiPlan:
    """Model sequential AI-efficiency unlocks and research."""
    if not 0 <= max_efficiency_level <= len(AI_EFFICIENCY_THRESHOLDS):
        raise ValueError("invalid AI efficiency level")

    generated = 0.0
    operating_dollars = 0.0
    research_dollars = 0.0
    level = 0

    for threshold, research_cost in zip(
        AI_EFFICIENCY_THRESHOLDS[:max_efficiency_level],
        AI_EFFICIENCY_RESEARCH_DOLLARS[:max_efficiency_level],
    ):
        segment_target = min(float(threshold), balance.ai_target)
        if segment_target > generated:
            tokens_per_dollar = (
                balance.orbital_tokens_per_cycle * (1 + level * 0.10)
                / balance.orbital_dollars_per_cycle
            )
            operating_dollars += (segment_target - generated) / tokens_per_dollar
            generated = segment_target
        if generated < threshold:
            break
        research_dollars += research_cost
        level += 1

    if generated < balance.ai_target:
        tokens_per_dollar = (
            balance.orbital_tokens_per_cycle * (1 + level * 0.10)
            / balance.orbital_dollars_per_cycle
        )
        operating_dollars += (balance.ai_target - generated) / tokens_per_dollar

    tokens_per_hour = balance.orbital_tokens_per_cycle * (1 + level * 0.10) * 120
    return AiPlan(
        efficiency_level=level,
        efficiency_research_dollars=research_dollars,
        operating_dollars=operating_dollars,
        total_dollars=research_dollars + operating_dollars,
        final_multiplier=1 + level * 0.10,
        one_core_hours=balance.ai_target / tokens_per_hour,
    )


def optimal_ai_plan(balance: Balance) -> AiPlan:
    return min(
        (ai_plan(balance, level) for level in range(len(AI_EFFICIENCY_THRESHOLDS) + 1)),
        key=lambda plan: plan.total_dollars,
    )


def power_plan(balance: Balance) -> PowerPlan:
    average_panel_watts = HD_SOLAR_PEAK_WATTS * NAUVIS_SOLAR_AVERAGE_FRACTION
    panels = math.ceil(balance.final_power_watts / average_panel_watts)

    megapacks_per_panel = (
        BASE_ACCUMULATORS_PER_PANEL
        * (HD_SOLAR_PEAK_WATTS / BASE_SOLAR_PANEL_PEAK_WATTS)
        * (BASE_ACCUMULATOR_CAPACITY_JOULES / MEGAPACK_CAPACITY_JOULES)
    )
    megapacks = math.ceil(panels * megapacks_per_panel)
    batch_dollars_per_panel = HD_SOLAR_BATCH_INPUT_DOLLARS / HD_SOLAR_BATCH_OUTPUT
    standard_dollars_per_panel = 1 / (1 + balance.solar_productivity)
    use_productive_standard_recipe = standard_dollars_per_panel < batch_dollars_per_panel
    panel_recipe_dollars = panels * min(
        batch_dollars_per_panel,
        standard_dollars_per_panel,
    )
    productivity_levels = round(balance.solar_productivity / 0.10)
    solar_research_dollars = 0.0
    if use_productive_standard_recipe:
        solar_research_dollars = sum(
            750 * 1.5**level for level in range(productivity_levels)
        )
    return PowerPlan(
        watts=balance.final_power_watts,
        panels=panels,
        megapacks=megapacks,
        panel_recipe_dollars=panel_recipe_dollars,
        solar_research_dollars=solar_research_dollars,
        megapack_opportunity_dollars=megapacks * MEGAPACK_SALE_DOLLARS,
        panel_tiles=panels * 9,
        megapack_tiles=megapacks * 4,
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
    consumed_megapack_opportunity = CONSUMED_MEGAPACKS * MEGAPACK_SALE_DOLLARS
    direct_dollars = (
        PRE_ENDGAME_DOLLARS
        + ai.total_dollars
        + balance.final_capital_dollars
        + power.panel_recipe_dollars
        + power.solar_research_dollars
        + orbital_panel_dollars
    )
    economic_burden = (
        direct_dollars
        + power.megapack_opportunity_dollars
        + consumed_megapack_opportunity
    )
    megapacks_sold = direct_dollars / SALES["megapack"].dollars
    return CampaignPlan(
        balance=balance.name,
        ai=ai,
        power=power,
        pre_endgame_dollars=PRE_ENDGAME_DOLLARS,
        final_capital_dollars=balance.final_capital_dollars,
        orbital_panel_dollars=orbital_panel_dollars,
        consumed_megapack_opportunity_dollars=consumed_megapack_opportunity,
        direct_dollars=direct_dollars,
        economic_burden_dollars=economic_burden,
        megapacks_sold_to_fund_direct_cost=megapacks_sold,
        megapacks_manufactured=megapacks_sold + power.megapacks + CONSUMED_MEGAPACKS,
        mass_market_ev_equivalent=economic_burden / SALES["mass_market"].dollars,
    )


def robotaxi_revenue_per_hour(balance: Balance, centers: int) -> float:
    vehicle_minutes_per_minute = (
        centers * ROBOTAXI_FLEETS_PER_CENTER
    )
    return vehicle_minutes_per_minute / balance.robotaxi_vehicle_minutes_per_dollar * 60


def robotaxi_hours_to_net(balance: Balance, centers: int, target_dollars: float) -> float:
    capex = centers * ROBOTAXI_CENTER_CAPEX
    return (target_dollars + capex) / robotaxi_revenue_per_hour(balance, centers)


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


def campaign_markdown(plans: Iterable[CampaignPlan]) -> str:
    plans = tuple(plans)
    lines = [
        "| Metric | " + " | ".join(plan.balance for plan in plans) + " |",
        "|---|" + "|".join("---:" for _ in plans) + "|",
    ]
    rows = (
        ("Final grid", lambda p: fmt_power(p.power.watts)),
        ("Optimal orbital AI efficiency", lambda p: f"Level {p.ai.efficiency_level}"),
        ("AI operating + efficiency Dollars", lambda p: fmt(p.ai.total_dollars)),
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
        ("HD solar panels", lambda p: fmt(p.power.panels)),
        ("Grid Megapacks", lambda p: fmt(p.power.megapacks)),
        ("HD-panel recipe Dollars", lambda p: fmt(p.power.panel_recipe_dollars)),
        ("Solar productivity research Dollars", lambda p: fmt(p.power.solar_research_dollars)),
        ("HD panels embedded in orbital solar", lambda p: fmt(p.orbital_panel_dollars)),
        (
            "Unsold Megapack opportunity cost",
            lambda p: fmt(
                p.power.megapack_opportunity_dollars
                + p.consumed_megapack_opportunity_dollars
            ),
        ),
        ("Direct Dollars required", lambda p: fmt(p.direct_dollars)),
        ("Total economic burden", lambda p: fmt(p.economic_burden_dollars)),
        ("Megapacks sold to fund direct Dollars", lambda p: fmt(p.megapacks_sold_to_fund_direct_cost)),
        ("Total Megapacks manufactured", lambda p: fmt(p.megapacks_manufactured)),
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
            plan.megapacks_sold_to_fund_direct_cost
            / (SALES["megapack"].dollars_per_hour / SALES["megapack"].dollars * offices)
            for plan in plans
        ]
        lines.append(
            f"| {offices} saturated Megapack Sales Offices | "
            + " | ".join(f"{fmt(value, 1)} h" for value in hours)
            + " |"
        )
    for centers in (10, 50, 100):
        lines.append(
            f"| {centers} full Robotaxi Service Centers, net of fleet capex | "
            + " | ".join(
                f"{fmt(robotaxi_hours_to_net(balance, centers, plan.direct_dollars), 1)} h"
                for balance, plan in zip((CURRENT, RELEASE_CANDIDATE, DEMANDING_RELEASE), plans)
            )
            + " |"
        )
    return "\n".join(lines)


def construction_markdown() -> str:
    rows = (
        ("Gigafactory V1", "100", "10 Gigafactory Modules"),
        ("Gigafactory V2 upgrade", "150", "Gigacast plus the V2 recipe"),
        ("V3 Supercharger upgrade", "75", "Direct recipe capital"),
        (
            "V4 Supercharger upgrade",
            "204 direct / 284 effective",
            "200 Dollars, 4 HD panels, and 4 unsold Megapacks",
        ),
        (
            "Full Robotaxi Service Center",
            f"{fmt(ROBOTAXI_CENTER_CAPEX)} direct / {fmt(ROBOTAXI_CENTER_CAPEX + 80)} effective",
            "200 fleets, charger chain, center, and four unsold Megapacks",
        ),
        (
            "Planetary Grid Controller",
            "11,000 direct / 13,000 effective",
            "10,000 direct, 100 Gigafactory Modules, and 100 unsold Megapacks",
        ),
        (
            "AGI recipe Megapacks",
            "20,000 effective",
            "1,000 unsold Megapacks, separate from grid storage",
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
        ("Premium EV", "125 Roadsters", 250, 250, 0),
        ("Energy Products", "500 Premium EVs", 500, 500, 0),
        ("Mass-market + Giga V2 + solar gate", "79 Megapacks", 1_580, 1_575, 5),
        ("Robotaxi", "4,375 Mass-market EVs", 4_375, 3_000, 1_380),
        ("Orbital Compute", "131 Megapacks", 2_620, 4_000, 0),
        ("Planetary Grid + controller", "677 Megapacks", 13_540, 13_525, 15),
    )
    lines = [
        "| Milestone funded | Products sold in this step | Profit raised | Spend | Cash after |",
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

This is a strategic lower-bound model of the current alpha economy and two
release-candidate rebalances. It models current recipe profits, required Dollars,
AI efficiency, final power, and solar storage. It excludes raw ore throughput,
customer-acquisition delay, quality, modules, and factory build time, so real
playtime will be longer.

One in-game Dollar represents `${DOLLAR_USD:,}` USD of profit.

## Sale Economics

{sale_markdown()}

## Terrestrial Progression

{progression_markdown()}

The physical sales gates remain important, but capital is already the tighter
gate at Premium EV: the 50 required Roadsters produce only 100 of the 250
Dollars needed for research. Once Energy Products unlocks, 20-Dollar Megapack
sales can fund later research much more efficiently than one-Dollar EV sales.

### Practical Mixed-Sales Path

{practical_progression_markdown()}

This path reaches a built Planetary Grid Controller with **5,000 consumer EVs
sold plus 887 Megapacks sold**. It deliberately uses the required consumer sales
to fund Robotaxi research before leaning on Megapacks again. Building the
controller also retains 100 additional Megapacks rather than selling them. An
EV-only path needs approximately **125 Roadsters, 2,075 Premium EVs, and 20,525
Mass-market EVs**, or 22,725 total consumer-vehicle sales. Neither path includes
the final AI run, final capital package, optional branches, or raw science-pack
costs.

Recommended construction around the mass-market transition adds about 275
Dollars: 100 for Gigafactory V1, 150 more for V2, and 25 for the solar-panel
production gate. A fully stocked Robotaxi Service Center costs about
{fmt(ROBOTAXI_CENTER_CAPEX)} Dollars, serves {fmt(ROBOTAXI_FLEETS_PER_CENTER * ROBOTAXI_CUSTOMERS_PER_FLEET)}
customers, and currently earns only {fmt(robotaxi_revenue_per_hour(CURRENT, 1))}
Dollars/hour.

Optional finite branches add 1,250 Dollars: 250 for Megatruck Engineering, 250
for Battery Material Recovery, and 750 for Cybertrain Logistics. Infinite
improvement research is intentionally excluded.

## Capital Construction

{construction_markdown()}

## Endgame Scenarios

{campaign_markdown(plans)}

The current alpha's 1 TW solar-only grid is approximately
{fmt(plans[0].power.panel_tiles + plans[0].power.megapack_tiles)} occupied tiles
before substations, access, and factory logistics. Its installed Megapacks also
represent {fmt(plans[0].power.megapack_opportunity_dollars)} Dollars of products
that cannot be sold. This makes the effective ending closer to
{fmt(plans[0].economic_burden_dollars)} Dollars than the visible 10-million-Dollar
capital package suggests.

Both release scenarios keep the 1-billion-token objective while changing four
pressure points:

- orbital compute consumes 1-2 Dollars rather than 100 per 10,000-token cycle;
- final packaged capital falls from 10,000,000 to 100,000-250,000 Dollars;
- the final sustained grid falls from 1 TW to 10-25 GW;
- Robotaxi service pays 1 Dollar per 5-10 vehicle-minutes rather than per 100.

At 10 GW the ending still asks for about {fmt(plans[1].power.panels)} HD panels
and {fmt(plans[1].power.megapacks)} Megapacks. That is roughly 200 times the
47 MW peak grid observed in the prior late-terrestrial playtest, so it remains
a major factory-scale objective.

## Nominal Funding Time

{timing_markdown(plans)}

These times assume every office or service center is continuously saturated.
Customer growth, reservations, production, transport, and power shortages all
increase elapsed playtime.

## Recommendation

The terrestrial sequence is in the right order of magnitude: hundreds of early
sales, thousands of mass-market sales, then a 5,000-customer Robotaxi gate. The
release blocker is the endgame multiplier. The current ending turns that
thousand-sale economy into a 20-to-40-million-Dollar economy and requires
millions of placed power entities.

The two release simulations bound the effective ending at roughly
{fmt(plans[1].economic_burden_dollars)}-{fmt(plans[2].economic_burden_dollars)}
Dollars. Start with the balanced case because every omitted system makes real
play slower. That target is about 20,000-25,000 Megapack-equivalent products, or
400,000-500,000 one-Dollar EV sales before mixing in Robotaxi income. Ten
well-utilized, rebalanced Robotaxi Service Centers could repay their fleet and
contribute the direct endgame capital in about 20 hours, making
customer-network scale useful without making it mandatory.

## Release Issues Found

The progress interface currently says to package 1 billion AI Tokens into
100,000 datasets. The recipe actually consumes 50,000 tokens per dataset and
20,000 datasets, which correctly equals 1 billion. The interface text is stale
and should say 20,000.

## Model Sources

- Biter Motors recipes and technologies:
  `mod/bitermotors_0.1.0/data.lua`
- Runtime sales gates and Robotaxi constants:
  `mod/bitermotors_0.1.0/control.lua`
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
        "bitermotors-sell-megapack": (
            'name = "bitermotors-dollar", amount = 20',
            "}}, 30,",
        ),
        "bitermotors-orbital-ai-token": (
            'name = "bitermotors-dollar", amount = 100',
            'name = "bitermotors-ai-token", amount = 10000',
        ),
        "bitermotors-package-capital-allocation": (
            'name = "bitermotors-dollar", amount = 10000',
            'name = "bitermotors-capital-allocation", amount = 1',
        ),
        "bitermotors-planetary-grid-controller": (
            'name = "bitermotors-megapack", amount = 100',
            'name = "bitermotors-dollar", amount = 10000',
        ),
        "bitermotors-agi-training-run": (
            'name = "bitermotors-megapack", amount = 1000',
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
        '  "1TW"',
        'high_density_space_solar_panel.production = "50MW"',
        '"750*1.5^(L-1)"',
        "ROBOTAXI_REVENUE_VEHICLE_MINUTES_PER_DOLLAR = 100",
        "ROBOTAXI_CUSTOMERS_PER_VEHICLE = 5",
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
