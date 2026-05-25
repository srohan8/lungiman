extends Node2D

## Karinkanni — Act IV Boss. Floating eye. Only hittable from tree crowns.
## Eye opens briefly → fire paralysis ray → close. 3 coconut hits to kill.

const MAX_HP          := 9   # 9 hits; eye interval drops to 3s when ≤3 HP remaining
const FLOAT_Y         := 150.0
const BOB_AMPLITUDE   := 12.0
const BOB_SPEED       := 1.8
const OPEN_INTERVAL   := 5.0   # seconds between openings (phase 2: 3.0)
const OPEN_DURATION   := 1.5   # seconds eye stays open
const RAY_DMG         := 0     # paralysis, no direct HP damage
const FLASH_DURATION  := 0.25

var hp:             int   = MAX_HP
var _eye_open:      bool  = false
var _open_timer:    float = 0.0
var _interval_timer: float = OPEN_INTERVAL
var _bob_t:         float = 0.0
var _flash_timer:   float = 0.0
var hit_cooldown:   float = 0.0
var _player: Node2D       = null
var _spr: AnimatedSprite2D = null

const KK_FRAME_W := 5400.0   # 60 SVG units × scale 90
const KK_FRAME_H := 5400.0   # 60 SVG units × scale 90

func _ready() -> void:
	add_to_group("enemies")
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	_player = get_tree().get_first_node_in_group("player")
	GameManager.set_boss(MAX_HP)
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/karinkanni_sheet.png"
	const TARGET_H := 90.0
	_spr = AnimatedSprite2D.new()
	# Sheet: 3 cells horizontal — closed | half-open | fully open
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 3, 1, [
		{"name": "closed",  "frames": [0],       "fps": 3.0, "loop": true},
		{"name": "opening", "frames": [0, 1, 2], "fps": 6.0, "loop": false},
		{"name": "open",    "frames": [2],       "fps": 3.0, "loop": true},
	], Color(0.55, 0.0, 0.80, 0.92))
	var s: float = GameManager.grid_sheet_scale(PATH, 1, TARGET_H)
	_spr.scale = Vector2(s, s)
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	_spr.play("closed")
	add_child(_spr)
	$Body.visible = false

func _process(delta: float) -> void:
	# Bob
	_bob_t      += delta * BOB_SPEED
	position.y   = FLOAT_Y + sin(_bob_t) * BOB_AMPLITUDE

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE

	hit_cooldown = maxf(0.0, hit_cooldown - delta)

	if not _eye_open:
		if _spr != null and _spr.animation != "closed": _spr.play("closed")
		_interval_timer -= delta
		if _interval_timer <= 0.0:
			_eye_open       = true
			_open_timer     = OPEN_DURATION
			_interval_timer = OPEN_INTERVAL if hp > 3 else 3.0
			if _spr != null: _spr.play("opening")
			_fire_ray()
	else:
		if _spr != null and _spr.animation == "opening" and not _spr.is_playing():
			_spr.play("open")
		_open_timer -= delta
		if _open_timer <= 0.0:
			_eye_open = false
			if _spr != null: _spr.play("closed")

func _fire_ray() -> void:
	if not is_instance_valid(_player): return
	GameManager.activate_paralysis(2.0)
	# Visual ray beam from eye to player
	var ray := Line2D.new()
	ray.width           = 4.0
	ray.default_color   = Color(0.7, 0.0, 1.0, 0.85)
	ray.z_index         = 5
	var target_local := to_local(_player.global_position)
	ray.add_point(Vector2.ZERO)
	ray.add_point(target_local)
	add_child(ray)
	# Fade and remove beam
	var tw := create_tween()
	tw.tween_property(ray, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(ray.queue_free)

func take_damage(_dmg: int) -> void:
	if not _eye_open: return
	if hit_cooldown > 0.0: return
	hp -= 1   # hit-count system: 1 HP per hit
	GameManager.boss_take_damage(1)
	_flash_timer = FLASH_DURATION
	modulate     = Color(1.0, 1.0, 1.0, 1.0)
	hit_cooldown = 0.4
	if hp <= 0: _die()

func _die() -> void:
	GameManager.clear_boss()
	GameManager.boss_grit_drop()   # Grit: 40 → 20. Flicker → Sputter. The lamp is almost out.
	GameManager.score += 300
	GameManager.show_score_popup(position - Vector2(0, 40), 300, Color(0.60, 0.30, 1.0))
	_drop_powerup()
	queue_free()

func _drop_powerup() -> void:
	for t: String in ["heart", "nut"]:
		var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
		pu.type     = t
		pu.position = position + Vector2(randf_range(-25, 25), 20)
		get_parent().add_child(pu)
