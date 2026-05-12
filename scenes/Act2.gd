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
