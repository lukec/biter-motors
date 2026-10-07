"""Small, reproducible economy catalog from final engine prototypes and runtime policy."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod/bitermotors_0.1.1"
CATALOG = ROOT / "docs/economy-prototypes.json"
DOLLAR = "bitermotors-dollar"
TOKEN = "bitermotors-ai-token"
DATASET = "bitermotors-agi-training-dataset"

REQUIRED_TECHNOLOGIES = (
    "bitermotors-premium-ev-program", "bitermotors-advanced-battery-chemistry",
    "bitermotors-energy-products", "bitermotors-ev-charging-network",
    "bitermotors-capital-scaling", "bitermotors-terrestrial-ai",
    "bitermotors-autonomous-logistics", "bitermotors-orbital-compute",
    "bitermotors-orbital-cluster-training", "bitermotors-grid-scale-energy",
    "bitermotors-hyperscale-training", "bitermotors-planetary-energy-grid",
)
ENTITY_TYPES = ("assembling-machine", "solar-panel", "accumulator", "container")
RECIPE_FIELDS = ("ingredients", "results", "energy_required", "categories", "category",
                 "allow_productivity", "maximum_productivity", "raise_on_crafted")
BASELINE_ROUTES = {
    "bitermotors-lithium-carbonate": "bitermotors-lithium-extraction",
    "bitermotors-nickel-sulfate": "bitermotors-dirty-nickel-refining",
    "bitermotors-cobalt-concentrate": "bitermotors-dirty-nickel-refining",
    "bitermotors-phosphate": "bitermotors-phosphate-extraction",
}


def source_fingerprint(mod: Path = MOD) -> str:
    digest = hashlib.sha256()
    paths = [mod / "info.json", *sorted(mod.rglob("*.lua"))]
    for path in paths:
        digest.update(path.relative_to(mod).as_posix().encode() + b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()


def file_fingerprint(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture_manifest(dump: Path, runtime: Path, expected_source: str) -> dict:
    if source_fingerprint() != expected_source:
        raise ValueError("mod source changed during native capture; rerun validation")
    return {"source_sha256": expected_source, "dump_sha256": file_fingerprint(dump),
            "runtime_sha256": file_fingerprint(runtime)}


def verify_capture(dump: Path, runtime: Path, manifest: dict) -> None:
    if manifest != capture_manifest(dump, runtime, manifest["source_sha256"]):
        raise ValueError("native capture hashes do not match; rerun validation")


def amount(entries: list, name: str) -> float:
    total = 0.0
    for entry in entries:
        if isinstance(entry, list):
            if entry[0] == name:
                total += entry[1]
        elif entry.get("name") == name:
            if "probability" in entry and entry["probability"] != 1:
                raise ValueError(f"stochastic product is not a fixed economy amount: {name}")
            if "amount" not in entry:
                raise ValueError(f"missing fixed amount: {name}")
            total += entry["amount"]
    return total


def energy(value: str) -> float:
    units = {"kW": 1e3, "MW": 1e6, "GW": 1e9, "W": 1,
             "kJ": 1e3, "MJ": 1e6, "GJ": 1e9, "J": 1}
    for suffix, multiplier in units.items():
        if value.endswith(suffix):
            return float(value[:-len(suffix)]) * multiplier
    raise ValueError(f"unsupported energy value: {value}")


def extract(raw: dict, runtime: dict) -> dict:
    recipes = {
        name: {key: value for key, value in recipe.items() if key in RECIPE_FIELDS}
        for name, recipe in raw["recipe"].items()
        if name.startswith("bitermotors-") and not name.endswith("-recycling")
        and not name.startswith("bitermotors-smoke-")
    }
    recipes["rocket-part"] = {key: value for key, value in raw["recipe"]["rocket-part"].items()
                              if key in RECIPE_FIELDS}
    technologies = {
        name: {key: value for key, value in technology.items()
               if key in ("unit", "prerequisites", "effects")}
        for name, technology in raw["technology"].items()
        if name in REQUIRED_TECHNOLOGIES or name in (
            "bitermotors-high-density-solar-productivity", "bitermotors-grid-battery-productivity",
            "bitermotors-megatruck-engineering", "bitermotors-battery-material-recovery",
            "bitermotors-cybertrain-logistics", "foundry", "logistic-system")
    }
    entities = {}
    for kind in ENTITY_TYPES:
        for name, prototype in raw.get(kind, {}).items():
            if name.startswith("bitermotors-") or name in ("assembling-machine-2", "assembling-machine-3"):
                entities[name] = {key: value for key, value in prototype.items() if key in (
                    "type", "crafting_speed", "energy_usage", "production", "energy_source",
                    "effect_receiver", "inventory_size", "selection_box")}
    items = {name: {key: value for key, value in item.items() if key in ("stack_size", "weight")}
             for kind in ("item", "item-with-entity-data", "tool")
             for name, item in raw.get(kind, {}).items() if name.startswith("bitermotors-")}
    mined_items = set()
    for resource in raw.get("resource", {}).values():
        minable = resource.get("minable", {})
        if minable.get("result"):
            mined_items.add(minable["result"])
        mined_items.update(product["name"] for product in minable.get("results", [])
                           if product.get("type", "item") == "item")
    catalog = {
        "schema": 1, "source_sha256": source_fingerprint(),
        "factorio_version": runtime["factorio_version"], "mod_version": runtime["mod_version"],
        "recipes": recipes, "technologies": technologies, "entities": entities,
        "items": items, "runtime": runtime, "mined_items": sorted(mined_items),
        "baseline_recipe_routes": BASELINE_ROUTES,
        "nauvis_orbit_solar_multiplier": raw["planet"]["nauvis"]["solar_power_in_space"] / 100,
        "assumptions": {"solar_average_fraction": 0.7, "storage_seconds_per_peak_watt": 70,
                        "quality": "normal", "modules": "none", "research_productivity": 0},
    }
    missing = set(REQUIRED_TECHNOLOGIES) - technologies.keys()
    if missing:
        raise ValueError(f"missing required research: {sorted(missing)}")
    return catalog


class EconomyCatalog:
    def __init__(self, data: dict):
        if data.get("schema") != 1:
            raise ValueError("unsupported economy catalog schema")
        self.data = data
        self.runtime = data["runtime"]

    @classmethod
    def load(cls, path: Path = CATALOG) -> EconomyCatalog:
        return cls(json.loads(path.read_text()))

    def recipe(self, name: str) -> dict:
        return self.data["recipes"][name]

    def ingredient(self, name: str, item: str) -> float:
        return amount(self.recipe(name)["ingredients"], item)

    def output(self, name: str, item: str) -> float:
        return amount(self.recipe(name)["results"], item)

    def seconds(self, recipe: str, machine: str) -> float:
        return self.recipe(recipe).get("energy_required", 0.5) / self.data["entities"][machine]["crafting_speed"]

    def research(self, name: str, item: str = DOLLAR) -> float:
        unit = self.data["technologies"][name]["unit"]
        return unit["count"] * amount(unit["ingredients"], item)

    def item_dollars(self, item: str, visiting: frozenset = frozenset()) -> float:
        if item == DOLLAR:
            return 1
        if not item.startswith("bitermotors-") or item in self.data["mined_items"]:
            return 0
        if item in visiting:
            raise ValueError(f"cyclic construction dependency: {item}")
        recipe_name = self.data["baseline_recipe_routes"].get(item, item)
        recipe = self.recipe(recipe_name)
        cost = sum(entry["amount"] * self.item_dollars(entry["name"], visiting | {item})
                   for entry in recipe["ingredients"] if entry.get("type", "item") == "item")
        return cost / self.output(recipe_name, item)

    def freshness_errors(self, mod: Path = MOD) -> list[str]:
        return [] if self.data["source_sha256"] == source_fingerprint(mod) else [
            "economy catalog is stale; export a new final prototype dump and runtime contract"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-sha", action="store_true")
    parser.add_argument("--record-capture", action="store_true")
    parser.add_argument("--expected-source-sha")
    parser.add_argument("--dump", type=Path)
    parser.add_argument("--runtime-contract", type=Path)
    parser.add_argument("--capture-manifest", type=Path)
    parser.add_argument("--output", type=Path, default=CATALOG)
    args = parser.parse_args()
    if args.source_sha:
        print(source_fingerprint())
        return 0
    if not args.dump or not args.runtime_contract:
        parser.error("--dump and --runtime-contract are required")
    manifest_path = args.capture_manifest or args.dump.parent / "bitermotors-economy-capture.json"
    if args.record_capture:
        if not args.expected_source_sha:
            parser.error("--expected-source-sha is required when recording a capture")
        manifest_path.write_text(json.dumps(capture_manifest(
            args.dump, args.runtime_contract, args.expected_source_sha), sort_keys=True) + "\n")
        print(manifest_path)
        return 0
    provenance = json.loads(manifest_path.read_text())
    verify_capture(args.dump, args.runtime_contract, provenance)
    catalog = extract(json.loads(args.dump.read_text()), json.loads(args.runtime_contract.read_text()))
    catalog["capture"] = provenance
    # Compact per-record output keeps the captured engine data reviewable.
    parts = []
    for key, value in catalog.items():
        if key in ("recipes", "technologies", "entities", "items"):
            entries = [f"    {json.dumps(name)}: {json.dumps(entry, sort_keys=True)}"
                       for name, entry in sorted(value.items())]
            parts.append(f"  {json.dumps(key)}: {{\n" + ",\n".join(entries) + "\n  }")
        else:
            parts.append(f"  {json.dumps(key)}: {json.dumps(value, sort_keys=True)}")
    args.output.write_text("{\n" + ",\n".join(parts) + "\n}\n")
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
