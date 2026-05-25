# Kanjiravanam Chronicles — Sprite Requirements

> **Art style:** Kerala mural / Kathakali aesthetic · Bold black outlines · Jewel-tone fills · Warm amber/gold palette  
> **Generation tool:** app.ludo.ai (MCP)  
> **Sheet format:** Single horizontal row OR 4-column grid (match existing Hero-run.png convention)  
> **Background:** Transparent PNG

---

## 🖼️ Base Image Policy

| Category | Needs base image? | Why |
|---|---|---|
| **Hero** | ✅ Yes — provide full reference | All hero animations must match exactly |
| **NPCs** (Thoma, Soniya, Basheer, Captain Biju, Mundakkal Ravi, Mooppan Velu) | ✅ Yes — provide one reference per character | Face, costume, proportions must be consistent across idle/talk |
| **Kili the Crow** | ✅ Yes — provide bird reference | Unique silhouette, needs consistency across perch/fly/caw |
| **Enemies & Bosses** | ⚡ Hero sheet as style ref only | They are mythological creatures — creative freedom, just match line/color style |
| **Props** | ❌ No base image needed | Style derived from hero art automatically |

**Bottom line: provide base images for Hero + 7 NPCs (including Kili). Everything else just needs the hero sheet as a style guide.**

---

## 👤 Hero (1 unified sheet)

> **Base image required:** Yes — provide current hero sprite or reference drawing

### 🔒 Canonical LungiMan Reference (LOCKED — 2026-05-17)

The single source-of-truth image for every LungiMan sprite. Use as composition reference for every subsequent generation.

```yaml
asset_id:        asset_PPMoCkraWSNaK7jvFcNLkFqq
base_model:      model_bfl-flux-1-dev
lora:            model_5tcKD1aGz3f4NquHV5hiF4Hp   # "LungiMan characters (Malayali Culture and Iconic Game Art)"
lora_scale:      0.5
guidance:        7
inference_steps: 35
width:           512
height:          768
seed:            340713770
team_id:         team_qDtk4xpgZyiVY8ftKi7WFCQy
project_id:      proj_hCj5yVgDUMLxGwztp5yuEGAe
```

**Locked prompt (exact text that produced the reference):**
```
LungiMan, Kerala coconut tapper, muscular bare-chested young South Indian man, warm brown skin, aviator sunglasses dark lenses gold frame, thick black mustache, dark curly hair, wearing a plain white cotton mundu hiked up and tucked at the thigh in Kerala working style, the long mundu has been hiked up so the bottom half of the cloth is raised and tied around the upper thighs creating a short doubled wrap that ends at mid thigh well above the knee, two visible cloth layers stacked at the hip and upper thigh region, the short wrap exposes the entire knee and lower leg, plain white cotton no border no gold no stripes no decoration, completely bare muscular legs visible from mid thigh all the way down past the knee to the ankles, barefoot, brown leather crossbody satchel with green coconut inside, coiled rope tied at side of waist, small curved sickle tucked into waistband, relaxed standing pose arms at sides, full body view, bold black outlines, flat Kerala mural cartoon style, jewel-tone fills, transparent background
```

> ⚠️ **Rope correction for all future generations:** The locked prompt says *"coiled rope tied at side of waist"* — this phrasing made the AI sometimes wrap the rope around the waist like a belt. **The rope is a climbing tool, NOT a belt.** For every new generation, replace that fragment with:
>
> *"a thick coiled climbing rope hanging at his hip like a tool, NOT wrapped around the waist, NOT used as a belt, the rope coil hangs loose attached to his side"*

> 📐 **Game camera = side-scrolling side view.** The locked reference is front-facing, used purely for character anchoring (face, mundu fold, accessories). All actual game sprites should be generated as **strict left/right profile views** with the pose-swap template — add *"side view profile, facing right"* to every action prompt.

**Pose-swap template for every other animation frame (same params + reference image, only swap action phrase):**
```
LungiMan, Kerala coconut tapper, same character as reference image, match the mundu fold and outfit exactly to the reference, side view profile facing right, [ACTION], a thick coiled climbing rope hanging at his hip as a tool not wrapped around the waist not a belt, full body view, bold black outlines, flat Kerala mural cartoon style, jewel-tone fills, transparent background
```

| Animation | ACTION phrase |
|---|---|
| `idle` | `standing relaxed, arms at sides, looking forward` |
| `walk` | `mid-stride walking pose, one leg forward, arms swinging naturally` |
| `run` | `running pose, both legs in mid-air sprint, arms pumping` |
| `sword` | `swinging a curved sickle horizontally, body twisted, dynamic action pose` |
| `swing_grab` | `right arm raised overhead gripping a lasso rope, looking up` |
| `swing` | `mid-air swinging from a rope, body angled diagonally, legs tucked` |
| `throw` | `arm pulled back behind head about to throw a green coconut, body coiled` |
| `chai` | `standing relaxed holding a small steel tea cup, drinking pose` |
| `mundu_lasso` | `whirling the white mundu cloth overhead like a lasso, mundu in motion above head` |
| `boxer_idle` | `wearing only dark beige boxer shorts no mundu, satchel and aviators still on, standing relaxed` |

**Generation workflow:**
1. Set base model, LoRA, LoRA scale, guidance, steps, width, height per locked spec above
2. Attach reference image (`asset_PPMoCkraWSNaK7jvFcNLkFqq`) as **Composition Reference** at strength 0.65–0.75
3. Use pose-swap template with the target ACTION phrase
4. **Vary seed per generation** (don't reuse 340713770 — keep that for the reference only) so you get pose variety
5. Generate 2–4 samples per animation, pick the strongest
6. Remove background → crop tight → resize to game sprite dimensions

---

### Character Identity
**Hero name: LungiMan** — a *thenginkeri* (traditional Kerala coconut tapper).  
He makes his living climbing coconut palms every day using a **climbing rope loop** (*cheppam* / *thenginkeri kayar*) — a loop of rope slung around his feet and the trunk that lets him walk straight up a tree. This rope is always coiled at his hip or across his chest when not in use. It is the *mechanical and visual anchor* for the entire swing/climb system — LungiMan doesn't use magic vines, he uses his work tool.

His weapon is the ***arivaal*** — a small curved sickle every tapper carries to cut coconuts. In code it's called "sword" (Z key), but in art it should always look like a short curved work blade, not a war sword.

**Generation prompt (copy-paste for Scenario.gg):**
```
LungiMan, Kerala coconut tapper, muscular bare-chested young South Indian man, warm brown skin,
aviator sunglasses dark lenses gold frame, thick black mustache, dark curly hair,
white mundu folded up at waist in Kerala working style, thick horizontal white fabric band at waist
with doubled gold border stripe, bare legs from mid-thigh down, NOT a dhoti, no fabric between legs,
boxer shorts visible below fabric hem, brown leather crossbody satchel with green coconut,
rope coil at hip, small curved sickle at waist, barefoot,
bold black outlines, flat Kerala mural cartoon style, jewel-tone fills, transparent background
```

**Confirmed character design (reference image locked):**
- Muscular bare-chested young Kerala man, warm brown South Indian skin tone
- **Aviator sunglasses** — dark lenses, warm gold frame (always present, signature look)
- Black thick mustache, dark curly/coily hair
- **White mundu, Kerala active/working fold** — worn in the "short lungi" style: first wrapped full-length around the waist, then the outer layer folded UP and tucked at the waist (steps 4→5 of traditional fold). Creates a doubled band of fabric at the front waist with the gold/yellow border stripe visible and doubled at the fold line. Legs fully exposed from mid-thigh down for mobility. NOT a dhoti (nothing passes between the legs).

  **For AI generation — use this exact prompt fragment:**
  > *"white mundu folded up at waist in Kerala working style, thick horizontal white fabric band at waist with doubled gold border stripe, bare legs from mid-thigh down, NOT a dhoti, no fabric between legs, short lungi style, boxer shorts visible below the fabric hem"*

  **Visual checklist for the mundu in every frame:**
  - Fabric ends at mid-thigh — legs bare below
  - A thick horizontal band of doubled white fabric sits at the waist
  - Gold/yellow border stripe runs along the bottom edge of that band, doubled
  - The fabric hangs straight down in front — no folds or drapes between the legs
  - Boxer shorts peek out just below the hem of the fold
- **Boxer shorts always worn underneath** — visible in the `boxer_idle` post-fight sprite when mundu is removed. Same colour/style as what's visible below the mundu fold in normal sprites.
- Brown leather crossbody satchel — green coconut visible inside
- Barefoot
- Bold black outlines, flat cartoon style

**Visual must-haves in every sprite:**
- Aviator sunglasses on at all times — never removed
- Rope coil visible at hip/waist in idle, walk, run — always present
- Rope extends to trunk during `swing_grab` and `swing` animations
- Curved arivaal sickle at the waist (small, not ornate)
- Crossbody coconut satchel stays on across all animations
- Young adult, sun-weathered Kerala village look

| Sheet | Animations (rows) | Grid | Frame size |
|---|---|---|---|
| `hero_full_sheet.png` | idle · walk · run · sword · sword2 · swing_grab · swing · throw · chai · mundu_lasso · boxer_idle | 4 cols × N rows | Match existing 768×448 |

**Animations detail:**
- `idle` — 2–3 frames, subtle breathing; rope coil at hip, sickle at waist
- `walk` — 6 frames loop; casual gait, rope sways slightly
- `run` — 8 frames loop; rope and sickle bounce with motion
- `sword` — 4 frames, forward *arivaal* slash — curved sickle swings wide at chest height
- `sword2` — 3 frames, return backswing — blade pulls back to hip
- `swing_grab` — 2 frames, rope loop thrown around trunk, gripping high up
- `swing` — 3 frames loop, pendulum mid-air on rope (feet tucked, rope taut)
- `throw` — 8 frames, coconut throw arc (already have Hero-Coconut-throw.png, use as reference)
- `chai` — 3 frames, drinking animation (rope still coiled at hip)
- `mundu_lasso` — 2 frames: **[1]** LungiMan unties mundu with one hand, arm raised; **[2]** full overhead lasso swing, mundu extended wide. *Used in Act V Pey Komban cinematic.*
- `boxer_idle` — 1 frame: LungiMan standing in **boxer shorts only** — no mundu, satchel still on, aviators still on, arivaal still at waist. Calm. Not embarrassed. He's just beaten a demon king. *Used post-cinematic until Thoma hands him a fresh mundu.*

**Worn-down visual states — code-only, no extra frames needed:**
These are `modulate` tints applied in `Player.gd` as HP drops. No new sprite frames required — just document the intended tint progression for reference when reviewing in-game:
- Full health: pure white modulate (no tint)
- 50% HP: very faint warm sepia — most players won't consciously notice
- 25% HP: visible warm-red shift — subconscious fatigue signal
- Critical: distinct reddish tint + idle animation slows to 55% speed
- Maveli blessed: golden tint overrides all worn states for rest of game

---

## 👥 NPCs (base image per character)

### BrotherThoma
> **Base image:** Middle-aged Kerala Christian man, white mundu, wooden cross, gentle expression

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `thoma_sheet.png` | idle · talk | 2 cols × 1 row | 256×512 |

---

### SoniyaChechi
> **Base image:** Middle-aged Kerala woman, floral churidar, chai flask, warm smile

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `soniya_sheet.png` | idle · talk | 2 cols × 1 row | 256×512 |

---

### Ustad Basheer
> **Base image:** Elderly Muslim elder, white kurta, skull cap, walking staff, wise expression

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `basheer_sheet.png` | idle · talk | 2 cols × 1 row | 256×512 |

---

### Captain Biju
> **Base image:** Weathered ex-fighter turned houseboat captain, mundu + open shirt, strong build softened by years of river life, slight beard, calm knowing expression — a man carrying old guilt quietly

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `biju_sheet.png` | idle · talk | 2 cols × 1 row | 256×512 |

---

### Mundakkal Ravi
> **Base image:** Stout jovial man, colourful lungi, toddy seller energy, slightly tipsy grin

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `ravi_sheet.png` | idle · talk | 2 cols × 1 row | 256×512 |

---

### Mooppan Velu
> **Base image:** Ancient Kerala forest monk, gaunt and hollow-eyed, simple white dhoti, long matted hair, bare-chested, the look of a man who has not forgiven himself in fifty years — leaning on a gnarled walking staff, crouched in a cave mouth

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `mooppan_sheet.png` | idle · talk | 2 cols × 1 row | 256×512 |

---

### Maveli (Mahabali)
> **Base image:** The legendary Kerala king — large, portly, regal and warm. Ornate white mundu with heavy gold border, bare-chested with thick gold jewelry (necklaces, armlets), tall traditional Kerala raja crown, kind face with a full beard, melancholic eyes that carry centuries of waiting. He sits on an ancient stone throne. He is not sad. He is patient. Amber-gold color palette — he is the opposite of darkness.
>
> **Scale note:** Maveli is significantly larger than LungiMan — a king, not a man. About 1.8× player height. He should feel immense but never threatening.

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `maveli_sheet.png` | seated · stand · bless | 3 cols × 1 row | 512×768 |

**Animation detail:**
- `seated` — 2 frames, gentle breathing on the throne, oil lamp light flickers across face
- `stand` — 2 frames, rises from throne slowly, regal weight
- `bless` — 3 frames, hand extends to LungiMan's chest, golden light pulses outward

---

### Kili the Spirit Crow
> **Base image:** Glowing amber-eyed crow, slightly translucent spirit energy, Kerala forest crow

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `kili_sheet.png` | perch · fly · caw | 3 cols × 1 row | 192×192 |

---

## 👹 Enemies & Bosses (hero sheet = style ref, no separate base image)

### TempleCrow *(Act V pre-boss — possessed temple crows)*
> **Style ref:** Hero sheet for line/colour · dark near-black body · glowing amber eye (possession) · perched vs dive-bomb poses

| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `temple_crow_sheet.png` | perch · dive | 2 cols × 1 row | 96×80 |

- **Perch** (1 fr): crow sitting on branch, wings folded tight, amber eye visible, very dark silhouette
- **Dive** (1 fr): wings swept fully back, body angled downward, beak forward, eye blazing bright amber
- Color: near-black body `#0D0505`, wing edge highlight `#1A0A0A`, amber eye `#F27300`
- Scale: small (~30px in-game) — they are birds, not bosses
- Procedural fallback currently active in code (ColorRect body + wings); this sheet replaces it when ready

---

### CoconutCrab *(already has crab_sheet.png — may update to match new style)*
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `crab_sheet.png` | walk | 8 cols × 1 row | 250×125 |

---

### HauntedMonkey
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `monkey_sheet.png` | patrol · attack | 4 cols × 1 row | 256×384 |

- Patrol: 2 frames, knuckle-walk
- Attack: 2 frames, leap lunge

---

### GhostClone
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `ghost_sheet.png` | float | 2 cols × 1 row | 256×512 |

- Translucent white/blue wisp
- **Real clone** gets a shadow node added in code (no separate art needed)

---

### Crocodile
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `croc_sheet.png` | walk · lunge | 4 cols × 1 row | 360×176 |

- Dark mottled green, low silhouette, wide jaw
- Walk: 3 frames · Lunge: 1 frame (open jaw)

---

### Yakshi
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `yakshi_sheet.png` | float · hypno · stun | 5 cols × 1 row | 208×320 |

- Pale moonlit saree, flowing dark hair, glowing amber eyes
- Float: 2fr loop · Hypno: 2fr loop · Stun: 1fr

---

### Kuttichathan
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `kuttichathan_sheet.png` | idle · spawn | 4 cols × 1 row | 176×240 |

- Small child spirit, deep red skin, tiny horns, fiery aura
- Idle: 2fr loop · Spawn: 2fr

---

### Odiyan
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `odiyan_sheet.png` | human · bull · dog | 5 cols × 1 row | 224×272 |

- Human: grey cloaked man (1fr) · Bull: dark brown, white horns (2fr loop) · Dog: near-black lean hound (2fr loop)

---

### Karinkanni
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `karinkanni_sheet.png` | closed · open | 3 cols × 1 row | 240×240 |

- Floating lidded eye orb, purple-black body
- Closed: 1fr · Half-open: 1fr · Fully open: 1fr

---

### PeyKomban
| Sheet | Animations | Grid | Frame size |
|---|---|---|---|
| `peykomban_sheet.png` | patrol · windup · charge | 4 cols × 1 row | 320×360 |

- Massive tusk-wielding demon, dark brown — dwarfs the player
- Patrol: 2fr loop · Windup: 1fr (orange glow) · Charge: 1fr

---

## 🏠 Props (no base image needed — style derived from hero)

### Vehicles
| Prop | Sheet | Frames | Frame size | Notes |
|---|---|---|---|---|
| Boat | `boat_sheet.png` | 1 static | 480×120 | Kerala vallam, wooden, river |
| Raft | `raft_sheet.png` | 2 (bob animation) | 360×96 | Rough logs tied together |

### Stalls & Structures
| Prop | Sheet | Frames | Frame size | Notes |
|---|---|---|---|---|
| Chaya Kada | `chaykada_sheet.png` | 1 static | 320×280 | Tea stall, kettle steaming, bench |
| Toddy Shop | `toddy_shop_sheet.png` | 1 static | 320×280 | Palm frond roof, clay pots |
| Carnival Bell Stall | `bell_stall_sheet.png` | 2 (bell swing) | 256×320 | Hanging bell, coconut toss counter |
| Roadside Shrine | `shrine_sheet.png` | 2 (lamp flicker) | 160×240 | Bhadrakali shrine, brass lamp |

### Environment Details
| Prop | Sheet | Frames | Frame size | Notes |
|---|---|---|---|---|
| Fire Hazard Patch | `fire_hazard_sheet.png` | 3 (flicker loop) | 280×88 | Glowing ember ground zone |
| Cursed Ground Zone | `cursed_ground_sheet.png` | 3 (pulse loop) | 280×32 | Act V only — deep blood-red ground glow with faint rune marks; procedural ColorRect active until this ships |
| Hoof Print Marker | `hoof_marker_sheet.png` | 2 (glow pulse) | 112×112 | Spirit smoke amber glow |
| Broken Ferris Wheel | `ferris_wheel_sheet.png` | 1 static | 480×480 | Act II background silhouette |
| Fallen Toddy Cart | `fallen_cart_sheet.png` | 1 static | 320×200 | Overturned cart, pots scattered |

---

## 📋 Generation Order (priority)

1. **Hero unified sheet** — needed to fix current placeholder animations
2. **NPCs** (Thoma, Soniya, Mundakkal Ravi, Basheer, Captain Biju, Mooppan Velu, Kili) — needed for all acts
3. **Major bosses** (Yakshi, Kuttichathan, Odiyan, Karinkanni, PeyKomban) — needed for Act I–V
4. **Common enemies** (Monkey, Croc, GhostClone, CoconutCrab update)
5. **Props** — polish pass, done last

---

## ✅ Already Done

| Asset | Status |
|---|---|
| `hero_sheet.png` | ✅ Wired (placeholder animations) |
| `Hero-run.png` | ✅ Wired in Player.gd |
| `Hero-Coconut-throw.png` | ✅ Wired in Player.gd |
| `powerup_icon_sheet.png` | ✅ Wired in PowerUp.gd |
| `fire_hazard_row.png` | ✅ Wired in Act2.gd |
| `hoof_water_row.png` / `hoof_platform_row.png` | ✅ Wired in Act3.gd |
