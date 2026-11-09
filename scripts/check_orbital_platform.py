#!/usr/bin/env python3
"""Reconcile native platform JSONL evidence; passing is not campaign qualification."""

from __future__ import annotations

import argparse
from collections import Counter
import json
import math
from pathlib import Path
import re

from validation_support import check_report

P = "bitermotors-"
CORE, SOLAR, RADIATOR = (P + suffix for suffix in (
    "orbital-datacenter-core", "high-density-space-solar-panel", "orbital-radiator-panel"))
DOLLAR, TOKEN, DATASET = (P + suffix for suffix in ("dollar", "ai-token", "agi-training-dataset"))
STARTER, FOUNDATION = "space-platform-starter-pack", "space-platform-foundation"
STATUSES = ("setup_passed", "starter_delivered", "built_passed", "mid_checkpoint",
            "mid_reload_passed", "measured_passed", "complete_checkpoint", "reload_passed")


def require(ok, message):
    if not ok:
        raise ValueError(message)


def numeric(value, name, *, integer=False, positive=False):
    require(type(value) in (int, float) and (type(value) is int or math.isfinite(value)) and value >= 0
            and (not integer or int(value) == value) and (not positive or value > 0),
            "invalid " + name)
    return value


def counts(value, name, *, positive=False):
    # Factorio can encode an empty Lua table as an array.
    if value == []:
        value = {}
    require(isinstance(value, dict), name + " must be a count mapping")
    for item, count in value.items():
        require(isinstance(item, str) and bool(item), "invalid " + name + " key")
        numeric(count, name + "." + item, integer=True, positive=positive)
    return value


def launch_contract(catalog=None):
    data = catalog.data if hasattr(catalog, "data") else catalog
    launch = data["launch"] if data is not None else {
        "capacity_grams": 1000000, "inventory_slots": 10, "parts_per_rocket": 50}
    return data, launch


def check_shipping(row, manifest, built_tick, catalog=None):
    data, launch = launch_contract(catalog)
    require(counts(row["shipped"], "shipped") == manifest
            == counts(row["delivered"], "delivered"), "manifest shipping/delivery mismatch")
    shipments = row["shipments"]
    require(isinstance(shipments, list) and bool(shipments), "missing native shipments")
    aggregate = Counter()
    for shipment in shipments:
        require(isinstance(shipment, dict), "invalid shipment")
        cargo = counts(shipment["cargo"], "cargo", positive=True)
        require(bool(cargo) and not cargo.keys() - manifest.keys(), "empty or unexpected cargo")
        numeric(shipment["mass"], "shipment mass", positive=True)
        numeric(shipment["slots"], "shipment slots", integer=True, positive=True)
        require(shipment["slots"] >= len(cargo), "cargo types exceed reported occupied slots")
        # These are the supported native 2.1 transport envelope, not recipe costs.
        require(shipment["mass"] <= launch["capacity_grams"] and shipment["slots"] <= launch["inventory_slots"],
                "shipment exceeds native mass/pod slots")
        if data is not None:
            mass = sum(launch["item_weights_grams"][item] * count for item, count in cargo.items())
            slots = sum(math.ceil(count / data["items"][item]["stack_size"]) for item, count in cargo.items())
            require(math.isclose(shipment["mass"], mass, rel_tol=1e-12, abs_tol=1e-6),
                    "shipment mass disagrees with native catalog")
            require(shipment["slots"] == slots, "shipment slots disagree with native catalog")
        tick = numeric(shipment["tick"], "shipment tick", integer=True)
        delivered = numeric(shipment["delivered_tick"], "delivery tick", integer=True)
        require(tick <= delivered <= built_tick, "invalid cargo event order")
        aggregate.update(cargo)
    require(dict(aggregate) == manifest, "shipment cargo does not conserve manifest")
    rockets = numeric(row["rockets"], "rockets", integer=True, positive=True)
    parts = numeric(row["rocket_parts"], "rocket parts", integer=True, positive=True)
    require(rockets == len(shipments), "rocket/shipments mismatch")
    # Ready rockets, internal parts and productivity can leave extra produced parts.
    # Their capacity is not reported, so only the consumed launch minimum is known.
    require(rockets * launch["parts_per_rocket"] <= parts, "rocket part accounting mismatch")
    if "rocket_input_remaining" in row:
        supplied = counts(row["rocket_supplied"], "rocket supplied")
        remaining = counts(row["rocket_input_remaining"], "rocket input remaining")
        require(bool(supplied) and not remaining.keys() - supplied.keys(), "unexpected rocket inputs")
        require(all(supplied[item] >= remaining.get(item, 0) for item in supplied),
                "rocket ingredients exceed supplied stock")
        # Per-part ingredient amounts are not reported; do not invent them here.


def check_snapshot(row, contract, *, built_tick, manifest, hardware, catalog=None):
    for field, value in contract.items():
        require(row[field] == value, "changed native contract: " + field)
        if field != "output_item":
            numeric(row[field], field, integer=field in ("cores", "batch_output", "batch_dollars", "target_batches"),
                    positive=True)
    for field in ("completions", "produced", "returned", "physical_returned", "earned_equivalents",
                  "measured_ticks", "built_tiles", "foundation_added", "low_power_samples",
                  "no_cooling_samples", "return_pods"):
        numeric(row[field], field, integer=True)
    require(row["operation_tick"] == built_tick, "operation tick does not match completed build")
    require(row["measured_ticks"] == row["tick"] - built_tick, "invalid measured tick window")
    require(row["produced"] == row["completions"] * contract["batch_output"], "batch/output mismatch")
    require(row["completions"] <= contract["target_batches"], "finite batch target exceeded")
    require(row["returned"] == row["physical_returned"] <= row["produced"], "physical pad count mismatch")
    require(row["earned_equivalents"] == row["produced"] * (50000 if contract["output_item"] == DATASET else 1),
            "earned compute does not match native output")
    require(counts(row["manifest"], "manifest") == manifest, "changed manifest")
    require(counts(row["built"], "built") == hardware, "constructed hardware mismatch")
    require(row["built_tiles"] == row["foundation_added"] == manifest[FOUNDATION], "foundation count mismatch")
    for field in ("solar_multiplier", "solar_coefficient"):
        numeric(row[field], field, positive=True)
    require(row["solar_multiplier"] == 1 and row["solar_coefficient"] == 300,
            "non-native orbital solar settings")
    require(row["low_power_samples"] == row["no_cooling_samples"] == 0, "power/cooling interruption")
    require(manifest[SOLAR] * contract["wing_nominal_watts"] * row["solar_coefficient"] / 100
            >= contract["cores"] * contract["core_rated_watts"], "insufficient orbital solar")
    products = counts(row["core_products"], "core products")
    require(len(products) <= contract["cores"] and sum(products.values()) == row["completions"],
            "per-core completion conservation mismatch")
    if row["completions"]:
        first = numeric(row["first_completion_tick"], "first completion tick", integer=True)
        last = numeric(row["last_completion_tick"], "last completion tick", integer=True)
        require(built_tick < first <= last <= row["tick"], "invalid native completion event order")
        # Include at most one initially in-progress batch per core at the boundary.
        require(row["completions"] <= row["measured_ticks"] / contract["cycle_ticks"] * contract["cores"]
                + contract["cores"], "completion rate exceeds native cycle capacity")
    check_shipping(row, manifest, built_tick, catalog)


def check_rows(logrows, expected_source_sha256=None, *, catalog=None):
    """Validate eight native lifecycle rows; return a compact evidence summary.

    The report records aggregate cargo mass/slots, not item weights/stack sizes.
    This checks those native totals and cargo conservation, not prototype capture
    or byte-for-byte engine-log/source qualification.
    """
    require(isinstance(logrows, list) and all(isinstance(row, dict) for row in logrows),
            "report rows must be objects")
    require(tuple(row.get("status") for row in logrows) == STATUSES, "expected eight statuses in order")
    try:
        setup, starter, built, mid, resumed, measured, complete, reload = logrows
        source = setup["source_sha256"]
        require(isinstance(source, str) and re.fullmatch(r"[0-9a-f]{64}", source) is not None,
                "invalid source SHA-256")
        if expected_source_sha256 is not None:
            require(source == expected_source_sha256, "unexpected source SHA-256")
        data, _ = launch_contract(catalog)
        if data is not None and "source_sha256" in data:
            require(data["source_sha256"] == source, "source SHA-256 differs from native catalog")
        require(setup["technologies_supplied"] is True, "fixture must disclose supplied technology")
        if "bulk_capacity_bonus" in setup:
            numeric(setup["bulk_capacity_bonus"], "bulk capacity bonus", integer=True)
        cores = numeric(setup["cores"], "cores", integer=True, positive=True)
        require(cores in (1, 4, 8, 12), "unsupported core count")
        require(isinstance(setup["recipe"], str) and setup["recipe"].startswith(P + "orbital-ai-"),
                "invalid orbital recipe")
        for row in logrows:
            numeric(row["tick"], "tick", integer=True)
            numeric(row["assertions"], "assertions", integer=True, positive=True)
            numeric(row["cores"], "cores", integer=True, positive=True)
            require((row["cores"], row["recipe"], row["source_sha256"])
                    == (cores, setup["recipe"], source), "changed case/source identity")
            require(row["scope"] == "native-platform-logistics" and isinstance(row["limits"], str)
                    and bool(row["limits"].strip()), "missing evidence scope/limits")
        require(all(b["tick"] >= a["tick"] and b["assertions"] >= a["assertions"]
                    for a, b in zip(logrows, logrows[1:])), "ticks/assertions moved backwards")
        require(built["tick"] > starter["tick"] and mid["tick"] > built["tick"]
                and resumed["tick"] > mid["tick"] and measured["tick"] > resumed["tick"]
                and reload["tick"] > complete["tick"], "no real build/measure/reload advancement")
        contract = {field: built[field] for field in ("cores", "output_item", "batch_output", "batch_dollars",
                    "cycle_ticks", "target_batches", "core_rated_watts", "wing_nominal_watts")}
        require(contract["output_item"] in (TOKEN, DATASET), "unsupported native output")
        for field in ("batch_output", "batch_dollars", "target_batches"):
            numeric(contract[field], field, integer=True, positive=True)
        for field in ("cycle_ticks", "core_rated_watts", "wing_nominal_watts"):
            numeric(contract[field], field, positive=True)
        require(contract["target_batches"] % cores == 0, "nonintegral per-core target")
        manifest = counts(starter["manifest"], "manifest", positive=True)
        require(manifest.get(STARTER) == 1 and manifest.get(CORE) == cores
                and manifest.get(RADIATOR, 0) >= cores and manifest.get(SOLAR, 0) > 0
                and manifest.get(FOUNDATION, 0) > 0, "missing required platform hardware")
        require(manifest.get(DOLLAR) == contract["target_batches"] * contract["batch_dollars"],
                "finite operating Dollar stock mismatch")
        hardware = {item: count for item, count in manifest.items() if item not in (STARTER, FOUNDATION, DOLLAR)}
        for row in (setup, starter):
            layout = row["layout"]
            require(layout["cores"] == cores and isinstance(layout["entities"], list), "invalid layout")
            require(dict(Counter(entry["name"] for entry in layout["entities"])) == hardware,
                    "layout entities do not match manifest")
            require(len(layout["tiles"]) >= manifest[FOUNDATION], "foundation exceeds layout tiles")
            expected = hardware if row is setup else {item: count for item, count in manifest.items() if item != STARTER}
            if row is setup and FOUNDATION in layout["manifest"]:
                # Pre-starter geometry can state planned tiles; actual shipped additions
                # are measured after native starter placement and checked separately.
                expected = {**expected, FOUNDATION: len(layout["tiles"])}
            require(counts(layout["manifest"], "layout manifest") == expected, "layout manifest mismatch")
        numeric(starter["starter_tick"], "starter tick", integer=True, positive=True)
        require(starter["starter_tick"] <= starter["tick"] and starter["starter_tick"] > setup["tick"],
                "invalid native starter delivery tick")
        for row in logrows[2:]:
            check_snapshot(row, contract, built_tick=built["tick"], manifest=manifest, hardware=hardware, catalog=catalog)
        require(built["completions"] == built["produced"] == built["returned"] == 0,
                "compute predates operation")
        for a, b in zip(logrows[2:], logrows[3:]):
            for field in ("completions", "produced", "returned", "return_pods"):
                require(b[field] >= a[field], "counter moved backwards: " + field)
            for unit, count in counts(a["core_products"], "core products").items():
                require(counts(b["core_products"], "core products").get(unit, 0) >= count,
                        "per-core counter moved backwards")
            require(a["shipments"] == b["shipments"], "completed uplift records changed")
            if a["completions"]:
                require(a["first_completion_tick"] == b["first_completion_tick"]
                        and a["last_completion_tick"] <= b["last_completion_tick"],
                        "native completion history changed")
        for checkpoint, restored in ((mid, resumed), (complete, reload)):
            for field in ("completions", "produced", "returned", "core_products", "shipments",
                          "shipped", "delivered", "rockets", "built", "built_tiles", "rocket_supplied"):
                require(checkpoint[field] == restored[field], "checkpoint/reload state mismatch: " + field)
        require(reload["saved_tick"] == complete["tick"], "final reload saved_tick mismatch")
        for field in ("completions", "produced", "returned", "core_products"):
            require(measured[field] == complete[field], "measured/checkpoint state mismatch: " + field)
        products = counts(measured["core_products"], "core products", positive=True)
        require(len(products) == cores, "not all cores participated")
        require(measured["return_pods"] > 0 and measured["returned"] > 0, "no real native output return")
        raw = measured.get("raw_baseline", False)
        require(type(raw) is bool, "invalid raw baseline marker")
        if raw:
            require(contract["output_item"] == TOKEN and cores == 1, "raw baseline must be one Token core")
            require(36000 <= measured["measured_ticks"] < 36060, "raw baseline is not bounded at 600s")
            require(0 < measured["returned"] < measured["produced"], "raw baseline has no transport deficit")
        else:
            require(contract["output_item"] == DATASET, "non-baseline case must return physical Datasets")
            require(measured["completions"] == contract["target_batches"]
                    and measured["produced"] == measured["returned"], "Dataset finite target/return incomplete")
            require(measured["completions"] > resumed["completions"], "no new completions after mid reload")
            require(0 < mid["completions"] < contract["target_batches"], "mid checkpoint is not partial work")
        data, lift = launch_contract(catalog)
        return {"cores": cores, "recipe": setup["recipe"], "source_sha256": source,
                "technologies_supplied": True, "bulk_capacity_bonus": setup.get("bulk_capacity_bonus"),
                "raw_baseline": raw, "rockets": measured["rockets"], "completions": measured["completions"],
                "minimum_launched_rocket_parts": measured["rockets"] * lift["parts_per_rocket"],
                "fixture_prebuilt_buffer_parts": measured["rocket_parts"] - measured["rockets"] * lift["parts_per_rocket"],
                "cargo_mass_slots_recomputed": data is not None,
                "produced": measured["produced"], "returned": measured["returned"],
                "measured_ticks": measured["measured_ticks"],
                "qualification": "native fixture evidence reconciled; not a natural campaign or player-time measurement"}
    except (KeyError, TypeError, AttributeError, IndexError, OverflowError) as error:
        raise ValueError(f"missing or invalid native evidence: {error}") from error


def read_report(path: Path, expected_source_sha256=None, *, catalog=None):
    check_report(path, "reload_passed", 1)
    rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    check_rows(rows, expected_source_sha256, catalog=catalog)
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    parser.add_argument("--expected-source-sha256", "--expected-source-sha")
    parser.add_argument("--catalog", type=Path, help="optional native catalog to recompute each cargo mass/slot count")
    args = parser.parse_args()
    try:
        catalog = json.loads(args.catalog.read_text()) if args.catalog else None
        rows = read_report(args.report, args.expected_source_sha256, catalog=catalog)
        print(json.dumps(check_rows(rows, args.expected_source_sha256, catalog=catalog), sort_keys=True))
    except (ValueError, OSError) as error:
        parser.exit(1, f"ERROR: {error}\n")


if __name__ == "__main__":
    main()
