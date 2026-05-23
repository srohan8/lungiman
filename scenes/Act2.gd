extends "res://scenes/BaseAct.gd"

## Act II — Kuttichathan's Carnival
## Abandoned festival grounds. Fire sky. Kuttichathan boss + decoy clones.
## Fire Rain event forces player onto tree crowns.

const NEXT_SCENE    := "res://scenes/Act3.tscn"
const ACT_TRIGGER_X := 7800.0

const ZONE1_TREES  := 10
const ZONE1_X_FROM := 300.0
const ZONE1_X_TO   := 3800.0
const ZONE1_H      := 270.0   # crown y≈430 (GROUND_Y now 700, trunk longer)

const ZONE2_TREES  := 10
const ZONE2_X_FROM := 4000.0
const ZONE2_X_TO   := 7500.0
const ZONE2_H      := 270.0   # crown y≈430 (GROUND_Y now 700, trunk longer)

var _fire_rain_running := false

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 3
	# bg_act2_scene: proper side-scrolling carnival (regenerate with: python generate_sprites.py --sheet bg_act2_scene)
	# Fallback to bg_act2_mountains if not yet generated (isometric, but better than nothing)
	const _BG2 := "res://assets/backgrounds/bg_act2_scene.png"
	const _BG2_FALLBACK := "res://assets/backgrounds/bg_act2_mountains.png"
	_init_sprite_parallax(Color(0.18, 0.06, 0.02),
			_BG2 if ResourceLoader.exists(_BG2) else _BG2_FALLBACK)
	_add_parallax_layers([
		# All three strips regenerated 2026-05-21 — proper side-scrolling silhouettes
		{"path": "res://assets/backgrounds/bg_act2_mountains.png",
			"scroll": 0.12, "tile": true, "alpha": 0.45,
			"remove_white": false},   # carnival ruins skyline strip — amber glow intentional (far)
		{"path": "res://assets/backgrounds/bg_act2_trees.png",
			"scroll": 0.26, "tile": true,
			"remove_white": true},    # scorched palm silhouettes on white → transparent (mid)
		{"path": "res://assets/backgrounds/bg_act2_props.png",
			"scroll": 0.38, "tile": true,
			"remove_white": true},    # ferris wheel + tent + torn flag on white → transparent (near)
	])
	_spawn_trees()
	_spawn_fire_hazards()
	_spawn_carnival_bell()
	_spawn_monkey_swarm()
	_spawn_clone_decoy_zone()
	_spawn_kuttichathan()
	_spawn_powerups()
	_spawn_npcs()
	_spawn_props()
	_spawn_embers()
	_connect_player_to_hud()
	_queue_hint("💥 Clones EXPLODE when hit — find the real one first!", 2.0, 6.0)
	_queue_hint("🔥 Fire ahead — CLIMB over the ground hazards!", 4.0, 5.0)

func _spawn_trees() -> void:
	var tint := Color(0.95, 0.7, 0.4, 1.0)   # reddish-orange fire carnival
	var z1 := _linspace(ZONE1_X_FROM, ZONE1_X_TO, ZONE1_TREES)
	for x: float in z1:
		_add_tree($Trees, x, ZONE1_H, 0.0, tint)
	var z2 := _linspace(ZONE2_X_FROM, ZONE2_X_TO, ZONE2_TREES)
	for x: float in z2:
		_add_tree($Trees, x, ZONE2_H, 0.0, tint)

## Fire hazard patches on the ground — 8 dmg on touch, forces crown traversal.
func _spawn_fire_hazards() -> void:
	var patches := [
		[800.0,  260.0],
		[950.0,  280.0],
		[1100.0, 260.0],
		[1300.0, 270.0],
		[1450.0, 260.0],
	]
	for p: Array in patches:
		# Visual: glowing orange-red patch
		var vis := ColorRect.new()
		vis.color    = Color(1.0, 0.35, 0.0, 0.80)
		vis.size     = Vector2(140.0, 22.0)
		vis.position = Vector2(float(p[0]) - 70.0, GROUND_Y - 22.0)
		vis.z_index  = 1
		add_child(vis)
		# Shimmer strip
		var glow := ColorRect.new()
		glow.color    = Color(1.0, 0.80, 0.0, 0.45)
		glow.size     = Vector2(140.0, 8.0)
		glow.position = Vector2(float(p[0]) - 70.0, GROUND_Y - 30.0)
		glow.z_index  = 2
		add_child(glow)
		# Damage Area2D
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask  = 2
		var col   := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size    = Vector2(140.0, 28.0)
		col.shape     = shape
		area.position = Vector2(float(p[0]), GROUND_Y - 10.0)
		area.add_child(col)
		area.body_entered.connect(_on_fire_entered)
		add_child(area)

func _on_fire_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(8)

## Fire Rain event — triggered when player passes x=5000.
## Spawns fireballs from the sky every 1.8s. Crown = safe. Ground = dangerous.
var _fire_rain_triggered := false

func _process(delta: float) -> void:
	super._process(delta)
	if not _fire_rain_triggered:
		var player := _get_player()
		if player and player.global_position.x >= 5000.0:
			_fire_rain_triggered = true
			_fire_rain_running   = true
			_queue_hint("⚡ FIRE RAIN — get to the trees NOW!", 0.1, 5.0)
			_schedule_fireball()

func _schedule_fireball() -> void:
	if not _fire_rain_running:
		return
	get_tree().create_timer(1.8).timeout.connect(_drop_fireball)

func _drop_fireball() -> void:
	if not _fire_rain_running:
		return
	# Random x in the fire rain zone
	var fx := randf_range(5000.0, 5500.0)
	var start_y := -80.0   # above screen top

	# Fireball visual + hitbox
	var fb := Area2D.new()
	fb.collision_layer = 0
	fb.collision_mask  = 2
	fb.position        = Vector2(fx, start_y)
	var fc := CollisionShape2D.new()
	var fs := CircleShape2D.new()
	fs.radius = 14.0
	fc.shape  = fs
	fb.add_child(fc)
	var fv := ColorRect.new()
	fv.color    = Color(1.0, 0.4, 0.0, 0.90)
	fv.size     = Vector2(28.0, 28.0)
	fv.position = Vector2(-14.0, -14.0)
	fb.add_child(fv)
	fb.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(20)
			fb.queue_free()
	)
	add_child(fb)

	# Tween fall — lands at GROUND_Y
	var tw := create_tween()
	tw.tween_property(fb, "position:y", GROUND_Y, 1.4)
	tw.tween_callback(fb.queue_free)

	_schedule_fireball()

## Carnival Bell stall at x=1500 — throw coconut from crown to hit it, drops nut.
func _spawn_carnival_bell() -> void:
	# Elevated platform for the stall
	_add_platform(1500.0, 450.0, 80.0, Color(0.45, 0.22, 0.08, 1.0))

	# Bell hitbox Area2D — detected by coconut projectiles
	var bell := Area2D.new()
	bell.name = "CarnivalBell"
	bell.collision_layer = 8    # layer 4 = bells / interactables
	bell.collision_mask  = 16   # layer 5 = coconut projectiles
	bell.position        = Vector2(1500.0, 284.0)
	var bc := CollisionShape2D.new()
	var bs := CircleShape2D.new()
	bs.radius = 16.0
	bc.shape  = bs
	bell.add_child(bc)
	# Visual: golden circle
	var bv := ColorRect.new()
	bv.color    = Color(1.0, 0.80, 0.10, 1.0)
	bv.size     = Vector2(28.0, 28.0)
	bv.position = Vector2(-14.0, -14.0)
	bell.add_child(bv)
	# Label
	var lbl := Label.new()
	lbl.text     = "🔔"
	lbl.position = Vector2(-10.0, -36.0)
	bell.add_child(lbl)
	var rung_flag := [false]   # array so lambda captures by reference
	bell.area_entered.connect(func(area: Area2D) -> void:
		if rung_flag[0]: return
		if area.is_in_group("coconut"):
			rung_flag[0] = true
			_add_powerup($PowerUps, 1500.0, 442.0, "nut")
			_add_powerup($PowerUps, 1540.0, 442.0, "nut")
			var hud := _get_hud()
			if hud: hud.show_hint("🏆 Carnival Champion!", 3.0)
			bv.color = Color(0.5, 0.5, 0.5, 1.0)   # greyed out after ring
	)
	add_child(bell)

## Monkey Swarm midboss at x=2800 — 5 monkeys, each death speeds survivors.
func _spawn_monkey_swarm() -> void:
	const SWARM := "act2_swarm"
	var positions := [2600.0, 2700.0, 2800.0, 2900.0, 3000.0]
	for px: float in positions:
		var m: Node2D = preload("res://scenes/HauntedMonkey.tscn").instantiate()
		m.position     = Vector2(px, GROUND_Y)
		m.swarm_id     = SWARM
		m.patrol_left  = 2400.0
		m.patrol_right = 3200.0
		$Enemies.add_child(m)
	_queue_hint("🙈 MONKEY SWARM — kill one, the rest get faster!", 10.0, 5.5)

## 3 pre-fight Kuttichathan decoys at x=3200–4800.
## Real one flickers fast; fakes flash slowly. Wrong hit = 15 dmg explosion.
func _spawn_clone_decoy_zone() -> void:
	var real_idx := randi() % 3
	var positions := [3200.0, 4000.0, 4800.0]
	for i: int in positions.size():
		var px: float = positions[i]
		var is_real   := (i == real_idx)
		_spawn_one_decoy(px, is_real)
	_queue_hint("👻 Clone zone — the REAL one flickers fast!", 18.0, 5.0)

func _spawn_one_decoy(px: float, is_real: bool) -> void:
	var decoy := Area2D.new()
	decoy.collision_layer = 0
	decoy.collision_mask  = 0   # coconuts hit via area_entered with coconut group check
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28.0, 52.0)
	col.shape  = shape
	decoy.add_child(col)
	decoy.position = Vector2(px, GROUND_Y - 26.0)

	# Visual body — small fiery Kuttichathan silhouette
	var body := ColorRect.new()
	body.color    = Color(0.85, 0.18, 0.05, 0.90)
	body.size     = Vector2(28.0, 52.0)
	body.position = Vector2(-14.0, -26.0)
	decoy.add_child(body)

	# Eye marker
	var eye := Label.new()
	eye.text     = "👁️"
	eye.position = Vector2(-10.0, -44.0)
	decoy.add_child(eye)

	# Flicker tween — real = fast (0.08s), fake = slow (0.45s)
	var tw := create_tween()
	tw.set_loops()
	var spd := 0.08 if is_real else 0.45
	tw.tween_property(body, "modulate:a", 0.2, spd)
	tw.tween_property(body, "modulate:a", 1.0, spd)

	# Hit detection via sword (Z key player hitbox) or coconut
	# We use a simple body_entered with player group + sword phase check
	decoy.collision_mask = 2   # player layer
	var hit_flag := [false]   # array so lambda captures by reference
	decoy.body_entered.connect(func(body_node: Node) -> void:
		if hit_flag[0] or not body_node.is_in_group("player"): return
		# Only triggers on sword swing (sword_phase > 0)
		if not (body_node.get("sword_phase") > 0): return
		hit_flag[0] = true
		if is_real:
			_get_hud().show_hint("✅ Real Kuttichathan! Keep going!", 2.5)
			GameManager.score += 30
			decoy.queue_free()
		else:
			# Wrong clone — explode
			body.color = Color(1.0, 0.6, 0.0, 1.0)
			body_node.take_damage(15)
			_get_hud().show_hint("💥 Wrong clone! −15 HP", 2.5)
			get_tree().create_timer(0.3).timeout.connect(decoy.queue_free)
	)
	add_child(decoy)

func _spawn_kuttichathan() -> void:
	var boss: Node2D = preload("res://scenes/Kuttichathan.tscn").instantiate()
	boss.position = Vector2(5500.0, GROUND_Y)
	$Enemies.add_child(boss)

func _spawn_powerups() -> void:
	var data := [
		[800.0,  GROUND_Y, "nut"],
		[1800.0, GROUND_Y, "heart"],
		[3000.0, GROUND_Y, "toddy"],
		[4500.0, GROUND_Y, "nut"],
		[6000.0, GROUND_Y, "heart"],
		[7000.0, GROUND_Y, "porotta"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(200.0, GROUND_Y)
	add_child(thoma)
	# Mundakkal Ravi — Phase 3 swing race reappears here too
	var ravi: Node2D = preload("res://scenes/AniyandyRavi.tscn").instantiate()
	ravi.position = Vector2(2200.0, GROUND_Y)
	add_child(ravi)
	# Stop fire rain when boss dies (game_won / next scene fires)
	GameManager.game_won.connect(func() -> void: _fire_rain_running = false)

func _spawn_props() -> void:
	_build_fallen_cart(2200.0)   # Ravi's toddy cart — overturned in the carnival chaos
	_build_burnt_chapel(3800.0)  # Brother Thoma's shelter in the ruins

## Ravi's toddy cart — tipped over, toddy puddled on the road
func _build_fallen_cart(x: float) -> void:
	# Tilted cart body
	var body := ColorRect.new()
	body.size     = Vector2(62.0, 26.0)
	body.position = Vector2(x - 31.0, GROUND_Y - 22.0)
	body.color    = Color(0.32, 0.20, 0.10, 1.0)
	body.z_index  = 1
	add_child(body)
	# Upright wheel (still attached)
	var wheel_up := ColorRect.new()
	wheel_up.size     = Vector2(20.0, 20.0)
	wheel_up.position = Vector2(x - 40.0, GROUND_Y - 20.0)
	wheel_up.color    = Color(0.15, 0.10, 0.06, 1.0)
	wheel_up.z_index  = 2
	add_child(wheel_up)
	# Fallen wheel — flat on road
	var wheel_flat := ColorRect.new()
	wheel_flat.size     = Vector2(22.0, 8.0)
	wheel_flat.position = Vector2(x + 18.0, GROUND_Y - 8.0)
	wheel_flat.color    = Color(0.15, 0.10, 0.06, 1.0)
	wheel_flat.z_index  = 2
	add_child(wheel_flat)
	# Spilled toddy puddle — dark amber
	var spill := ColorRect.new()
	spill.size     = Vector2(56.0, 6.0)
	spill.position = Vector2(x - 8.0, GROUND_Y - 6.0)
	spill.color    = Color(0.72, 0.40, 0.10, 0.65)
	spill.z_index  = 0
	add_child(spill)
	# Pot rolling away
	var pot := ColorRect.new()
	pot.size     = Vector2(12.0, 12.0)
	pot.position = Vector2(x + 34.0, GROUND_Y - 12.0)
	pot.color    = Color(0.70, 0.30, 0.10, 1.0)
	pot.z_index  = 2
	add_child(pot)

## Burnt chapel ruins — Thoma's shelter, scorched walls
func _build_burnt_chapel(x: float) -> void:
	# Left scorched wall fragment
	var wall_l := ColorRect.new()
	wall_l.size     = Vector2(14.0, 80.0)
	wall_l.position = Vector2(x - 50.0, GROUND_Y - 80.0)
	wall_l.color    = Color(0.18, 0.12, 0.08, 1.0)
	wall_l.z_index  = 1
	add_child(wall_l)
	# Right scorched wall fragment
	var wall_r := ColorRect.new()
	wall_r.size     = Vector2(14.0, 60.0)
	wall_r.position = Vector2(x + 36.0, GROUND_Y - 60.0)
	wall_r.color    = Color(0.18, 0.12, 0.08, 1.0)
	wall_r.z_index  = 1
	add_child(wall_r)
	# Charred ground inside
	var ground_ash := ColorRect.new()
	ground_ash.size     = Vector2(86.0, 8.0)
	ground_ash.position = Vector2(x - 43.0, GROUND_Y - 8.0)
	ground_ash.color    = Color(0.12, 0.08, 0.06, 0.80)
	ground_ash.z_index  = 0
	add_child(ground_ash)
	# Ember glow in rubble
	var glow := ColorRect.new()
	glow.size     = Vector2(16.0, 6.0)
	glow.position = Vector2(x - 8.0, GROUND_Y - 12.0)
	glow.color    = Color(1.0, 0.40, 0.05, 0.55)
	glow.z_index  = 2
	add_child(glow)
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.20, 0.9)
	tw.tween_property(glow, "modulate:a", 1.00, 0.7)

## Screen-space CPUParticles2D ember drift — CanvasLayer so it follows the camera.
func _spawn_embers() -> void:
	var cl := CanvasLayer.new()
	cl.name  = "EmberLayer"
	cl.layer = 8
	var p := CPUParticles2D.new()
	p.emitting               = true
	p.amount                 = 60
	p.lifetime               = 3.5
	p.emission_shape         = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents  = Vector2(640, 8)
	p.position               = Vector2(410, 470)   # rise from bottom
	p.direction              = Vector2(0.2, -1.0).normalized()
	p.spread                 = 30.0
	p.gravity                = Vector2(0, 0)
	p.initial_velocity_min   = 40.0
	p.initial_velocity_max   = 100.0
	p.color                  = Color(1.0, 0.45, 0.05, 0.70)
	p.scale_amount_min       = 2.0
	p.scale_amount_max       = 5.0
	cl.add_child(p)
	add_child(cl)
