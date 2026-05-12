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

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 3
	_spawn_trees()
	_spawn_kuttichathan()
	_spawn_powerups()
	_spawn_npcs()
	_connect_player_to_hud()
	_queue_hint("💥 Clones EXPLODE when hit — find the real one first!", 2.0, 6.0)

func _spawn_trees() -> void:
	var tint := Color(0.95, 0.7, 0.4, 1.0)   # reddish-orange fire carnival
	var z1 := _linspace(ZONE1_X_FROM, ZONE1_X_TO, ZONE1_TREES)
	for x: float in z1:
		_add_tree($Trees, x, ZONE1_H, 0.0, tint)
	var z2 := _linspace(ZONE2_X_FROM, ZONE2_X_TO, ZONE2_TREES)
	for x: float in z2:
		_add_tree($Trees, x, ZONE2_H, 0.0, tint)

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
	thoma.position = Vector2(350.0, GROUND_Y - 10.0)
	add_child(thoma)
