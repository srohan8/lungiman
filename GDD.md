# Kanjiravanam Chronicles — Game Design Document

> **Engine:** Godot 4.6 · Jolt physics · **Viewport:** 820×460 · Mobile-first  
> **Village:** Muruthikudi ("Sacred Grove Hamlet") — outer edge of Kanjiravanam forest, bordering a backwater river village.  
> **Tone:** Mysterious, spiritual, wild. Kerala mythology meets side-scrolling action.  
> **Time span:** Golden hour (Prologue) → full nightfall (Act V).

---

## 🎮 Core Controls

| Key | Ground | On Crown |
|---|---|---|
| **A / D** | Move left/right | Face direction |
| **E** | Climb nearest tree | Drop from crown |
| **X / Space** | Jump / Dodge | **Press toward tree → Swing; release on arc → launch to next crown** |
| **Z** | Sword swing | — |
| **C** | Throw coconut | **Throw coconut** (key for aerial bosses) |
| **S / Down** | Dodge roll | — |
| **Esc** | Main Menu | Main Menu |

### Swing Mechanic
- Climbing a tree enters **SWINGING** state (pendulum physics, rope length ~110px)
- Press E while swinging forward → releases and **launches to the nearest tree** in your facing direction
- If no target tree: pure tangential release (free-fly)
- A brown rope Line2D shows the swing visually
- Swinging is **safe** from boss charges and triggers ammo regen

---

## 🏺 Powerup System

| Item | Icon | Effect | Where found |
|---|---|---|---|
| **Heart** | ❤️ | +40 HP instant | Common drops, act pickups |
| **Nut** | 🥥 | +4 ammo | Enemy drops, tree platforms |
| **Porotta** | 🫓 | +25 HP + 2× damage for 4s | Boss arenas, hard-fight rewards |
| **Chai** | ☕ | Slow-mo 6s + cures hypnosis, paralysis, dizziness | Soniya Chechi, act pickups |
| **Toddy** | 🏺 | +20 HP BUT dizzy 5s (wobbly controls + camera sway) | Risk/reward near danger zones |
| **Resurrection** | 🪙 | Extra life token | Brother Thoma, once per act |

**Toddy — The Kerala Challenge Pickup:** Real fermented coconut sap. Placed temptingly near rivers, fire zones, and boss arenas. Chai cures it instantly.

**Porotta — The Warrior's Meal:** Flaky Kerala flatbread. No debuff. Pure fuel. Rage buff (2× damage 4s) rewards aggression.

---

## 🌿 Player State Machine

```
TreeState { NONE, CLIMBING, PERCHED, SWINGING, FLYING }
in_water: bool     — wading (55% speed, passive water dmg)
rolling: bool      — dodge roll (0.35s active, 0.40s iframes)
_shake_trauma      — screen shake (trauma-squared decay)
```

---

## 📖 Act Summaries

### PROLOGUE — "Muruthikudi at Dusk" (World.tscn)
*Tutorial warmth. Golden hour. Learn everything safely.*

- Biju Ettan's Hut → dialogue + first coconut
- Kanjiravanam Gate — ancient moss arch, camera pullback
- Brother Thoma → resurrection token + "Stay on the trees"
- First tree climb (E), first swing (X), coconut throw tutorial
- River crossing: boat visible, crocodile glides below
- First enemy: Coconut Crab (sword tutorial)
- Ghost Clone cameo at distance
- x=7800 → Act I

---

### ACT I — "Yakshi's Hollow" (Act1.tscn)
*Bamboo grove, Muruthikudi river bend, dusk → nightfall.*  
*Mechanics: River wading + boats, forced swing at broken bridge, Mirror Pool decoys, hypnosis boss.*

**Key beats:**
- Aniyandi Ravi at Toddy Stall (x=400) — Swing-off Race quest (Phase 3)
- Broken Bridge (x=700) — forced swing traversal
- River Zone (x=2200–3000): 3 boats | 2 crocodiles (22 dmg lunge)
- Soniya Chechi — Chaya Kada (x=3400)
- Mirror Pool Zone (x=4000–5500): 5 fake Ghost Clones + 1 real (real casts shadow)
- Boss: **YAKSHI** — Hypnosis reverses controls 8s. Chai cures. 3 coconut hits.

---

### ACT II — "Kuttichathan's Carnival" (Act2.tscn)
*Abandoned fire festival, ember-lit ruins, cracked lanterns.*  
*Mechanics: Bike cold open, fire hazard zones, clone explosion damage, Fire Rain event (vertical play).*

**Cold open — Ravi's Bullet (new):**
- **Aniyandi Ravi** (x=200) hands the hero his 1990s Royal Enfield Bullet
  > *"The carnival grounds are 2km down — take my bike, machane. But when the trees start, you walk. The Bullet won't go where the spirits live."*
- **5km side-scroll bike ride** with heavy parallax (3 layers: crowds/lights · trees · road)
- **Engine Health gauge** shown on HUD — damage but bike *always* reaches the trees
- **3 obstacle types:**
  1. Festival crowds spilling onto road — weave left/right
  2. Potholes & speed bumps — tap Jump to pop front wheel
  3. Kuttichathan's mischief — firecrackers, stray goat, broken cart
- Road narrows as forest closes in; carnival lights fade behind
- **Music arc:** festive chenda drums → engine joins the beat → single nadaswaram fades in (ominous) → silence
- **End:** Fallen burning trees block the road. Dead stop. Wind. Distant drums. Player dismounts.
- **Callback (Act V):** If Engine Health full → Ravi says *"Did you scratch my bike, machane?"*

**Key beats (on foot):**
- Fire Hazard Ground Zones (x~800–1200): orange patches, 8 dmg on touch
- Carnival Bell Stall: sword-hit → nut powerup + "Carnival Champion" badge
- Clone Decoy Zone (x~3000–5000): wrong clone = 15 dmg explosion; real flickers fast
- Fire Rain Event (x~5000): fireballs every ~1.8s; crowns = safe
- Boss: **KUTTICHATHAN** — phase 1 mid-fight clones; phase 2 fireball charge, vulnerable 0.8s on landing

---

### ACT III — "Odiyan's Hunt" (Act3.tscn)
*Foggy highland forest, cattle trails, half-buried ruins.*  
*Mechanics: Transform-window combat, Odiyan's Tracks mini-quest, bull chase 3rd-person moment.*

**Key beats:**
- Ustad Basheer at crossroads → activates Odiyan's Tracks quest
- 4 glowing hoof-prints: press Z near spirit smoke to "read"
- All 4 found → `weakness_revealed = true` on Odiyan (extends window 0.6s → 0.9s)
- Kili the Spirit Crow at shrine (feeds 3 porotta → companion in Phase 3)
- Fog deepens dynamically
- **Hoof-print #4 triggers BULL CHASE (new):**
  - Camera pulls behind the player — brief 3rd-person over-the-shoulder perspective
  - Odiyan in bull form charges directly at camera, screen shaking violently
  - **Single input:** Jump/Roll to vault over a root or rock blocking the path
  - ~3 seconds. Camera snaps back to 2D. Boss fight begins immediately.
  - Pure adrenaline — terror that something is hunting *you*
- Boss: **ODIYAN** — HUMAN (immune) → FLASH (vulnerable) → BULL (charge) → DOG (bite)

---

### ACT IV — "Karinkanni's Curse" (Act4.tscn)
*Rain-drenched mangroves, rising water, distant thunder.*  
*Mechanics: Must be on tree crown to hit boss. Eye opens briefly. Paralysis ray.*

**Key beats:**
- Soniya Chechi at flooded hut → auto-serves chai
- Sr. Devi at shrine → Bell of Bhadrakali quest (Phase 5)
- Brother Thoma building raft → resurrection token
- Tall Tree Zone (x~2000–6000): 22 trees height=240, crowns at y~135
- Boss: **KARINKANNI** — drifts at y~150, only reachable from crown
  - CLOSED (purple, immune) → OPEN eye (1.5s vulnerable, paralysis ray)

---

### ACT V — "Pey Komban's Rampage" (Act5.tscn) — FINALE
*Sacred temple grove, near-black sky, ancient banyan, fireflies.*  
*Mechanics: Stay off ground — one charge is fatal. 3 boss phases. 3rd-person opening reveal.*

**Key beats:**
- **Act V opening — 3rd-person reveal (new):**
  - Ground shakes. Thunderous footsteps heard before anything visible.
  - Camera pulls behind player as they walk through the temple gate.
  - Pey Komban's silhouette emerges through ancient trees — impossibly large.
  - Pure spectacle. ~3 seconds. Camera snaps back to 2D side-scroll.
  - Emotional register: **awe**, not terror (contrast with Act III's terror)
- Brother Thoma at gate → auto-grants resurrection token · *"Stay. On. The. Trees. Promise me."*
- Soniya Chechi emergency chai cart (x~700) → full powerup spread
- Pey Komban patrols entire level from start, ground shakes every 8s
- Boss: **PEY KOMBAN** — PATROL → WINDUP (0.5s) → CHARGE (420px/s, immune) → RECOVER
  - Phase 2: speed 520px/s, recovery 0.7s
  - Rage: alternating L/R charges, screen shake on each impact
- **VICTORY:** "Kanjiravanam breathes again." Sacred tree blooms in all 5 act colours.

---

## 🧩 Side Quests

### Built (no QuestManager needed)
| Quest | Act | Mechanic | Reward |
|---|---|---|---|
| **Odiyan's Tracks** | III | 4 hoof-print markers; press Z to read; all 4 → weakness revealed | Vulnerable window 0.6s → 0.9s |

### Phase 3 (with QuestManager)
| Quest | NPC | Mechanic | Reward |
|---|---|---|---|
| **Swing-off with Aniyandi Ravi** | Toddy Shop (Act I) | AI Ravi tweens crown-to-crown; player must reach tree #5 first | Appam Glide ability |
| **Chaya Kada Showdown** | Soniya Chechi (Act I) | Timed button-mash vs 3 drunkards | Ammo regen 2× near tea shops |

### Phase 5 (post-core)
| Quest | NPC | Blocker | Reward |
|---|---|---|---|
| **Bell of Bhadrakali** | Sr. Devi | Houseboat sub-scene needed | Totem Revival (extra resurrection) |
| **The Crow and the Cooked Rice** | Kili the Spirit Crow | Companion AI + stealth detection | Kili warns of ambushes |
| **Fish Fry for the Gods** | Biju Ettan | Fishing mini-game loop | Double HP regen for 1 act |

---

## 👤 NPCs

| Name | Location | Role | Mechanic |
|---|---|---|---|
| **Soniya Chechi** | Acts I, IV, V | Chaya Kada owner | 3-stage dialogue; drops chai; side quest giver |
| **Brother Thoma** | Acts I–V | Protector | Grants resurrection token once per act |
| **Aniyandi Ravi** | Acts I, II | Toddy shop owner | Swing-off Race quest |
| **Ustad Basheer** | Act III | Elder tracker | Odiyan's Tracks quest |
| **Kili the Spirit Crow** | Act III | Animal guide | Companion (Phase 3); warns before Odiyan transforms |
| **Sr. Devi** | Act IV | Buddhist nun | Bell of Bhadrakali (Phase 5) |
| **Biju Ettan** | Prologue | Village elder | Introduces world; Fish Fry quest (Phase 5) |

---

## ⚙️ Systems Reference

### GameManager (autoload)
| Variable | Type | Purpose |
|---|---|---|
| `hp`, `max_hp` | int | Player health |
| `ammo`, `max_ammo` | int | Coconut ammo |
| `score` | int | Global score |
| `slow_mo_active / timer` | bool/float | Chai / rum effect |
| `rage_active / timer` | bool/float | Porotta double-damage |
| `hypnosis_active / timer` | bool/float | Yakshi curse |
| `paralysis_active / timer` | bool/float | Karinkanni curse |
| `has_resurrection` | bool | Brother Thoma token |
| `boss_hp / boss_max_hp` | int | HUD boss bar |
| `climb_press_pending` | bool | Mobile E button one-shot |

### BaseAct — Shared Helpers
```
_linspace(from, to, count)            → Array
_add_tree(parent, x, h, lean, tint)
_add_powerup(parent, x, y, type)
_add_platform(x, y, w, tint)          → StaticBody2D
_spawn_boat(parent, x, water_y)       → 120px wood platform
_queue_hint(text, delay, duration)    → HUD.show_hint after delay
_connect_player_to_hud()              → wires climb_prompt, signals
```

### Boss Pattern (all bosses follow this)
1. `_ready()`: cache `_player`, call `GameManager.set_boss(MAX_HP)`
2. `take_damage()`: **NO await** — use `_flash_timer` float
3. `_process()`: tick `_flash_timer`, reset modulate when done
4. `_die()`: call `GameManager.clear_boss()`, drop powerup, `queue_free()`

### Signal Flow (never break)
```
Enemies ──► GameManager signals ──► HUD (presentation)
Player  ──► climb_prompt_changed ──► HUD
Bosses  ──► player_died / game_won ──► GameOver / Victory overlays
QuestMarker ──► QuestManager ──► Boss weakness flags
```

---

## 🚫 Architecture Rules — Never List

- **NEVER** call `get_nodes_in_group()` inside `_physics_process` — cache in `_ready()`
- **NEVER** use `await` inside `take_damage()` — use `_flash_timer` float ticked in `_process`
- **NEVER** put gameplay logic in act `_process` beyond the x-trigger check
- **NEVER** duplicate `_linspace` / `_connect_player_to_hud` — use `BaseAct`
- **NEVER** let `GameManager` grow beyond: stats, status effects, boss HP, progress signals
- **NEVER** call `SpriteFrames.new()` in `_process` — build once in `_ready()`
- **NEVER** use `play()` every frame — guard with `if spr.animation != target_anim`
- **NEVER** use `scale.x` on `AnimatedSprite2D` for direction — use `flip_h` instead

---

## 📁 File Map

```
C:\Projects\Lungiman\
├── autoload/
│   ├── GameManager.gd       ✅
│   └── SceneManager.gd      ✅
├── assets/sprites/
│   ├── hero_sheet.png        ✅ wired in Player.gd
│   ├── crab_sheet.png        ✅ wired in CoconutCrab.gd
│   └── [boss sheets]         🎨 Phase 2.5 — generate via mcp__godot__generate_2d_asset
└── scenes/
    ├── BaseAct.gd / World / Act1–5   ✅
    ├── Player.gd             ✅ pendulum swing mechanic
    ├── HUD.gd / .tscn        ✅ BossBar + HintLabel
    ├── GameOver.gd / .tscn   ✅ Retry + Menu + Level Select
    ├── LevelSelect.tscn      ✅ main scene
    ├── PowerUp.gd            ✅ sprite sheet visual
    └── [all bosses/enemies]  🔄 Phase 2.5: AnimatedSprite2D upgrade
```
