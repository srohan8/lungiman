#!/usr/bin/env python3
"""
make_parallax_layers.py
=======================
Uses parallax-maker's depth pipeline to slice each act composite background
into transparent parallax layers, saved ready for Godot.

Usage
-----
  python make_parallax_layers.py                   # process all composites
  python make_parallax_layers.py --act prologue    # prologue only
  python make_parallax_layers.py --act 1           # Act 1 only
  python make_parallax_layers.py --layers 5        # number of depth slices (default 5)
  python make_parallax_layers.py --model dinov2    # depth model: midas | zoedepth | dinov2

Output
------
  assets/backgrounds/bg_prologue_layer_0.png  <- sky (farthest)
  assets/backgrounds/bg_prologue_layer_1.png
  assets/backgrounds/bg_prologue_layer_2.png
  assets/backgrounds/bg_prologue_layer_3.png
  assets/backgrounds/bg_prologue_layer_4.png  <- ground (nearest)
  (same pattern for bg_act1 ... bg_act5)
"""

import sys
import argparse
import numpy as np
from pathlib import Path
from PIL import Image

# -- Point at parallax-maker's venv ------------------------------------------
PMAKER_VENV = Path(r"C:\Project Tools\parallax-maker\venv\Lib\site-packages")
if str(PMAKER_VENV) not in sys.path:
    sys.path.insert(0, str(PMAKER_VENV))
# Also add the parallax-maker source itself
PMAKER_SRC = Path(r"C:\Project Tools\parallax-maker")
if str(PMAKER_SRC) not in sys.path:
    sys.path.insert(0, str(PMAKER_SRC))

from parallax_maker.depth import DepthEstimationModel
from parallax_maker.segmentation import (
    generate_depth_map,
    analyze_depth_histogram,
    generate_image_slices,
)

# -- Paths --------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).parent
BG_DIR     = SCRIPT_DIR / "assets" / "backgrounds"

# Map act name -> composite PNG filename
ACTS = {
    "prologue": "bg_prologue.png",
    "1":        "bg_act1.png",
    "2":        "bg_act2.png",
    "3":        "bg_act3.png",
    "4":        "bg_act4.png",
    "5":        "bg_act5.png",
}

# Human-readable layer names (index 0 = farthest/sky)
LAYER_NAMES = ["sky", "far", "mid", "near", "ground"]


def process_image(composite_path: Path, act_key: str, num_layers: int, model_name: str):
    print(f"\n  >> {composite_path.name}  ->  {num_layers} layers  [{model_name}]")

    # Load image
    img_pil  = Image.open(composite_path).convert("RGB")
    img_np   = np.array(img_pil)

    # Depth map
    print("      depth map ...", end=" ", flush=True)
    model = DepthEstimationModel(model=model_name)
    depth = generate_depth_map(img_np, model)
    print("done")

    # Auto-thresholds
    thresholds = analyze_depth_histogram(depth, num_slices=num_layers)
    print(f"      thresholds: {thresholds}")

    # Slice
    print("      slicing ...", end=" ", flush=True)
    slices = generate_image_slices(img_np, depth, thresholds, num_expand=40)
    print("done")

    # Save
    prefix = f"bg_{act_key}" if act_key != "prologue" else "bg_prologue"
    saved = []
    for i, s in enumerate(slices):
        # index 0 = farthest (sky); name using LAYER_NAMES list, fall back to index
        layer_label = LAYER_NAMES[i] if i < len(LAYER_NAMES) else str(i)
        out_name = f"{prefix}_layer_{i}_{layer_label}.png"
        out_path = BG_DIR / out_name
        # s.image is RGBA numpy array
        Image.fromarray(s.image, "RGBA").save(out_path)
        saved.append(out_name)
        print(f"      OK  {out_name}")

    return saved


def main():
    parser = argparse.ArgumentParser(description="Slice act composites into parallax layers")
    parser.add_argument("--act",    default="all",   help="prologue | 1-5 | all")
    parser.add_argument("--layers", default=5, type=int, help="number of depth slices")
    parser.add_argument("--model",  default="dinov2",
                        choices=["midas", "zoedepth", "dinov2"],
                        help="depth estimation model")
    args = parser.parse_args()

    acts_to_run = ACTS if args.act == "all" else {args.act: ACTS[args.act]}

    print("=" * 60)
    print("  Parallax Layer Generator -- Kanjiravanam Chronicles")
    print("=" * 60)

    all_saved = {}
    for act_key, filename in acts_to_run.items():
        composite = BG_DIR / filename
        if not composite.exists():
            print(f"\n  SKIP  {filename} -- file not found")
            continue
        saved = process_image(composite, act_key, args.layers, args.model)
        all_saved[act_key] = saved

    print("\n" + "=" * 60)
    print("  Done! Files saved to assets/backgrounds/")
    print()
    print("  Next steps:")
    print("  1. Check the layer PNGs look right (open in any viewer)")
    print("  2. Update World.gd / Act*.gd layer paths to use the new names")
    print("  3. Rescan filesystem in Godot")
    print("=" * 60)

    # Print a summary of what to put in World.gd / Act*.gd
    print()
    for act_key, names in all_saved.items():
        label = "World.gd (Prologue)" if act_key == "prologue" else f"Act{act_key}.gd"
        print(f"  {label}:")
        scroll_speeds = [0.02, 0.08, 0.18, 0.35, 0.70]
        for i, name in enumerate(names):
            speed = scroll_speeds[i] if i < len(scroll_speeds) else 0.5
            print(f'    {{"path": "res://assets/backgrounds/{name}", "scroll": {speed}, "tile": true}},')
        print()


if __name__ == "__main__":
    main()
