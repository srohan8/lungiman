#!/usr/bin/env python3
"""
Kanjiravanam Chronicles — Replicate Sprite Generation Pipeline
==============================================================
Generates Kerala mural-style sprite sheets for all characters, enemies, and
props.  Reads REPLICATE_API_TOKEN from the .env file next to this script.

Usage
-----
  python generate_sprites.py                          # Generate all missing sprites
  python generate_sprites.py --force                  # Regenerate even if file exists
  python generate_sprites.py --category npcs          # Only NPCs
  python generate_sprites.py --category enemies       # Only enemies / bosses
  python generate_sprites.py --category props         # Only props
  python generate_sprites.py --sheet thoma_sheet      # Single sheet only
  python generate_sprites.py --list                   # Show status of all sprites
  python generate_sprites.py --dry-run                # Show what would be generated (no API calls)
  python generate_sprites.py --estimate               # Cost estimate and exit

Requirements
------------
  pip install replicate Pillow python-dotenv requests rembg
  (rembg is optional but gives much better background removal)
"""

import argparse
import os
import sys
import time
from io import BytesIO
from pathlib import Path
from typing import Optional

# Force UTF-8 on Windows terminals (emoji + box-drawing chars)
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# ── dependency check ─────────────────────────────────────────────────────────
_missing = []
try:
    from dotenv import load_dotenv
except ImportError:
    _missing.append("python-dotenv")
try:
    import replicate
except ImportError:
    _missing.append("replicate")
try:
    from PIL import Image
except ImportError:
    _missing.append("Pillow")
try:
    import requests
except ImportError:
    _missing.append("requests")

if _missing:
    print("Missing dependencies:", ", ".join(_missing))
    print("Install with:  pip install " + " ".join(_missing))
    sys.exit(1)

# rembg is optional — graceful fallback if not installed
try:
    from rembg import remove as rembg_remove
    HAVE_REMBG = True
except ImportError:
    HAVE_REMBG = False

# ─────────────────────────────────────────────────────────────────────────────
# Paths & models
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR  = Path(__file__).parent
ENV_FILE    = SCRIPT_DIR / ".env"
SPRITES_DIR = SCRIPT_DIR / "assets" / "sprites"
BG_DIR      = SCRIPT_DIR / "assets" / "backgrounds"
REF_DIR     = SCRIPT_DIR / "assets" / "reference"   # drop reference images here

MODEL_FAST    = "black-forest-labs/flux-schnell"  # ~$0.003 / image
MODEL_QUALITY = "black-forest-labs/flux-dev"      # ~$0.025 / image
MODEL_RECRAFT = "recraft-ai/recraft-v3"           # ~$0.040 / image — better at isolated elements + flat illustration

COST = {MODEL_FAST: 0.003, MODEL_QUALITY: 0.025, MODEL_RECRAFT: 0.040}

# Valid size strings for Recraft v3 (width × height)
_RECRAFT_SIZES = [
    (1024, 1024), (1365, 1024), (1024, 1365), (1536, 1024),
    (1024, 1536), (1820, 1024), (1024, 1820), (2048, 1024),
    (1024, 2048), (1434, 1024), (1024, 1434), (1024, 1280),
    (1280, 1024), (1024, 1707), (1707, 1024),
]

def _recraft_size(w: int, h: int) -> str:
    """Map desired (w, h) to the closest Recraft v3 size enum string."""
    target_ratio = w / max(h, 1)
    best = min(_RECRAFT_SIZES,
               key=lambda s: (abs(s[0] / s[1] - target_ratio), abs(s[0] * s[1] - w * h)))
    return f"{best[0]}x{best[1]}"

# ─────────────────────────────────────────────────────────────────────────────
# Art style fragments re-used across all prompts
# ─────────────────────────────────────────────────────────────────────────────
_STYLE = (
    "Kerala mural Kathakali aesthetic, bold black outlines, jewel-tone fills, "
    "warm amber gold palette, flat 2D cartoon game sprite art, "
    "pure white background, single character, no text, no watermark, no border"
)

_SIDE = _STYLE + ", strict side-view profile facing right, full body visible, feet touching ground"

# ─────────────────────────────────────────────────────────────────────────────
# Sprite database
# ─────────────────────────────────────────────────────────────────────────────
# Structure per sheet:
#   desc     — human label for logging
#   frame_w  — width of ONE frame in the final strip (px)
#   frame_h  — height of the strip (px)
#   model    — Replicate model to use
#   frames   — list of {name, prompt}
#
# The generated image for each frame is resized to (frame_w × frame_h) and
# then all frames are stitched side-by-side into a horizontal strip.
# ─────────────────────────────────────────────────────────────────────────────

SPRITE_DB: dict = {

    # ── NPCs ─────────────────────────────────────────────────────────────────
    "npcs": {

        "thoma_sheet": {
            "desc": "BrotherThoma — Kerala Christian protector",
            "frame_w": 256, "frame_h": 512, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "idle",
                    "prompt": (
                        "Middle-aged Kerala Christian man, plain white mundu, "
                        "small wooden cross necklace, warm gentle face, short greying hair, "
                        "warm brown South Indian skin, arms relaxed at sides, standing calmly, "
                        + _SIDE
                    ),
                },
                {
                    "name": "talk",
                    "prompt": (
                        "Middle-aged Kerala Christian man, plain white mundu, "
                        "small wooden cross necklace, talking expressively, one hand raised open palm, "
                        "warm gentle expression, short greying hair, warm brown skin, "
                        + _SIDE
                    ),
                },
            ],
        },

        "soniya_sheet": {
            "desc": "SoniyaChechi — Chaya Kada owner",
            "frame_w": 256, "frame_h": 512, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "idle",
                    "prompt": (
                        "Middle-aged plump cheerful Kerala woman, bright floral churidar salwar, "
                        "gold earrings, dark hair in tight bun, holding stainless-steel chai flask, "
                        "warm inviting smile, warm brown South Indian skin, "
                        + _SIDE
                    ),
                },
                {
                    "name": "talk",
                    "prompt": (
                        "Middle-aged plump cheerful Kerala woman, bright floral churidar salwar, "
                        "gold earrings, dark hair in bun, chai flask at hip, "
                        "animated talking pose both hands gesturing, big warm smile, "
                        + _SIDE
                    ),
                },
            ],
        },

        "basheer_sheet": {
            "desc": "Ustad Basheer — elder tracker",
            "frame_w": 256, "frame_h": 512, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "idle",
                    "prompt": (
                        "Elderly Muslim elder, long plain white kurta, white skull cap, "
                        "gnarled wooden walking staff, long full white beard, "
                        "deep-set wise eyes, weathered warm brown skin, calm dignified stance, "
                        + _SIDE
                    ),
                },
                {
                    "name": "talk",
                    "prompt": (
                        "Elderly Muslim elder, long plain white kurta, white skull cap, "
                        "long white beard, staff in one hand, other hand raised with pointing finger, "
                        "sharing wisdom expression, eyes slightly closed in thought, "
                        + _SIDE
                    ),
                },
            ],
        },

        "biju_sheet": {
            "desc": "Captain Biju — houseboat captain",
            "frame_w": 256, "frame_h": 512, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "idle",
                    "prompt": (
                        "Weathered Kerala ex-fighter turned houseboat captain, "
                        "plain white mundu and unbuttoned white shirt, muscular build softened by age, "
                        "slight grey beard, calm knowing face, man carrying old guilt quietly, "
                        "strong hands at sides, warm brown South Indian skin, "
                        + _SIDE
                    ),
                },
                {
                    "name": "talk",
                    "prompt": (
                        "Weathered Kerala houseboat captain, plain white mundu and open shirt, "
                        "slight grey beard, speaking quietly with weight, head slightly tilted, "
                        "one hand extended gesturing softly, warm brown skin, "
                        + _SIDE
                    ),
                },
            ],
        },

        "ravi_sheet": {
            "desc": "Mundakkal Ravi — toddy shop owner",
            "frame_w": 256, "frame_h": 512, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "idle",
                    "prompt": (
                        "Stout jovial barrel-chested Kerala man, bright colourful lungi, "
                        "bare-chested, slightly tipsy happy grin, round warm face, "
                        "warm brown South Indian skin, arms relaxed at sides, "
                        + _SIDE
                    ),
                },
                {
                    "name": "talk",
                    "prompt": (
                        "Stout jovial barrel-chested Kerala man, bright colourful lungi, "
                        "bare-chested, mouth open laughing, one hand slapping thigh, "
                        "exuberant happy energy, round warm face, "
                        + _SIDE
                    ),
                },
            ],
        },

        "mooppan_sheet": {
            "desc": "Mooppan Velu — forest monk",
            "frame_w": 256, "frame_h": 512, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "idle",
                    "prompt": (
                        "Ancient gaunt Kerala forest monk, extremely thin hollow-cheeked old man, "
                        "simple plain white dhoti, bare-chested bony frame, "
                        "long matted greying hair, leaning on gnarled wooden staff, "
                        "haunted distant eyes, deeply weathered skin, man carrying decades of guilt, "
                        + _SIDE
                    ),
                },
                {
                    "name": "talk",
                    "prompt": (
                        "Ancient gaunt Kerala forest monk, extremely thin old man, "
                        "plain white dhoti, bare-chested, long matted hair, "
                        "one finger raised speaking cryptic parable, eyes closed in meditation, "
                        "other hand still on staff, "
                        + _SIDE
                    ),
                },
            ],
        },

        "maveli_sheet": {
            "desc": "Maveli (Mahabali) — legendary Kerala king",
            "frame_w": 512, "frame_h": 768, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "seated",
                    "prompt": (
                        "Legendary Kerala king Mahabali, large portly regal figure, "
                        "bare-chested with thick gold necklaces and armlets, "
                        "ornate white mundu with heavy gold border, "
                        "tall traditional Kerala raja crown with jewels, "
                        "full black beard, melancholic patient wise eyes, "
                        "seated on ancient stone throne with carved arms, "
                        "oil lamp amber glow illuminating face, sacred amber-gold colour palette, "
                        "serene and immensely dignified, "
                        + _STYLE + ", front facing, full body, seated on throne"
                    ),
                },
                {
                    "name": "stand",
                    "prompt": (
                        "Legendary Kerala king Mahabali, large portly regal figure rising, "
                        "bare-chested with thick gold jewelry, ornate white mundu with gold border, "
                        "tall Kerala raja crown, full black beard, "
                        "beginning to rise from stone throne, regal weight, both hands on throne arms, "
                        "sacred amber-gold palette, "
                        + _STYLE + ", front facing, full body, mid-rise from throne"
                    ),
                },
                {
                    "name": "bless",
                    "prompt": (
                        "Legendary Kerala king Mahabali, large portly regal figure standing, "
                        "bare-chested with thick gold jewelry, ornate white mundu with gold border, "
                        "tall Kerala raja crown, full black beard, "
                        "right hand extended forward palm open upward, "
                        "sacred golden light radiating from palm, blessing gesture, "
                        "warm divine compassionate expression, sacred amber-gold palette, "
                        + _STYLE + ", front facing, full body, blessing pose"
                    ),
                },
            ],
        },

        "kili_sheet": {
            "desc": "Kili the Spirit Crow",
            "frame_w": 192, "frame_h": 192, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "perch",
                    "prompt": (
                        "Spirit crow bird, blue-black feathers with subtle amber glow aura, "
                        "glowing amber eyes, slightly translucent ethereal spirit energy, "
                        "perched on branch wings folded, alert upright pose, "
                        + _STYLE + ", side view full body, perched bird"
                    ),
                },
                {
                    "name": "fly",
                    "prompt": (
                        "Spirit crow bird, blue-black feathers with subtle amber glow aura, "
                        "glowing amber eyes, slightly translucent ethereal spirit, "
                        "wings spread wide mid-flight, dynamic soaring pose, "
                        + _STYLE + ", side view full body, wings spread flying"
                    ),
                },
                {
                    "name": "caw",
                    "prompt": (
                        "Spirit crow bird, blue-black feathers with amber glow aura, "
                        "glowing amber eyes, beak open wide cawing loudly, "
                        "wings slightly raised in alarm, warning call pose, "
                        + _STYLE + ", side view full body, cawing bird"
                    ),
                },
            ],
        },
    },

    # ── Enemies & Bosses ─────────────────────────────────────────────────────
    "enemies": {

        "croc_sheet": {
            "desc": "Crocodile — river enemy",
            "frame_w": 360, "frame_h": 176, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "walk_1",
                    "prompt": (
                        "Crocodile low silhouette, mottled dark green scales, "
                        "short stubby legs, jaw firmly closed, long tail flat, "
                        "patrol walking pose left legs forward, "
                        + _SIDE + ", very low to ground"
                    ),
                },
                {
                    "name": "walk_2",
                    "prompt": (
                        "Crocodile low silhouette, mottled dark green scales, "
                        "short stubby legs, jaw closed, long flat tail, "
                        "patrol walking pose right legs forward, "
                        + _SIDE + ", very low to ground"
                    ),
                },
                {
                    "name": "walk_3",
                    "prompt": (
                        "Crocodile low silhouette, mottled dark green scales, "
                        "short stubby legs, jaw slightly open, tail slightly raised, "
                        "patrol walking third step pose, "
                        + _SIDE + ", very low to ground"
                    ),
                },
                {
                    "name": "lunge",
                    "prompt": (
                        "Crocodile lunging attack, mottled dark green scales, "
                        "jaw wide open showing rows of sharp teeth, "
                        "front body raised off ground, aggressive lunge pose, "
                        + _SIDE + ", attack lunge"
                    ),
                },
            ],
        },

        "yakshi_sheet": {
            "desc": "Yakshi — Act I boss, spirit woman",
            "frame_w": 208, "frame_h": 320, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "float_1",
                    "prompt": (
                        "Yakshi Kerala female spirit, pale moonlit white saree with gold border, "
                        "flowing long dark hair spread wide, large glowing amber eyes, "
                        "floating in mid-air arms loosely spread, "
                        "ethereal mist wisps below where feet should be, "
                        "beautiful but deeply unsettling, Kerala ghost mythology, "
                        + _STYLE + ", front facing full body floating A"
                    ),
                },
                {
                    "name": "float_2",
                    "prompt": (
                        "Yakshi Kerala female spirit, pale moonlit white saree with gold border, "
                        "flowing long dark hair, large glowing amber eyes, "
                        "floating in air arms in slightly different graceful position, "
                        "ethereal mist below, beautiful and unsettling, Kerala ghost, "
                        + _STYLE + ", front facing full body floating B"
                    ),
                },
                {
                    "name": "hypno_1",
                    "prompt": (
                        "Yakshi Kerala female spirit, pale moonlit white saree, "
                        "enormous glowing amber hypnotic eyes wide open, "
                        "arms raised and spread casting hypnosis, "
                        "spiral light rings emanating from eyes, mesmerizing gaze, "
                        + _STYLE + ", front facing full body hypnosis A"
                    ),
                },
                {
                    "name": "hypno_2",
                    "prompt": (
                        "Yakshi Kerala female spirit, pale moonlit white saree, "
                        "hypnotic amber eyes shooting golden rays outward, "
                        "fingers spread wide casting spell, intense focused expression, "
                        "golden energy swirling around hands, "
                        + _STYLE + ", front facing full body hypnosis B"
                    ),
                },
                {
                    "name": "stun",
                    "prompt": (
                        "Yakshi Kerala female spirit, pale moonlit white saree, "
                        "stunned recoiling expression, eyes dimmed half-closed, "
                        "floating lower than usual, arms hanging loosely, "
                        "hit stagger pose, weakened but still floating, "
                        + _STYLE + ", front facing full body stunned"
                    ),
                },
            ],
        },

        "kuttichathan_sheet": {
            "desc": "Kuttichathan — Act II boss, child demon",
            "frame_w": 176, "frame_h": 240, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "idle_1",
                    "prompt": (
                        "Kuttichathan Kerala child spirit, small squat body, "
                        "deep red skin, tiny curved horns on round forehead, "
                        "fiery orange aura radiating around whole body, "
                        "mischievous wide grin big round eyes, arms at sides, "
                        "Kerala mythology child demon, "
                        + _STYLE + ", front facing full body idle A"
                    ),
                },
                {
                    "name": "idle_2",
                    "prompt": (
                        "Kuttichathan Kerala child spirit, small squat body, "
                        "deep red skin, tiny curved horns, fiery orange aura, "
                        "mischievous grin, arms slightly raised bouncing energy, "
                        "Kerala mythology child demon, "
                        + _STYLE + ", front facing full body idle B"
                    ),
                },
                {
                    "name": "spawn_1",
                    "prompt": (
                        "Kuttichathan Kerala child spirit, deep red skin, tiny horns, "
                        "fiery orange aura exploding outward, "
                        "both arms raised triumphantly overhead, "
                        "fire and smoke cloud erupting around feet, emerging pose, "
                        + _STYLE + ", front facing full body spawning A"
                    ),
                },
                {
                    "name": "spawn_2",
                    "prompt": (
                        "Kuttichathan Kerala child spirit, deep red skin, tiny horns, "
                        "fully emerged arms spread wide, "
                        "massive fire explosion ring around body, laughing wildly, "
                        + _STYLE + ", front facing full body spawning B"
                    ),
                },
            ],
        },

        "odiyan_sheet": {
            "desc": "Odiyan — Act III boss, shapeshifter",
            "frame_w": 224, "frame_h": 272, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "human",
                    "prompt": (
                        "Odiyan Kerala shapeshifter in human form, "
                        "hunched figure in grey tattered cloak and hood, "
                        "face hidden in shadow, only glowing yellow eyes visible, "
                        "unsettling stillness, Kerala mythology sorcerer, "
                        + _SIDE
                    ),
                },
                {
                    "name": "bull_1",
                    "prompt": (
                        "Odiyan transformed into massive dark brown bull, "
                        "large curved white horns, muscular powerful body, "
                        "wild glowing yellow eyes, standing patrol stance, "
                        "Kerala mythology shapeshifter bull form, "
                        + _SIDE + ", bull animal"
                    ),
                },
                {
                    "name": "bull_2",
                    "prompt": (
                        "Odiyan transformed into massive dark brown bull, "
                        "large curved white horns, charging forward, "
                        "head lowered neck muscles bulging, hooves raised, "
                        "Kerala mythology shapeshifter bull charging, "
                        + _SIDE + ", bull charging"
                    ),
                },
                {
                    "name": "dog_1",
                    "prompt": (
                        "Odiyan transformed into lean near-black feral dog, "
                        "angular sharp face, long thin legs, glowing yellow eyes, "
                        "prowling slow stalking walk pose, "
                        "Kerala mythology shapeshifter dog form, "
                        + _SIDE + ", dog animal prowling"
                    ),
                },
                {
                    "name": "dog_2",
                    "prompt": (
                        "Odiyan transformed into lean near-black feral dog, "
                        "running at full sprint, body stretched low, "
                        "all four legs extended in gallop, glowing yellow eyes, "
                        "Kerala mythology shapeshifter dog running, "
                        + _SIDE + ", dog running gallop"
                    ),
                },
            ],
        },

        "karinkanni_sheet": {
            "desc": "Karinkanni — Act IV boss, floating eye",
            "frame_w": 240, "frame_h": 240, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "closed",
                    "prompt": (
                        "Karinkanni Kerala spirit, floating round orb body, "
                        "purple-black smooth surface, single large eyelid fully closed, "
                        "serene closed lid with lashes, sinister floating orb, "
                        "Kerala ghost mythology, "
                        + _STYLE + ", front facing, full orb visible, eye closed"
                    ),
                },
                {
                    "name": "half_open",
                    "prompt": (
                        "Karinkanni Kerala spirit, floating round purple-black orb body, "
                        "single large eye half open, iris beginning to glow deep red, "
                        "ominous awakening, Kerala ghost mythology, "
                        + _STYLE + ", front facing, full orb visible, eye half open"
                    ),
                },
                {
                    "name": "open",
                    "prompt": (
                        "Karinkanni Kerala spirit, floating round purple-black orb body, "
                        "single enormous eye fully open, blazing deep red iris pupil, "
                        "red paralysis energy rays shooting outward from eye, "
                        "terrifying stare, Kerala ghost mythology, "
                        + _STYLE + ", front facing, full orb visible, eye fully open blazing"
                    ),
                },
            ],
        },

        "peykomban_sheet": {
            "desc": "PeyKomban — Act V final boss, giant tusk demon",
            "frame_w": 320, "frame_h": 360, "model": MODEL_QUALITY,
            "frames": [
                {
                    "name": "patrol_1",
                    "prompt": (
                        "Pey Komban massive Kerala demon, enormous muscular dark brown body, "
                        "gigantic curved ivory tusks jutting forward, "
                        "four large arms with massive fists, thick trunk-like legs, "
                        "demonic face burning orange eyes, towering over trees, "
                        "walking patrol pose left step, Kerala mythology giant demon, "
                        + _SIDE + ", massive towering demon"
                    ),
                },
                {
                    "name": "patrol_2",
                    "prompt": (
                        "Pey Komban massive Kerala demon, enormous muscular dark brown body, "
                        "gigantic curved ivory tusks, four large arms, thick legs, "
                        "burning orange eyes, mid-stride right step, "
                        "Kerala mythology giant demon, "
                        + _SIDE + ", massive towering demon striding"
                    ),
                },
                {
                    "name": "windup",
                    "prompt": (
                        "Pey Komban massive Kerala demon, enormous dark brown body, "
                        "gigantic ivory tusks, pulling entire body backward coiling for charge, "
                        "orange energy building and glowing around body, "
                        "coiled tension before release, burning eyes focused, "
                        "Kerala mythology giant demon windup, "
                        + _SIDE + ", massive demon coiling"
                    ),
                },
                {
                    "name": "charge",
                    "prompt": (
                        "Pey Komban massive Kerala demon, enormous dark brown body, "
                        "gigantic ivory tusks angled forward like weapons, "
                        "full-speed charge body leaning hard forward, "
                        "ground cracking under feet, unstoppable force, "
                        "Kerala mythology giant demon charging, "
                        + _SIDE + ", massive demon full speed charge"
                    ),
                },
            ],
        },

        "ghost_sheet": {
            "desc": "GhostClone — mirror image enemy",
            "frame_w": 256, "frame_h": 512, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "float_1",
                    "prompt": (
                        "Translucent ghost spirit clone, white and pale blue ethereal wisp, "
                        "vague human silhouette barely visible, "
                        "floating gently upward, semi-transparent ghostly form, "
                        "Kerala forest spirit, "
                        + _STYLE + ", front facing full body floating A"
                    ),
                },
                {
                    "name": "float_2",
                    "prompt": (
                        "Translucent ghost spirit clone, white and pale blue ethereal wisp, "
                        "vague human silhouette, floating slightly different position, "
                        "semi-transparent ghostly form, rippling spirit energy, "
                        "Kerala forest spirit, "
                        + _STYLE + ", front facing full body floating B"
                    ),
                },
            ],
        },

        "monkey_sheet": {
            "desc": "HauntedMonkey — possessed tree enemy",
            "frame_w": 256, "frame_h": 384, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "patrol_1",
                    "prompt": (
                        "Possessed haunted monkey, dark brown fur, glowing red eyes, "
                        "angry possessed snarl, knuckle-walking on all fours, "
                        "left side forward, Kerala forest demon monkey, "
                        + _SIDE
                    ),
                },
                {
                    "name": "patrol_2",
                    "prompt": (
                        "Possessed haunted monkey, dark brown fur, glowing red eyes, "
                        "knuckle-walking mid-stride right side forward, "
                        "Kerala forest demon monkey, "
                        + _SIDE
                    ),
                },
                {
                    "name": "attack_1",
                    "prompt": (
                        "Possessed haunted monkey, dark brown fur, glowing red eyes, "
                        "leaping lunge with arms outstretched reaching forward, "
                        "airborne attack pose, mouth open snarling, "
                        + _SIDE + ", mid-leap attack"
                    ),
                },
                {
                    "name": "attack_2",
                    "prompt": (
                        "Possessed haunted monkey, dark brown fur, glowing red eyes, "
                        "slashing with both clawed hands forward, "
                        "landed attack strike pose, "
                        + _SIDE + ", slashing"
                    ),
                },
            ],
        },

        "crab_sheet": {
            "desc": "CoconutCrab — ground enemy",
            "frame_w": 250, "frame_h": 125, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "walk_1",
                    "prompt": (
                        "Coconut crab, large tropical crab, bright orange-red shell, "
                        "oversized claws, walking sideways frame 1, "
                        "Kerala beach crab, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
                {
                    "name": "walk_2",
                    "prompt": (
                        "Coconut crab, large tropical crab, bright orange-red shell, "
                        "oversized claws, walking sideways frame 2 legs shifted, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
                {
                    "name": "walk_3",
                    "prompt": (
                        "Coconut crab, large tropical crab, bright orange-red shell, "
                        "oversized claws raised slightly, walking frame 3, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
                {
                    "name": "walk_4",
                    "prompt": (
                        "Coconut crab, large tropical crab, orange-red shell, "
                        "claws at chest height alert walking frame 4, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
                {
                    "name": "walk_5",
                    "prompt": (
                        "Coconut crab, large tropical crab, orange-red shell, "
                        "mid-stride claws forward frame 5, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
                {
                    "name": "walk_6",
                    "prompt": (
                        "Coconut crab, large tropical crab, orange-red shell, "
                        "claws slightly open defensive frame 6, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
                {
                    "name": "walk_7",
                    "prompt": (
                        "Coconut crab, large tropical crab, orange-red shell, "
                        "both claws raised threat display frame 7, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
                {
                    "name": "walk_8",
                    "prompt": (
                        "Coconut crab, large tropical crab, orange-red shell, "
                        "return to resting walking pose frame 8, "
                        + _STYLE + ", side view full body low angle"
                    ),
                },
            ],
        },
    },

    # ── Props ─────────────────────────────────────────────────────────────────
    "props": {

        "boat_sheet": {
            "desc": "Kerala vallam river boat",
            "frame_w": 480, "frame_h": 120, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "static",
                    "prompt": (
                        "Kerala traditional wooden vallam river boat, "
                        "long narrow wooden boat with curved raised bow and stern, "
                        "flat-bottomed river craft, warm brown wood planks, "
                        "floating on calm water, "
                        + _STYLE + ", strict side view, full boat length visible"
                    ),
                },
            ],
        },

        "shrine_sheet": {
            "desc": "Bhadrakali roadside shrine",
            "frame_w": 160, "frame_h": 240, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "lamp_off",
                    "prompt": (
                        "Kerala roadside Bhadrakali shrine, small stone platform plinth, "
                        "brass nilavilakku oil lamp unlit, fresh flower offerings, "
                        "stone Bhadrakali carving, "
                        + _STYLE + ", side view full shrine visible"
                    ),
                },
                {
                    "name": "lamp_on",
                    "prompt": (
                        "Kerala roadside Bhadrakali shrine, small stone platform, "
                        "brass nilavilakku oil lamp burning with bright golden flame, "
                        "warm amber glow radiating, fresh flower offerings, "
                        + _STYLE + ", side view full shrine, lamp lit glowing"
                    ),
                },
            ],
        },

        "hoof_marker_sheet": {
            "desc": "Odiyan hoof-print track marker",
            "frame_w": 112, "frame_h": 112, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "pulse_dim",
                    "prompt": (
                        "Glowing demon hoof print track mark on forest ground, "
                        "amber spirit smoke wisps rising, mystical evil track, "
                        "dim glow pulse A, "
                        + _STYLE + ", top-down overhead view"
                    ),
                },
                {
                    "name": "pulse_bright",
                    "prompt": (
                        "Glowing demon hoof print track mark on forest ground, "
                        "amber spirit smoke wisps rising bright, mystical evil track, "
                        "bright glow pulse B, "
                        + _STYLE + ", top-down overhead view"
                    ),
                },
            ],
        },

        "fire_hazard_sheet": {
            "desc": "Carnival fire hazard ground zone",
            "frame_w": 280, "frame_h": 88, "model": MODEL_FAST,
            "frames": [
                {
                    "name": "flicker_1",
                    "prompt": (
                        "Glowing fire embers ground hazard zone, "
                        "low flat patch of orange-red smouldering fire on ground, "
                        "ember glow flame flicker A, "
                        + _STYLE + ", top-down view, ground level fire patch"
                    ),
                },
                {
                    "name": "flicker_2",
                    "prompt": (
                        "Glowing fire embers ground hazard zone, "
                        "low flat patch of orange-red smouldering fire, "
                        "brighter flame flicker B, "
                        + _STYLE + ", top-down view, ground level fire patch"
                    ),
                },
                {
                    "name": "flicker_3",
                    "prompt": (
                        "Glowing fire embers ground hazard zone, "
                        "low flat patch smouldering fire with small upward flame, "
                        "intense flicker C, "
                        + _STYLE + ", top-down view, ground level fire"
                    ),
                },
            ],
        },
    },

    # ── Backgrounds — 5-layer parallax system ────────────────────────────────
    #
    # Same 5-layer structure every act. Only colors + props change per act.
    #   Layer 0: _sky       - opaque gradient sky, no objects
    #   Layer 1: _clouds    - cloud/atmosphere shapes on WHITE bg -> transparent
    #   Layer 2: _mountains - distant horizon + small far act props on WHITE bg
    #   Layer 3: _trees     - mid tree canopy silhouette strip on WHITE bg
    #   Layer 4: _props     - act-specific near props (2-3 sizes) on WHITE bg
    #
    # Transparent layers: "pure white background" in prompt + threshold removal.
    # Sky layers: opaque (skip_bg_removal: True). No img2img ref needed.
    # All 1344x768. Godot scales to 270px viewport height.
    # ─────────────────────────────────────────────────────────────────────────
    "backgrounds": {

        # ── Prologue (World.gd) — Golden hour Kerala dusk ─────────────────────
        "bg_prologue_sky": {
            "desc": "Prologue sky -- warm amber terracotta dusk",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": True,
            "frames": [{"name": "sky", "prompt": (
                "Pure Kerala golden hour dusk sky panorama, "
                "warm amber terracotta orange gradient from bright horizon to deeper orange above, "
                "no trees no buildings no clouds, clean seamless gradient sky only, "
                "flat Kerala mural art style, wide seamless tileable panorama, no text"
            )}],
        },
        "bg_prologue_clouds": {
            "desc": "Prologue clouds -- golden dusk cloud wisps",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "clouds", "prompt": (
                "Soft amber-gold wispy dusk clouds floating, "
                "flat golden cloud shapes on pure white background, "
                "Kerala mural illustration style, bold outlines, "
                "wide seamless tileable panorama, clouds only isolated on white, no text"
            )}],
        },
        "bg_prologue_mountains": {
            "desc": "Prologue mountains -- Kerala hills + distant temple silhouette",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "mountains", "prompt": (
                "Kerala rolling hills silhouette panorama, "
                "distant ancient temple gopuram spire visible above low hills, "
                "warm amber-orange flat silhouette shapes, pure white background, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_prologue_trees": {
            "desc": "Prologue trees -- warm palm canopy strip",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_FAST,
            "skip_bg_removal": False,
            "frames": [{"name": "trees", "prompt": (
                "Kerala coconut palm canopy silhouette strip panorama, "
                "dense palm fronds and trunks, dark warm brown-orange flat shapes, "
                "pure white background, bottom-anchored tree line, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_prologue_props": {
            "desc": "Prologue props -- Kerala stilt hut + lamp post",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "props", "prompt": (
                "Kerala traditional wooden stilt house on river bank, "
                "large hut left side, medium lamp post center-right, small distant hut far right, "
                "warm amber-brown flat silhouette shapes, pure white background, "
                "flat Kerala mural illustration, bottom-anchored props, no text"
            )}],
        },

        # ── Act 1 (Act1.gd) -- Bamboo grove dusk to nightfall ─────────────────
        # Strategy: ONE element per image, Recraft v3, simple prompts.
        # Recraft's 2d_art_poster style naturally isolates elements on white.
        # All layer images use white-removal shader in-engine.
        "bg_act1_sky": {
            "desc": "Act 1 base scene -- bamboo grove with lily pond and ruined arch",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration/2d_art_poster",
            "skip_bg_removal": True,
            "frames": [{"name": "sky", "prompt": (
                "Bamboo forest with still lily pond and ancient stone arch in background, "
                "lush tropical green, misty blue-green atmosphere, "
                "flat 2D illustration, wide horizontal panorama, no people"
            )}],
        },
        "bg_act1_clouds": {
            "desc": "Act 1 clouds element -- dark purple-blue clouds only, white background",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration/2d_art_poster",
            "skip_bg_removal": False,
            "frames": [{"name": "clouds", "prompt": (
                "Dark indigo-purple clouds, flat bold graphic shapes, "
                "clouds only, pure white background, "
                "no landscape, no ground, no trees, no people"
            )}],
        },
        "bg_act1_mountains": {
            "desc": "Act 1 far element -- distant bamboo and tree line silhouette, white background",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration/2d_art_poster",
            "skip_bg_removal": False,
            "frames": [{"name": "mountains", "prompt": (
                "Distant bamboo grove silhouette along horizon line, "
                "dark teal-green flat shapes, pure white background, "
                "bamboo stalks and canopy only, no people, no sky fill"
            )}],
        },
        "bg_act1_trees": {
            "desc": "Act 1 mid element -- bamboo grove mid-ground, white background",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration/2d_art_poster",
            "skip_bg_removal": False,
            "frames": [{"name": "trees", "prompt": (
                "Bamboo grove, tall bamboo stalks with leaves, "
                "dark green flat illustration, pure white background, "
                "bamboo only, no people, no sky fill, no ground fill"
            )}],
        },
        "bg_act1_props": {
            "desc": "Act 1 near element -- traditional Kerala hut and oil lamp, white background",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration/2d_art_poster",
            "skip_bg_removal": False,
            "frames": [{"name": "props", "prompt": (
                "Traditional Kerala thatched-roof hut and tall brass oil lamp post, "
                "dark silhouette flat illustration, pure white background, "
                "hut and lamp only, no people, no landscape fill"
            )}],
        },

        # ── Act 2 (Act2.gd) -- Abandoned fire carnival ────────────────────────
        # NOTE: All original Act 2 images came out ISOMETRIC (top-down).
        # All prompts now explicitly demand SIDE-SCROLLING horizontal view.
        "bg_act2_sky": {
            "desc": "Act 2 base scene -- abandoned fire carnival side-scrolling panorama",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": True,
            "frames": [{"name": "sky", "prompt": (
                "Abandoned fire festival grounds at night, "
                "SIDE VIEW horizontal 2D platformer game background, NOT isometric NOT top-down, "
                "viewed from the side like a traditional side-scrolling video game, "
                "crumbling stone arches and smashed carnival lanterns seen from the side, "
                "broken ferris wheel silhouette far right, fire pits along the ground, "
                "embers drifting upward, deep ember-red and crimson sky, "
                "flat illustration style, bold outlines, jewel-tone fills, "
                "wide seamless tileable horizontal panorama, no characters no people, no text"
            )}],
        },
        "bg_act2_clouds": {
            "desc": "Act 2 clouds -- fire smoke wisps strip (silhouette layer)",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 256, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "clouds", "prompt": (
                "Horizontal strip of fire smoke wisps and floating ember sparks, "
                "side view NOT top-down NOT isometric, "
                "dark orange-grey smoke curls drifting sideways, tiny glowing ember dots, "
                "pure white background, flat illustration style, "
                "thin horizontal strip format, only smoke and sparks on white, "
                "no figures no people no characters, no text"
            )}],
        },
        "bg_act2_mountains": {
            "desc": "Act 2 mountains -- ruined carnival arch silhouette strip",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 256, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "mountains", "prompt": (
                "Horizontal silhouette strip of ruined carnival structures seen from the side, "
                "SIDE VIEW NOT isometric NOT top-down, "
                "crumbling decorative arch center, distant broken ferris wheel right, "
                "ruined festival gateway left, dark ember-red flat silhouettes, "
                "pure white background, flat illustration style, "
                "bottom-anchored strip, no people no characters no figures, no text"
            )}],
        },
        "bg_act2_trees": {
            "desc": "Act 2 trees -- scorched tropical tree canopy silhouette strip",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 256, "model": MODEL_FAST,
            "skip_bg_removal": False,
            "frames": [{"name": "trees", "prompt": (
                "Horizontal silhouette strip of scorched coconut palm tree canopy seen from the side, "
                "SIDE VIEW NOT isometric NOT top-down, "
                "dark orange-brown tree crowns with ember glow at edges, "
                "pure white background, bottom-anchored tree line strip, "
                "flat illustration style, no people no figures no characters, no text"
            )}],
        },
        "bg_act2_props": {
            "desc": "Act 2 props -- large broken ferris wheel silhouette strip",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 256, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "props", "prompt": (
                "Horizontal silhouette strip of broken carnival ferris wheel seen from the side, "
                "SIDE VIEW NOT isometric NOT top-down, "
                "large broken ferris wheel dominates center-left, "
                "torn carnival banner on pole right side, "
                "dark ember-orange flat silhouettes, pure white background, "
                "flat illustration style, bottom-anchored strip, "
                "no people no figures no characters, no text"
            )}],
        },

        # ── Act 3 (Act3.gd) -- Foggy highland forest ──────────────────────────
        "bg_act3_sky": {
            # FIXED: original generated a person crouching in a garden (wrong!)
            # New prompt is purely atmospheric — no scene context that invites figures.
            "desc": "Act 3 sky -- pale overcast foggy sky gradient (no scene, no characters)",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": True,
            "frames": [{"name": "sky", "prompt": (
                "Flat horizontal gradient sky, pale grey-blue-green foggy overcast, "
                "darker at top lighter at horizon, uniform flat misty colour bands, "
                "ABSOLUTELY NO figures NO people NO silhouettes NO trees NO objects, "
                "pure abstract sky gradient only, "
                "flat illustration style, wide seamless tileable panorama, no text"
            )}],
        },
        "bg_act3_clouds": {
            # FIXED v2: still generating characters — now using pure abstract geometry approach
            "desc": "Act 3 clouds -- abstract fog gradient strip (no figures, no scene)",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 256, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "clouds", "prompt": (
                "Abstract horizontal gradient strip, "
                "soft grey-green-blue colour bands blending left to right, "
                "thin wisps of lighter fog across dark background, "
                "purely abstract atmospheric gradient, "
                "zero figures zero humans zero animals zero faces zero silhouettes, "
                "no trees no buildings no objects no characters whatsoever, "
                "texture-only abstract art, seamless horizontal tile, no text"
            )}],
        },
        "bg_act3_mountains": {
            "desc": "Act 3 mountains -- crumbling ruins + cattle silhouette",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "mountains", "prompt": (
                "Foggy highland silhouette panorama, "
                "crumbling ancient stone wall ruins on horizon, small distant cattle silhouette, "
                "muted grey-green flat shapes, pure white background, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_act3_trees": {
            "desc": "Act 3 trees -- foggy grey-green forest canopy",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_FAST,
            "skip_bg_removal": False,
            "frames": [{"name": "trees", "prompt": (
                "Foggy highland forest canopy silhouette strip panorama, "
                "ancient gnarled tree crowns in thick fog, dark grey-green flat shapes, "
                "pure white background, bottom-anchored tree line, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_act3_props": {
            "desc": "Act 3 props -- stone cattle trail marker + crumbling shed",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "props", "prompt": (
                "Highland stone ruins scene silhouette, "
                "large ancient stone cattle trail marker left, crumbling stone cattle shed center, "
                "small distant stone pillar right, dark grey-green flat shapes, "
                "pure white background, flat Kerala mural illustration, "
                "bottom-anchored props, no text"
            )}],
        },

        # ── Act 4 (Act4.gd) -- Rain-drenched mangroves ────────────────────────
        "bg_act4_sky": {
            "desc": "Act 4 sky -- deep navy blue monsoon night",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": True,
            "frames": [{"name": "sky", "prompt": (
                "Monsoon night sky panorama Kerala mangrove, "
                "deep navy blue-black heavy rain sky, no stars visible, "
                "dark blue gradient uniform, no objects no trees, "
                "flat Kerala mural art, wide seamless tileable panorama, no text"
            )}],
        },
        "bg_act4_clouds": {
            "desc": "Act 4 clouds -- dark storm clouds + rain streaks",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "clouds", "prompt": (
                "Monsoon storm cloud silhouettes and rain streaks panorama, "
                "heavy dark blue-grey storm clouds, thin diagonal rain streak lines, "
                "pure white background, flat Kerala mural illustration, "
                "wide seamless tileable panorama, clouds and rain only on white, no text"
            )}],
        },
        "bg_act4_mountains": {
            "desc": "Act 4 mountains -- flooded stilt structures silhouette",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "mountains", "prompt": (
                "Flooded mangrove landscape silhouette panorama, "
                "distant stilt houses half-submerged in floodwater, mangrove root horizon, "
                "dark navy blue flat shapes, pure white background, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_act4_trees": {
            "desc": "Act 4 trees -- dark navy mangrove aerial root canopy",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_FAST,
            "skip_bg_removal": False,
            "frames": [{"name": "trees", "prompt": (
                "Mangrove aerial root canopy silhouette strip panorama, "
                "tangled mangrove roots arching into floodwater, dark navy-blue flat shapes, "
                "pure white background, bottom-anchored dense mangrove line, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_act4_props": {
            "desc": "Act 4 props -- flooded hut + waterlogged boat",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "props", "prompt": (
                "Flooded Kerala riverside scene silhouette, "
                "large flooded hut left with water stain line, wooden boat partially submerged center, "
                "small distant flooded structure right, dark navy-blue flat shapes, "
                "pure white background, flat Kerala mural illustration, "
                "bottom-anchored props, no text"
            )}],
        },

        # ── Act 5 (Act5.gd) -- Sacred banyan grove night ──────────────────────
        "bg_act5_sky": {
            "desc": "Act 5 sky -- near-black deep indigo sacred night",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": True,
            "frames": [{"name": "sky", "prompt": (
                "Sacred grove deep night sky panorama Kerala, "
                "near-black deep indigo purple sky, a few faint stars, "
                "pure dark gradient, no trees no objects, "
                "flat Kerala mural art, wide seamless tileable panorama, no text"
            )}],
        },
        "bg_act5_clouds": {
            "desc": "Act 5 clouds -- sacred smoke wisps + firefly glows",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "clouds", "prompt": (
                "Sacred smoke wisps and golden firefly glows panorama, "
                "thin dark indigo incense smoke tendrils, scattered small golden firefly dots, "
                "pure white background, flat Kerala mural illustration, "
                "wide seamless tileable panorama, smoke and fireflies on white, no text"
            )}],
        },
        "bg_act5_mountains": {
            "desc": "Act 5 mountains -- ancient temple gopuram silhouette",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "mountains", "prompt": (
                "Ancient Kerala temple silhouette panorama, "
                "tall ornate temple gopuram tower center, stone arch gateway, "
                "dark indigo-black flat shapes, pure white background, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_act5_trees": {
            "desc": "Act 5 trees -- massive ancient banyan canopy with hanging roots",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_FAST,
            "skip_bg_removal": False,
            "frames": [{"name": "trees", "prompt": (
                "Ancient banyan tree canopy silhouette strip panorama, "
                "massive banyan crowns with long hanging aerial roots, dark indigo-green flat shapes, "
                "pure white background, bottom-anchored dense banyan line, "
                "flat Kerala mural illustration, wide seamless tileable, no text"
            )}],
        },
        "bg_act5_props": {
            "desc": "Act 5 props -- stone temple gate + sacred lamp nilavilakku",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "props", "prompt": (
                "Sacred Kerala temple entrance scene silhouette, "
                "large ornate stone temple gate arch left, tall nilavilakku sacred oil lamp center, "
                "small stone pillar with lotus carving right, dark indigo-gold flat shapes, "
                "pure white background, flat Kerala mural illustration, "
                "bottom-anchored props, no text"
            )}],
        },
        # Act 2 needs a proper side-scrolling scene — all generated Act 2 images
        # came out isometric (top-down). Run: python generate_sprites.py --sheet bg_act2_scene
        # Then update Act2.gd sky_path to "res://assets/backgrounds/bg_act2_scene.png"
        "bg_act2_scene": {
            "desc": "Act 2 Kuttichathan's Carnival — abandoned fire festival, side-scrolling wide landscape",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 768, "model": MODEL_QUALITY,
            "skip_bg_removal": True,
            "frames": [{"name": "sky", "prompt": (
                "abandoned Kerala fire festival at night, wide side-scrolling platformer background, "
                "ember-lit carnival grounds, crumbling stone arches, cracked festival lanterns hanging, "
                "broken ferris wheel silhouette far background, smoldering torches and fire pits, "
                "embers drifting upward like fireflies, dark sky with deep amber and crimson fire glow, "
                "flat Kerala mural illustration style, bold black outlines, jewel-tone fills, "
                "side-on perspective NOT isometric, horizontal landscape, rich atmosphere, "
                "no text, no characters, no UI elements"
            )}],
        },
        # ── Parallax depth layers — generated to match Scenario.gg source scenes ──
        # Two-stage approach (irisogli.com/parallax-background-creation):
        #   Stage 1 = Scenario.gg full scene (already exists on disk — not regenerated)
        #   Stage 2 = Recraft generates isolated depth layers matching that scene's style
        #
        # Layer scroll speeds (in Act GD files):
        #   sky  → 0.08   mid → 0.22   near → 0.38
        # All layers: skip_bg_removal=False → white background removed by shader
        # ------------------------------------------------------------------

        # ── PROLOGUE parallax layers — test batch (run first before other acts) ──
        # Source scene: bg_prologue.png — golden-hour dusk Kerala village
        # Visual style: flat silhouette illustration, warm amber-orange sky,
        #   cream puffy clouds, dark palm silhouettes, Kerala thatched hut, temple spire far
        "bg_prologue_par_sky": {
            "desc": "Prologue parallax far layer — amber dusk sky + distant temple",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "sky", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FAR BACKGROUND: Only distant environmental elements. Low contrast and reduced detail. "
                "No gameplay platforms. No foreground objects. No characters. "
                "Scene: warm amber-orange golden-hour dusk sky with large cream puffy clouds, "
                "ancient Kerala temple gopuram spire silhouette rising from the far distance, "
                "Kerala village at sunset atmosphere. "
                "Art style: flat vector 2D game illustration, warm amber, orange and gold palette, "
                "soft dusk lighting, same style as a Kerala golden-hour village scene. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_prologue_par_mid": {
            "desc": "Prologue parallax mid layer — tropical foliage band",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "mid", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "MID BACKGROUND: Environmental structures with medium detail and contrast. "
                "Still no gameplay platforms. No characters. "
                "Scene: tropical foliage band, orange-brown mid-ground trees and bushes, "
                "Kerala village vegetation at golden hour, warm amber-brown silhouette tones. "
                "Art style: flat vector 2D game illustration, dark amber-brown silhouette palette, "
                "same flat style as a Kerala golden-hour village scene. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_prologue_par_near": {
            "desc": "Prologue parallax near layer — dark palm silhouettes + Kerala hut",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "near", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FOREGROUND: High-contrast silhouette or decorative foreground elements. "
                "Positioned at the bottom or edges of the frame. No characters. "
                "Scene: tall dark palm tree silhouettes framing both sides of the image, "
                "traditional Kerala thatched-roof hut with wooden steps on one side, "
                "dark foreground vegetation and grass, golden-hour Kerala village. "
                "Art style: flat vector 2D game illustration, near-black dark silhouette palette, "
                "same flat style as a Kerala golden-hour village scene. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },

        # ── Parallax depth layers — article-exact prompt structure ──────────────
        # Source: irisogli.com/parallax-background-creation (two-stage method)
        # Stage 1 = Scenario.gg full scene already on disk (base image, not regenerated)
        # Stage 2 = these specs below — Recraft generates isolated layers matching that scene
        #
        # Prompt skeleton used verbatim from the article:
        #   "Generate separate depth layers for a 2D side-scrolling game environment.
        #    Each layer must be created as an individual image file.
        #    [LAYER]: [Article constraint]. [Scene-specific content].
        #    Do not merge layers. Do not generate a collage.
        #    Do not create multiple panels. Each layer is a separate standalone 16:9 image."
        #
        # Style: digital_illustration (gives white bg — 2d_art_poster ignores white bg request)

        # ── Act 1 — Bamboo + Lily Pond + Ruined Arch (bg_act1_far.png) ─────────
        "bg_act1_par_sky": {
            "desc": "Act 1 parallax far layer — misty sky + distant ruins",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "sky", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FAR BACKGROUND: Only distant environmental elements. Low contrast and reduced detail. "
                "No gameplay platforms. No foreground objects. No characters. "
                "Scene: misty blue-green sky above a Kerala bamboo forest, ancient stone arch silhouette "
                "barely visible in the far distance through haze. Muted teal-blue atmosphere. "
                "Art style: flat vector 2D game illustration, muted teal-green palette, soft depth haze. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act1_par_mid": {
            "desc": "Act 1 parallax mid layer — lily pond + mid-ground palms",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "mid", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "MID BACKGROUND: Environmental structures with medium detail and contrast. "
                "Still no gameplay platforms. No characters. "
                "Scene: still tropical lily pond with lily pads and reflections, distant palm trees "
                "along the water edge, Kerala jungle atmosphere. Deep jade-green tones. "
                "Art style: flat vector 2D game illustration, jade-green and teal palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act1_par_near": {
            "desc": "Act 1 parallax near layer — foreground bamboo stalks",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "near", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FOREGROUND: High-contrast silhouette or decorative foreground elements. "
                "Positioned at the bottom or edges of the frame. No characters. "
                "Scene: tall dark bamboo stalks with leaves as a foreground framing element, "
                "Kerala jungle. Dark deep green, bold outlines, bamboo only. "
                "Art style: flat vector 2D game illustration, dark green silhouette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },

        # ── Act 2 — Night Carnival (bg_act2_scene.png) ────────────────────────
        "bg_act2_par_sky": {
            "desc": "Act 2 parallax far layer — deep purple carnival night sky",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "sky", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FAR BACKGROUND: Only distant environmental elements. Low contrast and reduced detail. "
                "No gameplay platforms. No foreground objects. No characters. "
                "Scene: deep purple-navy night sky with stars, distant ferris wheel silhouette, "
                "dark carnival smoke, ember-orange glow on the horizon. "
                "Art style: flat vector 2D game illustration, deep indigo and charcoal night palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act2_par_mid": {
            "desc": "Act 2 parallax mid layer — stone arch columns + festival lanterns",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "mid", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "MID BACKGROUND: Environmental structures with medium detail and contrast. "
                "Still no gameplay platforms. No characters. "
                "Scene: ancient stone arch columns and carved ruins, hanging festival oil lanterns "
                "glowing warm orange, draped cloth festival banners, Kerala carnival ruins. "
                "Art style: flat vector 2D game illustration, dark stone and ember-orange palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act2_par_near": {
            "desc": "Act 2 parallax near layer — fire pits + dark ground silhouettes",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "near", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FOREGROUND: High-contrast silhouette or decorative foreground elements. "
                "Positioned at the bottom or edges of the frame. No characters. "
                "Scene: crackling fire pits with ember sparks, dark palm silhouettes and rocky debris, "
                "Kerala carnival abandoned grounds. Deep charcoal and ember-orange tones. "
                "Art style: flat vector 2D game illustration, dark silhouette and fire-orange palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },

        # ── Act 3 — Moonlit Forest (bg_act3.png — NO near layer, has character) ─
        "bg_act3_par_sky": {
            "desc": "Act 3 parallax far layer — moonlit forest night sky",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "sky", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FAR BACKGROUND: Only distant environmental elements. Low contrast and reduced detail. "
                "No gameplay platforms. No foreground objects. No characters. "
                "Scene: dark blue-purple moonlit night sky, large glowing full moon high center, "
                "soft silver moonbeam, Kerala highland forest atmosphere. "
                "Art style: flat vector 2D game illustration, deep indigo and silver-white palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act3_par_mid": {
            "desc": "Act 3 parallax mid layer — moonlit forest tree canopy",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "mid", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "MID BACKGROUND: Environmental structures with medium detail and contrast. "
                "Still no gameplay platforms. No characters. "
                "Scene: tall dark Kerala forest trees with arching branches and dense canopy, "
                "silver moonlight catching the edges of leaves, highland fog. "
                "Art style: flat vector 2D game illustration, deep teal-green and dark indigo palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },

        # ── Act 4 — Rain Mangroves (bg_act4.png) ──────────────────────────────
        "bg_act4_par_sky": {
            "desc": "Act 4 parallax far layer — monsoon overcast sky",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "sky", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FAR BACKGROUND: Only distant environmental elements. Low contrast and reduced detail. "
                "No gameplay platforms. No foreground objects. No characters. "
                "Scene: grey-blue overcast monsoon sky, heavy storm clouds, diagonal rain streaks, "
                "distant stilt village silhouette on flooded horizon. Kerala mangrove flood atmosphere. "
                "Art style: flat vector 2D game illustration, grey-blue and dark slate rain palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act4_par_mid": {
            "desc": "Act 4 parallax mid layer — mangroves + flooded water",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "mid", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "MID BACKGROUND: Environmental structures with medium detail and contrast. "
                "Still no gameplay platforms. No characters. "
                "Scene: mangrove trees with exposed aerial root systems in shallow flooded water, "
                "Kerala stilt houses on flooded horizon, olive-gold distant paddy fields. "
                "Art style: flat vector 2D game illustration, rain-washed green and muddy water palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act4_par_near": {
            "desc": "Act 4 parallax near layer — dark mangrove trunk silhouettes",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "near", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FOREGROUND: High-contrast silhouette or decorative foreground elements. "
                "Positioned at the bottom or edges of the frame. No characters. "
                "Scene: dark mangrove tree trunk silhouettes with gnarled rope-like aerial roots "
                "arching dramatically, Kerala flooded mangrove. Very dark green-brown tones. "
                "Art style: flat vector 2D game illustration, near-black silhouette palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },

        # ── Act 5 — Banyan Grove + Temple (bg_act5.png) ───────────────────────
        "bg_act5_par_sky": {
            "desc": "Act 5 parallax far layer — sunset sky + distant temple gopuram",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "sky", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FAR BACKGROUND: Only distant environmental elements. Low contrast and reduced detail. "
                "No gameplay platforms. No foreground objects. No characters. "
                "Scene: vivid cyan-to-golden-yellow sunset sky with scattered clouds, "
                "ancient Kerala temple gopuram spire silhouette rising above dark forest treeline. "
                "Art style: flat vector 2D game illustration, cyan-gold-amber sunset palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act5_par_mid": {
            "desc": "Act 5 parallax mid layer — temple gateway + lush undergrowth",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "mid", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "MID BACKGROUND: Environmental structures with medium detail and contrast. "
                "Still no gameplay platforms. No characters. "
                "Scene: ancient Kerala temple gateway with carved stone columns, lush tropical "
                "green undergrowth, small winding stream, dark forest backdrop. "
                "Art style: flat vector 2D game illustration, deep forest green and dark stone palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },
        "bg_act5_par_near": {
            "desc": "Act 5 parallax near layer — massive banyan trunk silhouettes",
            "output_dir": "backgrounds",
            "frame_w": 2048, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "near", "prompt": (
                "Generate separate depth layers for a 2D side-scrolling game environment. "
                "Each layer must be created as an individual image file. "
                "FOREGROUND: High-contrast silhouette or decorative foreground elements. "
                "Positioned at the bottom or edges of the frame. No characters. "
                "Scene: massive ancient banyan tree trunk silhouettes framing left and right edges, "
                "long rope-like hanging aerial roots descending from above, sacred Kerala grove. "
                "Art style: flat vector 2D game illustration, very dark brown-green silhouette palette. "
                "Pure white background. "
                "Do not merge layers together. Do not generate a collage. "
                "Do not create multiple panels in one image. "
                "Each layer must be exported as a separate standalone 16:9 image."
            )}],
        },

        # ── Recraft composite designed for Pillow layer extraction ──────────────
        # This is the SOURCE image for extract_layers.py — NOT used directly in Godot.
        # Prompt is engineered for 3 clearly separated depth bands with flat color fills.
        "bg_prologue_rc": {
            "desc": "Prologue Recraft composite — designed for Pillow HSV layer extraction",
            "output_dir": "backgrounds",
            "frame_w": 1820, "frame_h": 1024, "model": MODEL_RECRAFT,
            "recraft_style": "digital_illustration",
            "skip_bg_removal": False,
            "frames": [{"name": "rc", "prompt": (
                "Kerala dusk village panorama, side-scrolling 2D game background, "
                "flat vector illustration. "
                "Three clearly separated depth bands: "
                "TOP THIRD — wide amber-orange sky with cream puffy clouds, pale haze, "
                "distant temple spire silhouette, low contrast, very flat color fill. "
                "MIDDLE THIRD — dark orange-brown tropical foliage band, palm tree midground, "
                "dense overlapping leaf shapes, flat silhouette. "
                "BOTTOM THIRD — very dark near-black foreground silhouettes, grass tufts, "
                "ground cover, roots, completely black at base edge. "
                "Pure flat vector style, hard color boundaries between depth bands, "
                "no photographic gradients, no characters, pure white does not appear."
            )}],
        },

        "bg_water_tile": {
            "desc": "Animated water tile -- Kerala backwater river surface for parallax",
            "output_dir": "backgrounds",
            "frame_w": 1344, "frame_h": 128, "model": MODEL_QUALITY,
            "skip_bg_removal": False,
            "frames": [{"name": "water", "prompt": (
                "Kerala backwater river surface texture, top-down view, "
                "gentle ripples and soft wave patterns, "
                "deep cerulean blue with soft teal highlights, amber sky reflections, "
                "flat Kerala mural art style, seamless tileable horizontal strip, "
                "no land no sky no trees, only water surface, no text"
            )}],
        },
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# Cost estimator
# ─────────────────────────────────────────────────────────────────────────────

def estimate_cost(categories: Optional[list] = None) -> dict:
    total_images = 0
    total_cost   = 0.0
    breakdown: dict = {}
    for cat_name, cat_sprites in SPRITE_DB.items():
        if categories and cat_name not in categories:
            continue
        ci, cc = 0, 0.0
        for spec in cat_sprites.values():
            n    = len(spec["frames"])
            c    = n * COST.get(spec.get("model", MODEL_FAST), 0.003)
            ci  += n
            cc  += c
        breakdown[cat_name] = {"images": ci, "cost": cc}
        total_images        += ci
        total_cost          += cc
    return {"total_images": total_images, "total_cost": total_cost, "breakdown": breakdown}


# ─────────────────────────────────────────────────────────────────────────────
# Replicate API
# ─────────────────────────────────────────────────────────────────────────────

def _parse_url(output) -> str:
    """Extract URL string from Replicate output (handles list or FileOutput)."""
    if isinstance(output, list):
        output = output[0]
    # FileOutput has .url attribute in newer replicate SDK
    if hasattr(output, "url"):
        return str(output.url)
    return str(output)


def generate_image(
    prompt:     str,
    width:      int,
    height:     int,
    model:      str            = MODEL_FAST,
    ref_bytes:  Optional[bytes] = None,    # reference image for img2img (FLUX Dev only)
    strength:   float          = 0.70,     # prompt_strength: how much to deviate from ref
    retries:    int            = 3,
    recraft_style: str         = "digital_illustration/2d_art_poster",  # Recraft v3 only
) -> Optional[bytes]:
    """Call Replicate and return raw PNG bytes, or None on failure.

    Supports two model families:
    - FLUX (flux-schnell / flux-dev): uses width/height/num_inference_steps
    - Recraft v3: uses style + size enum — completely different API, no img2img support
    """
    # ── Recraft v3 path ───────────────────────────────────────────────────────
    if "recraft" in model:
        params: dict = {
            "prompt": prompt,
            "style":  recraft_style,
            "size":   _recraft_size(width, height),
        }
        for attempt in range(retries):
            try:
                output = replicate.run(model, input=params)
                url    = _parse_url(output)
                resp   = requests.get(url, timeout=120)
                resp.raise_for_status()
                return resp.content
            except Exception as exc:
                wait = 2 ** attempt
                print(f"    ⚠  attempt {attempt + 1}/{retries} failed: {exc}  — retry in {wait}s")
                time.sleep(wait)
        return None

    # ── FLUX path (flux-schnell / flux-dev) ───────────────────────────────────
    if ref_bytes is not None:
        model = MODEL_QUALITY   # img2img requires flux-dev

    params = {
        "prompt":        prompt,
        "width":         min(width,  1440),
        "height":        min(height, 1440),
        "num_outputs":   1,
        "output_format": "png",
    }
    if ref_bytes is not None:
        params["image"]           = BytesIO(ref_bytes)
        params["prompt_strength"] = strength
        params["num_inference_steps"] = 28
        params["guidance"]            = 3.5
    elif "schnell" in model:
        params["num_inference_steps"] = 4
    elif "dev" in model:
        params["num_inference_steps"] = 28
        params["guidance"]            = 3.5

    for attempt in range(retries):
        try:
            output = replicate.run(model, input=params)
            url    = _parse_url(output)
            resp   = requests.get(url, timeout=120)
            resp.raise_for_status()
            return resp.content
        except Exception as exc:
            wait = 2 ** attempt
            print(f"    ⚠  attempt {attempt + 1}/{retries} failed: {exc}  — retry in {wait}s")
            time.sleep(wait)
    return None


# ─────────────────────────────────────────────────────────────────────────────
# Background removal
# ─────────────────────────────────────────────────────────────────────────────

def _remove_bg(img: Image.Image) -> Image.Image:
    """Remove background. Uses rembg if available, else simple white-threshold."""
    img = img.convert("RGBA")
    if HAVE_REMBG:
        buf = BytesIO()
        img.save(buf, "PNG")
        out_bytes = rembg_remove(buf.getvalue())
        return Image.open(BytesIO(out_bytes)).convert("RGBA")
    # Simple threshold fallback — works OK on flat-colour AI art
    data     = list(img.getdata())
    new_data = []
    for r, g, b, a in data:
        if r > 235 and g > 235 and b > 235:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append((r, g, b, a))
    img.putdata(new_data)
    return img


# ─────────────────────────────────────────────────────────────────────────────
# Sheet builder
# ─────────────────────────────────────────────────────────────────────────────

def _resolve_output_dir(spec: dict) -> Path:
    """Return the output directory for a spec."""
    od = spec.get("output_dir", "sprites")
    if od == "backgrounds":
        return BG_DIR
    return SPRITES_DIR


_REF_EXTS = (".png", ".jpg", ".jpeg", ".webp")


def _pick_game_art_ref(sheet_name: str) -> Optional[Path]:
    """Return one game_art_ref_*.{ext} file, chosen deterministically by sheet name."""
    pool = sorted(REF_DIR.glob("game_art_ref_*.*"))
    if not pool:
        return None
    import hashlib
    idx = int(hashlib.md5(sheet_name.encode()).hexdigest(), 16) % len(pool)
    return pool[idx]


def _load_ref_bytes(sheet_name: str, spec: dict) -> Optional[bytes]:
    """
    Load reference image bytes. Four-tier priority:

    1. User per-sheet override  → assets/reference/{sheet_name}_ref.{ext}
       Drop any illustration or photo here to steer a specific layer.

    2. Game art style pool  (for specs with use_style_ref=True)
       Picks one of game_art_ref_1..8 deterministically by sheet name hash.
       Used for act flat composites — locks in illustration style before
       those composites become the per-act parallax references.

    3. Act composite  (automatic for bg_actN_* parallax layers)
       Uses bg_actN.png once generated — inherits style from step 2.

    4. Spec ref_path fallback
       Prologue layers use bg_prologue.png explicitly.

    Returns None → prompt-only generation.
    """
    import re as _re

    # 1. User per-sheet override
    for ext in _REF_EXTS:
        user_ref = REF_DIR / f"{sheet_name}_ref{ext}"
        if user_ref.exists():
            print(f"      ref: {user_ref.name} (user override)")
            return user_ref.read_bytes()

    # 2. Game art style pool (opt-in via use_style_ref: True in spec)
    if spec.get("use_style_ref"):
        chosen = _pick_game_art_ref(sheet_name)
        if chosen:
            print(f"      ref: {chosen.name} (game art style #{chosen.stem.split('_')[-1]})")
            return chosen.read_bytes()

    # 3. Act flat composite — bg_actN.png for any bg_actN_* parallax layer
    m = _re.match(r'^(bg_act\d+)_', sheet_name)
    if m:
        act_flat = BG_DIR / f"{m.group(1)}.png"
        if act_flat.exists():
            print(f"      ref: {act_flat.name} (act composite style ref)")
            return act_flat.read_bytes()

    # 4. Spec-defined fallback (prologue uses bg_prologue.png)
    spec_ref_str: str = spec.get("ref_path", "")
    if spec_ref_str:
        spec_ref = SCRIPT_DIR / spec_ref_str
        if spec_ref.exists():
            print(f"      ref: {spec_ref.name} (spec reference)")
            return spec_ref.read_bytes()

    return None


def build_sheet(
    sheet_name: str,
    spec:       dict,
    dry_run:    bool = False,
    force:      bool = False,
) -> bool:
    """Generate all frames, stitch horizontally, save PNG. Returns success.

    Background specs (output_dir='backgrounds') are treated as single wide
    images — no stitching needed since frame count is always 1.
    """
    out_dir     = _resolve_output_dir(spec)
    output_path = out_dir / f"{sheet_name}.png"

    if output_path.exists() and not force:
        print(f"  ⏭   {sheet_name}.png  already exists  (--force to regenerate)")
        return True

    frames_spec      = spec["frames"]
    frame_w          = spec["frame_w"]
    frame_h          = spec["frame_h"]
    model            = spec.get("model", MODEL_FAST)
    skip_bg_removal  = bool(spec.get("skip_bg_removal", False))
    ref_strength     = float(spec.get("prompt_strength", 0.70))
    n                = len(frames_spec)
    cost_est         = n * COST.get(model, 0.003)

    model_label = model.split("/")[-1]
    print(
        f"\n  🖼  {sheet_name}  "
        f"[{n} frame{'s' if n > 1 else ''}  {frame_w}×{frame_h}  "
        f"model={model_label}  est.${cost_est:.3f}]"
    )
    print(f"      {spec['desc']}")

    if dry_run:
        import re as _re2
        ref_note = ""
        has_user_ref  = any((REF_DIR / f"{sheet_name}_ref{e}").exists() for e in _REF_EXTS)
        has_style_ref = bool(spec.get("use_style_ref") and sorted(REF_DIR.glob("game_art_ref_*.*")))
        m2 = _re2.match(r'^(bg_act\d+)_', sheet_name)
        has_act_ref   = bool(m2 and (BG_DIR / f"{m2.group(1)}.png").exists())
        if spec.get("ref_path") or has_user_ref or has_style_ref or has_act_ref:
            chosen_art = _pick_game_art_ref(sheet_name) if has_style_ref else None
            ref_label  = f" [{chosen_art.stem}]" if chosen_art else ""
            ref_note   = f"  [uses reference image{ref_label}]"
        for i, frame in enumerate(frames_spec):
            print(f"      [{i + 1}/{n}] {frame['name']}{ref_note}")
        return True

    # Load reference image once (shared across all frames in this sheet)
    ref_bytes = _load_ref_bytes(sheet_name, spec)

    frame_images: list[Image.Image] = []
    for i, frame in enumerate(frames_spec):
        label = frame["name"]
        print(f"      [{i + 1}/{n}] {label} ... ", end="", flush=True)

        raw = generate_image(
            frame["prompt"], frame_w, frame_h,
            model          = model,
            ref_bytes      = ref_bytes if "recraft" not in model else None,  # Recraft has no img2img
            strength       = ref_strength,
            recraft_style  = spec.get("recraft_style", "digital_illustration/2d_art_poster"),
        )
        if raw is None:
            print("✗ FAILED")
            return False

        img = Image.open(BytesIO(raw)).convert("RGBA")
        if not skip_bg_removal:
            img = _remove_bg(img)
        img = img.resize((frame_w, frame_h), Image.LANCZOS)
        frame_images.append(img)
        print("✓")
        time.sleep(0.3)   # polite rate limiting

    # Stitch horizontal strip (single-frame backgrounds: strip == frame)
    strip = Image.new("RGBA", (frame_w * n, frame_h), (0, 0, 0, 0))
    for i, fim in enumerate(frame_images):
        strip.paste(fim, (i * frame_w, 0))

    out_dir.mkdir(parents=True, exist_ok=True)
    strip.save(str(output_path), "PNG")
    print(f"      ✅  saved → {output_path.name}  ({frame_w * n}×{frame_h} px)")
    return True


# ─────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Kanjiravanam Chronicles — Replicate sprite generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--force",    action="store_true",
                        help="Regenerate sprites that already exist")
    parser.add_argument("--dry-run",  action="store_true",
                        help="List what would be generated without calling the API")
    parser.add_argument("--estimate", action="store_true",
                        help="Show cost estimate and exit (no generation)")
    parser.add_argument("--list",     action="store_true",
                        help="Show status of every sprite file and exit")
    parser.add_argument("--category",
                        choices=["npcs", "enemies", "props", "backgrounds"],
                        help="Generate only this category")
    parser.add_argument("--sheet",    metavar="NAME", action="append", default=[],
                        help="Generate only this sheet (repeat for multiple)")
    args = parser.parse_args()

    # ── Load API token ────────────────────────────────────────────────────────
    if ENV_FILE.exists():
        load_dotenv(ENV_FILE)
    token = os.environ.get("REPLICATE_API_TOKEN", "")

    needs_token = not (args.estimate or args.list or args.dry_run)
    if needs_token and not token:
        print(f"✗  REPLICATE_API_TOKEN not found in {ENV_FILE}")
        print("   Add it:  REPLICATE_API_TOKEN=r8_your_token_here")
        sys.exit(1)
    if token:
        os.environ["REPLICATE_API_TOKEN"] = token

    # ── --list ────────────────────────────────────────────────────────────────
    if args.list:
        print("\nKanjiravanam Asset Status")
        print("─" * 72)
        for cat_name, cat_sprites in SPRITE_DB.items():
            print(f"\n  {cat_name.upper()}")
            for sheet_name, spec in cat_sprites.items():
                out_dir = _resolve_output_dir(spec)
                path    = out_dir / f"{sheet_name}.png"
                ref_ok  = (REF_DIR / f"{sheet_name}_ref.png").exists()
                status  = "✅" if path.exists() else "❌"
                ref_tag = " [ref]" if ref_ok else ""
                size    = f"{path.stat().st_size // 1024} KB" if path.exists() else "—"
                n       = len(spec["frames"])
                print(f"    {status}  {sheet_name:<34}{ref_tag:<7}  {n:2d} fr  {size:>8}  {spec['desc']}")
        print(f"\n  Reference images folder: {REF_DIR}")
        print("  Drop {sheet_name}_ref.png there to use as img2img reference for any sheet.")
        return

    # ── Cost estimate header ──────────────────────────────────────────────────
    cats = [args.category] if args.category else None
    est  = estimate_cost(cats)
    print("\n💰 Cost Estimate")
    print("─" * 44)
    for cat, info in est["breakdown"].items():
        print(f"  {cat:<10}  {info['images']:3d} images   ${info['cost']:.3f}")
    print("─" * 44)
    print(f"  {'TOTAL':<10}  {est['total_images']:3d} images   ${est['total_cost']:.3f}")

    if args.estimate:
        return

    if not args.dry_run:
        print(f"\n  rembg background removal: {'✅ available' if HAVE_REMBG else '⚠  not installed — using simple threshold'}")
        if not HAVE_REMBG:
            print("  → For better results: pip install rembg")

    print(f"\n{'═' * 56}")
    print(f"  🎨  Kanjiravanam Sprite Generator")
    print(f"  Output → {SPRITES_DIR}")
    print(f"  Mode   → {'DRY RUN' if args.dry_run else 'LIVE'}")
    print(f"{'═' * 56}")

    success = 0
    failed  = 0
    skipped = 0

    for cat_name, cat_sprites in SPRITE_DB.items():
        if args.category and cat_name != args.category:
            continue

        print(f"\n{'─' * 56}")
        print(f"  {cat_name.upper()}")
        print(f"{'─' * 56}")

        for sheet_name, spec in cat_sprites.items():
            if args.sheet and sheet_name not in args.sheet:
                continue

            output_path = _resolve_output_dir(spec) / f"{sheet_name}.png"
            if output_path.exists() and not args.force:
                skipped += 1
                print(f"  ⏭   {sheet_name}.png  already exists")
                continue

            ok = build_sheet(sheet_name, spec, dry_run=args.dry_run, force=args.force)
            if args.dry_run:
                success += 1
            elif ok:
                success += 1
            else:
                failed += 1

    print(f"\n{'═' * 56}")
    print(f"  ✅ {success} generated   ⏭  {skipped} skipped   ❌ {failed} failed")
    if failed:
        print("  → Re-run to retry failed sheets (missing files are never skipped)")
    if HAVE_REMBG is False and not args.dry_run and success > 0:
        print("\n  Tip: install rembg for much cleaner transparent backgrounds:")
        print("       pip install rembg")


if __name__ == "__main__":
    main()
