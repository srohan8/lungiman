# Kanjiravanam Chronicles — Music Requirements

> **Creation tools:** Freesound.org samples + LMMS (free DAW) — or Suno.ai for rapid prototyping  
> **Format:** OGG Vorbis — Godot's preferred format (not MP3/WAV)  
> **Loop:** All act themes and ambient tracks must loop seamlessly  
> **Style anchor:** Kerala classical × 80s synth fusion — *Ilaiyaraaja scored a Malayalam adventure game in 1987*  
> **Folder:** `res://assets/audio/music/` (BGM) and `res://assets/audio/sfx/` (stings/SFX)  
>
> **The two layers always present in every track:**  
> — Organic (Kerala): mridangam, veena, nadaswaram, chenda, temple bell, bansuri  
> — Synthetic (80s): Roland TR-808 kick/snare, DX7-style synth lead, Moog bass, synth pad  
>
> **Reference listening:** Ilaiyaraaja 1980s Malayalam scores · A.R. Rahman *Roja* · Vangelis *Blade Runner*  
> **Full production workflow:** `docs/music-guide.md`

---

## 🎵 Track List

### Menu Music (looping)
| File | Used in |
|---|---|
| `music_menu.ogg` | MainMenu.tscn + LevelSelect.tscn |

### Act Themes (looping)
| File | Used in |
|---|---|
| `music_prologue.ogg` | World.tscn — Muruthikudi at Dusk |
| `music_act1.ogg` | Act1.tscn — Yakshi's Hollow |
| `music_act2.ogg` | Act2.tscn — Kuttichathan's Carnival |
| `music_act3.ogg` | Act3.tscn — Odiyan's Hunt |
| `music_act4.ogg` | Act4.tscn — Karinkanni's Curse |
| `music_act5.ogg` | Act5.tscn — Pey Komban's Rampage |

### Boss Themes (looping)
| File | Boss |
|---|---|
| `music_boss_yakshi.ogg` | Yakshi fight |
| `music_boss_kuttichathan.ogg` | Kuttichathan fight |
| `music_boss_odiyan.ogg` | Odiyan fight |
| `music_boss_karinkanni.ogg` | Karinkanni fight |
| `music_boss_peykomban.ogg` | Pey Komban fight |

### Interlude (looping during gameplay phases)
| File | Used in | BPM | Loop length |
|---|---|---|---|
| `music_disco.ogg` | DiscoHallucination.tscn — dance + fight phases | 130 | 3 min |

> **`music_disco.ogg` style:** nadaswaram lead over TR-808 beat + DX7 synth bass. Must feel like a 1987 Kerala film score written for a disco scene. Pitch-shift during "The Turn" phase is done in-engine (`AudioServer.set_bus_pitch_scale`) — no separate file needed.

### Cinematic / Event (one-shot)
| File | Moment |
|---|---|
| `music_bike_ride.ogg` | Act II cold open — Ravi's Bullet |
| `music_bull_chase.ogg` | Act III — Odiyan bull chase (3rd person) |
| `music_peykomban_reveal.ogg` | Act V — Pey Komban silhouette reveal |
| `music_victory.ogg` | Victory screen |
| `music_gameover.ogg` | Game Over screen |
| `sting_disco_perfect.ogg` | Dance phase — perfect timing hit |
| `sting_disco_miss.ogg` | Dance phase — missed prompt (trombone wah) |
| `sting_disco_turn.ogg` | The Turn — music warp + scream swell (3 sec) |

### UI / Ambient Stings (short, one-shot)
| File | Trigger |
|---|---|
| `sting_powerup.ogg` | Powerup collected (heart/nut/porotta/resurrection) |
| `sting_chai.ogg` | Chai collected — satisfying slurp, slow-mo whoosh |
| `sting_toddy.ogg` | Toddy collected — wobbly/woozy sound |
| `sting_resurrection.ogg` | Brother Thoma gives token |
| `sting_hint.ogg` | HUD hint appears |
| `sting_boss_die.ogg` | Boss defeated |
| `sting_level_clear.ogg` | Act transition |
| `sting_carnival_bell.ogg` | Act II — carnival bell rung ("Carnival Champion!") |
| `sting_clone_explode.ogg` | Wrong clone hit — explosion impact |
| `sting_fire_rain.ogg` | Act II — fire rain event trigger alarm |
| `sting_hypnosis.ogg` | Yakshi hypnosis activates — disorienting spiral sound |
| `sting_odiyan_flash.ogg` | Odiyan transform window opens — whoosh/flash |
| `sting_kili_caw.ogg` | Kili warns before Odiyan transforms |

### Ambient Loops
| File | Used in |
|---|---|
| `ambience_river.ogg` | River zone — World + Act I |
| `ambience_rain.ogg` | Act IV — full monsoon rain |
| `ambience_fire.ogg` | Act II — ember/fire crackle |
| `ambience_forest_night.ogg` | Acts I, III, V — night forest |
| `ambience_festival_crowd.ogg` | Act II bike ride — distant crowd, firecrackers |

### SFX (in-game sound effects — generate via Suno "sound effect" mode or source separately)
| File | Trigger |
|---|---|
| `sfx_sword_swing.ogg` | Z key sword swing |
| `sfx_coconut_throw.ogg` | C key coconut throw |
| `sfx_coconut_hit.ogg` | Coconut hits enemy |
| `sfx_jump.ogg` | Player jumps |
| `sfx_land.ogg` | Player lands on ground |
| `sfx_roll.ogg` | Dodge roll |
| `sfx_tree_climb.ogg` | Player climbs tree |
| `sfx_swing_whoosh.ogg` | Pendulum swing whoosh |
| `sfx_water_splash.ogg` | Player enters river |
| `sfx_fire_damage.ogg` | Player steps on fire patch |
| `sfx_player_damage.ogg` | Player takes damage |
| `sfx_player_death.ogg` | Player dies |
| `sfx_enemy_hit.ogg` | Enemy takes damage |
| `sfx_enemy_die.ogg` | Enemy dies |
| `sfx_bike_engine.ogg` | Act II — Bullet engine running loop |
| `sfx_bike_crash.ogg` | Act II — bike hits obstacle |
| `sfx_dialogue_blip.ogg` | NPC dialogue text blip |

---

## 🎼 Suno.ai Prompts — Ready to Paste

> **How to use:** Go to [suno.ai](https://suno.ai) → Create → paste prompt → generate 3–4 variations → pick best → download

---

### 🏠 Menu / Level Select
```
Kerala village ambience, warm and inviting, soft veena melody,
gentle percussion, feeling of adventure waiting ahead,
hopeful and calm, not too dramatic, looping game menu music,
Spiritfarer-inspired warmth, 2D platformer menu theme
```

---

### 🌅 Prologue — "Muruthikudi at Dusk"
```
Kerala village at golden hour, peaceful and warm, soft veena melody, 
gentle tabla rhythm, distant temple bells, birds chirping, 
light breeze through coconut palms, hopeful and adventurous, 
instrumental, seamless loop, 2D platformer game music style, 
Spiritfarer-inspired warmth
```

---

### 🎋 Act I — "Yakshi's Hollow"
```
Misty bamboo forest at nightfall Kerala, slow building dread, 
haunting bansuri flute melody, distant chenda drum heartbeat, 
moonlit river ambience, mysterious and tense, 
occasional nadaswaram wail fading in and out, 
silence gaps for atmosphere, instrumental, seamless loop, 
Hollow Knight inspired dark folk, Kerala classical undertones
```

---

### 🔥 Act II — "Kuttichathan's Carnival"
```
Abandoned Kerala fire festival, chaotic energy, heavy chenda drum ensemble, 
nadaswaram at full intensity, firecracker percussion, 
festive but deeply ominous, child spirit mischief energy, 
ember crackle texture underneath, brass and percussion clash, 
instrumental, seamless loop, dark carnival game music
```

---

### 🌫️ Act II — Bike Ride Cold Open (one-shot, ~90 seconds)
```
1990s Royal Enfield Bullet engine rhythm as percussion base, 
Kerala festival chenda drums join the beat, 
crowd cheering and festival sounds fade behind, 
single haunting nadaswaram rises slowly, 
energy builds then drops to eerie silence, 
journey from celebration into darkness, 
cinematic one-shot, no loop, 90 seconds, 
music arc: festive → driving → ominous → silence
```

---

### 🌿 Act III — "Odiyan's Hunt"
```
Foggy highland forest Kerala, shape-shifter stalking, 
low cello drones, slow mizhavu hand drum heartbeat, 
silence and tension, occasional bull bellow distant, 
something is hunting you feeling, sparse and ominous, 
Carnatic minor scale motif on violin, 
instrumental, seamless loop, survival horror folk
```

---

### 🐂 Act III — Bull Chase (one-shot, ~15 seconds)
```
Sudden violent chenda drum explosion, 
ground shaking bass percussion, 
pure adrenaline terror 15 seconds, 
Kerala war drums at maximum intensity, 
no melody just rhythm and chaos, 
cinematic one-shot, ends abruptly
```

---

### 🌧️ Act IV — "Karinkanni's Curse"
```
Heavy Kerala monsoon rain ambience, oppressive and ancient, 
deep resonant mizhavu drum, 
single slow veena note bending like an eye opening, 
paralysis and dread, thunder distant, 
mangrove forest darkness, rising water tension, 
very sparse instrumentation, long silences, 
instrumental, seamless loop, psychological horror folk
```

---

### 🌳 Act V — "Pey Komban's Rampage"
```
Sacred Kerala temple grove finale, epic and primal, 
full chenda ensemble at war tempo, 
ancient brass instruments, massive percussion, 
ground shaking bass, firefly shimmer in high strings, 
something enormous and unstoppable, 
hero's last stand energy, Kerala classical epic scale, 
instrumental, seamless loop, final boss platformer intensity
```

---

### 🐘 Act V — Pey Komban Reveal (one-shot, ~10 seconds)
```
Deep earth-shaking bass hit, 
silence, 
single ancient temple horn note, 
awe and terror combined, 
10 seconds cinematic sting, 
something ancient just woke up
```

---

### ⚔️ Boss — Yakshi
```
Hypnotic Kerala folk melody that reverses itself, 
ghostly female vocal hum, 
reversed chenda rhythm, 
controls feel wrong, disorienting, 
moonlit terror dance, 
Carnatic scale twisted and haunting, 
instrumental with ghost vocal texture, seamless loop
```

---

### 🔥 Boss — Kuttichathan
```
Child spirit chaos energy, rapid chenda tempo, 
mischievous high-pitched nadaswaram, 
firecracker bursts as percussion hits, 
laughing energy underneath the danger, 
carnival gone wrong, 
fast and relentless, seamless loop, 
dark playful boss fight music
```

---

### 🐂 Boss — Odiyan
```
Shape-shifter boss Kerala, three-phase energy, 
phase 1 slow stalking human — sparse mizhavu, 
phase 2 bull charge — thundering chenda war drums, 
phase 3 dog hunt — fast frantic strings, 
all three blend in one track that shifts, 
Carnatic classical foundation gone wild, 
seamless loop with clear phase shifts
```

---

### 👁️ Boss — Karinkanni
```
Floating eye curse, slow and inevitable, 
single veena note held and bending, 
paralysis theme, you cannot move, 
deep resonant temple bell every 5 seconds, 
ancient malevolence, very minimal, 
the eye is always watching, 
seamless loop, psychological dread
```

---

### 💀 Boss — Pey Komban (FINALE)
```
Epic Kerala temple battle, maximum intensity, 
full chenda war ensemble, ancient brass horns, 
hero vs colossus energy, 
ground shaking with every beat, 
Carnatic epic scale, brass and percussion battle, 
never lets up, relentless power, 
seamless loop, final boss of the entire game
```

---

### 🏆 Victory
```
Kerala celebration burst, 
veena and nadaswaram triumphant melody, 
chenda joyful rhythm, 
forest coming back to life, 
warm golden emotional resolution, 
sacred grove blooms feeling, 
30 seconds, gentle fade out
```

---

### 💀 Game Over
```
Single mournful nadaswaram note fading, 
distant temple bell, 
Kerala forest night closing in, 
melancholy but not hopeless, 
15 seconds, fade to silence
```

---

## 🌿 Ambient Loops — Prompts

### River Ambient
```
Kerala backwater river night sounds, 
water lapping, frogs, distant owls, 
no music just atmosphere, seamless loop
```

### Rain Ambient (Act IV)
```
Heavy Kerala monsoon rain, 
mangrove drips, thunder distance, 
oppressive downpour, seamless loop
```

### Fire/Ember Ambient (Act II)
```
Burning festival ground ambience, 
ember crackle, distant fire roar, 
occasional wood pop, seamless loop
```

### Forest Night Ambient
```
Kerala forest at deep night, 
crickets, nightjar call, 
wind through coconut palms, 
sacred silence, seamless loop
```

---

## 📁 AudioManager.gd — To Be Implemented

Once audio files are in `res://assets/audio/`, I will build:

- `AudioManager.gd` autoload with bus routing (Master / Music / SFX / Ambient)
- Act theme auto-crossfade when scene changes
- Boss music trigger (replaces act theme, restores on death)
- Cinematic one-shots (play once, no loop)
- Ambient layer system (independent of music track)
- Volume control wired to Settings menu

---

## ✅ Generation Checklist

### Menu
- [ ] `music_menu.ogg`

### Act Themes
- [ ] `music_prologue.ogg`
- [ ] `music_act1.ogg`
- [ ] `music_act2.ogg`
- [ ] `music_act3.ogg`
- [ ] `music_act4.ogg`
- [ ] `music_act5.ogg`

### Boss Themes
- [ ] `music_boss_yakshi.ogg`
- [ ] `music_boss_kuttichathan.ogg`
- [ ] `music_boss_odiyan.ogg`
- [ ] `music_boss_karinkanni.ogg`
- [ ] `music_boss_peykomban.ogg`

### Cinematics
- [ ] `music_bike_ride.ogg`
- [ ] `music_bull_chase.ogg`
- [ ] `music_peykomban_reveal.ogg`
- [ ] `music_victory.ogg`
- [ ] `music_gameover.ogg`

### Stings
- [ ] `sting_powerup.ogg`
- [ ] `sting_chai.ogg`
- [ ] `sting_toddy.ogg`
- [ ] `sting_resurrection.ogg`
- [ ] `sting_hint.ogg`
- [ ] `sting_boss_die.ogg`
- [ ] `sting_level_clear.ogg`
- [ ] `sting_carnival_bell.ogg`
- [ ] `sting_clone_explode.ogg`
- [ ] `sting_fire_rain.ogg`
- [ ] `sting_hypnosis.ogg`
- [ ] `sting_odiyan_flash.ogg`
- [ ] `sting_kili_caw.ogg`

### Ambient Loops
- [ ] `ambience_river.ogg`
- [ ] `ambience_rain.ogg`
- [ ] `ambience_fire.ogg`
- [ ] `ambience_forest_night.ogg`
- [ ] `ambience_festival_crowd.ogg`

### SFX
- [ ] `sfx_sword_swing.ogg`
- [ ] `sfx_coconut_throw.ogg`
- [ ] `sfx_coconut_hit.ogg`
- [ ] `sfx_jump.ogg`
- [ ] `sfx_land.ogg`
- [ ] `sfx_roll.ogg`
- [ ] `sfx_tree_climb.ogg`
- [ ] `sfx_swing_whoosh.ogg`
- [ ] `sfx_water_splash.ogg`
- [ ] `sfx_fire_damage.ogg`
- [ ] `sfx_player_damage.ogg`
- [ ] `sfx_player_death.ogg`
- [ ] `sfx_enemy_hit.ogg`
- [ ] `sfx_enemy_die.ogg`
- [ ] `sfx_bike_engine.ogg`
- [ ] `sfx_bike_crash.ogg`
- [ ] `sfx_dialogue_blip.ogg`

### Disco Hallucination SFX
- [ ] `sting_disco_perfect.ogg`
- [ ] `sting_disco_miss.ogg`
- [ ] `sting_disco_turn.ogg`
- [ ] `sfx_disco_collapse.ogg`

---

## 🎛️ Loop Length & BPM Reference

| Track | BPM | Loop length | Mood |
|---|---|---|---|
| `music_menu.ogg` | 72 | 90 sec | Warm, inviting. Veena lead over soft synth pad. |
| `music_prologue.ogg` | 80 | 120 sec | Gentle mridangam, bansuri, nostalgic synth strings. |
| `music_act1.ogg` | 95 | 90 sec | Tense bamboo groove. Slow chenda + minor veena. |
| `music_act2.ogg` | 120 | 90 sec | Full nadaswaram + DX7 electric piano. Peak energy. |
| `music_act3.ogg` | 75 | 120 sec | Sparse. Temple bell, low synth drone, distant bansuri. |
| `music_act4.ogg` | 68 | 120 sec | Atmospheric. Ghatam + synth strings. Eerie and beautiful. |
| `music_act5.ogg` | 85 | 120 sec | Chenda + distorted synth bass. Building dread. |
| `music_disco.ogg` | 130 | 180 sec | Nadaswaram + TR-808 + DX7 synth bass. Neon Kerala 1987. |
| `music_bike_ride.ogg` | 130 | 60 sec | Driving 808 kick + chenda. Pure forward momentum. |
| `music_boss_yakshi.ogg` | 110 | 60 sec | Hypnotic minor. Veena tremolo + gated reverb snare. |
| `music_boss_kuttichathan.ogg` | 140 | 60 sec | Chaotic. Nadaswaram screech + 808 fills. |
| `music_boss_odiyan.ogg` | 125 | 60 sec | Shape-shifting meter. Bar of 3 + bar of 4 alternating. |
| `music_boss_karinkanni.ogg` | 100 | 60 sec | Dark, hypnotic. Low mridangam + 808 + minor key synth. |
| `music_boss_peykomban.ogg` | 150 | 60 sec | Chenda wall + orchestral synth. Earth-shaking. |
| `music_victory.ogg` | — | 30 sec | One-shot. Rising nadaswaram fanfare. |
| `music_gameover.ogg` | — | 10 sec | One-shot. Descending veena phrase. Melancholy. |

## 🎵 Production Workflow (Freesound + LMMS)

1. **Get samples** from freesound.org (filter CC0 or CC-BY):
   - Percussion: `mridangam single stroke`, `TR-808 kick`, `chenda`, `ghatam`
   - Melody: `veena pluck`, `nadaswaram`, `bansuri flute`
   - 80s synth: `analog synth arpeggio`, `DX7 electric piano`, `synth bass stab`
2. **Build in LMMS:** Beat+Bassline for drums, Song Editor for melody layers, ZynAddSubFX for synth pads
3. **Export:** `File → Export → WAV` → convert to OGG in Audacity (quality 6)
4. **Loop test:** End the LMMS song at exactly N bars — it will loop cleanly in Godot
5. **Drop into** `assets/audio/music/` and tell me — I'll wire AudioManager to play it per scene
