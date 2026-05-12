# 🌴 Kanjiravanam Chronicles — Game Design Document

> Engine: Godot 4.6 · Viewport: 820×460 · Mobile-first  
> Setting: Muruthikudi — Kerala forest village, golden hour to full nightfall

---

## 🎮 Core Controls

| Key | Ground | On Crown |
|---|---|---|
| **A / D** | Move left/right | Face direction |
| **X / Space** | Jump | **Swing to next crown** (or leap off) |
| **E** | Climb nearest tree | Drop from crown |
| **Z** | Sword swing | — |
| **C** | Throw coconut | **Throw coconut** (key for aerial bosses) |
| **S / Down** | Dodge roll | — |
| **Esc** | Main Menu | Main Menu |

---

## 🏺 Powerup System

| Item | Icon | Effect | Where found |
|---|---|---|---|
| **Heart** | ❤️ | +40 HP instant | Common drops, act pickups |
| **Nut** | 🥥 | +4 ammo | Enemy drops, tree platforms |
| **Porotta** | 🫓 | +25 HP + 2× damage for 4s | Boss arenas, comfort after hard fights |
| **Chai** | ☕ | Slow-mo 6s + cures hypnosis, paralysis, dizziness | Soniya Chechi, act pickups |
| **Toddy** | 🏺 | +20 HP BUT dizzy for 5s (wobbly controls + camera sway) | Risk/reward near danger zones |
| **Resurrection** | 🪙 | Extra life token | Brother Thoma, once per act |

### Toddy — The Kerala Challenge Pickup
Kerala palm toddy is real fermented coconut sap. In-game it's a temptation:
- You need HP and there's a `🏺` right there
- But for 5 seconds your controls drift randomly and the screen sways
- **Chai cures it instantly** — if you have one
- Strategically placed near rivers, fire zones, and right before boss arenas

### Porotta — The Warrior's Meal
Flaky Kerala flatbread. No debuff. Pure fuel.
- Best post-fight reward when you cleared an area
- The rage buff (2× damage for 4s) rewards aggressive play

---

## 🌿 Player State Machine

```
TreeState { NONE, CLIMBING, PERCHED, FLYING }

NONE     → E near tree    → CLIMBING
CLIMBING → reaches crown  → PERCHED
PERCHED  → X (Jump)       → FLYING (swing arc to next tree, or free jump)
PERCHED  → E              → NONE (drop)
FLYING   → lands on crown → PERCHED
FLYING   → lands on floor → NONE
```

**Special states:**
- `in_water` — wading: 55% speed, passive damage every 2.5s
- `rolling` — dodge roll: 0.35s duration, 0.40s iframes
- `hypnosis_active` — controls reversed (Yakshi curse, cured by chai)
- `paralysis_active` — frozen (Karinkanni curse, cured by chai)
- `toddy_active` — input drift + camera sway (cured by chai)

---

## 🗺 Level Design

### PROLOGUE — "Muruthikudi at Dusk"
**Tone:** Warm, golden, safe. Everything is a tutorial.

```
Village → Kanjiravanam Gate (camera widens)
→ Brother Thoma [resurrection token, climb teaching]
→ Tree 1: [E climb] → Tree 2: [X swing] — feel the arc
→ Mini-challenge: 3 trees, no ground
→ Coconut throw tutorial
→ River: first boat crossing, croc visible below
→ Coconut Crab: first combat
→ Ghost Clone cameo: "Something doesn't feel right..."
→ x=7800 → ACT I
```

---

### ACT I — "Yakshi's Hollow"
**Tone:** Bamboo and mist. Beautiful and dangerous. Something watches.

```
  CROWN (y≈150)  🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴
  MID   (y≈240)  ─────────  ─────────  ─────────
  GROUND(y≈375)  ═════════════════════════════════

[x=400]  Aniyandi Ravi (Toddy Stall) → Side Quest: Swing-off Race
[x=700]  BROKEN BRIDGE → forced first real swing
[x=1200] MID LAYER platform → Monkey above, throw upward
[x=1500] ENEMY ZONE: Haunted Monkeys on vines
[x=2200] RIVER ZONE: 3 boats, 2 crocs | chai hidden above on mangrove
[x=3400] Soniya Chechi → chai + tutorial | Side Quest: Chaya Kada Showdown
[x=4000] MIRROR POOL: 5 fake clones + 1 real (real = casts shadow)
[x=5500] Owl Spirit on crown — atmospheric
[x=5800] ASCENT ZONE: trees grow taller, fog thickens
[x=6800] BOSS: YAKSHI
```

**BOSS: YAKSHI**
- Phase 1: Hypnosis reverses controls for 8s. Chai cures.
- Phase 2 (<2 HP): 2 Ghost Clones mid-fight. Real = shadow.
- Phase 3 (<1 HP): Hypnosis pulses every 5s.
- 3 coconut hits to kill.
- Drop: Chai + resurrection token

---

### ACT II — "Kuttichathan's Carnival"
**Tone:** Abandoned fire festival. Ember-lit ruins. Unsettling joy.

```
  CROWN (y≈170)  🌴  🌴  🌴  🌴  🌴  🌴  🌴  🌴
  MID   (y≈270)  ──────  ──────
  GROUND(y≈375)  ════[FIRE]════════════════════════

[x=800]  FIRE HAZARD ground — 8 dmg/touch, must swing overhead
[x=1500] Carnival Bell stall — throw from crown to hit bell → nut drop
[x=2200] Aniyandi Ravi → Side Quest: Swing-off Race (Phase 3)
[x=2800] MIDBOSS: Monkey Swarm — 5 monkeys, each death speeds the rest
[x=3000] CLONE DECOY ZONE: 3 Kuttichathan clones — real one flickers
[x=4500] Brother Thoma → resurrection token
[x=5000] FIRE RAIN EVENT → crown = safe, ground = death
[x=5500] BOSS: KUTTICHATHAN
```

**BOSS: KUTTICHATHAN**
- Phase 1: Summons clones mid-fight. Find real (blinking eye).
- Phase 2 (<2 HP): Rides fireball — 0.8s landing stun is the only window.
- Drop: Coconut powerup

---

### ACT III — "Odiyan's Hunt"
**Tone:** Foggy. Paranoid. Every shadow could be him.

```
  CROWN (y≈185)  🌴  🌴  🌴  🌴  🌴  🌴  🌴  🌴
  MID   (y≈280)  ──────  [HOOF #2]
  GROUND(y≈375)  ══[#1]═══════════[#3]═══[#4]═════

[x=300]  Ustad Basheer → QUEST: Odiyan's Tracks ACTIVE
[x=700]  Hoof #1 (ground) → vision flash of bull
[x=1200] Odiyan appears as human in fog — vanishes
[x=1800] Hoof #2 (elevated — must climb) → vision flash
[x=2600] Kili the Spirit Crow at shrine
[x=3200] Hoof #3 — Odiyan lunges as dog, retreats (10 dmg if hit)
[x=3500] Fog thickens, near-black
[x=4000] Hoof #4 — full vision sequence. If all 4 found: weakness_revealed = true
[x=4500] BOSS: ODIYAN
```

**BOSS: ODIYAN**
- HUMAN (immune) → FLASH 0.6s (vulnerable) → BULL (charge) → DOG (bite)
- If weakness_revealed: FLASH window = 0.9s
- Phase 2 (<1 HP): window 0.4s, faster cycle
- Drop: Toddy (you earned it — now wobble home)

---

### ACT IV — "Karinkanni's Curse"
**Tone:** Oppressive. The rain never stops. The eye is always watching.

```
  BOSS  (y≈150)  ← KARINKANNI FLOATS HERE ~~~~~~~~~~
  CROWN (y≈135)  🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴🌴
  MID   (y≈280)  ─────────────────────
  GROUND(y≈375)  ══════[RISING WATER]══════════════════

[x=400]  Soniya Chechi (auto-serves chai)
[x=1200] Sr. Devi → Side Quest: Bell of Bhadrakali (Phase 5)
[x=1800] Brother Thoma → resurrection token
[x=2000] TALL TREE ZONE: 22 trees height=240, crowns at y≈135
[x=2500] Karinkanni first pass — eye CLOSED. Ground players: paralysis ray.
[x=3500] PARALYSIS TRAP ZONE: ray fires downward, misses crown level
[x=5000] Powerup cache (crown-only): heart + nut
[x=5500] BOSS: KARINKANNI
```

**BOSS: KARINKANNI**
- CLOSED (immune, drifting) → OPEN eye (1.5s) → fires paralysis ray
- Hit her only with coconuts from crown level while eye is open
- Below 1 HP: opens every 3s, fires dual ray
- Drop: Heart + ammo cache

---

### ACT V — "Pey Komban's Rampage" *(FINALE)*
**Tone:** Ancient. Sacred. Terrifying. The ground is death.

```
  CROWN (y≈115)  🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳🌳
  MID   (y≈250)  ──────────── [POROTTA + HEART] ────
  GROUND(y≈375)  ══[INSTANT DEATH DURING CHARGE]═══

[x=200]  Brother Thoma → auto resurrection token
[x=700]  Soniya Chechi → heart, nut, toddy, porotta, chai spread
[x=2000] Snapped trees — Pey Komban's trail, scale reveal
[x=2800] Powerup cache (mid-layer, crown-leap): porotta + heart
[x=3500] FIRST SIGHT: Pey Komban in foreground, as tall as 3 trees
[x=4000] BOSS: PEY KOMBAN
```

**BOSS: PEY KOMBAN**
- PATROL → WINDUP (0.5s orange) → CHARGE (420px/s, fatal ground hit) → RECOVER
- Damage window: PATROL only, coconut from crown only
- Phase 2 (<3 HP): charge 520px/s, recovery 0.7s
- Rage (<1 HP): alternating L+R charges, no pause
- Drop: Heart + nut + porotta (the full Kerala feast)

---

## 🧩 Side Quests

| Quest | Act | Status | Reward |
|---|---|---|---|
| **Odiyan's Tracks** | III | ✅ Live | Boss vulnerable window 0.6s → 0.9s |
| **Swing-off Race** | I | 📋 Phase 3 | Unlocks Appam Glide ability |
| **Chaya Kada Showdown** | I | 📋 Phase 3 | Ammo regens 2× near tea shops |
| **Bell of Bhadrakali** | IV | 📋 Phase 5 | Totem Revival (2nd resurrection) |
| **The Crow & the Cooked Rice** | III | 📋 Phase 5 | Kili warns before Odiyan transforms |
| **Fish Fry for the Gods** | Prologue | 📋 Phase 5 | Double HP regen for 1 act |

---

## 👤 NPCs

| NPC | Acts | Role |
|---|---|---|
| **Soniya Chechi** | I, IV, V | Chaya Kada owner. Serves chai, gives quests. |
| **Brother Thoma** | I–V | Protector. One resurrection token per act. |
| **Aniyandi Ravi** | I, II | Toddy shop owner. Swing-off Race quest giver. |
| **Ustad Basheer** | III | Elder tracker. Odiyan's Tracks quest. |
| **Kili the Spirit Crow** | III | Animal guide. Warns before Odiyan transforms (Phase 3+). |
| **Sr. Devi** | IV | Buddhist nun. Bell of Bhadrakali quest. |
| **Biju Ettan** | Prologue | Village elder. Fish Fry quest. |

---

## 📦 Development Phases

| Phase | Status | Description |
|---|---|---|
| 1 — Architecture | ✅ Done | BaseAct, GameManager, signal flow, boss patterns |
| 2 — Level Polish | ✅ Done | All 5 acts with river, platforms, hints |
| 2.5 — Sprites | ✅ Done | All 11 sprite sheets generated and wired |
| 3 — Quest System | 🔄 In Progress | QuestManager ✅, Swing-off Race + Chaya Kada gameplay |
| 4 — Abilities | 📋 Planned | Appam Glide, Totem Revival, Stamina Regen |
| 5 — Post-core | 📋 Planned | Bell of Bhadrakali, Kili AI, Fishing mini-game |
| Audio | 📋 Planned | AudioManager, SFX per action, ambient per act |

---

## 🏗 Architecture Rules

- `GameManager` owns all stats. HUD never touches Player directly.
- All bosses: NO `await` in `take_damage()` — use `_flash_timer` float.
- `_player` cached in `_ready()` — never `get_nodes_in_group()` per frame.
- Signal flow: Enemies → GameManager → HUD. Never backwards.
- `BaseAct` provides all shared helpers. Never duplicate across acts.
