#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/blender/battery-cybertrain/renders"
GRAPHICS = ROOT / "mod/factoryx_0.1.0/graphics"
ICON_OUTPUT = GRAPHICS / "icons"
TRAIN_OUTPUT = GRAPHICS / "entity/cybertrain"
STOP_OUTPUT = GRAPHICS / "entity/cybertrain-charging-stop"
FRAME_SIZE = 256
NORTH_SOURCE_FRAME = 23


def crop_icon(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if not bounds:
        raise ValueError(f"{source} is fully transparent")
    subject = image.crop(bounds)
    subject.thumbnail((224, 224), Image.Resampling.LANCZOS)
    icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    icon.alpha_composite(subject, ((256 - subject.width) // 2, (256 - subject.height) // 2))
    icon.save(destination, optimize=True)


def source_frame(direction: int) -> int:
    return (NORTH_SOURCE_FRAME - direction) % 64


def build_train_sheet(shadow: bool = False) -> None:
    sheet = Image.new("RGBA", (FRAME_SIZE * 8, FRAME_SIZE * 8), (0, 0, 0, 0))
    infix = "-shadow" if shadow else ""
    for direction in range(64):
        index = source_frame(direction)
        frame = Image.open(SOURCE / "directions" / f"cybertrain{infix}-{index:02d}.png").convert("RGBA")
        if shadow:
            alpha = frame.getchannel("A").filter(ImageFilter.GaussianBlur(4)).point(lambda value: round(value * 0.44))
            frame = Image.new("RGBA", frame.size, (0, 0, 0, 0))
            frame.putalpha(alpha)
        sheet.alpha_composite(frame, ((direction % 8) * FRAME_SIZE, (direction // 8) * FRAME_SIZE))
    TRAIN_OUTPUT.mkdir(parents=True, exist_ok=True)
    sheet.save(TRAIN_OUTPUT / ("cybertrain-shadow.png" if shadow else "cybertrain.png"), optimize=True)


def build_stop_sheet(shadow: bool = False) -> None:
    sheet = Image.new("RGBA", (FRAME_SIZE * 4, FRAME_SIZE), (0, 0, 0, 0))
    infix = "-shadow" if shadow else ""
    for direction in range(4):
        frame = Image.open(SOURCE / "stop-directions" / f"charging-stop{infix}-{direction}.png").convert("RGBA")
        if shadow:
            alpha = frame.getchannel("A").filter(ImageFilter.GaussianBlur(4)).point(lambda value: round(value * 0.44))
            frame = Image.new("RGBA", frame.size, (0, 0, 0, 0))
            frame.putalpha(alpha)
        sheet.alpha_composite(frame, (direction * FRAME_SIZE, 0))
    STOP_OUTPUT.mkdir(parents=True, exist_ok=True)
    sheet.save(STOP_OUTPUT / ("charging-stop-shadow.png" if shadow else "charging-stop.png"), optimize=True)


def main() -> None:
    ICON_OUTPUT.mkdir(parents=True, exist_ok=True)
    for source in sorted((SOURCE / "icons").glob("*.png")):
        crop_icon(source, ICON_OUTPUT / source.name)
        print(f"Built icon {source.stem}")
    crop_icon(SOURCE / "cybertrain-master.png", ICON_OUTPUT / "electric-semi.png")
    build_train_sheet(False)
    build_train_sheet(True)
    build_stop_sheet(False)
    build_stop_sheet(True)
    print("Built Cybertrain directional sprites")
    print("Built Cybertrain charging-stop directional sprites")


if __name__ == "__main__":
    main()
