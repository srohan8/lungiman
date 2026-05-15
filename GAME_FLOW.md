# Kanjiravanam Chronicles — Game User Flow

> Village: **Muruthikudi**, Kerala forest edge · Time: Golden hour → Full nightfall

---

## Stage Map

```
MAIN MENU
    │
    ├── New Game ──► PROLOGUE (World)
    │                    │
    │                    ▼
    │               ACT I — Yakshi's Hollow
    │                    │
    │                    ▼
    │               ACT II — Kuttichathan's Carnival
    │                    │
    │                    ▼
    │               ACT III — Odiyan's Hunt
    │                    │
    │                    ▼
    │               ACT IV — Karinkanni's Curse
    │                    │
    │                    ▼
    │               ACT V — Pey Komban's Rampage
    │                    │
    │                    ▼
    │                VICTORY
    │
    └── Level Select ──► Any unlocked stage
```

---

## MAIN MENU

**Entry point.** Options:
- **New Game** → Prologue
- **Level Select** → Unlocked acts (locks cleared progressively)
- **Settings** → Audio / controls overlay

---

## PROLOGUE — "Muruthikudi at Dusk"
`World.tscn` · Sky: golden hour · Unlocks Act I on exit

**Goal:** Learn all core mechanics before danger appears.

| Location | What Happens |
|---|---|
| Village outskirts | Biju Ettan dialogue — hands the player a coconut 🥥 |
| Roadside shrine | Brother Thoma — grants first resurrection token ✝️ |
| First two trees | Climb tutorial (E), swing tutorial (X) |
| Throw target x=620 | Coconut throw practice (Q) — stationary post |
| River x=2860 | Three boats to hop · one crocodile below · "Don't go in the water" |
| First enemies | Coconut Crabs (sword tutorial Z) |
| Ghost clone cameo | One clone drifts past — no threat, foreshadowing |
| x=7800 | Fog rolls in → **transition to Act I** |

**Side quests available:** Fish Fry for the Gods (Biju Ettan, Phase 5)

---

## ACT I — "Yakshi's Hollow"
`Act1.tscn` · Sky: dusk → nightfall · Unlocks Act II on exit

**Goal:** Cross the bamboo grove and defeat Yakshi. Master river + hypnosis.

| Location | What Happens |
|---|---|
| Toddy stall x=400 | Aniyandi Ravi — Swing-off Race side quest offer |
| Broken bridge x=700 | Forced tree-swing traversal (no ground path) |
| Mid platform x=1200 | Monkeys above — throw coconuts upward |
| Enemy zone x=1500–2200 | Haunted Monkeys on vines |
| River zone x=2200–3000 | 3 boats · 2 crocs · secret chai on mangrove platform |
| Chaya Kada x=3400 | Soniya Chechi — serves chai, Showdown quest |
| Mirror Pool x=4000–5500 | 5 fake Ghost Clones + 1 real · **Real = ground shadow** · Wrong hit = −15 HP |
| Owl Spirit x=5500 | Amber eyes, bows, vanishes |
| Ascent zone x=5800–6800 | Trees grow taller (200→260px), fog thickens |
| **BOSS x=6800** | **YAKSHI** — hypnosis reverses controls · chai cures · 3 coconut hits |

**Boss phases:**
1. Hypnosis pulse every 8 s (controls flip)
2. Below 2 HP → 2 extra Ghost Clones appear mid-fight
3. Below 1 HP → hypnosis pulses every 5 s

**Side quests:** Swing-off Race (Aniyandi Ravi) · Chaya Kada Showdown (Soniya Chechi)

---

## ACT II — "Kuttichathan's Carnival"
`Act2.tscn` · Sky: ember-red · Unlocks Act III on exit

**Goal:** Ride Ravi's Bullet to the carnival, navigate fire hazards, expose the real clone, defeat the boss.

| Location | What Happens |
|---|---|
| **x=200 — COLD OPEN** | **Aniyandi Ravi hands over his 1990s Royal Enfield Bullet** · *"When the trees start, you walk."* |
| **🏍️ 5km bike ride** | Festival crowds (weave) · Potholes (tap jump) · Kuttichathan mischief (firecrackers, goat, cart) · Engine Health gauge |
| **Music arc** | Festive chenda → engine joins beat → nadaswaram fades in → silence |
| **~x=2000 — fallen trees** | Burning trees block the road · Dead stop · Player dismounts on foot |
| Fire hazard x=800–1200 | Orange ground patches — 8 dmg on touch · must swing overhead |
| Carnival bell stall x=1500 | Sword-hit bell → drops 2 coconuts + "Carnival Champion" badge |
| Clone decoy zone x=3200–4800 | 3 Kuttichathan clones · **Real one flickers fast** · Wrong = −15 HP explosion |
| Brother Thoma x=chapel | Resurrection token ✝️ · "He hides behind his own laughter." |
| **Fire Rain x=5000–5500** | Fireballs every ~2 s from sky · **Tree crowns = safe · Ground = dangerous** |
| **BOSS x=5500** | **KUTTICHATHAN** — summons mid-fight clones · Phase 2 charges on a fireball |

**Boss phases:**
1. Summons clones — find the blinking eye = real one
2. Below 2 HP → rides fireball, only vulnerable during 0.8 s landing stun

---

## ACT III — "Odiyan's Hunt"
`Act3.tscn` · Sky: foggy highland · Unlocks Act IV on exit

**Goal:** Find 4 hoof-prints (quest), learn the weakness, hit Odiyan in his flash window.

| Location | What Happens |
|---|---|
| Crossroads | Ustad Basheer — activates **Odiyan's Tracks** quest |
| Hoof-print #1 x=700 | Ground level · press Z near smoke → bull vision flash |
| Hoof-print #2 x=1800 | On elevated platform (must climb) |
| Kili the Crow | Spirit crow at shrine — warns 1 s before each transform (Phase 3) |
| Hoof-print #3 x=3200 | Odiyan lunges in dog form then retreats |
| Hoof-print #4 x=4000 | Full vision + Basheer's horn = transform incoming |
| **🐂 BULL CHASE** | **3rd-person over-the-shoulder ~3s** · Odiyan charges at camera · tap Jump to vault root/rock · screen shaking · snaps back to 2D · emotional register: TERROR |
| **BOSS x=4500** | **ODIYAN** — immune in human/bull/dog · only vulnerable in 0.6 s transform flash |

**Quest bonus:** All 4 prints found → `weakness_revealed = true` → flash window 0.6 s → **0.9 s**

**Boss phases:**
1. Human (immune) → Flash (vulnerable) → Bull (charge) → Dog (fast bite)
2. Below 1 HP → window shrinks to 0.4 s, faster cycle

---

## ACT IV — "Karinkanni's Curse"
`Act4.tscn` · Sky: rain-drenched · Unlocks Act V on exit

**Goal:** Reach Karinkanni from tree crowns only — it floats too high to hit from ground.

| Location | What Happens |
|---|---|
| Flooded hut | Soniya Chechi — auto-serves chai (curse is bad) |
| Rising water x=500–1500 | Visual pressure — water line creeps upward |
| Sr. Devi at shrine | Bell of Bhadrakali quest — ghostly houseboat stole the temple bell (Phase 5) |
| Brother Thoma | Building a raft · grants resurrection token ✝️ |
| Tall trees x=2000–6000 | 22 trees height=240 · crowns reach y≈135 |
| **BOSS (drifting y=150)** | **KARINKANNI** — eye closes (immune) / opens 1.5 s (vulnerable) · eye fires paralysis ray |

**Boss phases:**
1. Eye opens every 5 s → throw from crown height
2. Below 1 HP → opens every 3 s, dual-direction ray

**Side quest:** Bell of Bhadrakali (Sr. Devi) → Houseboat sub-scene (Phase 5)

---

## ACT V — "Pey Komban's Rampage" *(FINALE)*
`Act5.tscn` · Sky: near-black, fireflies · No act unlock — leads to Victory

**Goal:** Stay off the ground at all costs. Hit boss only during patrol phase from a crown.

| Location | What Happens |
|---|---|
| Temple gate | Brother Thoma — auto-grants resurrection token ✝️ ("Stay. On. The. Trees.") |
| Soniya Chechi x=700 | Emergency chai cart — full powerup spread |
| Sacred grove x=500–7500 | 24 massive trees height=260 · ground shakes every 8 s (screen shake) |
| Powerup cache x=2800 | Curry + Heart on elevated platform (crown-leap only) |
| **🏔️ OPENING REVEAL** | **3rd-person over-the-shoulder ~3s** · Camera pulls behind player at temple gate · Pey Komban's silhouette emerges through trees — impossibly large · no input needed · snaps to 2D · emotional register: AWE |
| First sight x=3500 | Pey Komban visible in foreground — massive |
| **BOSS x=4000** | **PEY KOMBAN** — patrol → windup → charge (420 px/s, immune) → recover |

**Boss phases:**
1. Patrol → charge cycle · only damageable during patrol from crown
2. Below 3 HP → charge speed 420→520 px/s · recovery 1.2→0.7 s
3. Below 1 HP → charges left+right alternating · screen shake on every impact

**On death:** Golden light, fireflies swarm up, white flash → **VICTORY screen**

---

## VICTORY SCREEN
- Score tally
- Dialogue: Bhadrakali · Brother Thoma · Soniya Chechi
- Options: Main Menu · Level Select

---

## HOUSEBOAT SUB-SCENE *(Phase 5 — Bell of Bhadrakali)*
`Houseboat.tscn` · Entered from Act IV via Sr. Devi warp when quest ACTIVE

| Step | What Happens |
|---|---|
| Enter | Player warped onto dark backwater houseboat |
| Interior | 2 ghost guards patrol the cabin |
| Bell x=400 | Touch the golden bell 🔔 → 2 extra guards spawn |
| Exit left | Walk off left edge → if bell found: quest complete, **Totem Revival** granted |
| Return | Warp back to Act IV entry point |

---

## Side Quest Summary

| Quest | Act | NPC | Reward | Status |
|---|---|---|---|---|
| Odiyan's Tracks | III | Ustad Basheer | Wider boss vulnerability window | ✅ Implemented |
| Swing-off Race | I | Aniyandi Ravi | Appam Glide — slow mid-air fall | 🔄 Phase 3 |
| Chaya Kada Showdown | I | Soniya Chechi | 2× ammo regen near tea shops | 🔄 Phase 3 |
| Bell of Bhadrakali | IV | Sr. Devi | Totem Revival — extra resurrection | 🔄 Phase 5 |
| Fish Fry for the Gods | Prologue | Biju Ettan | Double HP regen for one act | 🔄 Phase 5 |

---

## Abilities Unlocked Per Stage

| Ability | Unlocked By | How |
|---|---|---|
| Climbing (E) | Prologue tutorial | Always available |
| Swinging (X) | Prologue tutorial | Always available |
| Sword (Z) | Prologue tutorial | Always available |
| Coconut Throw (Q) | Prologue tutorial | Always available |
| Roll / Dodge (Shift) | Always available | — |
| Resurrection Token | Brother Thoma (each act) | One-use per act |
| Appam Glide (hold Jump mid-air) | Swing-off Race win | Quest reward |
| Totem Revival | Bell of Bhadrakali | Quest reward |
| Ammo Regen 2× | Chaya Kada Showdown win | Quest reward |

---

*Engine: Godot 4.6 · Viewport: 820×460 (dev) / 1280×720 (release) · Mobile-first*
