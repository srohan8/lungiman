extends "res://scenes/BaseAct.gd"

## Act II — Kuttichathan's Carnival
## Abandoned festival grounds. Fire sky. Kuttichathan boss + decoy clones.
## Fire Rain event forces player onto tree crowns.

const NEXT_SCENE    := "res://scenes/Act3.tscn"
const ACT_TRIGGER_X := 7800.0

const ZONE1_TREES  := 10
const ZONE1_X_FROM := 300.0
const ZONE1_X_TO   := 3800.0
const ZONE1_H      := 160.0

const ZONE2_TREES  := 10
const ZONE2_X_FROM := 4000.0
const ZONE2_X_TO   := 7500.0
const ZONE2_H      := 160.0

var _fire_rain_running := false

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 3
	_spawn_trees()
	_spawn_fire_hazards()
	_spawn_carnival_bell()
	_spawn_monkey_swarm()
	_spawn_clone_decoy_zone()
	_spawn_kuttichathan()
	_spawn_powerups()
	_spawn_npcs()
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
	_add_platform(1500.0, 200.0, 80.0, Color(0.45, 0.22, 0.08, 1.0))

	# Bell hitbox Area2D — detected by coconut projectiles
	var bell := Area2D.new()
	bell.name = "CarnivalBell"
	bell.collision_layer = 8   # layer 4 = bells / interactables
	bell.collision_mask  = 0
	bell.position        = Vector2(1500.0, 190.0)
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
	var _rung := false
	bell.area_entered.connect(func(area: Area2D) -> void:
		if _rung: return
		if area.is_in_group("coconut"):
			_rung = true
			_add_powerup($PowerUps, 1500.0, 185.0, "nut")
			_add_powerup($PowerUps, 1540.0, 185.0, "nut")
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
	var already_hit := false
	decoy.body_entered.connect(func(body_node: Node) -> void:
		if already_hit or not body_node.is_in_group("player"): return
		# Only triggers on sword swing (sword_phase > 0)
		if not (body_node.get("sword_phase") > 0): return
		already_hit = true
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
	thoma.position = Vector2(200.0, GROUND_Y - 10.0)
	add_child(thoma)
	# Aniyandi Ravi — Phase 3 swing race reappears here too
	var ravi: Node2D = preload("res://scenes/AniyandyRavi.tscn").instantiate()
	ravi.position = Vector2(2200.0, GROUND_Y - 10.0)
	add_child(ravi)
	# Stop fire rain when boss dies (game_won / next scene fires)
	GameManager.game_won.connect(func() -> void: _fire_rain_running = false)
