# Disco Hallucination — Design Document

> Scene ID: `DiscoHallucination`  
> Trigger: Fires after the Odiyan boss fight ends. Hero walks a few steps, then collapses.  
> Tone: Completely alien to the rest of the game. Neon. Surreal. Funny then terrifying.  
> Duration: ~3–4 minutes total (dance phase + fight phase)

---

## Narrative Context

Hero defeats Odiyan. As Odiyan dies he transforms one last time — dog form — and bites the hero's
ankle. The hero doesn't feel it immediately. He walks forward, victorious.

Then the screen tilts. Legs go heavy. Darkness.

**He wakes up somewhere else.**

On the other side: an 80s Kerala disco-cabaret. Neon lights. Disco ball. Everyone in bell-bottoms
and coloured lungis doing synchronized moves. A nadaswaram plays over a Roland TR-808 beat.
The hero stands in the middle, still in his mundu, completely out of place.

At the end: he collapses on the dance floor. Wakes up in the real world.  
Ravi or another NPC is crouching over him: *"That shapeshifter put something in you, machane.
You were out for an hour. Talking nonsense about dancing."*

---

## Phase 1 — Collapse (non-interactive, ~8 seconds)

- Hero walks 3–4 steps after the Odiyan death animation
- Dialogue bubble: *"Something feels... wrong..."*
- Screen tilts with a tween, vignette closes in
- Heartbeat SFX slows down
- Hard cut to black → bass drop → neon flood

**Godot trigger:**  
`GameManager.trigger_hallucination()` called from Odiyan's `_die()` after a 2-second delay.  
Loads `res://scenes/DiscoHallucination.tscn` via `SceneManager.go_to()`.

---

## Phase 2 — Disorientation (non-interactive, ~10 seconds)

- Hero appears in centre of disco floor, screen shaking slightly
- Disco ball rotates and throws coloured light patches across the floor
- NPCs around him dance in sync (looping idle animation)
- Hero looks left, looks right — confused animation
- Dialogue: *"Where... what is this place?"*
- One NPC grabs his hand and pulls him into the dance circle
- Dialogue: *"DANCE, machane! Follow the steps!"*
- **Arrow prompts appear → Phase 3 begins**

---

## Phase 3 — Dance Minigame (interactive, ~60–90 seconds)

### How it works

Arrow prompts drop from the top of the screen toward a **target zone** at the bottom
(like DDR / Guitar Hero, but simplified to 4 directions + jump).

```
  ←  →  ↑  ↓  [SPACE]
  
  [target zone — glowing line near bottom]
```

- One prompt at a time, spaced ~0.9 seconds apart (matches the beat at ~130 BPM)
- Prompt slides down over ~1.2 seconds
- **Hit window:** 0.35 seconds either side of the target line
- Player presses the matching key as the arrow reaches the line

### Controls during dance
| Prompt | Key | Hero animation |
|---|---|---|
| ← Left arrow | `A` / `←` | Slides left, arm out |
| → Right arrow | `D` / `→` | Slides right, arm out |
| ↑ Up arrow | `W` / `↑` | Raises both arms |
| ↓ Down arrow | `S` / `↓` | Crouches low |
| SPACE (jump) | `Space` / `X` | Leaps with spin |

### Scoring
| Timing | Label | Effect |
|---|---|---|
| Perfect (±0.1s) | **PERFECT** | Gold flash, crowd cheers |
| Good (±0.25s) | **GOOD** | Green flash |
| OK (±0.35s) | **OK** | White flash, hero stumbles slightly |
| Miss | **MISS** | Crowd laughs, hero looks embarrassed |

- No fail state — the sequence always completes regardless of score
- Score is saved as `GameManager.disco_score` and shown at the wake-up screen
  ("You danced... somewhat acceptably.")
- 3 misses in a row: NPC beside him puts a hand on his shoulder — *"Relax, machane."*

### Sequence design (approximate — 20 prompts)
```
→ → ← SPACE → ← ↑ → ↓ → → SPACE ← → ↑ ↓ → ← SPACE
```
Starts slow and simple, builds in speed from prompt 12 onward (BPM feeling increases even
though the actual BPM stays constant).

### End of dance phase
After all prompts complete, hero does a final flourish pose.  
Crowd cheers. Disco ball spins faster.  
Then — the music warps.

---

## Phase 4 — The Turn (non-interactive, ~5 seconds)

- Player loses input control (explicitly: `set_process_input(false)`)
- Pitch of music drops slowly (tween `AudioServer` pitch scale from 1.0 → 0.4)
- Screen tint shifts from neon pink → deep red
- All NPC eyes flash red simultaneously
- Crowd faces hero. Silence for 1 beat.
- Then they lunge.
- Chromatic aberration shader activates

Dialogue (no voice, just text that flickers): *"No no no no no—"*

---

## Phase 5 — Fight Phase (interactive, ~90 seconds)

### Setup
- Normal combat resumes: sword attack, coconut throw, jump, all work as usual
- But visuals are heavily distorted:
  - Chromatic aberration (RGB split) — permanent during this phase
  - Screen has red vignette pulsing with the beat
  - Enemies glow red/purple — same as normal enemy types but recoloured
  - Disco ball still spinning, coloured light patches moving across floor

### Enemies
Reuse existing enemy types but wrapped as "disco zombies":
- `DiscoGuest` → behaves like a standard enemy, colourful lungi + red eyes
- `DiscoCouple` (two linked) → behaves like Karinkanni enemy type
- `DiscoDJ` (fixed position) → throws vinyl records as projectiles

### The twist — a losing fight by design
Hero has a **Hallucination Drain** bar (separate from normal HP):
- Starts at 100, drains at 8 per second automatically (cannot be recovered)
- When it hits 0 → scripted collapse regardless of enemy HP or player health
- Player can extend it slightly by killing enemies (+3 per kill)
- This means a perfect fighter gets ~2–3 extra seconds — not enough to win

HUD shows this bar labeled: **"CLARITY"** (not HP — keeping the fiction)

### Scoring
Every kill adds to `GameManager.disco_score`.  
Shown on wake-up: *"You took down [N] in there. Whatever that means."*

### Collapse
- Clarity hits 0
- Hero drops to one knee, sword clatters
- Screen goes to extreme white bloom
- Silence — then heartbeat — then real-world sounds

---

## Phase 6 — Wake-Up (non-interactive, ~15 seconds)

- Fade in from white to the real-world scene (exterior of the Odiyan arena, daytime)
- Hero is on the ground, Ravi (or other NPC) crouching over him
- Dialogue: *"Machane! You were out for almost an hour. Kept shouting 'left! right! left!'..."*
- Hero sits up slowly: *"There was music. And dancing. And then—"*
- Ravi: *"Odiyan's venom. Old shapeshifter trick. You'll be fine. Probably."*
- Hero HP restored to 40% (survived, but damaged)
- Game resumes normal flow → next act begins

---

## Visual Style Reference

| Element | Normal game | Disco hallucination |
|---|---|---|
| Background | Kerala nature, temples | Black floor with coloured tiles |
| Lighting | Natural, warm | Rotating disco ball, neon spots |
| Colour palette | Ochre, green, brown | Hot pink, electric blue, gold |
| Screen effects | None | Chromatic aberration, red vignette |
| Character colours | Normal | Same sprites, +red eye glow on enemies |

---

## Audio Requirements

| File | Length | Notes |
|---|---|---|
| `bgm_disco.ogg` | 3 min | 130 BPM, nadaswaram + TR-808 + DX7 synth bass |
| `sfx_disco_perfect.wav` | 0.5 sec | Bright chime + crowd "ooh" |
| `sfx_disco_miss.wav` | 0.5 sec | Trombone "wah-wah", crowd laugh |
| `sfx_disco_turn.wav` | 3 sec | Music pitch-shift + scream reverb swell |
| `sfx_collapse.wav` | 2 sec | Thud + reverb tail |

The `bgm_disco.ogg` pitch-shift during Phase 4 is done in-engine:  
`AudioServer.set_bus_pitch_scale("Music", 0.4)` — no separate file needed.

---

## Implementation Checklist (when ready to build)

- [ ] `scenes/DiscoHallucination.tscn` — new scene
- [ ] `scenes/DiscoHallucination.gd` — manages all 6 phases
- [ ] `scenes/DancePrompt.gd` — single arrow prompt node (spawned per beat)
- [ ] Add `trigger_hallucination()` to `GameManager.gd`
- [ ] Add disco enemy variants (recolour existing sprites, new CollisionLayer)
- [ ] Chromatic aberration shader (`shaders/chromatic_aberration.gdshader`)
- [ ] Disco ball node (rotating Sprite2D throwing light patches via `PointLight2D`)
- [ ] Wire `bgm_disco.ogg` in `AudioManager.gd`
- [ ] Add `disco_score: int` to `GameManager.gd`
- [ ] Connect Odiyan `_die()` → delayed `trigger_hallucination()` call

---

*Saved at `docs/disco-hallucination-design.md` — open this in any chat to continue.*
