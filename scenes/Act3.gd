extends "res://scenes/BaseAct.gd"

## Act III — "Odiyan's Hunt"
## Foggy hills. Only attack during Odiyan's 0.6s transform flash.
## Odiyan's Tracks mini-quest: find 4 hoof-prints → weakness_revealed on boss.

const NEXT_SCENE    := "res://scenes/Act4.tscn"
const ACT_TRIGGER_X := 7800.0

const ZONE_TREES   := 20
const ZONE_X_FROM  := 250.0
const ZONE_X_TO    := 7500.0
const ZONE_H       := 190.0

# Hoof-print positions (Odiyan's Tracks quest)
const TRACK_XS     := [700.0, 1800.0, 3200.0, 4000.0]

var _tracks_found  := 0
var _odiyan_ref: Node2D = null   # set when boss spawns

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 4
	QuestManager.activate_quest("odiyan_tracks")
	_spawn_trees()
	_spawn_odiyan()
	_spawn_tracks()
	_spawn_powerups()
	_spawn_npcs()
	_connect_player_to_hud()
	_queue_hint("⚡ Attack Odiyan ONLY during the transform flash!", 1.5, 6.0)

func _spawn_trees() -> void:
	var tint := Color(0.7, 0.7, 0.65, 1.0)   # foggy grey-green
	var xs   := _linspace(ZONE_X_FROM, ZONE_X_TO, ZONE_TREES)
	for i: int in xs.size():
		_add_tree($Trees, xs[i], ZONE_H, 0.03 * (1 if i % 2 == 0 else -1), tint)

func _spawn_odiyan() -> void:
	var boss: Node2D = preload("res://scenes/Odiyan.tscn").instantiate()
	boss.position = Vector2(4500.0, GROUND_Y)
	$Enemies.add_child(boss)
	_odiyan_ref = boss

## Spawn 4 hoof-print markers (Area2D + spirit smoke visual)
func _spawn_tracks() -> void:
	# Hoof print #2 sits on an elevated platform — teaches climbing to investigate
	_add_platform(1800.0, 240.0, 120.0)

	for i: int in TRACK_XS.size():
		var x   := TRACK_XS[i]
		var y   := 240.0 if i == 1 else GROUND_Y - 10.0   # #2 is elevated

		var marker := Area2D.new()
		marker.collision_layer = 0
		marker.collision_mask  = 2

		var col   := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 30.0
		col.shape    = shape
		marker.add_child(col)

		# Spirit smoke visual (glowing amber circle)
		var vis := ColorRect.new()
		vis.color    = Color(0.9, 0.6, 0.1, 0.70)
		vis.size     = Vector2(28.0, 28.0)
		vis.position = Vector2(-14.0, -14.0)
		marker.add_child(vis)

		marker.position = Vector2(x, y)

		# Each marker tracks its index so we can show different flashes
		var idx := i
		marker.body_entered.connect(func(body: Node) -> void:
			_on_track_entered(body, marker, idx)
		)
		add_child(marker)

func _on_track_entered(body: Node, marker: Node2D, _idx: int) -> void:
	if not body.is_in_group("player"):
		return
	if not Input.is_action_pressed("sword"):
		return   # must press Z near the smoke to "read" it
	_tracks_found += 1
	marker.queue_free()
	QuestManager.advance_quest("odiyan_tracks")
	# Flash HUD message per track found
	var hud := _get_hud()
	if hud and hud.has_method("show_hint"):
		hud.show_hint("🐾 Track %d/4 found!" % _tracks_found, 2.5)
	# All 4 found — reveal Odiyan's weakness
	if _tracks_found >= TRACK_XS.size():
		if is_instance_valid(_odiyan_ref) and _odiyan_ref.has_method("reveal_weakness"):
			_odiyan_ref.reveal_weakness()
		if hud and hud.has_method("show_hint"):
			hud.show_hint("💡 Odiyan's weakness revealed! Attack window extended!", 4.0)

func _spawn_powerups() -> void:
	var data := [
		[ 700.0, GROUND_Y, "heart"],
		[2200.0, GROUND_Y, "nut"],
		[3800.0, GROUND_Y, "rum"],
		[5500.0, GROUND_Y, "nut"],
		[7000.0, GROUND_Y, "heart"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(350.0, GROUND_Y - 10.0)
	add_child(thoma)
