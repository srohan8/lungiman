# Kanjiravanam Chronicles — Music Production Guide

> **Save this file.** It lives at `docs/music-guide.md` in the repo — open it any time, in any chat.  
> Goal: mix traditional Kerala instruments with 80s synth to create something that sounds like  
> *Ilaiyaraaja scored a Malayalam adventure game in 1987.*

---

## The Sound: Kerala × 80s Fusion

Think of it as two layers always playing together:

| Layer | Kerala (organic) | 80s (synthetic) |
|---|---|---|
| **Rhythm** | Mridangam, Chenda, Thavil | Roland TR-808 kick, snare, hi-hat |
| **Melody** | Veena, Nadaswaram, Bansuri | DX7-style synth lead, arpeggiated synth |
| **Texture** | Temple bells, Ghatam | Chorus/reverb pads, synth strings |
| **Bass** | Tabla low tones | Moog-style bass synth |

**Reference artists to listen to before starting:**
- Ilaiyaraaja (1980s Tamil/Malayalam film scores) — the original Kerala×synth master
- A.R. Rahman early work (Roja, 1992) — same fusion, slightly later
- Vangelis *Blade Runner* OST — for the 80s synth atmosphere
- Hiroshi Yoshimura *Music for Nine Post Cards* — for ambient forest tracks

---

## Step 1 — Get LMMS (Free DAW)

Download: **https://lmms.io/download**  
Works on Windows. No cost. Supports WAV samples + built-in synths.

Key LMMS tools you'll use:
- **Beat+Bassline editor** — for percussion loops (mridangam + 808)
- **Song Editor** — arrange all your loops into a full track
- **ZynAddSubFX** (built-in synth) — for the 80s synth leads and pads
- **AudioFileProcessor** — drag in your Freesound WAV samples here

---

## Step 2 — Sample Shopping List (Freesound.org)

Go to **https://freesound.org** — filter by **CC0** (no attribution needed) or **CC-BY**.

### Traditional Kerala instruments
| Search term | What to use it for |
|---|---|
| `mridangam single stroke` | percussion loop backbone |
| `mridangam theka` | pre-made rhythmic pattern |
| `veena pluck` | melodic accent notes |
| `nadaswaram` | carnival / festival scenes |
| `chenda` | boss battles, intense moments |
| `temple bell single` | prologue, sacred transitions |
| `ghatam` | mid-rhythm texture |
| `bansuri flute` | soft forest atmosphere |

### 80s synth sounds (also on Freesound)
| Search term | What to use it for |
|---|---|
| `analog synth arpeggio` | background motion/energy |
| `TR-808 kick` | main beat kick drum |
| `TR-808 snare` | backbeat |
| `DX7 electric piano` | melodic layer |
| `synth bass stab` | low-end punch |
| `80s synth pad` | sustained atmosphere |
| `gated reverb snare` | classic 80s drum sound |

**Download everything as WAV. Keep in a `music_sources/` folder outside the game repo.**

---

## Step 3 — LMMS Workflow (Scene by Scene)

### General recipe for each track:
1. Open Beat+Bassline → add TR-808 kick + mridangam sample side by side
2. Set BPM (see table below per scene)
3. Open Song Editor → add veena/synth melody over the beat loop
4. Add a pad layer (ZynAddSubFX or 80s synth pad sample) very quietly underneath
5. Export: `File → Export → WAV` → convert to OGG with Audacity or online tool

### Conversion to OGG
Godot needs OGG for streaming music (MP3 also works but OGG is smaller).  
Audacity (free): `File → Export → Export as OGG Vorbis` at quality 6.

---

## Step 4 — Audio Length & Loop Recommendations

> **Loop point rule:** Always end the file at exactly the same musical position as the start.  
> In LMMS: set your song length to exactly N bars, export — it will loop cleanly in Godot.

### Background Music (BGM) — looping tracks

| Scene | File name | BPM | Length | Mood |
|---|---|---|---|---|
| Main Menu | `bgm_menu.ogg` | 72 | **90 sec** | Warm, inviting. Veena lead over soft synth pad. |
| Prologue (village evening) | `bgm_prologue.ogg` | 80 | **120 sec** | Gentle mridangam, bansuri, nostalgic synth strings. |
| Act 1 (carnival approach) | `bgm_act1.ogg` | 110 | **90 sec** | Nadaswaram + arpeggiated synth. Festive but with edge. |
| Bike Ride | `bgm_bike.ogg` | 130 | **60 sec** | Driving 808 kick + chenda. Fast. Pure forward momentum. |
| Kanjiravanam Forest | `bgm_forest.ogg` | 65 | **120 sec** | Sparse. Temple bell, low synth drone, distant bansuri. |
| Act 2 (carnival grounds) | `bgm_carnival.ogg` | 120 | **90 sec** | Full nadaswaram + DX7 electric piano. Peak energy. |
| Act 3 (dark forest) | `bgm_act3.ogg` | 75 | **120 sec** | Chenda + distorted synth bass. Building dread. |
| Act 4 (backwater night) | `bgm_act4.ogg` | 68 | **120 sec** | Atmospheric. Ghatam + synth strings. Eerie and beautiful. |
| Boss — Odiyan | `bgm_boss_odiyan.ogg` | 140 | **60 sec** | Intense chenda polyrhythm + screaming synth lead. |
| Boss — Karinkanni | `bgm_boss_karinkanni.ogg` | 125 | **60 sec** | Dark, hypnotic. Low mridangam + 808 + minor key synth. |

### One-shot sounds (no loop — play once and stop)

| Moment | File name | Length | Notes |
|---|---|---|---|
| Level/act complete | `sting_victory.ogg` | **8–12 sec** | Rising nadaswaram fanfare. Triumphant. |
| Game over | `sting_gameover.ogg` | **5–8 sec** | Descending veena phrase. Melancholy, not harsh. |
| Quest complete | `sting_quest.ogg` | **4–6 sec** | Short bell + synth shimmer. |
| Powerup collect | `sting_powerup.ogg` | **2–3 sec** | Single bright chime + synth blip. |
| Boss intro | `sting_boss_intro.ogg` | **6–10 sec** | Dramatic chenda hit + synth swell. Plays before BGM starts. |

### Ambient layers (optional, play under BGM at low volume)

| Location | File name | Length | Notes |
|---|---|---|---|
| Forest (any act) | `amb_forest.ogg` | **60 sec** | Crickets, wind, distant water. Loops seamlessly. |
| Carnival grounds | `amb_crowd.ogg` | **30 sec** | Crowd murmur, distant drums. |
| Backwater | `amb_water.ogg` | **45 sec** | Lapping water, frogs, night birds. |

---

## Step 5 — Godot Integration

Drop your OGG files into `assets/audio/music/` and `assets/audio/sfx/`.

Tell me when you have even one track ready and I'll wire `AudioManager.gd` to:
- Auto-play the right BGM when each scene loads
- Crossfade smoothly between tracks (0.8 second fade)
- Play one-shot stings on top without cutting the BGM
- Remember the current position so music doesn't restart on scene reload

---

## Quick-Start: Make the Bike Ride Track First

The Bike Ride scene has its own GDScript and no existing music — perfect test case.

**Target:** `bgm_bike.ogg` — 60 seconds, 130 BPM, loops

1. LMMS → New project → Set BPM to 130
2. Beat+Bassline: TR-808 kick on beats 1 & 3, snare on 2 & 4, mridangam fills on the 16th notes
3. Song Editor: add a chenda sample every 2 bars for intensity
4. ZynAddSubFX: simple 5-note ascending synth riff (think Vangelis but faster)
5. 16 bars = ~29 seconds at 130 BPM → duplicate to 32 bars = ~58 seconds → export

That's your first loop. Drop it in, it'll feel completely different with music.

---

*This guide is part of the Kanjiravanam Chronicles repo — `docs/music-guide.md`*
