# Kanjiravanam Chronicles — Game Design Document

> **Engine:** Godot 4.6 · Jolt physics · **Viewport:** 480×270 · Mobile-first  
> **Village:** Muruthikudi ("Sacred Grove Hamlet") — outer edge of Kanjiravanam forest, bordering a backwater river village.  
> **Tone:** Mysterious, spiritual, wild. Kerala mythology meets side-scrolling action.  
> **Time span:** Golden hour (Prologue) → full nightfall (Act V).

---

## 📜 The Curse of Kanjiravanam — Origin Lore

> *"The five sacred trees hold the world in balance. The demons have waited centuries. All that stands between them and the mortal realm is one carefree toddy-tapper with an arivaal, a bag of coconuts, and very bad judgment."*

Long ago, deep within the sacred forest of Kanjiravanam — Kerala's most mysterious and untouched jungle — a portal between the mortal world and the realm of forgotten demons was accidentally torn open by ancient rituals gone wrong.

The gods sealed the portal by binding it to **five sacred trees** — the **Eternal Coconuts of Balance**. Each tree was guarded by a celestial guardian. But over centuries, the protectors faded from memory, and the demons, known as ***Kazhukans***, began slipping back into the mortal realm — corrupting the wild with illusions, poison, and rage. Each Kazhukan claims one sacred grove, holds its tree hostage, and widens the crack in the seal.

### Timeline
- **Ancient Era** — The portal tears open. Gods bind it to five sacred trees; celestial guardians assigned.
- **Centuries Later** — Guardians forgotten. Kazhukan demons begin slipping through one by one, corrupting the five sacred groves.
- **Present Day** — LungiMan falls into a cursed grove during a routine coconut harvest. The forest goddess Bhadrakali appears in a vision and grants him ancient powers. The reckoning begins.

### Landscape Healing Progression
Each time LungiMan restores a sacred tree (by defeating the act boss), the surrounding region heals — permanently and visually for the rest of the game. Players who return to earlier acts will see:
- Corrupted black soil replaced by vibrant green
- Demon fog cleared, stars visible again
- Backwater water running clean
- Sacred groves blooming in that act's colour

This is a permanent environmental change — a record of every Kazhukan freed.

---

## 🧑 The Hero — Character Identity

**Name:** **LungiMan**  
**Occupation:** *Thenginkeri* — traditional Kerala coconut palm tapper  
**Home:** Muruthikudi village, lives near Kanjiravanam forest edge

LungiMan is not a warrior. He's a coconut tapper — someone who makes their living climbing coconut palms every day using a **climbing rope loop** (*cheppam*), a loop of rope slung around both feet and the trunk that lets them walk straight up a tree. This rope is always coiled at his hip or chest. It is his *work tool*, repurposed for survival.

His weapon is an ***arivaal*** — the small curved sickle every coconut tapper carries to cut down coconuts. Not a war sword — a work blade. The fact that he can fight at all is an accident of profession. In code and controls it's called "sword" (Z key), but visually it is always the curved arivaal.

**Why this matters for design:**
- The swing/climb mechanic is not magic — it's his job, done every day
- He doesn't fear the trees; he fears what's *in* them tonight
- Every NPC recognises him as the local *thenginkeri* — hence the village trust
- The rope is always visible. In idle, run, sword — always coiled at the hip
- **Aviator sunglasses** (dark lenses, gold frame) — always on, his signature look; never removed
- **Black thick mustache**, dark curly hair; muscular build from a lifetime of tree-climbing
- **White mundu, Kerala active fold** — outer layer folded up and tucked at the waist ("short lungi" style), doubled fabric band visible at the front with gold/yellow border at the fold, legs free from mid-thigh (NOT a dhoti)
- **Brown leather crossbody satchel** with a green coconut inside — worn in every animation
- Warm brown South Indian skin tone

### The Blessing of Bhadrakali
LungiMan was not chosen. He stumbled. During a routine coconut harvest in Kanjiravanam, a branch broke and he fell into a cursed grove deeper in the forest than any tapper had been in living memory. He should have died.

Instead, the forest goddess **Bhadrakali** appeared in a vision. She saw in him not a warrior — but a man with the right tool, in the wrong place, at the right moment. She gifted him:
- Ancient agility beyond any mortal climber
- The ability to commune with the forest itself (whether he wants to or not)
- The mandate to seal the five corrupted sacred trees before the Kazhukans tear the portal fully open

He went home that night, made tea, and didn't sleep well.

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
- From a tree crown, press **Jump (Space / BtnUp)** to throw the lasso — rope tip travels to the nearest crown in your facing direction in ~0.12 s
- Pendulum physics: true angular velocity, pump by holding a direction, auto-release after 2.5 s
- Press **Jump again** while swinging to release: converts angular velocity to linear flight toward the next tree
- If no target tree in range: pure tangential release (free-fly)
- A sandy-brown rope line drawn via `_draw()` shows the swing visually
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

### PROLOGUE — "The Swinging Awakening" · Muruthikudi at Dusk (World.tscn)
*Tutorial warmth. Golden hour. Learn everything safely.*

*Opening: LungiMan stumbles out of the cursed grove where he met Bhadrakali — shaken, blessed, unsure what just happened. The village is still golden-hour warm. The tutorial teaches everything (climb, swing, throw, fight) in the safety of the village and river edge. The weight of the mandate hasn't landed yet.*

- Captain Biju's Hut → dialogue + first coconut
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
- Mundakkal Ravi at Toddy Stall (x=400) — Swing-off Race quest (Phase 3)
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
- **Mundakkal Ravi** (x=200) hands the hero his 1990s Royal Enfield Bullet
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

### ACT IV.5 — "Pathalam" (Pathalam.tscn) — THE UNDERGROUND *(new act)*

> *Between Act IV and Act V. Accessed through a sinkhole that opens at the end of Act IV — the monsoon floods carve through ancient soil and reveal a crack into the underworld. LungiMan falls in. There is no climbing back. Only forward.*

*Deep underground Kerala temple ruins. Bioluminescent caves. An underground river glowing blue-white. Ancient stone pillars carved with murals. Oil lamps floating without wind.*  
*The one act where you cannot truly die — because Maveli is here.*

**The Setting:**
Pathalam is beautiful and wrong. The rules of the surface don't apply. Trees are replaced by enormous glowing stalactite columns — LungiMan swings between them using the cheppam just like above ground, but the world is inverted and ancient. Underground rivers run cyan. Stone faces carved into walls seem to watch. There is no sky — only the weight of the earth above, and the quiet of a kingdom that has been waiting.

**Aesthetic:**
- Near-black background, deep indigo stone
- Bioluminescent accents — cyan/teal underground rivers, soft purple mushroom clusters, amber oil lamps
- Ancient Kerala temple carvings on every wall — faces, elephants, lotus, gods
- Sound design: dripping water, distant chanting, no wind

**Key beats:**
- LungiMan falls in — disoriented. No HUD hint. Just silence and glow.
- First 1000px: no enemies. Just the space. The murals. The lamps.
- **Ancient Serpent (Naga) guardian** — mini-boss at x~2000. Not evil — just old. Tests whether LungiMan is worthy to pass. 2 hits to calm (not kill). Yields the path.
- x~3500: a massive carved throne room. Oil lamps everywhere. Something sits on the throne.

**Maveli — The Encounter:**
When LungiMan's HP drops to **1** anywhere in Pathalam, the screen slows. A warm golden light fills the cave from the direction of the throne. Maveli speaks before LungiMan reaches him — the voice comes from everywhere.

*"I know these trees. I planted some of them."*

LungiMan reaches the throne room. **Maveli** sits — enormous, regal, warm. A Kerala king from the golden age. He does not look like a prisoner. He looks like a man who made peace with his circumstances long ago.

He looks at LungiMan for a long moment.

*"My people have been sending me visitors through Onam for a thousand years. None of them looked quite like you."*

He stands. The room gets brighter.

*"Kanjiravanam was protected once. By better men than either of us. They're gone now. You're what's left."*

He places his hand on LungiMan's chest. LungiMan's HP fills completely. A golden aura — Maveli's blessing layered on Bhadrakali's — lingers on every subsequent coconut throw for the rest of the game: **deeper red on the impact burst, brighter gold on the glow.**

*"Go up. Finish it. Onam is coming — my people need a home to come back to."*

A stone staircase rises from the floor. LungiMan climbs out. Pathalam seals behind him.

**Maveli's intervention rules:**
- Triggers **once only** — if HP hits 1, not 0 (player can still die after the blessing if they're reckless in Act V)
- If player enters Pathalam at full health and never drops to 1 HP: Maveli is still on the throne, but silent — a silhouette in the distance. Visible. Watching. Not approached.
- Players who played carelessly get the full scene. Players who played perfectly see only his shadow. **Both are correct endings for Pathalam.**

**Maveli — Character Notes:**
- Large, portly, regal. Kerala raja: ornate white mundu, heavy gold jewelry, tall crown.
- Warm amber-gold color palette — the opposite of the demon darkness above.
- Kind face. Melancholic eyes. The weight of centuries, worn gracefully.
- Speaks Malayalam cadence — formal but never stiff. Like a grandfather who was also once a king.
- He has never stopped caring about Kerala. That's the tragedy and the dignity of him.

**Act placement:** Between Act IV and Act V. Optional only in the sense that low-HP players experience it more fully — but all players pass through it physically.

**Implementation phase:** Phase 3 (alongside QuestManager — Maveli's blessing can be tracked as a permanent flag `maveli_blessed: bool` on GameManager).

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

### 🩱 The Mundu Moments — Cultural Signature Mechanics

> *Malayalam cinema reference: the Kerala hero always finds a way with what he has. The mundu is not just clothing — it is his last tool.*

#### Mundu Swing — Pey Komban Finale (Act V)
A climactic one-time cinematic action in the final boss fight. When Pey Komban's tusk comes within range at a specific story beat:

1. LungiMan **unties and yanks off his mundu** in one motion — fully in-character (he was wearing the active fold; it comes off fast)
2. He **swings it like a lasso**, looping it around Pey Komban's tusk
3. Uses it as a rope to **climb up the tusk** — gets above the boss entirely
4. **Delivers the killing coconut throw** from above, point-blank into the demon's eye
5. Lands barefoot on the ground. Mundu gone. Just him, aviators, **boxer shorts**, the arivaal, and the silence.
6. **Post-fight:** he's standing in his boxers in the sacred temple grove. Brother Thoma wordlessly hands him a fresh mundu. LungiMan puts it on without breaking eye contact with the camera.

**Canonical detail:** LungiMan always wears **boxer shorts** under the mundu — every moment of every act. The mundu coming off simply reveals what was always there. This is not a surprise to him.

**Tone:** Triumphant, absurd, deeply Kerala. The audience who gets the reference will lose their minds.  
**Implementation:** Scripted tween sequence in `Act5.gd`, triggers at Rage Phase (below 1 HP). Not repeatable — one-shot cinematic.  
**Animation needed:** `mundu_lasso` (2 frames: swing + release) · `mundu_climb` (reuse swing animation on tusk) · `boxer_idle` (post-fight, 1 frame — same body, no mundu)

---

#### Mundu Whip — Combat Move (Mid-game, optional)
Available from Act III onward as an unlockable combo extender:

- **Input:** hold Sword (Z) for 0.6s → LungiMan loosens one end of the mundu and **cracks it like a whip**
- **Effect:** stuns nearby enemies for 1.2s, interrupts charging enemies (including Odiyan's bull charge if timed right)
- **Visual:** cloth snaps wide in an arc — can hit multiple enemies in the swing radius
- **Cultural ref:** *mundu veechu* — the traditional Kerala gesture of spinning/cracking the mundu as a challenge or warning. Every Malayali will recognise it immediately.
- **Unlock:** reward for completing Odiyan's Tracks quest (currently gives extended vulnerability window — can stack, or replace with this if preferred)
- **Limitation:** uses the mundu, so LungiMan can't swing with it on the same turn (minor tactical layer)

---

## 👹 The Kazhukans — Enemy Collective

All demons in Kanjiravanam belong to the **Kazhukans** — a race of forgotten spirits who slipped back into the mortal realm when the five sacred tree guardians were forgotten. Each boss-level Kazhukan has claimed one sacred grove and corrupted the surrounding landscape. Common enemies (Coconut Crabs, Haunted Monkeys, Ghost Clones, Crocodiles) are lesser Kazhukan thralls — spirits too small to hold a grove but vicious enough to serve.

| Boss | Grove | Kazhukan Type |
|---|---|---|
| **Yakshi** | Bamboo hollow | Seductress spirit — illusion, hypnosis |
| **Kuttichathan** | Carnival grounds | Mischief demi-god — chaos, fire, clones |
| **Odiyan** | Foggy highlands | Shapeshifter — bull, dog, human forms |
| **Karinkanni** | Rain mangroves | Floating eye — paralysis, curse |
| **Pey Komban** | Sacred temple grove | Tusked beast — raw power, charge |

---

## 🧩 Side Quests

### Built (no QuestManager needed)
| Quest | Act | Mechanic | Reward |
|---|---|---|---|
| **Odiyan's Tracks** | III | 4 hoof-print markers; press Z to read; all 4 → weakness revealed | Vulnerable window 0.6s → 0.9s |

### Phase 3 (with QuestManager)
| Quest | NPC | Mechanic | Reward |
|---|---|---|---|
| **Swing-off with Mundakkal Ravi** | Toddy Shop (Act I) | AI Ravi tweens crown-to-crown; player must reach tree #5 first | Appam Glide ability |
| **Chaya Kada Showdown** | Soniya Chechi (Act I) | Timed button-mash vs 3 drunkards | Ammo regen 2× near tea shops |

### Phase 5 (post-core)
| Quest | NPC | Blocker | Reward |
|---|---|---|---|
| **Bell of Bhadrakali** | Sr. Devi | Houseboat sub-scene needed | Totem Revival (extra resurrection) |
| **The Crow and the Cooked Rice** | Kili the Spirit Crow | Companion AI + stealth detection | Kili warns of ambushes |
| **Fish Fry for the Gods** | Captain Biju | Fishing mini-game loop | Double HP regen for 1 act |

### Bhadrakali's Gift — Future Abilities (Phase 4+)
Abilities granted by Bhadrakali that unlock through progression. Not yet implemented.

| Ability | Description | Unlock path |
|---|---|---|
| **Forest Sense** | Briefly reveals hidden enemies, traps, and relic locations. Bhadrakali's vision made practical. | Phase 4 — Mooppan Velu quest |
| **Vine Bind** | Temporarily roots an enemy in place. Essential for cornering Odiyan and setting traps against Pey Komban. | Phase 4 — Bell of Bhadrakali reward |
| **Aerial Slash** | Sword attack while swinging on the rope — deals bonus damage and leaves a slash trail arc. LungiMan's signature combat move. | Phase 4 — Swing-off Race reward |

---

## 👤 NPCs

### Why They All Help — The Unspoken Guilt

Fifty years ago, a grove guardian (*kaavadukaaran*) named **Mooppan Velu** sold logging rights to the edge of the third sacred tree's grove to pay off a family debt. He didn't believe the old stories. The seal cracked. The Kazhukans sensed it and began testing the other four groves. The remaining guardians died trying to reinforce their seals alone. Mooppan Velu has been in his cave ever since.

Every NPC in Muruthikudi is connected to what happened. None of them say it directly. They just help — urgently, without asking for anything back — because LungiMan is the first chance any of them has had to make it right.

**None of this is stated in dialogue. LungiMan never learns the full truth.** The player pieces it together from Basheer's lore songs, Biju's one cryptic line, and the way nobody in the village seems surprised that the forest is cursed.

---

### NPC Profiles

| Name | Location | Role | Mechanic |
|---|---|---|---|
| **Soniya Chechi** | Acts I, IV, V | Chaya Kada owner | 3-stage dialogue; drops chai; side quest giver |
| **Brother Thoma** | Acts I–V | Protector | Grants resurrection token once per act |
| **Mundakkal Ravi** | Acts I, II | Toddy shop owner | Swing-off Race quest |
| **Ustad Basheer** | Act III | Elder tracker | Odiyan's Tracks quest |
| **Kili the Spirit Crow** | Act III | Animal guide | Companion (Phase 3); warns before Odiyan transforms |
| **Sr. Devi** | Act IV | Buddhist nun | Bell of Bhadrakali (Phase 5) |
| **Captain Biju** | Prologue | Houseboat Captain | Ex-fighter, now serene boat captain; ferries LungiMan between remote areas; Fish Fry quest (Phase 5) |
| **Mooppan Velu** | Act III forest | Forest Monk | Lives in a cave, speaks in parables, knows every demon's weakness; meditation ability tree (Phase 5) |
| **Maveli (Mahabali)** | Act IV.5 — Pathalam | Legendary Kerala king, ruler of the underworld | Heals LungiMan to full HP + grants permanent `maveli_blessed` golden tint. Silent silhouette if player arrives unwounded. |

### NPC Backstory — The Connection

**Mooppan Velu** — He made the deal. He knows every Kazhukan by name because he watched them slip through one by one over fifty years. He'll tell LungiMan everything about the demons — everything except what he did. His guidance is penance. He will never say sorry because saying it out loud would mean it's real.

**Captain Biju** — He was the boat captain who transported the timber out of the grove. Didn't ask questions. Retired immediately after. He knows. That's why he ferries LungiMan without charging, without explaining. *"I owed this to someone."* His houseboat is built from the same planks.

**Brother Thoma** — He witnessed the logging deal as a young newly-arrived seminarian. Didn't understand the spiritual stakes, thought it was a property dispute, said nothing. Has spent every year since praying at every forest shrine he can find. The resurrection token he gives is him trying to keep one person alive in a catastrophe he failed to prevent.

**Ustad Basheer** — He arranged the debt relief. He found the logging company, thought he was helping a desperate family. His songs contain the actual history of what happened — the lore hints embedded in them are confessions in folk-song form, if anyone listens carefully enough.

**Soniya Chechi** — Her chai stall was built on the cleared land. The first years after the logging were the best business years of her life. She's known something has been wrong ever since the chai stopped tasting right — the water from the forest spring is tainted. The chai she gives LungiMan is brewed from the last clean source she still has access to.

**Mundakkal Ravi** — He bought some of the timber for his toddy shop renovation. The shop sits on planks from a sacred grove. Every drink he's served since has a bad feeling he can't name. He's loud, boisterous, jokes constantly — he never stops talking because he's terrified of what the silence in his shop sounds like at 2am.

---

## 🪔 The Nilavilakku HUD — Health as Flame

> *No number. No bar. The player reads their state from the lamp — like a real lamp.*

LungiMan's health is displayed as a traditional Kerala **Nilavilakku** (oil lamp). The flame's height, color, and stability communicate health intuitively. The lamp is the only health indicator — there is no HP number, no hearts.

| HP % | Flame | Color | Feel |
|---|---|---|---|
| 100–75% | 🪔 tall, steady | Warm amber | Full strength |
| 75–50% | 🪔 steady | Deeper amber | Carrying damage |
| 50–25% | 🪔 lower | Dark orange | Worn down |
| 25–10% | 🕯️ flickering | Red-orange | Near the edge |
| <10% | 🕯️ sputtering | Deep red, flickers | Almost gone |
| **Maveli blessed** | 🪔 blazing | **Sacred gold** | Restored, transcendent |

The golden state persists from Pathalam through all of Act V — a visual record of Maveli's intervention.

### Worn-Down Sprite States
The character's sprite mirrors the lamp — no UI required:

| Tier | HP range | Sprite modulate | Idle speed |
|---|---|---|---|
| 0 — Full | 100–75% | No tint | Normal |
| 1 — Carrying | 75–50% | Barely perceptible warm sepia | Normal |
| 2 — Worn | 50–25% | Visible sepia-warm tint | Normal |
| 3 — Struggling | 25–10% | Reddish-warm tint | Normal |
| 4 — Critical | <10% | Distinct reddish tint | 55% speed (fatigue) |
| Maveli | any | **Gold tint** | Normal — restored |

Tint transitions are **tweened over 0.8s** — damage accumulates visually, it doesn't snap.

**What the player feels:** By Act V, even a healthy player will notice LungiMan looks subtly different from Act I — slightly more amber, slightly more weathered. They've been on this journey together.

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
| `maveli_blessed` | bool | Set true in Pathalam — persists Act V; golden HUD lamp + player tint |
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
