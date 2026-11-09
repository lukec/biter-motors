#!/usr/bin/env python3
"""Render measured native thermal traces, not synthetic gameplay screenshots."""
import argparse
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


def draw_trace(samples, reports, output, *, fault=False):
    repair = next(row["tick"] for row in reports if row["status"] == "repair_passed")
    burned = next(row for row in reports if row["status"] == "burnout_passed")
    death = burned["thermal"]["burnout_events"][0]
    origin = repair if fault else 0
    selected = [row for row in samples if row["tick"] >= origin]
    end = max(death["tick"], max(row["tick"] for row in selected))
    span = (end - origin) / 60
    canvas = Image.new("RGB", (1120, 470), "#151a20")
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default(size=16)
    small = ImageFont.load_default(size=13)
    title = ImageFont.load_default(size=22)
    left, top, width, height = 64, 90, 1024, 310
    def point(tick, temp):
        return left + (tick - origin) / 60 / span * width, top + (140 - temp) / 140 * height
    draw.text((24, 18), "PIPE FAILURE / NATIVE CORE DESTRUCTION" if fault else "NATIVE ORBITAL THERMAL TEST", fill="#f0f3f5", font=title)
    draw.text((24, 51), "Measured simulation time, not wall time or an in-game screenshot", fill="#aeb9c4", font=small)
    for temperature in (0, 30, 60, 90, 120):
        y = point(origin, temperature)[1]
        draw.line((left, y, left + width, y), fill="#343e48")
        draw.text((12, y - 8), str(temperature), fill="#aeb9c4", font=small)
    for temperature, color, label in ((97, "#69c58d", "97 C target"), (105, "#d9b15e", "105 C warning"), (130, "#ef7770", "130 C destruction")):
        y = point(origin, temperature)[1]
        draw.line((left, y, left + width, y), fill=color)
        draw.text((left + 8, y - 16), label, fill=color, font=small)
    for step in range(9):
        seconds = step * span / 8
        x = left + step * width / 8
        draw.text((x - 12, top + height + 12), f"{seconds:.0f}s" if fault else f"{seconds / 60:.0f}m", fill="#aeb9c4", font=small)
    for kind, color in (("core", "#9ed5ff"), ("radiator", "#ceabed")):
        points = []
        for row in selected:
            entries = row["thermal"]["cores" if kind == "core" else "radiators"]
            if entries:
                points.append(point(row["tick"], entries[0]["temperature"]))
        if kind == "core":
            points.append(point(death["tick"], death["temperature"]))
        if len(points) > 1:
            draw.line(points, fill=color, width=3)
    x, y = point(death["tick"], death["temperature"])
    draw.line((x - 6, y - 6, x + 6, y + 6), fill="#ff5959", width=3)
    draw.line((x - 6, y + 6, x + 6, y - 6), fill="#ff5959", width=3)
    draw.text((64, 445), "Core temperature", fill="#9ed5ff", font=font)
    draw.text((255, 445), "Connected radiator", fill="#ceabed", font=font)
    draw.text((490, 445), "X = real native entity death; no automatic shutdown", fill="#ef7770", font=small)
    canvas.save(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samples", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    samples = [json.loads(line) for line in args.samples.read_text().splitlines()]
    reports = [json.loads(line) for line in args.report.read_text().splitlines()]
    if not reports or reports[-1]["status"] != "reload_passed":
        raise ValueError("complete native validation required")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    for fault, suffix in ((False, "overview"), (True, "failure")):
        draw_trace(samples, reports, args.output.with_name("orbital-thermal-" + suffix + ".png"), fault=fault)
    steady = next(row for row in reports if row["status"] == "steady_passed")["thermal"]["cores"][0]
    burned = next(row for row in reports if row["status"] == "burnout_passed")
    event = burned["thermal"]["burnout_events"][0]
    summary = {"scope": "isolated native prototype, not campaign or graphical qualification",
               "steady_c": round(steady["temperature"], 3), "burnout_c": round(event["temperature"], 3),
               "seconds_from_110c_checkpoint": burned["seconds_from_hot_checkpoint"],
               "seconds_from_nominal_disconnect": (event["tick"] - next(row["tick"] for row in reports if row["status"] == "repair_passed")) / 60,
               "native_deaths": reports[-1]["native_deaths"],
               "stages": [{"status": row["status"], "tick": row["tick"]} for row in reports]}
    args.output.with_suffix(".json").write_text(json.dumps(summary, indent=2) + "\n")
    stats = "".join(f"<tr><th>{html.escape(label)}</th><td>{value}</td></tr>" for label, value in (
        ("Operating temperature", f'{summary["steady_c"]} C'), ("Warning", "105 C"),
        ("Native destruction", f'{summary["burnout_c"]} C'),
        ("Repair window from 97 C", f'{summary["seconds_from_nominal_disconnect"]} simulated seconds'),
        ("Remaining repair time at 110 C", f'{summary["seconds_from_110c_checkpoint"]} simulated seconds'),
        ("Destructions after reload", summary["native_deaths"])))
    args.output.write_text("""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Orbital Thermal Prototype</title><style>body{margin:0;background:#151a20;color:#e2e7eb;font:16px/1.5 system-ui}main{max-width:1120px;margin:auto;padding:24px}h1{font-size:28px}a{color:#9ed5ff}img{max-width:100%;height:auto}th,td{text-align:left;padding:6px 24px 6px 0}section{border-top:1px solid #4b5763;margin-top:24px;padding-top:18px}.warning{color:#e9bc6e}</style>
<main><h1>Orbital Thermal Prototype</h1><p>97 C target. Physical conduits. Finite radiators. Destructive overheating.</p>
<p class="warning">Experimental add-on only. The main campaign and live save are unchanged. These charts show native engine measurements, not gameplay screenshots.</p>
<table>""" + stats + """</table><section><h2>Working, Cooling And Failing</h2><img src="orbital-thermal-overview.png" alt="Measured core and radiator temperatures over the full native test">
<p>The test includes native solar power, output backpressure, brownouts, a full outage, pipe removal, repair, a hot checkpoint, destruction and a second reload.</p></section>
<section><h2>Ignore The Warning</h2><img src="orbital-thermal-failure.png" alt="Core heats after pipe disconnection and is destroyed at 130 degrees Celsius">
<p>Repair the conduit before burnout and the same core keeps working. Leave it disconnected and it is destroyed; loading a hot save does not erase the heat.</p></section>
<section><h2>Scope</h2><p>Supplied platform, hardware, research and capital. Native heat conduction, crafting, solar power and death. Heat generation and finite radiator rejection are scripted. The radiation law and thermal capacities are gameplay approximations.</p>
<p><a href="orbital-thermal-prototype.md">Design and test notes</a> | <a href="orbital-thermal-prototype.json">Compact measured results</a></p></section></main></html>""")
    print(args.output)


if __name__ == "__main__":
    main()
