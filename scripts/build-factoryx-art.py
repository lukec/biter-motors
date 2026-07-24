#!/usr/bin/env python3
"""Build deterministic FactoryX icons and lightweight animation overlays."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MOD_GRAPHICS = ROOT / "mod/factoryx_0.1.0/graphics"
ICON_DIR = MOD_GRAPHICS / "icons"
ANIMATION_DIR = MOD_GRAPHICS / "animation"
TECHNOLOGY_DIR = MOD_GRAPHICS / "technology"
SHOWROOM_DIR = MOD_GRAPHICS / "entity/sales-office/showroom"
ICON_SOURCE_DIR = ROOT / "art/factoryx-icon-sources"
MASTER_DIR = ROOT / "art/factoryx-masters/final"

ENTITY_ICON_SOURCES = {
    "sales-office": "sales-office/sales-office.png",
    "ev-charging-station": "ev-charging-station/ev-charging-station.png",
    "ev-charging-station-v2": "ev-charging-station-v2/ev-charging-station-v2.png",
    "ev-charging-station-v3": "ev-charging-station-v3/ev-charging-station-v3.png",
    "ev-charging-station-v4": "ev-charging-station-v4/ev-charging-station-v4.png",
    "gigafactory": "gigafactory/gigafactory.png",
    "megapack": "megapack/megapack.png",
    "terrestrial-datacenter": "terrestrial-datacenter/terrestrial-datacenter.png",
    "robotaxi-service-center": "robotaxi-service-center/robotaxi-service-center.png",
    "orbital-compute-array": "orbital-compute-array/orbital-compute-array.png",
    "planetary-grid-controller": "planetary-grid-controller/planetary-grid-controller.png",
}

def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    return alpha.getbbox()


def normalized_icon(image: Image.Image, subject_size: int = 216) -> Image.Image:
    image = image.convert("RGBA")
    bbox = alpha_bbox(image)
    if not bbox:
        return Image.new("RGBA", (256, 256))
    subject = image.crop(bbox)
    scale = min(subject_size / subject.width, subject_size / subject.height)
    size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    rgb = subject.convert("RGB").filter(ImageFilter.UnsharpMask(radius=0.7, percent=75, threshold=3))
    subject = Image.merge("RGBA", (*rgb.split(), subject.getchannel("A")))
    canvas = Image.new("RGBA", (256, 256))
    canvas.alpha_composite(subject, ((256 - size[0]) // 2, (256 - size[1]) // 2))
    return canvas


def derive_and_normalize_icons() -> None:
    for slug, relative_source in ENTITY_ICON_SOURCES.items():
        source = MOD_GRAPHICS / "entity" / relative_source
        normalized_icon(Image.open(source), 218).save(ICON_DIR / f"{slug}.png", optimize=True)

    for source in sorted(ICON_SOURCE_DIR.glob("*.png")):
        normalized_icon(Image.open(source)).save(ICON_DIR / source.name, optimize=True)

    normalized_icon(Image.open(MASTER_DIR / "agi-model.png")).save(ICON_DIR / "agi-model.png", optimize=True)


def build_sales_office_showroom_vehicles() -> None:
    SHOWROOM_DIR.mkdir(parents=True, exist_ok=True)
    for name in ("prototype-roadster", "premium-ev", "mass-market-ev", "cybertruck"):
        sheet = Image.open(MOD_GRAPHICS / f"entity/vehicles/{name}.png").convert("RGBA")
        # A shallow isometric view matches the showroom floor better than the
        # side-on driving frame and keeps each model recognizable behind glass.
        frame_index = 12
        left = (frame_index % 8) * 192
        top = (frame_index // 8) * 192
        frame = sheet.crop((left, top, left + 192, top + 192))
        bbox = alpha_bbox(frame)
        if not bbox:
            raise RuntimeError(f"Vehicle showroom frame is empty: {name}")
        vehicle = frame.crop(bbox)
        scale = min(190 / vehicle.width, 78 / vehicle.height)
        vehicle = vehicle.resize(
            (max(1, round(vehicle.width * scale)), max(1, round(vehicle.height * scale))),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", (256, 128))
        shadow = Image.new("RGBA", canvas.size)
        shadow_draw = ImageDraw.Draw(shadow, "RGBA")
        shadow_draw.ellipse((38, 62, 218, 108), fill=(8, 13, 15, 125))
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=7))
        canvas.alpha_composite(shadow)
        vehicle_x = (canvas.width - vehicle.width) // 2
        vehicle_y = 58 - vehicle.height // 2
        canvas.alpha_composite(vehicle, (vehicle_x, vehicle_y))

        glass = Image.new("RGBA", canvas.size)
        glass_draw = ImageDraw.Draw(glass, "RGBA")
        glass_draw.line((42, 28, 112, 8), fill=(184, 225, 235, 48), width=5)
        glass_draw.line((143, 116, 222, 91), fill=(184, 225, 235, 35), width=4)
        glass_draw.line((27, 108, 229, 108), fill=(112, 168, 181, 52), width=3)
        canvas.alpha_composite(glass)
        canvas.save(SHOWROOM_DIR / f"{name}.png", optimize=True)


def glow(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    x, y = center
    for extra, opacity in ((8, alpha // 10), (5, alpha // 6), (2, alpha // 3), (0, alpha)):
        r = radius + extra
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(*color, opacity))


def animation_sheet(name: str, width: int, height: int, painter) -> None:
    frame_count = 8
    sheet = Image.new("RGBA", (width * frame_count, height))
    for frame_index in range(frame_count):
        frame = Image.new("RGBA", (width, height))
        painter(frame, frame_index, frame_count)
        sheet.alpha_composite(frame, (frame_index * width, 0))
    ANIMATION_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(ANIMATION_DIR / f"{name}.png", optimize=True)
    if name == "robotaxi-dispatch-lights":
        for frame_index in range(frame_count):
            left = frame_index * width
            sheet.crop((left, 0, left + width, height)).save(
                ANIMATION_DIR / f"{name}-frame-{frame_index + 1}.png",
                optimize=True,
            )


def paint_sales_lights(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    pulse = (math.sin(index / count * math.tau) + 1) / 2
    glow(draw, (38, 30), 6, (88, 255, 120), round(110 + pulse * 110))
    for offset in range(3):
        glow(draw, (18 + offset * 12, 47), 2, (255, 174, 48), 110 + 35 * ((index + offset) % 3))


def paint_sales_status_light(frame: Image.Image, index: int, count: int, color: tuple[int, int, int]) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    pulse = (math.sin(index / count * math.tau) + 1) / 2
    center = (32, 32)
    radius = round(13 + pulse * 5)
    glow(draw, center, radius, color, round(125 + pulse * 120))
    draw.ellipse(
        (32 - radius, 32 - radius, 32 + radius, 32 + radius),
        outline=(*color, round(105 + pulse * 140)),
        width=3,
    )
    angle = index / count * math.tau
    for spoke in range(3):
        theta = angle + spoke * math.tau / 3
        inner = 9
        outer = 23
        draw.line(
            (
                32 + math.cos(theta) * inner,
                32 + math.sin(theta) * inner,
                32 + math.cos(theta) * outer,
                32 + math.sin(theta) * outer,
            ),
            fill=(245, 255, 248, 245),
            width=4,
        )
    glow(draw, center, 5, color, 255)
    draw.ellipse((29, 29, 35, 35), fill=(245, 255, 248, 255))


def paint_charger_stall_light(frame: Image.Image, index: int, count: int, state: str) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    if state == "idle":
        draw.rounded_rectangle((3, 6, 29, 26), 6, fill=(17, 28, 31, 235), outline=(91, 126, 132, 235), width=3)
        draw.ellipse((12, 12, 20, 20), fill=(60, 83, 88, 225))
        return
    frequency = {"low": 1, "medium": 1, "full": 2, "overload": 2, "charging": 2}[state]
    pulse = (math.sin(index / count * math.tau * frequency) + 1) / 2
    color = {
        "low": (48, 178, 205),
        "medium": (52, 222, 247),
        "full": (98, 245, 255),
        "overload": (255, 54, 38),
        "charging": (54, 201, 255),
    }[state]
    base_alpha = {"low": 70, "medium": 105, "full": 145, "overload": 150, "charging": 180}[state]
    glow(draw, (16, 16), 9, color, round(base_alpha + pulse * (245 - base_alpha)))
    draw.rounded_rectangle((2, 5, 30, 27), 6, fill=(12, 25, 29, 235), outline=(*color, 245), width=3)
    draw.rounded_rectangle((6, 9, 26, 23), 3, fill=(*color, round(120 + pulse * 120)))
    sweep_x = 8 + round(index / (count - 1) * 16)
    draw.line((sweep_x, 10, sweep_x, 22), fill=(255, 255, 255, 250), width=3)
    if state == "charging":
        draw.line((16, 3, 10, 15, 17, 13, 12, 29), fill=(255, 255, 255, 255), width=4)


def paint_factory_fan(
    draw: ImageDraw.ImageDraw,
    center: tuple[int, int],
    angle: float,
    accent: tuple[int, int, int],
) -> None:
    cx, cy = center
    draw.ellipse((cx - 23, cy - 23, cx + 23, cy + 23), fill=(18, 24, 28, 210), outline=(105, 124, 132, 220), width=5)
    for blade in range(4):
        theta = angle + blade * math.pi / 2
        perpendicular = theta + math.pi / 2
        root = (cx + math.cos(theta) * 5, cy + math.sin(theta) * 5)
        tip = (cx + math.cos(theta) * 18, cy + math.sin(theta) * 18)
        width = 6
        polygon = [
            (root[0] + math.cos(perpendicular) * width, root[1] + math.sin(perpendicular) * width),
            (tip[0] + math.cos(perpendicular) * 2, tip[1] + math.sin(perpendicular) * 2),
            (tip[0] - math.cos(perpendicular) * 2, tip[1] - math.sin(perpendicular) * 2),
            (root[0] - math.cos(perpendicular) * width, root[1] - math.sin(perpendicular) * width),
        ]
        draw.polygon(polygon, fill=(142, 158, 166, 235))
    glow(draw, center, 4, accent, 230)


def paint_gigafactory_v1_activity(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    phase = index / count * math.tau
    paint_factory_fan(draw, (62, 22), phase, (52, 192, 224))
    paint_factory_fan(draw, (319, 22), phase + math.pi / 4, (52, 192, 224))

    # The two exposed service lanes between the production halls each carry a
    # reciprocating gantry and a glowing body shell through the line.
    travel = round((1 - math.cos(phase)) * 42)
    for lane, offset in ((97, 0), (323, 2)):
        lane_phase = (index + offset) % count
        shell_y = 92 + lane_phase * 42
        draw.rounded_rectangle((lane - 24, 62, lane + 24, 470), 8, outline=(87, 103, 110, 190), width=6)
        draw.rounded_rectangle(
            (lane - 30, 78 + travel, lane + 30, 126 + travel),
            8,
            fill=(49, 57, 62, 245),
            outline=(202, 211, 214, 235),
            width=5,
        )
        draw.rectangle((lane - 39, 118 + travel, lane + 39, 130 + travel), fill=(24, 29, 32, 250))
        draw.rounded_rectangle(
            (lane - 27, shell_y, lane + 27, shell_y + 22),
            8,
            fill=(221, 112, 24, 225),
            outline=(255, 192, 64, 245),
            width=4,
        )
        glow(draw, (lane, shell_y + 11), 7, (255, 151, 34), 165)

    for light_index, y in enumerate(range(72, 465, 49)):
        active = (light_index - index) % 8
        alpha = 250 if active == 0 else 105 if active in (1, 7) else 35
        for x in (45, 149, 271, 375):
            glow(draw, (x, y), 4, (45, 202, 234), alpha)


def paint_gigafactory_v2_activity(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    phase = index / count * math.tau
    for fan_index, center in enumerate(((203, 21), (309, 21))):
        paint_factory_fan(draw, center, phase * 1.7 + fan_index * math.pi / 4, (82, 224, 255))

    # Twin gigacasting cells pulse independently while shuttle tables move
    # completed castings toward the lower transfer line.
    for cell_index, cx in enumerate((142, 400)):
        cell_phase = phase + cell_index * math.pi
        pulse = (math.sin(cell_phase) + 1) / 2
        core_radius = round(15 + pulse * 5)
        glow(draw, (cx, 221), 6, (86, 224, 255), round(115 + pulse * 105))
        draw.ellipse(
            (cx - core_radius, 221 - core_radius, cx + core_radius, 221 + core_radius),
            outline=(119, 235, 255, round(135 + pulse * 100)),
            width=6,
        )
        draw.arc((cx - 58, 145, cx + 58, 261), 205, 335, fill=(174, 226, 237, 220), width=9)
        arm_y = 274 + round((1 - math.cos(cell_phase)) * 32)
        draw.rounded_rectangle((cx - 44, arm_y, cx + 44, arm_y + 24), 7, fill=(61, 70, 75, 245), outline=(218, 228, 231, 235), width=5)
        draw.rounded_rectangle((cx - 29, arm_y + 25, cx + 29, arm_y + 47), 7, fill=(190, 122, 28, 235), outline=(255, 199, 74, 245), width=4)
        glow(draw, (cx, arm_y + 36), 8, (255, 167, 42), 175)

    shuttle_x = 72 + round(index / (count - 1) * 368)
    draw.rounded_rectangle((shuttle_x - 34, 441, shuttle_x + 34, 471), 8, fill=(56, 65, 70, 245), outline=(160, 221, 234, 240), width=5)
    glow(draw, (shuttle_x, 456), 9, (71, 216, 250), 190)
    for light_index in range(12):
        x = 47 + light_index * 38
        distance = (light_index - index * 2) % 12
        glow(draw, (x, 493), 4, (79, 224, 255), 245 if distance == 0 else 80 if distance in (1, 11) else 28)


def paint_gigafactory_loading_lights(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    for bay_start in (0, 211, 434):
        for light_index in range(6):
            x = bay_start + 12 + light_index * 14
            distance = (light_index - index) % 6
            alpha = 250 if distance == 0 else 105 if distance in (1, 5) else 28
            glow(draw, (x, 61), 5, (68, 214, 249), alpha)
        door_phase = (index + bay_start // 100) % count
        scan_y = 83 + round(door_phase / (count - 1) * 29)
        draw.line((bay_start + 9, scan_y, bay_start + 80, scan_y), fill=(255, 176, 45, 205), width=5)


def paint_fans(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    angle = index / count * math.tau
    for cx in (25, 64, 103):
        draw.ellipse((cx - 17, 15, cx + 17, 49), fill=(25, 31, 36, 210), outline=(118, 134, 143, 210), width=2)
        for blade in range(4):
            theta = angle + blade * math.pi / 2
            x1, y1 = cx + math.cos(theta) * 4, 32 + math.sin(theta) * 4
            x2, y2 = cx + math.cos(theta) * 14, 32 + math.sin(theta) * 14
            draw.line((x1, y1, x2, y2), fill=(150, 166, 174, 235), width=5)
        glow(draw, (cx, 32), 2, (58, 205, 255), 190)


def paint_dispatch_lights(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    for light_index in range(8):
        distance = (light_index - index) % 8
        alpha = 245 if distance == 0 else 125 if distance in (1, 7) else 38
        glow(draw, (15 + light_index * 14, 32), 3, (255, 190, 48), alpha)


def paint_grid_charge(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    progress = (index + 1) / count
    center = (64, 64)
    for ring_index, radius in enumerate((18, 31, 44, 56)):
        alpha = 225 if ring_index / 4 <= progress else 38
        draw.arc((64 - radius, 64 - radius, 64 + radius, 64 + radius), -90, -90 + 360 * progress, fill=(72, 225, 255, alpha), width=3)
    for node in range(8):
        theta = node / 8 * math.tau
        glow(draw, (64 + math.cos(theta) * 46, 64 + math.sin(theta) * 46), 2, (255, 191, 52), 220 if node <= index else 45)
    glow(draw, center, 7, (98, 232, 255), round(90 + progress * 140))


def build_animations() -> None:
    animation_sheet("sales-office-status-green", 64, 64, lambda frame, index, count: paint_sales_status_light(frame, index, count, (72, 255, 105)))
    animation_sheet("sales-office-status-amber", 64, 64, lambda frame, index, count: paint_sales_status_light(frame, index, count, (255, 178, 48)))
    animation_sheet("sales-office-status-red", 64, 64, lambda frame, index, count: paint_sales_status_light(frame, index, count, (255, 54, 42)))
    for state in ("idle", "low", "medium", "full", "overload", "charging"):
        animation_sheet(
            f"charger-stall-{state}", 32, 32,
            lambda frame, index, count, state=state: paint_charger_stall_light(frame, index, count, state),
        )
    animation_sheet("gigafactory-v1-activity", 512, 512, paint_gigafactory_v1_activity)
    animation_sheet("gigafactory-v2-activity", 512, 512, paint_gigafactory_v2_activity)
    animation_sheet("gigafactory-loading-lights", 512, 128, paint_gigafactory_loading_lights)
    animation_sheet("datacenter-cooling-fans", 128, 64, paint_fans)
    animation_sheet("robotaxi-dispatch-lights", 128, 64, paint_dispatch_lights)
    animation_sheet("grid-charge-stages", 128, 128, paint_grid_charge)


def build_technology_icon(name: str, primary_name: str, secondary_name: str | None, accent: tuple[int, int, int]) -> None:
    canvas = Image.new("RGBA", (256, 256), (20, 25, 29, 255))
    draw = ImageDraw.Draw(canvas, "RGBA")
    for radius, alpha in ((116, 220), (104, 120), (88, 65)):
        draw.ellipse((128 - radius, 128 - radius, 128 + radius, 128 + radius), outline=(*accent, alpha), width=4)
    for coordinate in range(32, 256, 32):
        draw.line((coordinate, 22, coordinate, 234), fill=(115, 130, 138, 25), width=1)
        draw.line((22, coordinate, 234, coordinate), fill=(115, 130, 138, 25), width=1)
    primary = normalized_icon(Image.open(ICON_DIR / primary_name), 184).resize((210, 210), Image.Resampling.LANCZOS)
    canvas.alpha_composite(primary, (23, 18))
    if secondary_name:
        secondary = normalized_icon(Image.open(ICON_DIR / secondary_name), 205).resize((82, 82), Image.Resampling.LANCZOS)
        badge = Image.new("RGBA", (92, 92), (14, 18, 21, 235))
        badge_draw = ImageDraw.Draw(badge, "RGBA")
        badge_draw.ellipse((2, 2, 89, 89), fill=(14, 18, 21, 235), outline=(*accent, 230), width=4)
        badge.alpha_composite(secondary, (5, 5))
        canvas.alpha_composite(badge, (154, 154))
    TECHNOLOGY_DIR.mkdir(parents=True, exist_ok=True)
    canvas.save(TECHNOLOGY_DIR / f"{name}.png", optimize=True)


def build_technology_icons() -> None:
    build_technology_icon("sales-office", "sales-office.png", None, (255, 156, 40))
    build_technology_icon("ev-charging-network", "ev-charging-station-v2.png", None, (64, 218, 255))
    build_technology_icon("gigafactory", "gigafactory.png", "gigafactory-module.png", (255, 156, 40))
    build_technology_icon("terrestrial-ai", "terrestrial-datacenter.png", "ai-token.png", (64, 196, 255))
    build_technology_icon("autonomous-logistics", "robotaxi-service-center.png", "robotaxi-fleet.png", (255, 194, 48))
    build_technology_icon("planetary-energy-grid", "planetary-grid-controller.png", "planetary-grid-segment.png", (68, 224, 255))
    build_technology_icon("achieving-agi", "agi-model.png", "ai-token.png", (255, 184, 48))


def main() -> int:
    derive_and_normalize_icons()
    build_sales_office_showroom_vehicles()
    build_animations()
    build_technology_icons()
    print(f"Built normalized icons in {ICON_DIR}")
    print(f"Built Sales Office vehicle overlays in {SHOWROOM_DIR}")
    print(f"Built animation overlays in {ANIMATION_DIR}")
    print(f"Built technology icons in {TECHNOLOGY_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
