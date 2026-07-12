#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "art" / "blender"
MOD = ROOT / "mod" / "factoryx_0.1.0"
ENTITY_OUTPUT = MOD / "graphics" / "entity" / "vehicles"
ICON_OUTPUT = MOD / "graphics" / "icons"

VEHICLES = {
    "prototype-roadster": ("prototype-roadster", "roadster", "prototype-roadster"),
    "premium-ev": ("premium-ev", "premium-ev", "premium-ev"),
    "mass-market-ev": ("mass-market-ev", "mass-market-ev", "mass-market-ev"),
    "cybertruck": ("cybertruck", "cybertruck", "cybertruck"),
    "robotaxi-fleet": ("robotaxi", "robotaxi", "robotaxi"),
}

FRAME_SIZE = 192
DIRECTION_COUNT = 64
NORTH_SOURCE_FRAME = 23


def factorio_source_frame(direction: int) -> int:
    # Blender positive-Z rotation is counter-clockwise in world space. Factorio
    # directions begin at screen north and advance clockwise.
    return (NORTH_SOURCE_FRAME - direction) % DIRECTION_COUNT


def build_sheet(item_name: str, folder: str, frame_stem: str) -> None:
    source = ART / folder / "renders" / "directions"
    sheet = Image.new("RGBA", (FRAME_SIZE * 8, FRAME_SIZE * 8), (0, 0, 0, 0))
    for direction in range(DIRECTION_COUNT):
        source_index = factorio_source_frame(direction)
        frame = Image.open(source / f"{frame_stem}-{source_index:02d}.png").convert("RGBA")
        if frame.size != (FRAME_SIZE, FRAME_SIZE):
            raise ValueError(f"{folder} frame {source_index} is {frame.size}, expected 192x192")
        sheet.alpha_composite(frame, ((direction % 8) * FRAME_SIZE, (direction // 8) * FRAME_SIZE))
    ENTITY_OUTPUT.mkdir(parents=True, exist_ok=True)
    sheet.save(ENTITY_OUTPUT / f"{item_name}.png", optimize=True)


def build_shadow_sheet(item_name: str, folder: str, frame_stem: str) -> None:
    source = ART / folder / "renders" / "directions"
    sheet = Image.new("RGBA", (FRAME_SIZE * 8, FRAME_SIZE * 8), (0, 0, 0, 0))
    for direction in range(DIRECTION_COUNT):
        source_index = factorio_source_frame(direction)
        frame = Image.open(source / f"{frame_stem}-shadow-{source_index:02d}.png").convert("RGBA")
        alpha = frame.getchannel("A").filter(ImageFilter.GaussianBlur(4))
        alpha = alpha.point(lambda value: round(value * 0.42))
        softened = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        softened.putalpha(alpha)
        shifted = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        shifted.alpha_composite(softened, (4, 5))
        sheet.alpha_composite(shifted, ((direction % 8) * FRAME_SIZE, (direction // 8) * FRAME_SIZE))
    sheet.save(ENTITY_OUTPUT / f"{item_name}-shadow.png", optimize=True)


def build_icon(item_name: str, folder: str, master_stem: str) -> None:
    master = Image.open(ART / folder / "renders" / f"{master_stem}-master.png").convert("RGBA")
    alpha = master.getchannel("A")
    bounds = alpha.getbbox()
    if not bounds:
        raise ValueError(f"{folder} master is fully transparent")
    subject = master.crop(bounds)
    subject.thumbnail((224, 224), Image.Resampling.LANCZOS)
    icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    icon.alpha_composite(subject, ((256 - subject.width) // 2, (256 - subject.height) // 2))
    icon.save(ICON_OUTPUT / f"{item_name}.png", optimize=True)


def main() -> None:
    for item_name, (folder, frame_stem, master_stem) in VEHICLES.items():
        build_sheet(item_name, folder, frame_stem)
        build_shadow_sheet(item_name, folder, frame_stem)
        build_icon(item_name, folder, master_stem)
        print(f"Built {item_name} vehicle sheet and icon")


if __name__ == "__main__":
    main()
