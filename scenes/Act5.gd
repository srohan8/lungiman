extends "res://scenes/BaseAct.gd"

## Act V — Pey Komban's Rampage (FINALE)
## Sacred temple grove. Stay on trees — ground combat is fatal.
## game_won signal fires on boss death; Victory overlay handles end screen.

const ACT_TRIGGER_X := 7800.0   # fallback only — game_won fires first

# Cinematic refs
var _thoma_ref:          Node2D = null
var _cinematic_running:  bool   = false
var _reveal_done:        bool   = false   # Pey Komban opening reveal (fires once)

const ZONE_TREES   := 24
const ZONE_X_FROM  := 150.0
const ZONE_X_TO    := 7650.0
const ZONE_H       := 365.0   # crown y≈335 (GROUND_Y now 700, trunk longer)

func _ready() -> void:
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 0
	_init_sprite_parallax(Color(0.04, 0.10, 0.04),   # sacred banyan grove deep forest night
			"res://assets/backgrounds/bg_act5.png")   # ancient banyan grove with temple gate — perfect finale backdrop
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
	_spawn_pey_komban()
	_spawn_powerups()
	_spawn_npcs()
	_spawn_props()
	_connect_player_to_hud()
	_queue_hint("⚠️ STAY OFF THE GROUND — one charge and you're done!", 1.5, 7.0)
	_start_footstep_shakes()
	_begin_peykomban_reveal()   # async — 3-second 3rd-person reveal, then normal gameplay

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

	# ── Step 5: Resume gameplay ───────────────────────────────────────────────
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.set_process(true)

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
