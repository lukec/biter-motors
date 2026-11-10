"""Seed parsing and fail-closed checks for disposable native world audits."""

import json
import math
import re
import sys


RESOURCES = (
    "iron-ore", "copper-ore", "coal", "stone", "crude-oil", "calcite",
    "bitermotors-nickel-ore", "bitermotors-lithium-brine", "uranium-ore",
)


def parse_seed(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]+", value):
        raise ValueError("BITERMOTORS_SEED must be a decimal uint32")
    seed = int(value)
    if seed > 4294967295:
        raise ValueError("BITERMOTORS_SEED must be a decimal uint32")
    return seed


def positive(value):
    return type(value) in (int, float) and math.isfinite(value) and value > 0


def check_resources(row, expected_seed=None):
    if not isinstance(row, dict) or row.get("status") != "battery_resources_complete":
        raise ValueError("resource report missing completion sentinel")
    if row.get("radius") != 1024:
        raise ValueError("resource report must cover the existing +/-1024 square")
    seed = row.get("seed")
    if type(seed) is not int or not 0 <= seed <= 4294967295:
        raise ValueError("resource report missing valid native seed")
    if expected_seed is not None and seed != expected_seed:
        raise ValueError("resource report seed mismatch")
    if (row.get("peaceful_mode") is not False or row.get("enemy_expansion") is not True
            or row.get("pollution") is not True
            or not positive(row.get("enemy_base_frequency"))):
        raise ValueError("resource report disables enemies or pollution")
    entries = row.get("resources")
    if not isinstance(entries, dict):
        raise ValueError("resource report missing resources")
    for name in (*RESOURCES, "water", "enemy-spawners"):
        entry = entries.get(name)
        if not isinstance(entry, dict):
            raise ValueError(f"resource report missing {name}")
        count, nearest, amount = (entry.get(key) for key in ("count", "nearest", "total_amount"))
        if (type(count) is not int or count <= 0
                or type(nearest) not in (int, float) or not math.isfinite(nearest)
                or not 0 <= nearest <= math.sqrt(2) * 1024):
            raise ValueError(f"resource report invalid count/distance: {name}")
        if name in RESOURCES:
            if not positive(amount):
                raise ValueError(f"resource report invalid total_amount: {name}")
        elif amount is not None:
            raise ValueError(f"resource report non-resource amount must be null: {name}")
    for count_key, distance_key, name in (
        ("nickel_tiles", "nickel_distance", "bitermotors-nickel-ore"),
        ("lithium_wells", "lithium_distance", "bitermotors-lithium-brine"),
        ("uranium_tiles", "uranium_distance", "uranium-ore"),
    ):
        if (row.get(count_key) != entries[name]["count"]
                or row.get(distance_key) != entries[name]["nearest"]):
            raise ValueError(f"resource report legacy field mismatch: {name}")


if __name__ == "__main__":
    try:
        print(json.dumps({"seed": parse_seed(sys.argv[1])}))
    except ValueError as error:
        raise SystemExit(str(error))
