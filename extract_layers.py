#!/usr/bin/env python3
"""
extract_layers.py
=================
Slice a flat-illustration background into transparent RGBA parallax layers
using HSV color-range + vertical Gaussian position masking.

Dependencies: numpy, scipy, Pillow  (all already installed)

Usage
-----
  python extract_layers.py --act prologue            # Prologue only (first test)
  python extract_layers.py --act prologue --preview  # Open result windows, don't save
  python extract_layers.py                           # All configured acts
"""

import argparse
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

SCRIPT_DIR = Path(__file__).parent
BG_DIR     = SCRIPT_DIR / "assets" / "backgrounds"


# ── Core extraction ──────────────────────────────────────────────────────────

def extract_layer(
    source: np.ndarray,       # H×W×3 float32 RGB, values 0-1
    hue_lo: float,            # HSV hue lower bound (degrees 0–360)
    hue_hi: float,            # HSV hue upper bound (degrees 0–360; lo>hi wraps)
    val_lo: float,            # HSV value (brightness) lower bound 0–1
    val_hi: float,            # HSV value upper bound 0–1
    vert_center: float,       # Gaussian bell centre (0=top, 1=bottom)
    vert_sigma: float,        # Gaussian half-width (fraction of image height)
    color_weight: float = 0.55,
    blur_px: int = 20,
) -> Image.Image:
    """Return RGBA PIL image: matched pixels opaque, others transparent, edges feathered."""
    H, W = source.shape[:2]

    # ── Manual HSV (avoids scikit-image dependency) ──────────────────────────
    R = source[:, :, 0]
    G = source[:, :, 1]
    B = source[:, :, 2]
    Cmax  = np.maximum.reduce([R, G, B])
    Cmin  = np.minimum.reduce([R, G, B])
    delta = Cmax - Cmin + 1e-9

    hue = np.where(
        Cmax == R, 60.0 * ((G - B) / delta % 6),
        np.where(
            Cmax == G, 60.0 * ((B - R) / delta + 2.0),
                       60.0 * ((R - G) / delta + 4.0),
        ),
    )
    hue = hue % 360.0
    val = Cmax   # value channel

    # ── Color match score ────────────────────────────────────────────────────
    if hue_lo <= hue_hi:
        hue_ok = (hue >= hue_lo) & (hue <= hue_hi)
    else:                       # wraps around 360° (e.g. reds: lo=340 hi=20)
        hue_ok = (hue >= hue_lo) | (hue <= hue_hi)

    val_ok      = (val >= val_lo) & (val <= val_hi)
    color_score = (hue_ok & val_ok).astype(np.float32)

    # ── Vertical position score (Gaussian bell) ──────────────────────────────
    ys         = np.linspace(0.0, 1.0, H)[:, np.newaxis]   # shape (H,1) — broadcasts
    vert_score = np.exp(
        -0.5 * ((ys - vert_center) / max(vert_sigma, 0.01)) ** 2
    ).astype(np.float32)

    # ── Blend and feather ────────────────────────────────────────────────────
    vert_w  = 1.0 - color_weight
    alpha_f = np.clip(color_weight * color_score + vert_w * vert_score, 0.0, 1.0)
    alpha_f = gaussian_filter(alpha_f, sigma=blur_px)
    alpha_u8 = (alpha_f * 255.0).clip(0, 255).astype(np.uint8)

    rgb_u8 = (source * 255.0).clip(0, 255).astype(np.uint8)
    rgba   = np.dstack([rgb_u8, alpha_u8])
    return Image.fromarray(rgba, "RGBA")


# ── Per-act configs ──────────────────────────────────────────────────────────
# source : PNG filename inside BG_DIR
# layers : list of dicts — one per output layer (sky → mid → near, farthest first)
#   name          → appended to output filename, e.g. bg_prologue_ex_sky.png
#   hue_lo/hi     → HSV hue band (degrees)
#   val_lo/hi     → HSV value (brightness) band
#   vert_center   → Gaussian centre on vertical axis (0=top, 1=bottom)
#   vert_sigma    → Gaussian half-width
#   color_weight  → weight of colour score vs vertical score (0–1)
#   blur_px       → Gaussian feather radius in pixels

CONFIGS: dict = {
    "prologue": {
        "source": "bg_prologue_rc.png",   # Recraft composite with 3 clear depth bands
        "layers": [
            # Sky — bright amber-orange upper band + cream clouds. val>0.65 avoids
            # the mid-tone grass strip at y≈65% bleeding into this layer.
            {
                "name": "sky",
                "hue_lo": 15.0, "hue_hi": 55.0,
                "val_lo": 0.65, "val_hi": 1.00,
                "vert_center": 0.25, "vert_sigma": 0.25,
                "color_weight": 0.55, "blur_px": 24,
            },
            # Mid — medium-brightness orange-brown silhouettes (temple, palms, mountains)
            {
                "name": "mid",
                "hue_lo": 10.0, "hue_hi": 45.0,
                "val_lo": 0.28, "val_hi": 0.64,
                "vert_center": 0.50, "vert_sigma": 0.24,
                "color_weight": 0.45, "blur_px": 18,
            },
            # Near — very dark near-black silhouettes (tall palm trunk, foreground grass)
            {
                "name": "near",
                "hue_lo":  0.0, "hue_hi": 60.0,
                "val_lo":  0.0, "val_hi": 0.28,
                "vert_center": 0.78, "vert_sigma": 0.22,
                "color_weight": 0.42, "blur_px": 16,
            },
        ],
    },
    # Acts 1–5 added here after prologue test passes
}


# ── Processing ───────────────────────────────────────────────────────────────

def process_act(act_key: str, preview: bool = False) -> list:
    cfg = CONFIGS[act_key]
    src = BG_DIR / cfg["source"]
    if not src.exists():
        print(f"  ⚠️  source not found: {src}")
        return []

    img = Image.open(src).convert("RGB")
    arr = np.array(img, dtype=np.float32) / 255.0
    print(f"  source: {src.name}  ({img.width}×{img.height})")

    saved = []
    for ldef in cfg["layers"]:
        print(f"  extracting '{ldef['name']}' layer ...", end=" ", flush=True)
        layer_img = extract_layer(
            arr,
            ldef["hue_lo"],  ldef["hue_hi"],
            ldef["val_lo"],  ldef["val_hi"],
            ldef["vert_center"], ldef["vert_sigma"],
            ldef.get("color_weight", 0.55),
            ldef.get("blur_px", 20),
        )
        out_name = f"bg_{act_key}_ex_{ldef['name']}.png"
        if preview:
            print("(preview)")
            layer_img.show(title=out_name)
        else:
            out_path = BG_DIR / out_name
            layer_img.save(out_path)
            print(f"saved  ({out_path.stat().st_size // 1024} KB)")
            saved.append(out_name)
    return saved


def main():
    ap = argparse.ArgumentParser(description="Extract transparent parallax layers from flat-illustration backgrounds")
    ap.add_argument("--act",     default="all", help="prologue | 1 | 2 | … | all")
    ap.add_argument("--preview", action="store_true", help="open result in viewer, don't save")
    args = ap.parse_args()

    acts = [args.act] if args.act != "all" else list(CONFIGS.keys())
    for act in acts:
        if act not in CONFIGS:
            print(f"\n[{act}]  ⚠️  not configured yet")
            continue
        print(f"\n[{act}]")
        saved = process_act(act, args.preview)
        for name in saved:
            print(f"  ✅  {name}")

    print("\nDone.")
    if not args.preview:
        print("Next: python extract_layers.py --act prologue --preview  (to review before wiring into Godot)")


if __name__ == "__main__":
    main()
