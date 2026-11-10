#!/usr/bin/env python3
"""Read-only save observations and stock-aware remaining orbital budgets."""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import zipfile

from bitermotors_economy_catalog import EconomyCatalog, DOLLAR, TOKEN, amount, source_fingerprint
from model_orbital_ending import P, CORE, SCIENCE, supply_bill
from model_orbital_logistics import chapter_work, load_layouts, staged_hardware, validate_layouts


def normal_stock(snapshot):
    stock = Counter()
    for bucket in ("containers", "players", "cargo", "machine_outputs"):
        for item, qualities in snapshot["inventory"][bucket].items():
            stock[item] += qualities.get("normal", 0)
    # Science already in labs is directly usable, unlike arbitrary committed inputs.
    for item, qualities in snapshot["inventory"].get("labs", {}).items():
        if item in (*SCIENCE, TOKEN, DOLLAR):
            stock[item] += qualities.get("normal", 0)
    return dict(stock)


def sample_mod_identity(staged):
    if staged.is_dir():
        return {"sample_mod_source_sha256": source_fingerprint(staged)}
    archive = staged.with_name(staged.name + ".zip")
    if not archive.is_file():
        return {}
    with zipfile.ZipFile(archive) as package:
        prefix = staged.name + "/"
        paths = [prefix + "info.json", *sorted(n for n in package.namelist() if n.endswith(".lua"))]
        digest = hashlib.sha256()
        for name in paths:
            digest.update(name.removeprefix(prefix).encode() + b"\0")
            digest.update(package.read(name))
    return {"sample_mod_archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
            "sample_mod_source_sha256": digest.hexdigest()}


def summarize(rows, source):
    if len(rows) != 2 or [r["kind"] for r in rows] != ["initial", "final"]:
        raise ValueError("exactly initial/final observations required")
    first, last = rows
    minutes = (last["tick"] - first["tick"]) / 3600
    if minutes < 5:
        raise ValueError("at least five advancing simulated minutes required")
    if first["factorio_version"] != last["factorio_version"]:
        raise ValueError("inconsistent native versions")
    surfaces = [{s["name"]: s for s in row["surfaces"]} for row in rows]
    if surfaces[0].keys() != surfaces[1].keys():
        raise ValueError("surface set changed during sample")
    rates = {}
    for surface, initial in surfaces[0].items():
        final = surfaces[1][surface]
        for kind in ("items", "fluids"):
            for direction in ("produced", "consumed"):
                key = f"{kind}_{direction}"
                for item in initial[key].keys() | final[key].keys():
                    a = initial[key].get(item, {}).get("normal", {})
                    b = final[key].get(item, {}).get("normal", {})
                    delta = b.get("total", 0) - a.get("total", 0)
                    if delta < -1e-5:
                        raise ValueError("production statistics reset during sample")
                    row = rates.setdefault(item, {"observed_produced": 0, "observed_consumed": 0,
                                                  "historical_ten_minute_produced": 0,
                                                  "historical_hour_produced": 0})
                    row[f"observed_{direction}"] += max(0, delta) / minutes
                    if direction == "produced":
                        row["historical_ten_minute_produced"] += a.get("per_minute", {}).get("ten_minutes", 0)
                        row["historical_hour_produced"] += a.get("per_minute", {}).get("one_hour", 0)
    starting, ending = normal_stock(first), normal_stock(last)
    return {"schema": 1, "scope": "isolated-copy-current-mod-sample", "source": source,
            "factorio_version": first["factorio_version"], "mod_version": first["mod_version"],
            "play_hours": first["play_ticks"] / 216000, "sample_minutes": minutes,
            "opening_stock": starting, "closing_dollars": ending.get(DOLLAR, 0),
            "wallet_change_per_minute": (ending.get(DOLLAR, 0) - starting.get(DOLLAR, 0)) / minutes,
            "technologies": {name: row["researched"] for name, row in first["technologies"].items()},
            "entities": first["entities"], "rates_per_minute": rates,
            "force_modifiers": first["force_modifiers"],
            "business": {"taxi_dollars_per_minute": sum(d["revenue_per_minute"] for d in first.get("business", [])),
                         "grid_battery_adoption": first.get("grid_battery_adoption")},
            "limits": [first["limits"], "No external automation, player expansion or research selection during sampling.",
                       "Only normal quality stock credited, including extractable machine outputs and lab science; arbitrary machine inputs, belts and flying bots excluded.",
                       "Historical/gross output and a ten-minute wallet trend are observations, not sustainable spare capacity or guaranteed income."]}


def budget(catalog, baseline, layouts, *, hyperscale=True, observed=None):
    if any(sum(baseline["entities"].get(name, {}).values()) for name in (CORE, "space-platform-hub")):
        raise ValueError("budget starts before orbital construction; existing orbital work needs a separate plan")
    work = chapter_work(catalog, hyperscale=hyperscale)
    if observed is not None:
        if (observed.get("source_sha256") != catalog.data["source_sha256"] or
                observed.get("scope") != "qualified finite-ground-stock native physical ending" or
                len(observed.get("config", {}).get("tiers", [])) != (4 if hyperscale else 3)):
            raise ValueError("native pacing observation does not match source/route")
        for field in ("operating_dollars_used", "native_rocket_parts", "rockets", "research_dollars_consumed"):
            if type(observed.get(field)) is not int or observed[field] <= 0:
                raise ValueError("invalid native pacing counter: " + field)
        if (observed["operating_dollars_used"] < work["orbital_dollars"] or
                not math.isfinite(observed["total_minutes_including_freeplay"]) or
                observed["total_minutes_including_freeplay"] <= 0):
            raise ValueError("native pacing work/time below required floor")
        layouts = {**layouts, "stages": [dict(s, payload=dict(s["payload"])) for s in layouts["stages"]]}
        layouts["stages"][-1]["payload"] = dict(observed["manifest"], **{"space-platform-starter-pack": 1})
        validate_layouts(layouts)
    research = [r for r in work["research"] if not baseline["technologies"].get(r["technology"], False)]
    research_roots = Counter()
    for row in research:
        research_roots.update({item: count * row["cycles"] for item, count in row["science"].items()})
    # Include still-unresearched vanilla entry; do not charge an existing silo twice.
    for name in ("rocket-silo", "space-platform"):
        if not baseline["technologies"].get(name, False):
            technology = catalog.data["technologies"][name]
            if "unit" not in technology:
                if name == "space-platform" and technology.get("research_trigger", {}).get("type") == "create-space-platform":
                    continue  # The budget already includes the first starter launch.
                raise ValueError("unsupported entry research trigger: " + name)
            unit = technology["unit"]
            research_roots.update({item: unit["count"] * amount(unit["ingredients"], item) for item in SCIENCE})
    lift = staged_hardware(catalog, layouts["stages"], work)
    roots = Counter(lift["manufacturing_roots"])
    if observed is not None:
        parts = observed["native_rocket_parts"]
        if type(parts) is not int or parts < observed["rockets"] * catalog.data["launch"]["parts_per_rocket"]:
            raise ValueError("observed launch parts do not cover real rockets")
        projected_parts = lift["rockets"] * catalog.data["launch"]["parts_per_rocket"]
        for item in catalog.recipe("rocket-part")["ingredients"]:
            roots[item["name"]] += (parts - projected_parts) * item["amount"]
    for item in ("rocket-silo", "cargo-landing-pad"):
        if sum(baseline["entities"].get(item, {}).values()):
            roots[item] = 0
    roots.update(research_roots)
    bill = supply_bill(catalog, dict(roots), opening_stock=baseline["opening_stock"])
    entry_tokens = sum(row["tokens_per_cycle"] * row["cycles"] for row in research
                       if row["technology"] in (P + "autonomous-logistics", P + "orbital-compute"))
    missing_tokens = max(0, entry_tokens - baseline["opening_stock"].get(TOKEN, 0))
    terra = P + "terrestrial-ai-token"
    terra_dollars = math.ceil(missing_tokens / catalog.output(terra, TOKEN)) * catalog.ingredient(terra, DOLLAR)
    operating_cash = observed["operating_dollars_used"] if observed is not None else work["orbital_dollars"]
    cash = sum(r["cycles"] * r["dollars_per_cycle"] for r in research) + operating_cash + terra_dollars
    if observed is not None:
        scale_names = {r["name"] for r in observed["research"]}
        if scale_names <= {r["technology"] for r in research}:
            nominal = sum(catalog.research(n) for n in scale_names)
            cash += observed["research_dollars_consumed"] - nominal
    cash += bill["supplies"].get(DOLLAR, 0)
    cash_gap = max(0, cash - baseline["opening_stock"].get(DOLLAR, 0))
    adoption = baseline.get("business", {}).get("grid_battery_adoption") or {}
    finite_battery_cash = adoption.get("waiting", 0) * catalog.output(P + "sell-grid-battery", DOLLAR)
    known, unrated = [], []
    for item, count in bill["supplies"].items():
        if item == DOLLAR:
            continue
        rate = baseline["rates_per_minute"].get(item, {}).get("observed_produced", 0)
        if rate > 0:
            known.append({"item": item, "count": count, "gross_per_minute": rate, "minutes": count / rate})
        else:
            unrated.append(item)
    known.sort(key=lambda row: row["minutes"], reverse=True)
    return {"route": "Hyperscale" if hyperscale else "Grid only", "research": research,
            "operating_dollars": operating_cash,
            "cash_basis": "qualified native recipe consumption, partial lab commitments and reconfiguration losses" if observed is not None else "ideal instant-tier-change floor",
            "native_rehearsal_minutes": observed["total_minutes_including_freeplay"] if observed is not None else None,
            "native_rehearsal_rockets": observed["rockets"] if observed is not None else None,
            "science_before_stock": dict(research_roots), "entry_tokens_missing": missing_tokens,
            "direct_dollars_before_stock": cash, "cash_gap": cash_gap,
            "finite_already_eligible_battery_sales_gross": finite_battery_cash,
            "already_eligible_sales_cover_project_gap_before_other_spending": finite_battery_cash >= cash_gap,
            "funding_minutes_at_observed_wallet_trend": (cash_gap / baseline["wallet_change_per_minute"]
                 if baseline["wallet_change_per_minute"] > 0 else None),
            "ideal_compute_minutes": sum(b["one_core_hours"] / b["cores"] * 60 for b in work["bands"]),
            "conservative_separate_item_rockets": lift["rockets"],
            "materials": bill, "rated_gross_production_lower_bounds": known, "unrated_materials": unrated,
            "limits": ("Qualified native final I/O hardware and manufactured rocket parts replace the paper launch projection. " if observed is not None else "Conservative separate-item launches. ")
                + "Normal recipes without new module productivity. Gross material bounds are shared capacity, not spare output. Manufacturing, research, compute and income overlap; do not add these clocks or call them a campaign forecast."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sample", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--save-baseline", type=Path)
    parser.add_argument("--source", type=Path)
    parser.add_argument("--practical-evidence", type=Path, action="append", default=[])
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if bool(args.sample) == bool(args.baseline):
        parser.error("choose --sample or --baseline")
    if args.sample:
        rows = [json.loads(line) for line in args.sample.read_text().splitlines()]
        source = json.loads(args.source.read_text()) if args.source else {}
        source["sample_sha256"] = hashlib.sha256(args.sample.read_bytes()).hexdigest()
        staged = args.sample.parent.parent / "mods" / f"bitermotors_{rows[0]['mod_version']}"
        source.update(sample_mod_identity(staged))
        baseline = summarize(rows, source)
        if args.save_baseline:
            args.save_baseline.write_text(json.dumps(baseline, indent=2, sort_keys=True) + "\n")
    else:
        baseline = json.loads(args.baseline.read_text())
    catalog = EconomyCatalog.load()
    if catalog.freshness_errors():
        raise ValueError("fresh native economy catalog required")
    root = Path(__file__).resolve().parents[1]
    layouts = load_layouts([root / f"docs/orbital-layout-{n}.json" for n in (1, 4, 8, 12)])
    observed = [json.loads(p.read_text()) for p in args.practical_evidence]
    result = {"catalog_source_sha256": catalog.data["source_sha256"], "baseline_source": baseline["source"],
              "routes": [budget(catalog, baseline, layouts, hyperscale=h,
                    observed=next((o for o in observed if len(o.get("config", {}).get("tiers", [])) == (4 if h else 3)), None))
                         for h in (True, False)]}
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(args.output)


if __name__ == "__main__":
    main()
