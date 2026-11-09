#!/usr/bin/env python3
"""Pure remaining-chapter budgets; native observations are not player-time forecasts."""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path

from bitermotors_economy_catalog import CATALOG, ASSEMBLE, DOLLAR, TOKEN, DATASET, EconomyCatalog
from model_orbital_ending import (Business, ModelPlan, P, CORE, SOLAR, RADIATOR,
                                 SCIENCE, research_rows, shipments, supply_bill,
                                 simulate)
from simulate_bitermotors_economy import campaign_plan


def fingerprint(data: dict) -> str:
    return hashlib.sha256(json.dumps(data, sort_keys=True, separators=(",", ":"),
                                     allow_nan=False).encode()).hexdigest()


def geometry_fingerprint(layout: dict) -> str:
    # Recipe/role metadata differs between raw and Dataset rehearsals.
    return fingerprint({"cores": layout["cores"],
                        "entities": [{key: entry[key] for key in ("name", "position", "direction")
                                      if key in entry} for entry in layout["entities"]],
                        "tiles": layout["tiles"]})


def load_layouts(paths: list[Path]) -> dict | None:
    """Reuse the canonical preview reader; keep budget schema 1 backward compatible."""
    if not paths:
        return None
    if len(paths) == 1:
        data = json.loads(paths[0].read_text())
        if isinstance(data, dict) and "stages" in data:
            validate_layouts(data)
            return data
    from render_orbital_layout import read_layouts
    stages = []
    for path in paths:
        for layout in read_layouts(path):
            payload = {item: count for item, count in layout["manifest"].items() if item != DOLLAR}
            payload.setdefault("space-platform-starter-pack", 1)
            stages.append({"cores": layout["cores"], "payload": payload,
                           "geometry_sha256": geometry_fingerprint(layout)})
    result = {"schema": 1, "stages": sorted(stages, key=lambda row: row["cores"])}
    validate_layouts(result)
    return result


def normalize_fixture_rows(rows: list[dict], manifest: dict, *, evidence: str) -> dict:
    """Normalize fixture counters only; native fixture assertions own qualification."""
    passed = [row for row in rows if row.get("status") == "measured_passed"]
    if len(passed) != 1:
        raise ValueError("expected one measured_passed row per platform report")
    row = passed[0]
    if row.get("scope") != "native-platform-logistics":
        raise ValueError("not a native platform fixture report")
    if any(entry.get("source_sha256", row.get("source_sha256")) != row.get("source_sha256")
           for entry in rows):
        raise ValueError("fixture rows have inconsistent source provenance")
    stage = next((stage for stage in validate_layouts(manifest) if stage["cores"] == row["cores"]), None)
    payload = {item: count for item, count in row["manifest"].items() if item != DOLLAR}
    if stage is None or payload != stage["payload"]:
        raise ValueError("fixture manifest does not match concrete layout")
    setup = next((entry["layout"] for entry in rows if entry.get("status") == "setup_passed"
                  and "layout" in entry), None)
    if stage.get("geometry_sha256") and (setup is None or
            geometry_fingerprint(setup) != stage["geometry_sha256"]):
        raise ValueError("fixture geometry does not match concrete layout")
    ticks = number(row["measured_ticks"], "measured ticks", positive=True, integer=True)
    for field in ("tick", "operation_tick"):
        number(row[field], field, integer=True)
    if row["tick"] - row["operation_tick"] != ticks:
        raise ValueError("fixture measured ticks disagree with operation window")
    if row.get("first_completion_tick") is not None or row.get("last_completion_tick") is not None:
        first = number(row["first_completion_tick"], "first completion tick", integer=True)
        last = number(row["last_completion_tick"], "last completion tick", integer=True)
        if not row["operation_tick"] <= first <= last <= row["tick"]:
            raise ValueError("fixture completions outside operation window")
    for field in ("completions", "produced", "returned", "physical_returned", "batch_output"):
        number(row[field], field, integer=True)
    if row["produced"] != row["completions"] * row["batch_output"]:
        raise ValueError("fixture batch/output counters disagree")
    if not 0 <= row["physical_returned"] == row["returned"] <= row["produced"]:
        raise ValueError("fixture physical return counters disagree")
    raw = row.get("raw_baseline", False)
    if type(raw) is not bool:
        raise ValueError("raw_baseline must be a boolean")
    if not raw and row["returned"] != row["produced"]:
        raise ValueError("Dataset fixture has undelivered output")
    delays = []
    for shipment in row["shipments"]:
        elapsed = shipment["delivered_tick"] - shipment["tick"]
        number(elapsed, "shipment delivery ticks", integer=True)
        delays.append(elapsed / 60)
    mid = next((entry for entry in rows if entry.get("status") == "mid_checkpoint"), None)
    midpoint = ({"elapsed_ticks": mid["measured_ticks"], "completed_batches": mid["completions"]}
                if mid is not None else None)
    return {"schema": 1, "source_sha256": row.get("source_sha256"),
            "layouts_sha256": fingerprint(manifest), "evidence": evidence,
            "provenance_status": ("source hash recorded by fixture" if row.get("source_sha256")
                                  else "unqualified: fixture source hash absent; current catalog is assumed"),
            "fixture_rows": [row],
            "runs": [{"cores": row["cores"], "recipe": row["recipe"], "elapsed_ticks": ticks,
                      "completed_batches": row["completions"], "raw_baseline": raw,
                      "midpoint": midpoint,
                      "returned_items_per_second": row["returned"] * 60 / ticks}],
            "midpoint_observations": ([{key: mid[key] for key in (
                "cores", "recipe", "measured_ticks", "completions", "produced", "returned")}] if mid is not None else []),
            "transit": None,
            "uplift_observations": [{"cores": row["cores"], "delivery_seconds": delays,
                                     "rockets": row["rockets"], "rocket_parts": row["rocket_parts"],
                                     "scope": "independent fixture platform; actual mixed/partial cargo loads",
                                     "campaign_rocket_count": False}]}


def load_measurements(paths: list[Path], manifest: dict | None, catalog=None) -> dict | None:
    if not paths:
        return None
    if len(paths) == 1:
        try:
            data = json.loads(paths[0].read_text())
        except json.JSONDecodeError:
            data = None
        if isinstance(data, dict) and data.get("schema") == 1:
            return data
    if manifest is None:
        raise ValueError("native fixture measurements require concrete layouts")
    from check_orbital_platform import read_report
    parts = []
    for path in paths:
        rows = read_report(path, catalog=catalog)
        parts.append(normalize_fixture_rows(rows, manifest, evidence=str(path)))
    hashes = {part["source_sha256"] for part in parts}
    if len(hashes) != 1:
        raise ValueError("fixture reports have inconsistent source provenance")
    result = dict(parts[0])
    for field in ("runs", "fixture_rows", "uplift_observations", "midpoint_observations"):
        result[field] = [row for part in parts for row in part[field]]
    result["evidence"] = [part["evidence"] for part in parts]
    return result


def number(value, label: str, *, positive=False, integer=False) -> float:
    if (isinstance(value, bool) or not isinstance(value, (int, float))
            or not math.isfinite(value) or value < 0 or (positive and value == 0)
            or (integer and int(value) != value)):
        raise ValueError("invalid " + label)
    return value


def validate_layouts(manifest: dict) -> list[dict]:
    """Cumulative retained hardware, not per-core estimates or fixture inventories."""
    if manifest.get("schema") != 1:
        raise ValueError("unsupported layout schema")
    stages = manifest.get("stages", [])
    if [row.get("cores") for row in stages] != [1, 4, 8, 12]:
        raise ValueError("cumulative 1/4/8/12 layout stages required")
    previous = {}
    for row in stages:
        number(row["cores"], "layout cores", positive=True, integer=True)
        payload = row["payload"]
        if not isinstance(payload, dict):
            raise ValueError("layout payload must be an item/count mapping")
        for item, count in payload.items():
            number(count, "payload count", integer=True)
        if any(payload.get(item, 0) < count for item, count in previous.items()):
            raise ValueError("cumulative layouts cannot remove retained hardware")
        if payload.get(CORE) != row["cores"] or payload.get("space-platform-starter-pack") != 1:
            raise ValueError("layout must include exact cores and one starter pack")
        if DOLLAR in payload or P + "datacenter-rack" in payload:
            raise ValueError("operating Dollars and final Rack are budgeted separately")
        if not all(payload.get(item, 0) > 0 for item in (SOLAR, RADIATOR, "space-platform-foundation")):
            raise ValueError("layout must include solar, radiators and shipped foundation")
        previous = payload
    return stages


def chapter_work(catalog: EconomyCatalog, *, hyperscale=True) -> dict:
    """Starts after earlier EV/terrestrial research, before Autonomous Logistics."""
    native = campaign_plan(catalog, cores=12, hyperscale=hyperscale)
    rows = research_rows(catalog, ModelPlan())[:5 if hyperscale else 4]
    science = {item: sum(row["cycles"] * row["science"][item] for row in rows)
               for item in SCIENCE}
    bands = [dict(band) for band in native["bands"]]
    compact_missing = []
    for index, name in enumerate((P + "orbital-ai-dataset", P + "orbital-ai-dataset-cluster")):
        if name not in catalog.data["recipes"]:
            compact_missing.append(name)
            continue
        band = bands[index]
        raw_recipe, raw_batches = band["recipe"], band["batches"]
        equivalents = (catalog.output(raw_recipe, TOKEN)
                       + catalog.output(raw_recipe, DATASET) * catalog.runtime["dataset_tokens"])
        compact_yield = catalog.output(name, DATASET) * catalog.runtime["dataset_tokens"]
        if compact_yield <= 0:
            raise ValueError("compact recipe must produce physical Datasets")
        batches = math.ceil(raw_batches * equivalents / compact_yield)
        seconds = catalog.seconds(name, CORE)
        band.update(recipe=name, batches=batches, normal_cycle_seconds=seconds,
                    dollars=batches * catalog.ingredient(name, DOLLAR),
                    one_core_hours=batches * seconds / 3600,
                    raw_equivalent_recipe=raw_recipe, raw_equivalent_batches=raw_batches,
                    raw_equivalent_dollars=native["bands"][index]["dollars"],
                    raw_equivalent_one_core_hours=native["bands"][index]["one_core_hours"],
                    compact_rounding_equivalents=batches * compact_yield - raw_batches * equivalents)
    for cores, band in zip((1, 4, 8, 12), bands):
        band["cores"] = cores
    if not hyperscale:
        grid = bands.pop()
        threshold = catalog.runtime["orbital_milestones"][2]["threshold"]
        prior = sum(band["batches"] * (catalog.output(band["recipe"], TOKEN)
                    + catalog.output(band["recipe"], DATASET) * catalog.runtime["dataset_tokens"])
                    for band in bands)
        per_batch = catalog.output(grid["recipe"], DATASET) * catalog.runtime["dataset_tokens"]
        first_batches = min(grid["batches"], math.ceil(max(0, threshold - prior) / per_batch))
        for cores, count, target in ((8, first_batches, threshold),
                                     (12, grid["batches"] - first_batches, grid["target"])):
            bands.append(dict(grid, cores=cores, batches=count, target=target,
                              dollars=count * catalog.ingredient(grid["recipe"], DOLLAR),
                              one_core_hours=count * grid["normal_cycle_seconds"] / 3600))
    return {"hyperscale": hyperscale, "research": rows, "science": science,
            "research_dollars": sum(row["cycles"] * row["dollars_per_cycle"] for row in rows),
            "terrestrial_dollars": native["terrestrial_operating_dollars"],
            "orbital_dollars": sum(row["dollars"] for row in bands),
            "compact_status": "native compact recipes modeled" if not compact_missing else "unqualified: compact catalog entries missing",
            "missing_compact_recipes": compact_missing,
            "bands": bands, "ending": catalog.model_ending()}


def staged_hardware(catalog: EconomyCatalog, stages: list[dict], work: dict) -> dict:
    previous, roots, rows = Counter(), Counter(), []
    # Both routes use the four-stage ramp; skipping Hyperscale keeps Grid at 12.
    dollars = [row["dollars"] for row in work["bands"]]
    dollars += [0] * (4 - len(dollars))
    for index, stage in enumerate(stages):
        current = Counter(stage["payload"])
        payload = current - previous
        payload[DOLLAR] += dollars[index]
        if index == 3:
            payload[P + "datacenter-rack"] += catalog.ingredient(ASSEMBLE, P + "datacenter-rack")
        transport = shipments(catalog, dict(payload))
        if transport["blocked_items"]:
            raise ValueError("unlaunchable layout: " + str(transport["blocked_items"]))
        rows.append({"cores": stage["cores"], "payload": dict(payload), **transport})
        roots.update({item: count for item, count in payload.items() if item != DOLLAR})
        previous = current
    rockets = sum(row["rockets"] for row in rows)
    parts = rockets * catalog.data["launch"]["parts_per_rocket"]
    roots.update({entry["name"]: parts * entry["amount"]
                  for entry in catalog.recipe("rocket-part")["ingredients"]})
    roots.update({"rocket-silo": 1, "cargo-landing-pad": 1})
    seconds = (parts * catalog.recipe("rocket-part").get("energy_required", 0.5)
               / catalog.data["launch"]["silo_crafting_speed"])
    return {"stages": rows, "rockets": rockets, "manufacturing_roots": dict(roots),
            "silo_assembly_seconds_lower_bound": seconds,
            "launch_policy": "modeled conservative single-item loads; rounded separately each stage",
            "qualification": "projection for one growing platform; not measured native rocket counts",
            "silo_bound_scope": "part-crafting lower bound for this projected rocket count, not all packing policies",
            "return_model_items": 1, "return_requires_rocket": False}


def manufacturing_frontier(bill: dict, rates: dict) -> dict:
    """Rates are a shared sustained units/minute budget, never per-demand allocations."""
    for item, rate in rates.items():
        number(rate, "frontier rate for " + item, positive=True)
    rows = [{"item": item, "units": count, "units_per_minute": rates.get(item),
             "minutes_lower_bound": count / rates[item] if item in rates else None}
            for item, count in bill["supplies"].items() if item != DOLLAR]
    known = sorted((row for row in rows if row["minutes_lower_bound"] is not None),
                   key=lambda row: row["minutes_lower_bound"], reverse=True)
    missing = [row["item"] for row in rows if row["minutes_lower_bound"] is None]
    return {"rows": rows, "bottlenecks": known, "unrated_items": missing,
            "known_minutes_lower_bound": known[0]["minutes_lower_bound"] if known else None,
            "all_frontier_rates_supplied": not missing,
            "qualification": "assumed rates; parallel frontier lower bound, not construction time"}


def frontier_sensitivity(bill: dict, rates: dict) -> list[dict]:
    if not rates:
        return []
    result = []
    for scale in (0.5, 1, 2):
        frontier = manufacturing_frontier(bill, {item: rate * scale for item, rate in rates.items()})
        result.append({"rate_multiplier": scale,
                       "qualification": "EXPLICIT ASSUMPTION: synthetic simultaneously sustainable frontier production rates",
                       "all_frontier_rates_supplied": frontier["all_frontier_rates_supplied"],
                       "minutes_lower_bound": frontier["known_minutes_lower_bound"],
                       "top_bottlenecks": frontier["bottlenecks"][:3]})
    return result


def measured_summary(observed: dict) -> dict:
    """Small durable native evidence, without runtime inventories or full JSONL."""
    cases = []
    for row in observed.get("fixture_rows", []):
        products = row.get("core_products", {})
        balanced = row["completions"] * row["cycle_ticks"] / (60 * row["cores"])
        busiest = max(products.values()) * row["cycle_ticks"] / 60 if products else None
        operation_seconds = row["measured_ticks"] / 60
        last_seconds = ((row["last_completion_tick"] - row["operation_tick"]) / 60
                        if row.get("last_completion_tick") is not None else None)
        cases.append({key: row[key] for key in (
            "cores", "recipe", "source_sha256", "operation_tick", "first_completion_tick",
            "last_completion_tick", "measured_ticks", "completions", "target_batches", "produced",
            "returned", "physical_returned", "batch_output", "batch_dollars", "cycle_ticks",
            "output_item", "rockets", "rocket_parts", "low_power_samples", "no_cooling_samples") if key in row})
        cases[-1].update(raw_baseline=row.get("raw_baseline", False), operation_seconds=operation_seconds,
            completion_span_seconds=((row["last_completion_tick"] - row["first_completion_tick"]) / 60
                                     if row.get("last_completion_tick") is not None and row.get("first_completion_tick") is not None else None),
            last_completion_from_operation_seconds=last_seconds,
            return_drain_after_last_completion_seconds=operation_seconds - last_seconds if last_seconds is not None else None,
            balanced_native_cycle_seconds=balanced, busiest_core_cycle_floor_seconds=busiest,
            min_core_batches=min(products.values()) if products else None, max_core_batches=max(products.values()) if products else None,
            finite_allocation_imbalance_floor_seconds=busiest - balanced if busiest is not None else None,
            scope="finite window; first/last and batch distribution are not a sustained steady-state rate")
    return {"schema": 1, "status": observed["status"], "evidence": observed.get("evidence", []),
            "cases": cases, "launch_comparisons": observed.get("launch_comparisons", []),
            "midpoint_observations": observed.get("midpoint_observations", []),
            "limits": sorted({row["limits"] for row in observed.get("fixture_rows", []) if "limits" in row}),
            "qualification": "native finite fixture observations; not actual campaign/player time"}


def observations(catalog: EconomyCatalog, manifest: dict | None, measurements: dict | None) -> dict:
    if measurements is None:
        return {"status": "unqualified: native measurements missing", "runs": [], "transit": None,
                "source_bound": False, "launch_comparisons": []}
    if measurements.get("schema") != 1:
        raise ValueError("unsupported measurement schema")
    source_unbound = (measurements.get("source_sha256") is None and "fixture_rows" in measurements)
    if not source_unbound and measurements.get("source_sha256") != catalog.data["source_sha256"]:
        raise ValueError("measurements do not match native catalog source")
    if manifest is None or measurements.get("layouts_sha256") != fingerprint(manifest):
        raise ValueError("measurements do not match concrete layouts")
    runs, keys = [], set()
    for run in measurements.get("runs", []):
        cores = number(run["cores"], "measurement cores", positive=True, integer=True)
        if cores not in (1, 4, 8, 12):
            raise ValueError("measurement cores must be 1/4/8/12")
        recipe = run["recipe"]
        native_recipe = catalog.data["recipes"].get(recipe, {})
        categories = native_recipe.get("categories", [native_recipe.get("category")])
        if (not recipe.startswith(P + "orbital-ai-") or "bitermotors-orbital-compute" not in categories
                or catalog.output(recipe, TOKEN) + catalog.output(recipe, DATASET) <= 0):
            raise ValueError("unsupported measured recipe")
        key = (cores, recipe)
        if key in keys:
            raise ValueError("duplicate measurement")
        keys.add(key)
        ticks = number(run["elapsed_ticks"], "elapsed ticks", positive=True, integer=True)
        batches = number(run["completed_batches"], "completed batches", integer=True)
        if batches > ticks / (60 * catalog.seconds(recipe, CORE)) * cores + cores:
            raise ValueError("measurement exceeds native batch capacity")
        midpoint = run.get("midpoint")
        if midpoint is not None:
            mid_ticks = number(midpoint["elapsed_ticks"], "midpoint elapsed ticks", positive=True, integer=True)
            mid_batches = number(midpoint["completed_batches"], "midpoint completed batches", integer=True)
            if not mid_ticks < ticks or not mid_batches <= batches:
                raise ValueError("midpoint is outside finite measurement window")
        runs.append({"cores": cores, "recipe": recipe, "elapsed_ticks": ticks,
                     "completed_batches": batches, "batches_per_second": batches * 60 / ticks,
                     "raw_baseline": run.get("raw_baseline", False),
                     "midpoint": midpoint,
                     "returned_items_per_second": run.get("returned_items_per_second")})
    transit = measurements.get("transit")
    if transit is not None:
        for field in ("uplift_seconds_per_rocket", "model_return_seconds"):
            number(transit[field], field)
    comparisons = []
    for row in measurements.get("fixture_rows", []):
        output = row.get("output_item")
        if output and (catalog.output(row["recipe"], output) != row["batch_output"]
                       or catalog.ingredient(row["recipe"], DOLLAR) != row["batch_dollars"]
                       or catalog.seconds(row["recipe"], CORE) * 60 != row["cycle_ticks"]):
            raise ValueError("fixture batch contract disagrees with native catalog")
        separate = shipments(catalog, row["manifest"])
        if separate["blocked_items"]:
            raise ValueError("fixture cargo is not launchable under native catalog")
        comparisons.append({"cores": row["cores"], "recipe": row["recipe"],
                            "native_fixture_rockets": row["rockets"],
                            "minimum_launched_rocket_parts": row["rockets"] * catalog.data["launch"]["parts_per_rocket"],
                            "fixture_prebuilt_buffer_parts": row["rocket_parts"] - row["rockets"] * catalog.data["launch"]["parts_per_rocket"],
                            "single_item_same_manifest_projection": separate["rockets"],
                            "scope": "same finite fixture manifest only; neither is the staged campaign count"})
    return {"status": ("unqualified source provenance: native fixture observations supplied" if source_unbound
                        else "native observations supplied; coverage reported per recipe/layout" if runs
                        else "unqualified: native throughput samples missing"),
            "runs": runs, "transit": transit,
            "source_bound": not source_unbound, "launch_comparisons": comparisons,
            "provenance_status": measurements.get("provenance_status", "source/layout hashes supplied"),
            "fixture_rows": measurements.get("fixture_rows", []),
            "uplift_observations": measurements.get("uplift_observations", []),
            "midpoint_observations": measurements.get("midpoint_observations", []),
            "evidence": measurements.get("evidence", "no fixture artifact supplied")}


def compute_delays(catalog: EconomyCatalog, work: dict, observed: dict) -> list[dict]:
    result = []
    for index, band in enumerate(work["bands"]):
        cores = band["cores"]
        run = next((row for row in observed["runs"] if row["cores"] == cores
                    and row["recipe"] == band["recipe"]), None)
        ideal = band["batches"] * band["normal_cycle_seconds"] / cores
        midpoint = run.get("midpoint") if run else None
        mid_projection = (band["batches"] * midpoint["elapsed_ticks"] / (60 * midpoint["completed_batches"])
                          if midpoint and midpoint["completed_batches"] and observed["source_bound"]
                          and not run["raw_baseline"] else None)
        result.append({"recipe": band["recipe"], "cores": cores, "batches": band["batches"],
                       "ideal_seconds": ideal,
                       "startup_to_midpoint_projection_seconds": mid_projection,
                       "observed_rate_projection_seconds": (band["batches"] / run["batches_per_second"]
                            if run and run["batches_per_second"] and not run["raw_baseline"]
                            and observed["source_bound"] else None),
                       "status": ("unqualified: raw-Token transport-deficit baseline" if run and run["raw_baseline"]
                                  else "unqualified: source hash absent" if run and not observed["source_bound"]
                                  else "unqualified: zero observed completions" if run and not run["batches_per_second"]
                                  else "finite-window drain extrapolation sensitivity; not steady throughput" if run else "unqualified: ideal inputs only")})
    return result


def analyze(catalog: EconomyCatalog, manifest: dict | None = None,
            measurements: dict | None = None, frontier_rates: dict | None = None) -> dict:
    """No mutation, file I/O, gameplay tuning, or inferred native throughput."""
    catalog.model_ending()
    stages = validate_layouts(manifest) if manifest is not None else None
    observed = observations(catalog, manifest, measurements)
    scenarios = []
    businesses = (
        Business("Modest recurring; ten settlements", 10, 2000, 500, 1, 1, 120),
        Business("Finite non-taxi; skip Hyperscale", 10, 2000, 1000, 1, 0, 0,
                 taxi_sales_gate_met=False, research_tiers=2),
    )
    for business in businesses:
        work = chapter_work(catalog, hyperscale=business.research_tiers == 3)
        cash = simulate(catalog, ModelPlan(), business)
        hardware = staged_hardware(catalog, stages, work) if stages else None
        roots = Counter(hardware["manufacturing_roots"] if hardware else {})
        roots.update(work["science"])
        # New remaining-market stock, rather than free injected sales products.
        roots.update({P + "grid-battery": business.remaining_battery_buyers,
                      P + "sales-office": business.battery_offices,
                      P + "bitertaxi-fleet": business.allocated_fleet,
                      P + "bitertaxi-depot": business.taxi_depots})
        bill = supply_bill(catalog, dict(roots))
        materials_cash = bill["supplies"].get(DOLLAR, 0)
        base_cash = work["research_dollars"] + work["terrestrial_dollars"] + work["orbital_dollars"]
        total_cash = base_cash + materials_cash
        finite_revenue = business.remaining_battery_buyers * catalog.output(P + "sell-grid-battery", DOLLAR)
        gap = max(0, total_cash - business.starting_dollars - finite_revenue)
        rate = cash["net_taxi_dollars_per_hour"]
        transit = observed["transit"]
        compute = compute_delays(catalog, work, observed)
        projections = [band["observed_rate_projection_seconds"] for band in compute]
        mid_projections = [band["startup_to_midpoint_projection_seconds"] for band in compute]
        scenarios.append({"name": business.name, "work": work, "hardware": hardware,
            "joint_manufacturing_roots": dict(roots), "joint_material_bill": bill,
            "frontier": manufacturing_frontier(bill, frontier_rates or {}),
            "frontier_sensitivity": frontier_sensitivity(bill, frontier_rates or {}),
            "cash": {"research_and_compute": base_cash, "construction_and_business_stock": materials_cash,
                     "total_before_recurring_wear": total_cash,
                     "finite_sales_revenue_ceiling": finite_revenue,
                     "finite_funding_gap": gap, "recurring_net_dollars_per_hour": rate,
                     "steady_service_hours_lower_bound": gap / rate if rate else None,
                     "hardware_included": hardware is not None,
                     "finite_market_can_fund_bill": gap == 0 if hardware else None,
                     "ideal_input_business_simulation": cash,
                     "business_simulation_scope": "unchanged ideal raw-equivalent minute model; not compact batch scheduling or physical shipping",
                     "wear_materials": "not included; native business simulation amortizes wear Dollars only"},
            "compute": compute,
            "full_window_scaled_compute_hours": sum(projections) / 3600 if all(value is not None for value in projections) else None,
            "startup_midpoint_scaled_compute_hours": sum(mid_projections) / 3600 if all(value is not None for value in mid_projections) else None,
            "transit": ({"serialized_uplift_seconds": hardware["rockets"] * transit["uplift_seconds_per_rocket"],
                         "model_return_seconds": transit["model_return_seconds"],
                         "status": "modeled single-item campaign count x assumed serialized flight delay; overlaps not scheduled"}
                        if hardware and transit else {"status": "unqualified: Model-return transit missing; any native uplift samples remain separate"})})
    summary = measured_summary(observed)
    summary.update(source_sha256=catalog.data["source_sha256"] if observed["source_bound"] else None,
                   layouts_sha256=fingerprint(manifest) if manifest else None,
                   geometry_sha256_by_cores={str(stage["cores"]): stage["geometry_sha256"]
                                             for stage in stages or [] if "geometry_sha256" in stage})
    return {"schema": 1, "source_sha256": catalog.data["source_sha256"],
            "catalog_freshness_errors": catalog.freshness_errors(),
            "layouts_sha256": fingerprint(manifest) if manifest else None,
            "qualification": "unqualified for campaign pacing; not actual player time",
            "native_observations": observed, "scenarios": scenarios,
            "measurement_summary": summary,
            "frontier_rate_assumptions": frontier_rates or {},
            "limits": (["No concrete hardware cost until --layouts is supplied."] if not stages else []) + [
                       "Scope: Autonomous Logistics through activation; earlier research/factory assumed built.",
                       "Silo, landing pad and business capacity are charged as new; no opening stock credit.",
                       "Business uses finite buyers, native adoption/referral and shared-customer fleet caps.",
                       "Recurring scenario assumes the 5,000 consumer-sales taxi gate already met.",
                       "All frontier demand shares one production allocation; blue circuits counted once.",
                       "Campaign rockets use modeled single-item packing; native mixed-load fixture flights do not replace them.",
                       "No lab capacity, build schedule, wear-material replacement, power infrastructure or movement time modeled.",
                       "Independent lower bounds are not additive and are not a finish-time forecast."]}


def report(result: dict) -> str:
    def fmt(value):
        return "unqualified" if value is None else f"{value:,.2f}"

    lines = ["# Orbital Logistics Budget", "", result["qualification"], "",
             "Native observations: " + result["native_observations"]["status"], "",
             "Measured = finite native fixture windows, not a steady plateau. Midpoint and full/drain extrapolations below are sensitivities, not bounds or actual campaign time.", "",
             "Campaign rockets/materials are modeled with conservative separate-item loads, not native mixed-load counts.", "",
             "| Scenario | Projected Rockets | Joint blue circuits | Cash before wear | Finite funding gap |",
             "| --- | ---: | ---: | ---: | ---: |"]
    for row in result["scenarios"]:
        rockets = row["hardware"]["rockets"] if row["hardware"] else "unqualified"
        blue = row["joint_material_bill"]["supplies"].get("processing-unit", 0)
        lines.append(f"| {row['name']} | {rockets} | {blue:g} | {row['cash']['total_before_recurring_wear']:g} | {row['cash']['finite_funding_gap']:g} |")
    if any(not row["hardware"] for row in result["scenarios"]):
        lines += ["", "Layouts missing: material/cash columns are partial, not full chapter totals."]
    native = result["native_observations"].get("launch_comparisons", [])
    if native:
        lines += ["", "Independent fixture flights (not a measured campaign ramp):", "",
                  "| Cores / Recipe | Native flights | Same-manifest single-item projection |",
                  "| --- | ---: | ---: |"]
        for row in native:
            lines.append(f"| {row['cores']} / {row['recipe'].removeprefix(P)} | {row['native_fixture_rockets']} | {row['single_item_same_manifest_projection']} |")
    lines.append("")
    cases = result["measurement_summary"]["cases"]
    if cases:
        lines += ["## Native Finite Windows", "",
                  "| Cores / Recipe | Produced / Pad | Full window min | Midpoint min | Batches/core range | Last completion min | Drain after last sec |",
                  "| --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
        mids = result["measurement_summary"]["midpoint_observations"]
        for case in cases:
            mid = next((row for row in mids if (row["cores"], row["recipe"]) == (case["cores"], case["recipe"])), None)
            last = case["last_completion_from_operation_seconds"]
            lines.append(f"| {case['cores']} / {case['recipe'].removeprefix(P)} | {case['produced']} / {case['returned']} | "
                         f"{fmt(case['operation_seconds'] / 60)} | {fmt(mid['measured_ticks'] / 3600 if mid else None)} | "
                         f"{case['min_core_batches']}-{case['max_core_batches']} | {fmt(last / 60 if last is not None else None)} | "
                         f"{fmt(case['return_drain_after_last_completion_seconds'])} |")
        lines += ["", "Uses measured_passed, not reload+60. The JSON preserves first/last ticks and the busiest core's cycle floor. Uneven finite Dollar allocation can account for a substantial tail; this is not a proof of a sole cause or slow steady core cycles. A larger output hand was not established as the primary fix. Raw-Token backlog is only a restricted baseline.", ""]
    for row in result["scenarios"]:
        lines += ["## " + row["name"], "",
                  "Finite sales revenue ceiling (Dollars): " + fmt(row["cash"]["finite_sales_revenue_ceiling"]),
                  "Steady service funding-only lower bound (hours): " + fmt(row["cash"]["steady_service_hours_lower_bound"]),
                  "Frontier known lower bound (minutes): " + fmt(row["frontier"]["known_minutes_lower_bound"])
                  + "; unrated items: " + str(len(row["frontier"]["unrated_items"])),
                  "Transit: " + row["transit"]["status"], "",
                  "| Recipe | Cores | Ideal min | Startup-midpoint projection min | Full-drain projection min |",
                  "| --- | ---: | ---: | ---: | ---: |"]
        for band in row["compute"]:
            measured = band["observed_rate_projection_seconds"]
            midpoint = band["startup_to_midpoint_projection_seconds"]
            lines.append(f"| {band['recipe'].removeprefix(P)} | {band['cores']} | {fmt(band['ideal_seconds'] / 60)} | "
                         f"{fmt(midpoint / 60 if midpoint is not None else None)} | {fmt(measured / 60 if measured is not None else None)} |")
        lines += ["", f"Compute-only extrapolations: startup-midpoint {fmt(row['startup_midpoint_scaled_compute_hours'])} hours; finite-drain {fmt(row['full_window_scaled_compute_hours'])} hours. Not player time.", ""]
    lines += ["## Explicit Manufacturing Assumption", "",
              "Synthetic simultaneously sustainable units/minute; zero opening material stock. Not native campaign production. Each joint frontier item is shown; blue circuits are one shared allocation, and advanced circuits are already expanded, not another frontier bottleneck.", "",
              "| Frontier | Assumed units/min | Recurring demand | Finite demand |",
              "| --- | ---: | ---: | ---: |"]
    keys = sorted(set().union(*(set(row["joint_material_bill"]["supplies"]) for row in result["scenarios"])) - {DOLLAR})
    for item in keys:
        quantities = [row["joint_material_bill"]["supplies"].get(item, 0) for row in result["scenarios"]]
        lines.append(f"| {item} | {fmt(result['frontier_rate_assumptions'].get(item))} | {fmt(quantities[0])} | {fmt(quantities[1])} |")
    lines += ["", "| Scenario / Rate multiplier | Shared material lower bound min (hours) | Top bottlenecks: demand / rate |",
              "| --- | ---: | --- |"]
    for row in result["scenarios"]:
        for sensitivity in row["frontier_sensitivity"]:
            minutes = sensitivity["minutes_lower_bound"]
            top = "; ".join(f"{b['item']}: {b['units']:g} / {b['units_per_minute']:g}" for b in sensitivity["top_bottlenecks"])
            lines.append(f"| {row['name']} / {sensitivity['rate_multiplier']}x | {fmt(minutes)} ({fmt(minutes / 60 if minutes is not None else None)}) | {top} |")
    lines += ["", "## Verdict", "",
              "The 4-6 active-hour goal is not qualified. The finite-window compute sensitivities exclude construction, manufacturing and cash/cargo scheduling; the synthetic 1x material profile can exceed six simulated hours on its own. Startup-to-midpoint is less pessimistic but not a sustained measurement. Do not add max-parallel material bounds to cash or compute clocks as proven wall time; there is no free-grind or actual-player-time claim.", "",
              "Remaining bottleneck: shared manufacturing and financing/construction logistics, with finite Dollar distribution/tail uncertainty. These measurements do not establish an intrinsically slow native core cycle or prove cargo is the sole overhead.", "",
              "Modest business: ten settlements, 2,000 population, 500 finite battery buyers, one office/depot and 120 fleet; taxi sales gate assumed met. Finite alternative: 1,000 battery buyers, no taxi, no Hyperscale. Opening wallet 2,000 Dollars each; all remaining sales stock is charged. Finite revenue is a ceiling, not immediate cash. No funding gap does not prove finishability. The finite route uses Grid-scale/8 from 10M to 100M, then Grid-scale/12 through the gate, with no extra research or compute Dollars. The unchanged raw-equivalent minute business simulation remains at 8 cores in that case and is not used for these compute projections or compact batch/ship scheduling.", "",
              "Native spare prebuilt rocket parts are reported in JSON and not charged as minimum launch ingredients. Independent fresh-platform mixed flights do not replace the modeled staged single-item campaign count."]
    lines += result["catalog_freshness_errors"] + ["", *result["limits"], "",
        "Native catalog source SHA-256: `" + result["source_sha256"] + "`.", ""]
    return "\n".join(lines)


def report_data(result: dict) -> dict:
    """Serializable budget evidence without raw fixture inventories/snapshots."""
    return dict(result, native_observations={key: value for key, value in result["native_observations"].items()
                                           if key != "fixture_rows"})


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=CATALOG)
    parser.add_argument("--layouts", type=Path, action="append", default=[],
                        help="budget manifest or canonical layout export; repeat for four exports")
    parser.add_argument("--measurements", type=Path, action="append", default=[],
                        help="normalized schema 1 JSON or completed native JSONL; repeat for fixture cases")
    parser.add_argument("--frontier-rates", type=Path)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--summary-json", action="store_true", help="small normalized native evidence summary only")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    def read(path):
        return json.loads(path.read_text()) if path else None
    try:
        catalog = EconomyCatalog.load(args.catalog)
        if errors := catalog.freshness_errors():
            raise ValueError("; ".join(errors))
        manifest = load_layouts(args.layouts)
        measurements = load_measurements(args.measurements, manifest, catalog)
        result = analyze(catalog, manifest, measurements, read(args.frontier_rates))
        if args.json and args.summary_json:
            raise ValueError("choose --json or --summary-json, not both")
        output = (json.dumps(result["measurement_summary"] if args.summary_json else report_data(result), indent=2, allow_nan=False)
                  if args.json or args.summary_json else report(result))
        if args.output:
            args.output.write_text(output.rstrip() + "\n")
        else:
            print(output)
    except (ValueError, KeyError, TypeError, OSError) as error:
        parser.exit(1, f"ERROR: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
