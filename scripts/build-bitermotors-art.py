#!/usr/bin/env python3
"""Build deterministic Biter Motors icons and lightweight animation overlays."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MOD_GRAPHICS = ROOT / "mod/bitermotors_0.1.1/graphics"
ICON_DIR = MOD_GRAPHICS / "icons"
ANIMATION_DIR = MOD_GRAPHICS / "animation"
TECHNOLOGY_DIR = MOD_GRAPHICS / "technology"
SHOWROOM_DIR = MOD_GRAPHICS / "entity/sales-office/showroom"
ICON_SOURCE_DIR = ROOT / "art/bitermotors-icon-sources"
MASTER_DIR = ROOT / "art/bitermotors-masters/final"
ACTIVE_SHOWROOM_SOURCE = (
    ROOT / "art/bitermotors-masters/sources/sales-office-active-empty-chroma.png"
)
VEHICLE_ICON_NAMES = {
    "prototype-roadster",
    "premium-ev",
    "mass-market-ev",
    "megatruck",
    "bitertaxi-fleet",
}

ENTITY_ICON_SOURCES = {
    "sales-office": "sales-office/sales-office.png",
    "ev-charging-station": "ev-charging-station/ev-charging-station.png",
    "ev-charging-station-v2": "ev-charging-station-v2/ev-charging-station-v2.png",
    "ev-charging-station-v3": "ev-charging-station-v3/ev-charging-station-v3.png",
    "ev-charging-station-v4": "ev-charging-station-v4/ev-charging-station-v4.png",
    "biterfactory": "biterfactory/biterfactory.png",
    "high-density-solar-array": "high-density-solar-array/high-density-solar-array.png",
    "grid-battery": "grid-battery/grid-battery.png",
    "terrestrial-datacenter": "terrestrial-datacenter/terrestrial-datacenter.png",
    "bitertaxi-depot": "bitertaxi-depot/bitertaxi-depot.png",
    "planetary-grid-controller": "planetary-grid-controller/planetary-grid-controller.png",
}

ENERGY_PRODUCT_SOURCES = {
    "high-density-solar-array": {
        "source": "high-density-solar-panel-transparent.png",
        "subject_size": 496,
        "shadow_blur": 3,
        "shadow_offset": (1, 2),
        "shadow_alpha_floor": 8,
    },
    "grid-battery": {
        "source": "grid-battery-v2-transparent.png",
        "subject_size": 462,
    },
}

STATIC_ENTITY_SOURCES = {
    "terrestrial-datacenter": {
        "source": "terrestrial-datacenter.png",
        "subject_size": 508,
    },
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


def normalized_entity(image: Image.Image, subject_size: int) -> Image.Image:
    image = image.convert("RGBA")
    bbox = alpha_bbox(image)
    if not bbox:
        raise RuntimeError("Generated entity source has no visible subject")
    subject = image.crop(bbox)
    scale = min(subject_size / subject.width, subject_size / subject.height)
    size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (512, 512))
    canvas.alpha_composite(subject, ((512 - size[0]) // 2, (512 - size[1]) // 2))
    return canvas


def entity_shadow(
    entity: Image.Image,
    blur_radius: int = 4,
    offset: tuple[int, int] = (5, 5),
    alpha_floor: int = 0,
) -> Image.Image:
    alpha = entity.getchannel("A")
    shadow_alpha = alpha.filter(ImageFilter.GaussianBlur(radius=blur_radius)).point(
        lambda value: 0 if value < alpha_floor else round(value * 0.34)
    )
    shadow = Image.new("RGBA", entity.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha)
    shifted = Image.new("RGBA", entity.size)
    shifted.alpha_composite(shadow, offset)
    return shifted


def add_glow(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    color: tuple[int, int, int],
    opacity: int,
) -> None:
    glow_layer = Image.new("RGBA", canvas.size)
    glow_draw = ImageDraw.Draw(glow_layer, "RGBA")
    glow_draw.rounded_rectangle(box, radius=4, fill=(*color, opacity))
    canvas.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(radius=7)))
    canvas.alpha_composite(glow_layer)


def grid_battery_activity_frames(
    color: tuple[int, int, int], charging: bool
) -> Image.Image:
    sheet = Image.new("RGBA", (512 * 8, 512))
    gauge_left, gauge_right = 237, 276
    gauge_top, gauge_bottom = 174, 278
    segment_height = 9
    segment_gap = 3
    indicator_boxes = (
        (75, 202, 164, 217),
        (348, 202, 437, 217),
        (75, 392, 164, 407),
        (348, 392, 437, 407),
    )
    for frame_index in range(8):
        frame = Image.new("RGBA", (512, 512))
        active_segments = frame_index + 1 if charging else 8 - frame_index
        for segment in range(active_segments):
            if charging:
                y2 = gauge_bottom - segment * (segment_height + segment_gap)
            else:
                y2 = gauge_top + (segment + 1) * (segment_height + segment_gap)
            y1 = y2 - segment_height
            add_glow(frame, (gauge_left, y1, gauge_right, y2), color, 210)
        pulse = 90 + ((frame_index * 37) % 120)
        for box in indicator_boxes:
            add_glow(frame, box, color, pulse)
        sheet.alpha_composite(frame, (frame_index * 512, 0))
    return sheet


def build_energy_product_art() -> None:
    for slug, config in ENERGY_PRODUCT_SOURCES.items():
        source = MASTER_DIR.parent / "sources" / config["source"]
        entity = normalized_entity(Image.open(source), config["subject_size"])
        entity_dir = MOD_GRAPHICS / "entity" / slug
        entity_dir.mkdir(parents=True, exist_ok=True)
        entity.save(entity_dir / f"{slug}.png", optimize=True)
        entity_shadow(
            entity,
            config.get("shadow_blur", 4),
            config.get("shadow_offset", (5, 5)),
            config.get("shadow_alpha_floor", 0),
        ).save(entity_dir / f"{slug}-shadow.png", optimize=True)

    grid_battery_activity_frames((72, 224, 255), charging=True).save(
        ANIMATION_DIR / "grid-battery-charge.png", optimize=True
    )
    grid_battery_activity_frames((255, 165, 48), charging=False).save(
        ANIMATION_DIR / "grid-battery-discharge.png", optimize=True
    )


def build_static_entity_art() -> None:
    for slug, config in STATIC_ENTITY_SOURCES.items():
        entity = normalized_entity(
            Image.open(MASTER_DIR / config["source"]), config["subject_size"]
        )
        entity_dir = MOD_GRAPHICS / "entity" / slug
        entity_dir.mkdir(parents=True, exist_ok=True)
        entity.save(entity_dir / f"{slug}.png", optimize=True)


def derive_and_normalize_icons() -> None:
    for slug, relative_source in ENTITY_ICON_SOURCES.items():
        source = MOD_GRAPHICS / "entity" / relative_source
        destination = ICON_DIR / f"{slug}.png"
        if not source.exists():
            if destination.exists():
                continue
            raise FileNotFoundError(f"No entity source or retained icon for {slug}: {source}")
        normalized_icon(Image.open(source), 218).save(destination, optimize=True)

    for source in sorted(ICON_SOURCE_DIR.glob("*.png")):
        if source.stem in VEHICLE_ICON_NAMES:
            continue
        normalized_icon(Image.open(source)).save(ICON_DIR / source.name, optimize=True)

    normalized_icon(Image.open(MASTER_DIR / "agi-model.png")).save(ICON_DIR / "agi-model.png", optimize=True)


def build_sales_office_showroom_vehicles() -> None:
    SHOWROOM_DIR.mkdir(parents=True, exist_ok=True)
    for name in ("prototype-roadster", "premium-ev", "mass-market-ev", "megatruck"):
        vehicle = sales_office_vehicle(name)
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


def sales_office_vehicle(name: str) -> Image.Image:
    sheet = Image.open(MOD_GRAPHICS / f"entity/vehicles/{name}.png").convert("RGBA")
    # This shallow top-down direction displays the body shape and color while
    # still matching the showroom floor's orientation.
    frame_index = 12
    left = (frame_index % 8) * 192
    top = (frame_index // 8) * 192
    frame = sheet.crop((left, top, left + 192, top + 192))
    bbox = alpha_bbox(frame)
    if not bbox:
        raise RuntimeError(f"Vehicle showroom frame is empty: {name}")
    return frame.crop(bbox)


def aligned_active_showroom_source() -> Image.Image:
    source = Image.open(ACTIVE_SHOWROOM_SOURCE).convert("RGB")
    red, green, blue = source.split()
    high_red = red.point(lambda value: 255 if value > 220 else 0)
    low_green = green.point(lambda value: 255 if value < 90 else 0)
    high_blue = blue.point(lambda value: 255 if value > 220 else 0)
    chroma = ImageChops.multiply(ImageChops.multiply(high_red, low_green), high_blue)
    subject_mask = ImageChops.invert(chroma)
    subject_bbox = subject_mask.getbbox()
    if not subject_bbox:
        raise RuntimeError("Active Sales Office source contains no non-chroma subject")

    base = Image.open(MOD_GRAPHICS / "entity/sales-office/sales-office.png").convert("RGBA")
    base_bbox = alpha_bbox(base)
    if not base_bbox:
        raise RuntimeError("Sales Office base sprite is empty")

    subject = source.crop(subject_bbox).resize(
        (base_bbox[2] - base_bbox[0], base_bbox[3] - base_bbox[1]),
        Image.Resampling.LANCZOS,
    )
    aligned = Image.new("RGBA", base.size)
    aligned.alpha_composite(subject.convert("RGBA"), (base_bbox[0], base_bbox[1]))
    return aligned


def active_showroom_background() -> tuple[Image.Image, Image.Image]:
    aligned = aligned_active_showroom_source()
    # Keep the generated detail inside the glass. The original exterior and
    # footprint remain pixel-identical in every working frame.
    mask = Image.new("L", aligned.size)
    draw = ImageDraw.Draw(mask)
    draw.polygon(
        ((145, 300), (370, 300), (370, 411), (141, 411)),
        fill=255,
    )
    mask = mask.filter(ImageFilter.GaussianBlur(radius=1.2))
    background = Image.new("RGBA", aligned.size)
    background.paste(aligned, (0, 0), mask)
    return background, mask


def paint_active_sales_showroom(
    frame: Image.Image,
    vehicle: Image.Image,
    background: Image.Image,
    window_mask: Image.Image,
    index: int,
    count: int,
) -> None:
    frame.alpha_composite(background)
    phase = index / count * math.tau
    pulse = (math.sin(phase) + 1) / 2

    floor_light = Image.new("RGBA", frame.size)
    floor_draw = ImageDraw.Draw(floor_light, "RGBA")
    floor_draw.ellipse(
        (161, 316, 351, 407),
        fill=(255, 179, 67, round(18 + pulse * 20)),
        outline=(255, 202, 103, round(125 + pulse * 65)),
        width=5,
    )
    floor_draw.arc(
        (163, 318, 349, 405),
        math.degrees(phase),
        math.degrees(phase) + 72,
        fill=(255, 229, 177, 235),
        width=7,
    )
    floor_draw.arc(
        (163, 318, 349, 405),
        math.degrees(phase) + 180,
        math.degrees(phase) + 245,
        fill=(99, 225, 255, 220),
        width=6,
    )
    floor_light.putalpha(ImageChops.multiply(floor_light.getchannel("A"), window_mask))
    frame.alpha_composite(floor_light)

    shadow = Image.new("RGBA", frame.size)
    shadow_draw = ImageDraw.Draw(shadow, "RGBA")
    shadow_draw.ellipse((166, 337, 346, 393), fill=(8, 11, 13, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=7))
    frame.alpha_composite(shadow)

    vehicle_scale = min(186 / vehicle.width, 76 / vehicle.height)
    displayed_vehicle = vehicle.resize(
        (
            max(1, round(vehicle.width * vehicle_scale)),
            max(1, round(vehicle.height * vehicle_scale)),
        ),
        Image.Resampling.LANCZOS,
    )
    vehicle_x = (frame.width - displayed_vehicle.width) // 2
    vehicle_y = 359 - displayed_vehicle.height // 2
    frame.alpha_composite(displayed_vehicle, (vehicle_x, vehicle_y))

    effects = Image.new("RGBA", frame.size)
    effects_draw = ImageDraw.Draw(effects, "RGBA")
    # Moving glass reflection and ceiling spotlights make working state legible
    # at normal Factorio zoom without becoming a floating UI indicator.
    sweep_x = 145 + round(index / (count - 1) * 190)
    effects_draw.polygon(
        (
            (sweep_x - 25, 301),
            (sweep_x - 5, 301),
            (sweep_x + 42, 411),
            (sweep_x + 18, 411),
        ),
        fill=(216, 246, 255, 38),
    )
    for light_x, target_x in ((179, 218), (333, 294)):
        effects_draw.polygon(
            ((light_x - 8, 303), (light_x + 8, 303), (target_x + 31, 391), (target_x - 31, 391)),
            fill=(255, 224, 171, round(13 + pulse * 15)),
        )
        glow(effects_draw, (light_x, 306), 3, (255, 234, 199), round(145 + pulse * 80))

    for light_index, light_x in enumerate(range(158, 360, 25)):
        distance = (light_index - index) % 8
        alpha = 245 if distance == 0 else 115 if distance in (1, 7) else 42
        glow(effects_draw, (light_x, 300), 3, (255, 168, 45), alpha)

    effects = effects.filter(ImageFilter.GaussianBlur(radius=0.45))
    effects.putalpha(ImageChops.multiply(effects.getchannel("A"), window_mask))
    frame.alpha_composite(effects)


def build_sales_office_showroom_animations() -> None:
    background, window_mask = active_showroom_background()
    ANIMATION_DIR.mkdir(parents=True, exist_ok=True)
    for name in ("prototype-roadster", "premium-ev", "mass-market-ev", "megatruck"):
        vehicle = sales_office_vehicle(name)
        sheet = Image.new("RGBA", (512 * 8, 512))
        for frame_index in range(8):
            frame = Image.new("RGBA", (512, 512))
            paint_active_sales_showroom(
                frame,
                vehicle,
                background,
                window_mask,
                frame_index,
                8,
            )
            sheet.alpha_composite(frame, (frame_index * 512, 0))
        sheet.save(
            ANIMATION_DIR / f"sales-office-showroom-{name}.png",
            optimize=True,
        )


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
    if name == "bitertaxi-dispatch-lights":
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


def paint_biterfactory_v1_activity(frame: Image.Image, index: int, count: int) -> None:
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


def paint_biterfactory_v2_activity(frame: Image.Image, index: int, count: int) -> None:
    draw = ImageDraw.Draw(frame, "RGBA")
    phase = index / count * math.tau
    for fan_index, center in enumerate(((203, 21), (309, 21))):
        paint_factory_fan(draw, center, phase * 1.7 + fan_index * math.pi / 4, (82, 224, 255))

    # Twin structural_casting cells pulse independently while shuttle tables move
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


def paint_biterfactory_loading_lights(frame: Image.Image, index: int, count: int) -> None:
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
    animation_sheet("biterfactory-v1-activity", 512, 512, paint_biterfactory_v1_activity)
    animation_sheet("biterfactory-v2-activity", 512, 512, paint_biterfactory_v2_activity)
    animation_sheet("biterfactory-loading-lights", 512, 128, paint_biterfactory_loading_lights)
    animation_sheet("datacenter-cooling-fans", 128, 64, paint_fans)
    animation_sheet("bitertaxi-dispatch-lights", 128, 64, paint_dispatch_lights)
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
    build_technology_icon("biterfactory", "biterfactory.png", "biterfactory-module.png", (255, 156, 40))
    build_technology_icon("terrestrial-ai", "terrestrial-datacenter.png", "ai-token.png", (64, 196, 255))
    build_technology_icon("autonomous-logistics", "bitertaxi-depot.png", "bitertaxi-fleet.png", (255, 194, 48))
    build_technology_icon("planetary-energy-grid", "planetary-grid-controller.png", "planetary-grid-segment.png", (68, 224, 255))
    build_technology_icon("achieving-agi", "agi-model.png", "ai-token.png", (255, 184, 48))


def main() -> int:
    build_energy_product_art()
    build_static_entity_art()
    derive_and_normalize_icons()
    build_sales_office_showroom_vehicles()
    build_sales_office_showroom_animations()
    build_animations()
    build_technology_icons()
    print(f"Built normalized icons in {ICON_DIR}")
    print(f"Built Sales Office vehicle overlays in {SHOWROOM_DIR}")
    print(f"Built active Sales Office showroom animations in {ANIMATION_DIR}")
    print(f"Built animation overlays in {ANIMATION_DIR}")
    print(f"Built technology icons in {TECHNOLOGY_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
