extends "res://scenes/BaseAct.gd"

## Act V — Pey Komban's Rampage (FINALE)
## Sacred temple grove. Stay on trees — ground combat is fatal.
## game_won signal fires on boss death; Victory overlay handles end screen.

const ACT_TRIGGER_X := 7800.0   # fallback only — game_won fires first

const ZONE_TREES   := 24
const ZONE_X_FROM  := 150.0
const ZONE_X_TO    := 7650.0
const ZONE_H       := 260.0   # massive ancient trees

func _ready() -> void:
	# No _next_scene — Pey Komban death emits game_won instead
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 0   # finale — no further act to unlock
	_spawn_trees()
	_spawn_pey_komban()
	_spawn_powerups()
	_spawn_npcs()
	_connect_player_to_hud()
	_queue_hint("⚠️ STAY OFF THE GROUND — one charge and you're done!", 1.5, 7.0)

func _spawn_trees() -> void:
	var tint := Color(0.85, 0.75, 0.3, 1.0)   # ancient gold-green sacred grove
	var xs   := _linspace(ZONE_X_FROM, ZONE_X_TO, ZONE_TREES)
	for i: int in xs.size():
		_add_tree($Trees, xs[i], ZONE_H, 0.05 * (1 if i % 2 == 0 else -1), tint)

func _spawn_pey_komban() -> void:
	var boss: Node2D = preload("res://scenes/PeyKomban.tscn").instantiate()
	boss.position = Vector2(4000.0, GROUND_Y)
	$Enemies.add_child(boss)

func _spawn_powerups() -> void:
	var data := [
		[500.0,  GROUND_Y, "heart"],
		[1500.0, GROUND_Y, "nut"],
		[2800.0, 240.0,    "porotta"],   # elevated — crown-leap required
		[4800.0, GROUND_Y, "heart"],
		[5800.0, GROUND_Y, "nut"],
		[6800.0, GROUND_Y, "toddy"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])
	# Elevated platform holding the curry
	_add_platform(2800.0, 240.0, 140.0, Color(0.35, 0.25, 0.12, 1.0))

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(300.0, GROUND_Y - 10.0)
	add_child(thoma)
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(700.0, GROUND_Y - 10.0)
	add_child(soniya)
