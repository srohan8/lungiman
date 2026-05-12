extends "res://scenes/BaseAct.gd"

## PROLOGUE — "Muruthikudi at Dusk"
## Tutorial scene. Golden hour. Teaches climb, combat, river crossing.

const NEXT_SCENE    := "res://scenes/Act1.tscn"
const ACT_TRIGGER_X := 7800.0

const ZONE1_TREES  := 14
const ZONE1_X_FROM := 320.0
const ZONE1_X_TO   := 2780.0
const ZONE1_H      := 185.0

const ZONE2_TREES  := 9
const ZONE2_X_FROM := 2900.0
const ZONE2_X_TO   := 4350.0
const ZONE2_H      := 200.0

const ZONE3_TREES  := 12
const ZONE3_X_FROM := 4450.0
const ZONE3_X_TO   := 6750.0
const ZONE3_H      := 240.0

const RIVER_X := 2860.0
const RIVER_W := 500.0

func _ready() -> void:
	_next_scene = NEXT_SCENE
	_trigger_x  = ACT_TRIGGER_X
	_spawn_trees()
	_spawn_river()
	_spawn_crabs()
	_spawn_ghosts()
	_spawn_npcs()
	_spawn_powerups()
	_connect_player_to_hud()
	_queue_hint("🌴 Press [E] near a tree to climb!", 2.0, 5.5)

func _spawn_trees() -> void:
	var tint := Color(0.95, 0.85, 0.45, 1.0)   # golden hour
	var z1 := _linspace(ZONE1_X_FROM, ZONE1_X_TO, ZONE1_TREES)
	for i: int in z1.size():
		_add_tree($Trees, z1[i], ZONE1_H, 0.08 * (1 if i % 2 == 0 else -1), tint)
	var z2 := _linspace(ZONE2_X_FROM, ZONE2_X_TO, ZONE2_TREES)
	for x: float in z2:
		_add_tree($Trees, x, ZONE2_H, 0.0, tint)
	var z3 := _linspace(ZONE3_X_FROM, ZONE3_X_TO, ZONE3_TREES)
	for i: int in z3.size():
		_add_tree($Trees, z3[i], ZONE3_H, 0.06 * (1 if i % 2 == 0 else -1), tint)

func _spawn_river() -> void:
	var water_y := GROUND_Y - 18.0
	var vis := ColorRect.new()
	vis.color    = Color(0.06, 0.22, 0.70, 0.60)
	vis.size     = Vector2(RIVER_W, 45.0)
	vis.position = Vector2(RIVER_X, water_y - 22.0)
	vis.z_index  = -1
	add_child(vis)
	var river := Area2D.new()
	river.collision_layer = 0
	river.collision_mask  = 2
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size     = Vector2(RIVER_W, 55.0)
	col.shape      = shape
	river.position = Vector2(RIVER_X + RIVER_W * 0.5, GROUND_Y + 5.0)
	river.add_child(col)
	river.body_entered.connect(_on_river_entered)
	river.body_exited.connect(_on_river_exited)
	add_child(river)
	_spawn_boat($Trees, RIVER_X + 80.0,  water_y)
	_spawn_boat($Trees, RIVER_X + 250.0, water_y)
	_spawn_boat($Trees, RIVER_X + 420.0, water_y)
	var croc: Node2D = preload("res://scenes/Crocodile.tscn").instantiate()
	croc.position    = Vector2(RIVER_X + RIVER_W * 0.5, GROUND_Y)
	croc.patrol_left  = RIVER_X
	croc.patrol_right = RIVER_X + RIVER_W
	$Enemies.add_child(croc)

func _on_river_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("enter_water"):
		body.enter_water()

func _on_river_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("exit_water"):
		body.exit_water()

func _spawn_crabs() -> void:
	for x: float in [900.0, 1300.0, 1600.0, 1900.0, 2500.0]:
		var crab: Node2D = preload("res://scenes/CoconutCrab.tscn").instantiate()
		crab.position = Vector2(x, GROUND_Y)
		$Enemies.add_child(crab)

func _spawn_ghosts() -> void:
	var xs := _linspace(4500.0, 6700.0, 6)
	for i: int in xs.size():
		var ghost: Node2D = preload("res://scenes/GhostClone.tscn").instantiate()
		ghost.position = Vector2(xs[i], GROUND_Y)
		ghost.is_real  = (i == 3)
		$Enemies.add_child(ghost)

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(400.0, GROUND_Y - 10.0)
	add_child(thoma)
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(3400.0, GROUND_Y - 10.0)
	add_child(soniya)

func _spawn_powerups() -> void:
	var data := [
		[450.0,  235.0,    "heart"],
		[920.0,  235.0,    "nut"],
		[1520.0, GROUND_Y, "heart"],
		[1820.0, GROUND_Y, "nut"],
		[3920.0, GROUND_Y, "nut"],
		[4820.0, GROUND_Y, "heart"],
		[5220.0, GROUND_Y, "curry"],
		[5620.0, GROUND_Y, "nut"],
		[6020.0, GROUND_Y, "rum"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])
	_add_platform(RIVER_X + RIVER_W * 0.5, 210.0, 100.0)
	_add_powerup($PowerUps, RIVER_X + RIVER_W * 0.5, 205.0, "chai")
