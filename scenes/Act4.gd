extends "res://scenes/BaseAct.gd"

## Act IV — Karinkanni's Curse
## Rain-drenched mangroves. Karinkanni floats at y~150.
## MUST be on a tree crown (y~135) to hit her with coconuts.

const NEXT_SCENE    := "res://scenes/Act5.tscn"
const ACT_TRIGGER_X := 7800.0

const ZONE_TREES   := 22
const ZONE_X_FROM  := 200.0
const ZONE_X_TO    := 7600.0
const ZONE_H       := 240.0   # tall — crowns reach y~135, needed to hit Karinkanni

func _ready() -> void:
	_next_scene = NEXT_SCENE
	_trigger_x  = ACT_TRIGGER_X
	_spawn_trees()
	_spawn_karinkanni()
	_spawn_powerups()
	_spawn_npcs()
	_connect_player_to_hud()
	# Karinkanni hint fires early so players know BEFORE they waste ammo from ground
	_queue_hint("🥥 CLIMB a tree — Karinkanni floats too high to hit from the ground!", 1.5, 7.0)

func _spawn_trees() -> void:
	var tint := Color(0.3, 0.5, 0.4, 1.0)   # dark rain-soaked green
	var xs   := _linspace(ZONE_X_FROM, ZONE_X_TO, ZONE_TREES)
	for i: int in xs.size():
		_add_tree($Trees, xs[i], ZONE_H, 0.04 * (1 if i % 2 == 0 else -1), tint)

func _spawn_karinkanni() -> void:
	var boss: Node2D = preload("res://scenes/Karinkanni.tscn").instantiate()
	boss.position = Vector2(4000.0, 150.0)
	$Enemies.add_child(boss)

func _spawn_powerups() -> void:
	var data := [
		[600.0,  GROUND_Y, "nut"],
		[2000.0, GROUND_Y, "heart"],
		[3500.0, GROUND_Y, "nut"],
		[5000.0, GROUND_Y, "rum"],
		[6500.0, GROUND_Y, "heart"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(350.0, GROUND_Y - 10.0)
	add_child(thoma)
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(1200.0, GROUND_Y - 10.0)
	add_child(soniya)
