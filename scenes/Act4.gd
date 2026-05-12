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
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 5
	_apply_sky(Color(0.10, 0.18, 0.30))   # rain-drenched deep blue-grey
	_spawn_trees()
	_spawn_karinkanni()
	_spawn_powerups()
	_spawn_npcs()
	_spawn_rising_water()
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
		[5000.0, GROUND_Y, "toddy"],
		[6500.0, GROUND_Y, "heart"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(200.0, GROUND_Y - 10.0)
	add_child(thoma)
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(500.0, GROUND_Y - 10.0)
	add_child(soniya)
	# Sr. Devi — Bell of Bhadrakali quest giver (Phase 5 quest, NPC present now)
	var devi: Node2D = preload("res://scenes/SrDevi.tscn").instantiate()
	devi.position = Vector2(1400.0, GROUND_Y - 10.0)
	add_child(devi)

## Rising water visual — cosmetic pressure. Water line creeps up over 90 seconds.
func _spawn_rising_water() -> void:
	var water := ColorRect.new()
	water.color    = Color(0.06, 0.18, 0.55, 0.50)
	water.size     = Vector2(8200.0, 30.0)
	water.position = Vector2(0.0, GROUND_Y - 5.0)
	water.z_index  = 2
	add_child(water)
	# Slow tween upward — purely visual, creates urgency without instant death
	var tw := create_tween()
	tw.tween_property(water, "position:y", GROUND_Y - 80.0, 90.0)
	# Rain drops visual — thin streaks falling
	for i: int in 18:
		var drop := ColorRect.new()
		drop.color    = Color(0.5, 0.7, 1.0, 0.30)
		drop.size     = Vector2(2.0, 14.0)
		drop.position = Vector2(randf_range(0.0, 8200.0), randf_range(0.0, 460.0))
		drop.z_index  = 3
		add_child(drop)
		var dt := create_tween()
		dt.set_loops()
		dt.tween_property(drop, "position:y", drop.position.y + 460.0, randf_range(1.2, 2.2))
		dt.tween_property(drop, "position:y", -14.0, 0.0)
