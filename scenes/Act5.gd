extends "res://scenes/BaseAct.gd"

## Act V — Pey Komban's Rampage (FINALE)
## Sacred temple grove. Stay on trees — ground combat is fatal.
## game_won signal fires on boss death; Victory overlay handles end screen.

const ACT_TRIGGER_X := 7800.0   # fallback only — game_won fires first

const ZONE_TREES   := 24
const ZONE_X_FROM  := 150.0
const ZONE_X_TO    := 7650.0
const ZONE_H       := 388.0   # massive ancient trees

func _ready() -> void:
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 0
	_apply_sky(Color(0.04, 0.05, 0.10))   # near-black sacred grove night
	_spawn_trees()
	_spawn_trail_stumps()
	_spawn_fireflies()
	_spawn_pey_komban()
	_spawn_powerups()
	_spawn_npcs()
	_connect_player_to_hud()
	_queue_hint("⚠️ STAY OFF THE GROUND — one charge and you're done!", 1.5, 7.0)
	_start_footstep_shakes()

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

func _spawn_powerups() -> void:
	var data := [
		[500.0,  GROUND_Y, "heart"],
		[1500.0, GROUND_Y, "nut"],
		[2800.0, 358.0,    "porotta"],   # elevated — crown-leap required
		[4800.0, GROUND_Y, "heart"],
		[5800.0, GROUND_Y, "nut"],
		[6800.0, GROUND_Y, "toddy"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])
	# Elevated platform holding the curry
	_add_platform(2800.0, 358.0, 140.0, Color(0.35, 0.25, 0.12, 1.0))

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(300.0, GROUND_Y - 10.0)
	add_child(thoma)
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(700.0, GROUND_Y - 10.0)
	add_child(soniya)
