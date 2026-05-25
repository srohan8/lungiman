extends "res://scenes/BaseAct.gd"

## Act V — Pey Komban's Rampage (FINALE)
## Sacred temple grove. Stay on trees — ground combat is fatal.
## game_won signal fires on boss death; Victory overlay handles end screen.

const ACT_TRIGGER_X := 7800.0   # fallback only — game_won fires first

# Cinematic refs
var _thoma_ref:          Node2D = null
var _cinematic_running:  bool   = false
var _reveal_done:        bool   = false   # Pey Komban opening reveal (fires once)
var _arena_locked:       bool   = false   # fires once when player crosses ARENA_LOCK_X
var _presighting_done:   bool   = false   # PeyKomban background charge sighting (fires once)
var _cursed_zone_warned: bool   = false   # first-entry ground-zone hint (fires once)

# Pre-boss encounter state
var _crows:              Array[Node2D] = []   # TempleCrow Area2D nodes
var _cursed_zone_timers: Dictionary   = {}   # Area2D → float secs_until_next_tick

const ARENA_LOCK_X  := 3000.0   # commit point — past this, no retreat
const PRESIGHTING_X := 2400.0   # Pey Komban charges across background, fires once

const ZONE_TREES   := 24
const ZONE_X_FROM  := 150.0
const ZONE_X_TO    := 7650.0
const ZONE_H       := 365.0   # crown y≈335 (GROUND_Y now 700, trunk longer)

# Temple crow tuning
const CROW_DMG          := 18
const CROW_COOLDOWN     := 3.0
const CROW_SENSE_X      := 100.0   # horizontal trigger radius
const CROW_DIVE_DUR     := 0.28    # seconds to reach target
const CROW_RISE_DUR     := 0.55    # seconds to return to perch

# Cursed zone tuning
const ZONE_TICK_INTERVAL := 0.5    # damage tick frequency (seconds)
const ZONE_DMG_PER_TICK  := 6      # 12 HP/s at 0.5s interval

func _ready() -> void:
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 0
	_init_sprite_parallax(Color(0.04, 0.10, 0.04),   # sacred banyan grove deep forest night
			"res://assets/backgrounds/bg_act5.png")   # ancient banyan grove with temple gate
	_add_parallax_layers([
		# Full-colour scenes: MAX alpha 0.18 — any higher = muddy colour soup over the base
		{"path": "res://assets/backgrounds/bg_act5_mountains.png",
			"scroll": 0.09, "tile": true, "alpha": 0.12},   # Kerala temple + banyans (far ghost)
		{"path": "res://assets/backgrounds/bg_act5_trees.png",
			"scroll": 0.20, "tile": true, "alpha": 0.15},   # dense banyan grove (mid ghost)
		{"path": "res://assets/backgrounds/bg_act5_props.png",
			"scroll": 0.34, "tile": true, "alpha": 0.18},   # temple ruins + banyans (near ghost)
	])
	_spawn_trees()
	_spawn_trail_stumps()
	_spawn_fireflies()
	_spawn_temple_crows()
	_spawn_cursed_zones()
	_spawn_pey_komban()
	_spawn_powerups()
	_spawn_npcs()
	_spawn_props()
	_connect_player_to_hud()
	_queue_hint("⚠️ STAY OFF THE GROUND — one charge and you're done!", 1.5, 7.0)
	_start_footstep_shakes()
	_begin_peykomban_reveal()   # async — 3-second 3rd-person reveal, then normal gameplay

func _process(delta: float) -> void:
	super._process(delta)
	var player := _get_player()
	if not is_instance_valid(player): return

	# Arena lock — fires once when player crosses ARENA_LOCK_X
	if not _arena_locked and player.global_position.x >= ARENA_LOCK_X:
		_arena_locked = true
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		_lock_arena(player, cam)
		var hud := _get_hud()
		if hud and hud.has_method("show_hint"):
			hud.show_hint("⚠️ No retreat — face Pey Komban!", 3.0)

	# Pre-sighting — fires once when player crosses PRESIGHTING_X
	if not _presighting_done and player.global_position.x >= PRESIGHTING_X:
		_presighting_done = true
		_do_presighting(player.global_position.x)

	# Pre-boss encounter ticks
	_tick_crows(delta)
	_tick_cursed_zones(delta)

## Periodic ground-shake — Pey Komban's distant footsteps felt every 8s.
func _start_footstep_shakes() -> void:
	_schedule_shake()

func _schedule_shake() -> void:
	get_tree().create_timer(8.0).timeout.connect(func() -> void:
		var player := _get_player()
		if is_instance_valid(player) and player.has_method("add_trauma"):
			player.add_trauma(0.35)
		_schedule_shake()
	)

## Snapped tree stumps showing Pey Komban's trail of destruction.
func _spawn_trail_stumps() -> void:
	for sx: float in [1850.0, 2050.0, 2200.0, 2380.0]:
		var stump := ColorRect.new()
		stump.color    = Color(0.22, 0.14, 0.06, 1.0)
		stump.size     = Vector2(18.0, randf_range(28.0, 55.0))
		stump.position = Vector2(sx, GROUND_Y - stump.size.y)
		stump.z_index  = 1
		add_child(stump)
		# Jagged splinter on top
		var splinter := ColorRect.new()
		splinter.color    = Color(0.30, 0.18, 0.08, 1.0)
		splinter.size     = Vector2(8.0, 18.0)
		splinter.position = Vector2(sx + 5.0, GROUND_Y - stump.size.y - 14.0)
		add_child(splinter)
	_queue_hint("🌳 Something enormous passed here.", 9.0, 4.0)

## Fireflies — gentle yellow-green dots drifting through the sacred grove.
func _spawn_fireflies() -> void:
	for _i: int in 22:
		var ff := ColorRect.new()
		ff.color    = Color(0.75, 1.0, 0.35, 0.80)
		ff.size     = Vector2(4.0, 4.0)
		ff.position = Vector2(randf_range(500.0, 7500.0), randf_range(120.0, 510.0))
		ff.z_index  = 5
		add_child(ff)
		# Each firefly drifts in a small random oval, loops forever
		var tw := create_tween()
		tw.set_loops()
		var ox := randf_range(-40.0, 40.0)
		var oy := randf_range(-20.0, 20.0)
		var dur := randf_range(2.0, 4.5)
		tw.tween_property(ff, "position", ff.position + Vector2(ox, oy), dur).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ff, "position", ff.position, dur).set_trans(Tween.TRANS_SINE)
		# Alpha pulse
		var ta := create_tween()
		ta.set_loops()
		ta.tween_property(ff, "modulate:a", 0.2, randf_range(0.8, 1.8))
		ta.tween_property(ff, "modulate:a", 1.0, randf_range(0.8, 1.8))

func _spawn_trees() -> void:
	var tint := Color(0.85, 0.75, 0.3, 1.0)   # ancient gold-green sacred grove
	var xs   := _linspace(ZONE_X_FROM, ZONE_X_TO, ZONE_TREES)
	for i: int in xs.size():
		_add_tree($Trees, xs[i], ZONE_H, 0.05 * (1 if i % 2 == 0 else -1), tint)

# ─────────────────────────────────────────────────────────────────────────────
## OPTION A — TEMPLE CROWS
## Three possessed temple crows perch at crown level and dive-bomb the player
## when they linger on the ground below. They TEACH the "stay elevated" mechanic
## in the 4000px run-up before Pey Komban enforces it with a 999-damage charge.
## Visual: dark silhouette with a glowing amber eye (possession glow).
## Positions: x=1100 (mid-grove), x=1900 (stump zone), x=2600 (pre-arena).
# ─────────────────────────────────────────────────────────────────────────────

func _spawn_temple_crows() -> void:
	for data: Array in [
		[1100.0, 0.0],    # mid-grove entrance — first crow encounter
		[1900.0, 0.8],    # stump zone — second encounter, slightly staggered start
		[2600.0, 0.4],    # pre-arena — final crow warning before lock
	]:
		var cx: float = data[0]
		var cd: float = data[1]   # initial cooldown stagger
		_make_temple_crow(cx, cd)

func _make_temple_crow(cx: float, initial_cooldown: float) -> void:
	var perch := Vector2(cx, ZONE_H - 15.0)

	var area := Area2D.new()
	area.name            = "TempleCrow"
	area.position        = perch
	area.collision_layer = 0
	area.collision_mask  = 2   # player layer
	area.z_index         = 6   # above trees, visible game layer
	area.set_meta("perch",    perch)
	area.set_meta("diving",   false)
	area.set_meta("cooldown", initial_cooldown)

	# Hit zone
	var col   := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape    = shape
	area.add_child(col)

	# Body silhouette
	var body := ColorRect.new()
	body.color    = Color(0.05, 0.02, 0.02, 0.92)
	body.size     = Vector2(10.0, 8.0)
	body.position = Vector2(-5.0, -4.0)
	area.add_child(body)

	# Left wing
	var wl := ColorRect.new()
	wl.name     = "WingL"
	wl.color    = Color(0.06, 0.03, 0.03, 0.88)
	wl.size     = Vector2(12.0, 3.0)
	wl.position = Vector2(-15.0, -1.0)
	wl.rotation = -0.45
	area.add_child(wl)

	# Right wing
	var wr := ColorRect.new()
	wr.name     = "WingR"
	wr.color    = Color(0.06, 0.03, 0.03, 0.88)
	wr.size     = Vector2(12.0, 3.0)
	wr.position = Vector2(3.0, -1.0)
	wr.rotation = 0.45
	area.add_child(wr)

	# Glowing amber eye — possession marker
	var eye := ColorRect.new()
	eye.color    = Color(0.95, 0.45, 0.05, 1.0)
	eye.size     = Vector2(3.0, 3.0)
	eye.position = Vector2(1.0, -3.0)
	area.add_child(eye)

	add_child(area)
	_crows.append(area)

	# Deal damage on body contact, but ONLY during an active dive
	area.body_entered.connect(func(body: Node) -> void:
		if not body.is_in_group("player"): return
		if not area.get_meta("diving"): return
		if area.get_meta("cooldown") > 0.0: return
		if body.has_method("take_damage"):
			body.take_damage(CROW_DMG)
		area.set_meta("cooldown", CROW_COOLDOWN)
	)

func _tick_crows(delta: float) -> void:
	var player := _get_player()
	for crow: Node2D in _crows:
		if not is_instance_valid(crow): continue

		# Tick cooldown
		var cd: float = (crow.get_meta("cooldown") as float) - delta
		crow.set_meta("cooldown", maxf(0.0, cd))
		if (crow.get_meta("cooldown") as float) > 0.0: continue
		if crow.get_meta("diving") as bool: continue

		if not is_instance_valid(player): continue
		var dx := absf(player.global_position.x - crow.global_position.x)
		if dx > CROW_SENSE_X: continue
		# Only dive at players who are on or near the ground (not perched)
		if player.global_position.y < ZONE_H + 30.0: continue

		# ── DIVE ─────────────────────────────────────────────────────────────
		crow.set_meta("diving", true)
		var perch: Vector2 = crow.get_meta("perch") as Vector2
		var dive_target := Vector2(
			player.global_position.x,
			minf(player.global_position.y - 10.0, GROUND_Y - 40.0)
		)

		# Wing-fold during dive, unfold on rise
		var wl: ColorRect = crow.get_node_or_null("WingL") as ColorRect
		var wr: ColorRect = crow.get_node_or_null("WingR") as ColorRect
		if wl and wr:
			var fold_tw := create_tween()
			fold_tw.tween_property(wl, "rotation", 0.10, CROW_DIVE_DUR)
			fold_tw.tween_property(wl, "rotation", -0.45, CROW_RISE_DUR)
			var fold_twr := create_tween()
			fold_twr.tween_property(wr, "rotation", -0.10, CROW_DIVE_DUR)
			fold_twr.tween_property(wr, "rotation", 0.45, CROW_RISE_DUR)

		# Body movement
		var tw := create_tween()
		tw.tween_property(crow, "position", dive_target, CROW_DIVE_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(crow, "position", perch,       CROW_RISE_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			crow.set_meta("diving",   false)
			crow.set_meta("cooldown", CROW_COOLDOWN)
		)

# ─────────────────────────────────────────────────────────────────────────────
## OPTION B — CURSED GROUND ZONES
## Two sections of temple floor cursed by Pey Komban's footsteps.
## Standing here deals 12 HP/s (6 HP per 0.5s tick).
## Visual: deep red pulsing glow + faint rune marks at ground level.
## Positions: x=1300 (180px wide) and x=2200 (220px wide).
# ─────────────────────────────────────────────────────────────────────────────

func _spawn_cursed_zones() -> void:
	for data: Array in [
		[1300.0, 180.0],   # between first crow and stump zone
		[2200.0, 220.0],   # deeper into the pre-arena approach
	]:
		_make_cursed_zone(data[0], data[1])

func _make_cursed_zone(cx: float, width: float) -> void:
	# Ground glow
	var glow := ColorRect.new()
	glow.color    = Color(0.55, 0.0, 0.0, 0.14)
	glow.size     = Vector2(width, 22.0)
	glow.position = Vector2(cx - width * 0.5, GROUND_Y - 18.0)
	glow.z_index  = 1
	add_child(glow)

	# Subtle rune marks — 3 thin vertical lines
	for rx: float in [-0.30, 0.0, 0.30]:
		var rune := ColorRect.new()
		rune.color    = Color(0.85, 0.10, 0.05, 0.28)
		rune.size     = Vector2(2.0, 14.0)
		rune.position = Vector2(cx + rx * width - 1.0, GROUND_Y - 17.0)
		rune.z_index  = 2
		add_child(rune)

	# Alpha pulse on the glow (slow, ominous)
	var tw := create_tween().set_loops()
	tw.tween_property(glow, "color:a", 0.28, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "color:a", 0.08, 1.5).set_trans(Tween.TRANS_SINE)

	# Area2D for player detection
	var area := Area2D.new()
	area.position        = Vector2(cx, GROUND_Y - 8.0)
	area.collision_layer = 0
	area.collision_mask  = 2
	var col   := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(width, 36.0)
	col.shape = rect
	area.add_child(col)
	add_child(area)

	area.body_entered.connect(func(body: Node) -> void:
		if not body.is_in_group("player"): return
		_cursed_zone_timers[area] = 0.0   # tick immediately on entry
		if not _cursed_zone_warned:
			_cursed_zone_warned = true
			var hud := _get_hud()
			if hud and hud.has_method("show_hint"):
				hud.show_hint("🌑 Cursed ground — GET OFF IT!", 2.5)
	)
	area.body_exited.connect(func(body: Node) -> void:
		if not body.is_in_group("player"): return
		_cursed_zone_timers.erase(area)
	)

func _tick_cursed_zones(delta: float) -> void:
	if _cursed_zone_timers.is_empty(): return
	var player := _get_player()
	if not is_instance_valid(player): return
	for area: Area2D in _cursed_zone_timers.keys().duplicate():
		if not is_instance_valid(area):
			_cursed_zone_timers.erase(area)
			continue
		var t: float = (_cursed_zone_timers[area] as float) - delta
		_cursed_zone_timers[area] = t
		if t <= 0.0:
			_cursed_zone_timers[area] = ZONE_TICK_INTERVAL
			if player.has_method("take_damage"):
				player.take_damage(ZONE_DMG_PER_TICK)

# ─────────────────────────────────────────────────────────────────────────────
## OPTION C — PEY KOMBAN PRE-SIGHTING
## At x=2400, Pey Komban's massive silhouette charges across the far background
## right → left. No damage. Pure dread — the player sees the scale before the
## arena. Emotional beat: "I just saw that thing. It is incomprehensibly large."
## Silhouette is semi-transparent (feels like distance), tusks faintly ivory.
# ─────────────────────────────────────────────────────────────────────────────

func _do_presighting(player_x: float) -> void:
	# Spawn off the right edge of the visible screen, charge off the left
	var start_x := player_x + 420.0
	var end_x   := player_x - 520.0

	# Main silhouette — dark, semi-transparent, slightly below crown level
	var sil := ColorRect.new()
	sil.color    = Color(0.04, 0.06, 0.03, 0.52)
	sil.size     = Vector2(190.0, 220.0)
	sil.position = Vector2(start_x, GROUND_Y - 220.0)
	sil.z_index  = 1   # visible behind stumps (z=1 shares layer — fine)
	add_child(sil)

	# Tusks as children of sil — move for free during the charge tween
	for tx: float in [-38.0, 38.0]:
		var tusk := ColorRect.new()
		tusk.color    = Color(0.65, 0.58, 0.42, 0.48)
		tusk.size     = Vector2(16.0, 48.0)
		tusk.position = Vector2(95.0 + tx - 8.0, 68.0)
		tusk.rotation = tx * 0.045
		sil.add_child(tusk)

	# Two camera shakes — first on entry, second as it thunders past
	var player := _get_player()
	if is_instance_valid(player) and player.has_method("add_trauma"):
		player.add_trauma(0.48)
	get_tree().create_timer(0.55).timeout.connect(func() -> void:
		var p := _get_player()
		if is_instance_valid(p) and p.has_method("add_trauma"):
			p.add_trauma(0.75)
	)

	# Charge: accelerates (EASE_IN) — unstoppable force feel
	var tw := create_tween()
	tw.tween_property(sil, "position:x", end_x, 1.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(sil.queue_free)

	# Hint fires after the sighting passes — give the player a beat of silence first
	get_tree().create_timer(2.1).timeout.connect(func() -> void:
		var hud := _get_hud()
		if hud and hud.has_method("show_hint"):
			hud.show_hint("🐘 That was Pey Komban.", 3.0)
	)

# ─────────────────────────────────────────────────────────────────────────────

func _spawn_pey_komban() -> void:
	var boss: Node2D = preload("res://scenes/PeyKomban.tscn").instantiate()
	boss.position = Vector2(4000.0, GROUND_Y)
	$Enemies.add_child(boss)
	boss.defeat.connect(_start_mundu_cinematic.bind(boss))

func _spawn_powerups() -> void:
	var data := [
		[500.0,  GROUND_Y, "heart"],
		[1500.0, GROUND_Y, "nut"],
		[2800.0, 407.0,    "porotta"],   # elevated — crown-leap required
		[4800.0, GROUND_Y, "heart"],
		[5800.0, GROUND_Y, "nut"],
		[6800.0, GROUND_Y, "toddy"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])
	# Elevated platform holding the curry
	_add_platform(2800.0, 415.0, 140.0, Color(0.35, 0.25, 0.12, 1.0))

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(300.0, GROUND_Y)
	add_child(thoma)
	_thoma_ref = thoma   # stored for mundu cinematic
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(700.0, GROUND_Y)
	add_child(soniya)

func _spawn_props() -> void:
	_build_temple_gate(0.0)      # ancient temple arch at scene entrance
	_build_chai_cart(700.0)      # Soniya's emergency chai cart

## Ancient temple gate — two stone pillars flanking the entrance
func _build_temple_gate(x: float) -> void:
	for side: float in [-80.0, 80.0]:
		var pillar := ColorRect.new()
		pillar.size     = Vector2(20.0, 110.0)
		pillar.position = Vector2(x + side - 10.0, GROUND_Y - 110.0)
		pillar.color    = Color(0.30, 0.28, 0.24, 1.0)   # ancient weathered stone
		pillar.z_index  = 2
		add_child(pillar)
		# Carved top cap
		var cap := ColorRect.new()
		cap.size     = Vector2(28.0, 12.0)
		cap.position = Vector2(x + side - 14.0, GROUND_Y - 122.0)
		cap.color    = Color(0.26, 0.24, 0.20, 1.0)
		cap.z_index  = 2
		add_child(cap)
		# Moss tint strip
		var moss := ColorRect.new()
		moss.size     = Vector2(20.0, 20.0)
		moss.position = Vector2(x + side - 10.0, GROUND_Y - 110.0)
		moss.color    = Color(0.20, 0.36, 0.14, 0.35)
		moss.z_index  = 3
		add_child(moss)
	# Lintel connecting pillars
	var lintel := ColorRect.new()
	lintel.size     = Vector2(180.0, 14.0)
	lintel.position = Vector2(x - 90.0, GROUND_Y - 122.0)
	lintel.color    = Color(0.28, 0.26, 0.22, 1.0)
	lintel.z_index  = 2
	add_child(lintel)

## Soniya's emergency chai cart — same Chaya Kada sprite, she brought everything.
## image 4800×3584; scale 0.025 → content bottom 40px below sprite centre.
func _build_chai_cart(x: float) -> void:
	_prop_sprite("res://assets/sprites/chaykada_sheet.png",
			x, GROUND_Y - 40.0, 0.025, 1)

# ─────────────────────────────────────────────────────────────────────────────
## PEY KOMBAN REVEAL — 3rd-person opening cinematic.
## At scene start: camera pulls behind LungiMan at the temple gate, Pey Komban's
## silhouette looms through the ancient trees. AWE — not terror. ~3 s total.
## Camera snaps back; normal gameplay begins immediately after.
# ─────────────────────────────────────────────────────────────────────────────

func _begin_peykomban_reveal() -> void:
	if _reveal_done: return
	_reveal_done = true

	# Brief settle — let the scene tree finish spawning everything
	await get_tree().create_timer(0.60).timeout

	var player := _get_player()
	if not is_instance_valid(player): return

	# ── Step 1: Freeze player; pull camera "behind" (over-the-shoulder) ──────
	player.set_physics_process(false)
	player.set_process(false)
	player.velocity = Vector2.ZERO

	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(cam, "offset", Vector2(-80.0, -18.0), 0.48)
		await tw.finished
	else:
		await get_tree().create_timer(0.48).timeout

	# ── Step 2: Pey Komban silhouette emerges through the tree line ───────────
	# (CanvasLayer = screen-space, unaffected by world camera scrolling)
	var cl := CanvasLayer.new()
	cl.layer = 12
	add_child(cl)

	# Massive dark body — starts at horizon (small + far right) and grows to awe
	var boss_sil := ColorRect.new()
	boss_sil.size         = Vector2(55.0, 70.0)
	boss_sil.color        = Color(0.06, 0.04, 0.02, 0.88)
	boss_sil.position     = Vector2(345.0, 90.0)   # right side, mid-height
	boss_sil.pivot_offset = Vector2(27.5, 35.0)
	boss_sil.scale        = Vector2(0.35, 0.35)
	cl.add_child(boss_sil)

	# Tusks — two bright ivory streaks
	for tx: float in [-14.0, 14.0]:
		var tusk := ColorRect.new()
		tusk.size         = Vector2(8.0, 22.0)
		tusk.color        = Color(0.88, 0.82, 0.68, 0.90)
		tusk.position     = Vector2(345.0 + 27.5 + tx - 4.0, 108.0)
		tusk.pivot_offset = Vector2(4.0, 0.0)
		tusk.scale        = Vector2(0.35, 0.35)
		tusk.rotation     = tx * 0.035
		cl.add_child(tusk)
		create_tween().tween_property(tusk, "scale", Vector2(1.9, 1.9), 2.2).set_trans(Tween.TRANS_CUBIC)

	# Boss silhouette swells toward the camera — awe, not panic
	var grow_tw := create_tween()
	grow_tw.tween_property(boss_sil, "scale", Vector2(2.1, 2.1), 2.2).set_trans(Tween.TRANS_CUBIC)

	# Distant thunderous footstep shakes — unrolled to avoid closure-capture bug
	get_tree().create_timer(0.40).timeout.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("add_trauma"):
			player.add_trauma(0.28)
	)
	get_tree().create_timer(0.95).timeout.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("add_trauma"):
			player.add_trauma(0.36)
	)
	get_tree().create_timer(1.50).timeout.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("add_trauma"):
			player.add_trauma(0.44)
	)

	# ── Step 3: Sacred grove light flicker — trees shudder ───────────────────
	await get_tree().create_timer(1.8).timeout
	var hud := _get_hud()
	if hud: hud.show_hint("… something enormous lives here.", 2.5)

	# ── Step 4: Fade silhouette into the darkness, camera snaps back ─────────
	var fade_tw := create_tween()
	fade_tw.tween_property(boss_sil, "modulate:a", 0.0, 0.55)

	await get_tree().create_timer(0.65).timeout
	cl.queue_free()

	if is_instance_valid(cam):
		var back_tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		back_tw.tween_property(cam, "offset", Vector2(0.0, 0.0), 0.32)
		await back_tw.finished

	# ── Step 5: Resume gameplay ─────────────────────────────────────────────
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.set_process(true)
		# Arena lock fires later via _process when player crosses ARENA_LOCK_X

# ─────────────────────────────────────────────────────────────────────────────
## ARENA LOCK — called once the reveal cinematic ends.
## Clamps the camera's left scroll limit and drops an invisible wall so the
## player can no longer retreat out of the boss arena.
# ─────────────────────────────────────────────────────────────────────────────

func _lock_arena(player: Node2D, cam: Camera2D) -> void:
	# ── Camera left scroll clamp ─────────────────────────────────────────────
	# Viewport is 480px wide; half = 240px.  Locking limit_left to the player's
	# spawn X means the camera can never pull left of scene start.
	if is_instance_valid(cam):
		cam.limit_left = int(player.global_position.x) - 240   # allow current view, no further

	# ── Physical retreat barrier ─────────────────────────────────────────────
	# A thin StaticBody2D wall placed 30px behind the player.  Tall enough to
	# block at any jump height.  Collision layer 1 (world), mask 0 (player hits it).
	var wall := StaticBody2D.new()
	wall.name             = "ArenaWall"
	wall.collision_layer  = 1
	wall.collision_mask   = 0
	wall.global_position  = Vector2(player.global_position.x - 30.0, GROUND_Y - 400.0)

	var shape_node := CollisionShape2D.new()
	var rect       := RectangleShape2D.new()
	rect.size             = Vector2(10.0, 900.0)   # 10px wide, 900px tall
	shape_node.shape      = rect
	shape_node.position   = Vector2.ZERO
	wall.add_child(shape_node)
	add_child(wall)

	# Tiny visual indicator (thin dark line) — optional, shows in debug builds
	var vis := ColorRect.new()
	vis.color    = Color(0.0, 0.0, 0.0, 0.0)   # invisible in-game
	vis.size     = Vector2(4.0, 900.0)
	vis.position = Vector2(-2.0, -450.0)
	wall.add_child(vis)

# ─────────────────────────────────────────────────────────────────────────────
## MUNDU CINEMATIC — fires on Pey Komban defeat instead of instant win_game().
## LungiMan removes mundu → lasso throw → tusk climb → killing throw →
## boxer reveal → Thoma walks over with fresh mundu → win_game().
# ─────────────────────────────────────────────────────────────────────────────

func _start_mundu_cinematic(boss: Node2D) -> void:
	if _cinematic_running: return
	_cinematic_running = true
	# Capture tusk position NOW — boss queue_frees after emitting signal
	var tusk_pos := boss.global_position + Vector2(0.0, -110.0)
	_mundu_cinematic(tusk_pos)

func _mundu_cinematic(tusk_pos: Vector2) -> void:
	var player := _get_player()
	if not is_instance_valid(player):
		GameManager.win_game(); return

	# ── Freeze player controls ───────────────────────────────────────────────
	player.set_physics_process(false)
	player.set_process(false)
	player.velocity = Vector2.ZERO

	var hud := _get_hud()
	var spr: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")

	# ── STEP 1: Lasso windup animation (0.45s) ───────────────────────────────
	if spr:
		var anim := "mundu_lasso" if spr.sprite_frames.has_animation("mundu_lasso") else "swing_grab"
		spr.play(anim)
	await get_tree().create_timer(0.45).timeout

	# ── STEP 2: Cloth arc toward tusk ───────────────────────────────────────
	var cloth_start := player.global_position + Vector2(14.0, -28.0)
	var arc_peak    := (cloth_start + tusk_pos) * 0.5 + Vector2(0.0, -70.0)

	var cloth := ColorRect.new()        # white mundu strip
	cloth.color          = Color(0.95, 0.95, 0.85, 0.92)
	cloth.size           = Vector2(52.0, 10.0)
	cloth.z_index        = 12   # above trees (z=6), player (z=7), boss (z=0)
	cloth.pivot_offset   = Vector2(0.0, 5.0)
	cloth.global_position = cloth_start
	add_child(cloth)
	var gold_border := ColorRect.new() # gold border stripe
	gold_border.color    = Color(1.0, 0.78, 0.08, 1.0)
	gold_border.size     = Vector2(52.0, 4.0)
	gold_border.position = Vector2(0.0, 6.0)
	cloth.add_child(gold_border)

	# Quadratic Bézier arc tween: cloth flies from player → peak → tusk
	var cloth_tw := create_tween()
	cloth_tw.tween_method(func(t: float) -> void:
		var mt  := 1.0 - t
		# B(t) = (1−t)² P0 + 2(1−t)t P1 + t² P2
		cloth.global_position = mt*mt * cloth_start + 2.0*mt*t * arc_peak + t*t * tusk_pos
		cloth.rotation        = (tusk_pos - cloth_start).angle() * t * 0.6
		cloth.size.x          = 52.0 + t * 22.0   # cloth stretches in flight
	, 0.0, 1.0, 0.38)
	await cloth_tw.finished
	cloth.queue_free()

	# ── STEP 3: Player swings up the tusk ───────────────────────────────────
	if spr:
		var anim := "swing" if spr.sprite_frames.has_animation("swing") else "idle"
		spr.play(anim)
	var perch := tusk_pos + Vector2(0.0, -36.0)
	var climb_tw := create_tween()
	climb_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	climb_tw.tween_property(player, "global_position", perch, 0.55)
	await climb_tw.finished

	# ── STEP 4: Killing throw — straight down, blessed gold ─────────────────
	if spr:
		var anim := "throw" if spr.sprite_frames.has_animation("throw") else "idle"
		spr.play(anim)
	var coconut: Node2D = preload("res://scenes/CoconutProjectile.tscn").instantiate()
	add_child(coconut)
	coconut.global_position = player.global_position
	coconut.velocity        = Vector2(0.0, 900.0)   # sacred downward strike
	await get_tree().create_timer(0.28).timeout

	# ── STEP 5: Bhadrakali flash — sacred gold bloom ─────────────────────────
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 20
	add_child(flash_layer)
	var flash := ColorRect.new()
	flash.color        = Color(1.0, 0.85, 0.25, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_layer.add_child(flash)
	var flash_tw := create_tween()
	flash_tw.tween_property(flash, "color:a", 0.88, 0.10)
	flash_tw.tween_property(flash, "color:a", 0.0,  0.65)

	# Drop player back to ground during the fade
	var drop_tw := create_tween()
	drop_tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	drop_tw.tween_property(player, "global_position:y", GROUND_Y - 26.0, 0.32)
	await drop_tw.finished

	# ── STEP 6: Boxer reveal ─────────────────────────────────────────────────
	if spr:
		var anim := "boxer_idle" if spr.sprite_frames.has_animation("boxer_idle") else "idle"
		spr.play(anim)
	# Silence. Let it sit.
	await get_tree().create_timer(1.6).timeout

	# ── STEP 7: Thoma walks over with a fresh mundu ──────────────────────────
	if is_instance_valid(_thoma_ref):
		if hud: hud.show_hint("...", 4.5)
		var thoma_tw := create_tween()
		thoma_tw.set_trans(Tween.TRANS_SINE)
		thoma_tw.tween_property(_thoma_ref, "global_position:x",
			player.global_position.x - 58.0, 1.5)
		await thoma_tw.finished
		await get_tree().create_timer(1.0).timeout

	# ── STEP 8: Mundu back on — normal idle ─────────────────────────────────
	if spr: spr.play("idle")
	await get_tree().create_timer(0.5).timeout

	# Re-enable player, fire victory
	player.set_physics_process(true)
	player.set_process(true)
	GameManager.win_game()
