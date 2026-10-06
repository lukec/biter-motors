#!/usr/bin/env python3
"""Check final engine recipes, not Lua source or a copied recycling simulator."""

import argparse
import json
import math
from pathlib import Path


APPROVED = {
    "electric-furnace": {"steel-plate": 10, "electronic-circuit": 10, "stone-brick": 10},
    "big-mining-drill": {"electric-mining-drill": 4, "engine-unit": 20, "electronic-circuit": 20},
    "foundry": {"electric-furnace": 25, "electronic-circuit": 50, "refined-concrete": 200},
    "recycler": {"steel-plate": 20, "iron-gear-wheel": 40, "electronic-circuit": 20, "concrete": 20},
    "teslagun": {"bitermotors-high-energy-battery-pack": 4, "processing-unit": 10, "steel-plate": 20},
    "tesla-turret": {"teslagun": 1, "bitermotors-high-energy-battery-pack": 10, "processing-unit": 20, "accumulator": 4},
    "tesla-ammo": {"bitermotors-high-nickel-cell": 1, "advanced-circuit": 2, "copper-cable": 10},
    "stack-inserter": {"bulk-inserter": 1, "electric-engine-unit": 2, "processing-unit": 2, "low-density-structure": 5},
    "personal-roboport-mk2-equipment": {"personal-roboport-equipment": 5, "processing-unit": 100, "low-density-structure": 20},
    "battery-mk3-equipment": {"battery-mk2-equipment": 2, "bitermotors-high-energy-battery-pack": 4, "processing-unit": 10},
    "cliff-explosives": {"explosives": 10, "grenade": 1, "barrel": 1},
    "artillery-wagon": {"engine-unit": 64, "iron-gear-wheel": 10, "steel-plate": 40, "advanced-circuit": 20},
    "artillery-turret": {"steel-plate": 60, "concrete": 60, "iron-gear-wheel": 40, "advanced-circuit": 20},
    "artillery-shell": {"explosive-cannon-shell": 4, "radar": 1, "explosives": 8},
}
for family in ("speed", "productivity", "efficiency", "quality"):
    APPROVED[f"{family}-module-3"] = {
        f"{family}-module-2": 4, "advanced-circuit": 5,
        "processing-unit": 5, "bitermotors-dollar": 10,
    }

RECOVERY = {
    "high-energy": "bitermotors-high-nickel-cell",
    "lfp": "bitermotors-lfp-cell",
}


def item_amounts(rows):
    result = {}
    for row in rows:
        if row.get("type", "item") != "item" or row["name"] in result:
            raise ValueError(f"non-item or duplicate recipe entry: {row}")
        if any(row.get(key, 1) != 1 for key in ("probability", "independent_probability")):
            raise ValueError(f"unexpected probabilistic recipe entry: {row}")
        if "amount_min" in row or "amount_max" in row:
            raise ValueError(f"unexpected random recipe amount: {row}")
        result[row["name"]] = row.get("amount", 0) + row.get("extra_count_fraction", 0)
    return result


def validate(data):
    assertions = 0

    def require(condition, label):
        nonlocal assertions
        if not condition:
            raise ValueError(label)
        assertions += 1

    recipes = data["recipe"]
    unlocks = [effect.get("recipe") for effect in data["technology"]["recycling"]["effects"]
               if effect["type"] == "unlock-recipe"]
    for name, approved in APPROVED.items():
        forward = recipes[name]
        require(item_amounts(forward["ingredients"]) == approved, f"{name}: forward ingredients changed")
        require(item_amounts(forward["results"]) == {name: 1}, f"{name}: unsupported forward product")
        require(not forward.get("surface_conditions") and not forward.get("recycle_to_ingredients_of"),
                f"{name}: non-terrestrial recipe or stale recycling alias")
        reverse_name = f"{name}-recycling"
        reverse = recipes[reverse_name]
        require(item_amounts(reverse["ingredients"]) == {name: 1}, f"{reverse_name}: wrong input")
        actual = item_amounts(reverse["results"])
        expected = {item: amount / 4 for item, amount in approved.items()}
        require(actual.keys() == expected.keys() and all(math.isclose(actual[key], amount)
                                                       for key, amount in expected.items()),
                f"{reverse_name}: stale or wrong outputs: {actual}; expected {expected}")
        require(reverse.get("categories", [reverse.get("category")]) == ["recycling"],
                f"{reverse_name}: wrong machine category")
        require(reverse.get("hidden") is True and reverse.get("allow_productivity") is False,
                f"{reverse_name}: must be hidden and non-productive")
        require(reverse.get("allow_quality", True) is True and not reverse.get("surface_conditions"),
                f"{reverse_name}: quality disabled or planet restriction")
        require(unlocks.count(reverse_name) == 1, f"{reverse_name}: missing or duplicate unlock")

    for chemistry, cell in RECOVERY.items():
        damaged = f"bitermotors-damaged-{chemistry}-battery-pack"
        item = data["item"][damaged]
        require(item.get("auto_recycle") is False and "always-show" in item.get("flags", []),
                f"{damaged}: must be filterable and not auto-recycled")
        require(f"{damaged}-recycling" not in recipes, f"{damaged}: destructive self-recycling fallback")
        name = f"bitermotors-{chemistry}-battery-recovery"
        recipe = recipes[name]
        require(item_amounts(recipe["ingredients"]) == {damaged: 10}, f"{name}: wrong batch size")
        require(item_amounts(recipe["results"]) == {cell: 36}, f"{name}: must recover exactly 90 percent")
        require(recipe.get("allow_productivity") is False and recipe.get("auto_recycle") is False,
                f"{name}: recovery must not compound through productivity or recycling")
        require(recipe.get("categories", [recipe.get("category")]) == ["recycling"]
                and recipe.get("allow_quality", True) is True and not recipe.get("surface_conditions"),
                f"{name}: unsupported category, quality policy, or planet restriction")

    generic = recipes["bitermotors-wrecked-ev-recycling"]
    require({row["name"] for row in generic["results"]} == {"steel-plate", "electronic-circuit", "battery"},
            "generic wrecks must not create advanced chemistry")
    require(generic.get("allow_productivity") is False, "generic wrecks must not accept productivity")
    return {"rewritten": len(APPROVED), "battery_routes": len(RECOVERY), "assertions": assertions}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path)
    args = parser.parse_args()
    try:
        result = validate(json.loads(args.dump.read_text()))
    except (ValueError, KeyError, TypeError, OSError) as error:
        raise SystemExit(f"Recycling prototype validation failed: {error}") from error
    print("Recycling final prototypes passed:", json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
