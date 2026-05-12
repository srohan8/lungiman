extends "res://scenes/BaseAct.gd"

## Act I — "Yakshi's Hollow"
## Bamboo grove. Muruthikudi river bend. Dusk → nightfall.
## Features: river zone + boats + crocs, elevated platforms, decoy clones, Yakshi boss.

const NEXT_SCENE    := "res://scenes/Act2.tscn"
const ACT_TRIGGER_X := 7800.0

# Tree zones
const ZONE1_TREES  := 18
const ZONE1_X_FROM := 200.0
const ZONE1_X_TO   := 3500.0
const ZONE1_H      := 220.0
const ZONE1_LEAN   := 0.05

const ZONE2_TREES  := 16
const ZONE2_X_FROM := 3600.0
const ZONE2_X_TO   := 7600.0
const ZONE2_H      := 260.0
const ZONE2_LEAN   := 0.04

# River zone (gap in Zone 1)
const RIVER_X      := 2200.0
const RIVER_W      := 800.0

# Ghost clones — 5 decoys + 1 real (index 2)
const GHOST_COUNT  := 6
const GHOST_X_FROM := 1500.0
const GHOST_X_TO   := 6500.0

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 2   # completing Act I unlocks Act II
	_spawn_trees()
	_spawn_elevated_platforms()
	_build_river()
	_spawn_yakshi()
	_spawn_ghosts()
	_spawn_powerups()
	_spawn_npcs()
	_connect_player_to_hud()
	# Timed hints — river hint fires just before player reaches the water
	_queue_hint("⚠️ River ahead — ride a boat or CLIMB over!", 3.5, 5.5)

func _spawn_trees() -> void:
	var tint := Color(0.6, 0.9, 0.6, 1.0)   # dark green bamboo-grove
	var z1 := _linspace(ZONE1_X_FROM, ZONE1_X_TO, ZONE1_TREES)
	for i: int in z1.size():
		_add_tree($Trees, z1[i], ZONE1_H, ZONE1_LEAN * (1 if i % 2 == 0 else -1), tint)
	var z2 := _linspace(ZONE2_X_FROM, ZONE2_X_TO, ZONE2_TREES)
	for i: int in z2.size():
		_add_tree($Trees, z2[i], ZONE2_H, ZONE2_LEAN * (1 if i % 2 == 0 else -1), tint)

## Four elevated platforms to reward climbing over ground-rushing
func _spawn_elevated_platforms() -> void:
	var plank := Color(0.28, 0.18, 0.08, 1.0)
	_add_platform( 550.0, 240.0, 150.0, plank)  # near start — teaches vertical
	_add_platform(1250.0, 235.0, 130.0, plank)  # mid Zone 1
	_add_platform(3550.0, 220.0, 170.0, plank)  # just past river, rewards leapers
	_add_platform(5100.0, 230.0, 150.0, plank)  # deep Zone 2

func _build_river() -> void:
	var water_y := GROUND_Y - 18.0

	# Water visual
	var vis := ColorRect.new()
	vis.color    = Color(0.06, 0.22, 0.70, 0.60)
	vis.size     = Vector2(RIVER_W, 45.0)
	vis.position = Vector2(RIVER_X, water_y - 22.0)
	vis.z_index  = -1
	add_child(vis)

	# River hazard area
	var river := Area2D.new()
	river.collision_layer = 0
	river.collision_mask  = 2
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size     = Vector2(RIVER_W, 55.0)
	col.shape      = shape
	river.position = Vector2(RIVER_X + RIVER_W * 0.5, GROUND_Y + 5.0)
	river.add_child(col)
	river.body_entered.connect(_on_river_entered)
	river.body_exited.connect(_on_river_exited)
	add_child(river)

	# 3 boats spaced across the river for safe crossing
	_spawn_boat($Trees, RIVER_X + 110.0, water_y)
	_spawn_boat($Trees, RIVER_X + 390.0, water_y)
	_spawn_boat($Trees, RIVER_X + 670.0, water_y)

	# 2 crocodiles patrolling the river zone
	for cx: float in [RIVER_X + 180.0, RIVER_X + 560.0]:
		var croc: Node2D = preload("res://scenes/Crocodile.tscn").instantiate()
		croc.position     = Vector2(cx, GROUND_Y)
		croc.patrol_left  = RIVER_X
		croc.patrol_right = RIVER_X + RIVER_W
		$Enemies.add_child(croc)

	# Chai powerup on elevated platform ABOVE the river — reward for leaping
	_add_platform(RIVER_X + RIVER_W * 0.5, 210.0, 100.0)
	_add_powerup($PowerUps, RIVER_X + RIVER_W * 0.5, 205.0, "chai")

func _on_river_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("enter_water"):
			body.enter_water()

func _on_river_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("exit_water"):
			body.exit_water()

func _spawn_yakshi() -> void:
	var yakshi: Node2D = preload("res://scenes/Yakshi.tscn").instantiate()
	yakshi.position = Vector2(6800.0, GROUND_Y)
	$Enemies.add_child(yakshi)

func _spawn_ghosts() -> void:
	var xs := _linspace(GHOST_X_FROM, GHOST_X_TO, GHOST_COUNT)
	for i: int in xs.size():
		var ghost: Node2D = preload("res://scenes/GhostClone.tscn").instantiate()
		ghost.position = Vector2(xs[i], GROUND_Y)
		ghost.is_real  = (i == 2)   # index 2 is the real Yakshi decoy
		$Enemies.add_child(ghost)

func _spawn_powerups() -> void:
	var data := [
		[ 450.0, 235.0,    "heart"],   # on first elevated platform
		[1250.0, 228.0,    "nut"],     # on second elevated platform
		[3000.0, GROUND_Y, "rum"],
		[4500.0, GROUND_Y, "nut"],
		[5800.0, GROUND_Y, "heart"],
		[6200.0, GROUND_Y, "chai"],    # second chai near Yakshi for insurance
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])

func _spawn_npcs() -> void:
	# Brother Thoma near the very start
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(400.0, GROUND_Y - 10.0)
	add_child(thoma)
	# Soniya's Chaya Kada — placed before the ghost zone
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(3400.0, GROUND_Y - 10.0)
	add_child(soniya)
