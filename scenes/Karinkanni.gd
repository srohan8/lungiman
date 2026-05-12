extends Node2D

## Karinkanni — Act IV Boss. Floating eye. Only hittable from tree crowns.
## Eye opens briefly → fire paralysis ray → close. 3 coconut hits to kill.

const MAX_HP          := 3
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
	_spr = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		for anim_name: String in ["closed", "opening", "open"]:
			sf.add_animation(anim_name)
			sf.set_animation_loop(anim_name, false)
			sf.set_animation_speed(anim_name, 3.0)
		# closed: frame 0
		var at0 := AtlasTexture.new(); at0.atlas = load(PATH)
		at0.region = Rect2(0, 0, KK_FRAME_W, KK_FRAME_H); sf.add_frame("closed", at0)
		# opening: frames 0→1
		for fi: int in [0, 1]:
			var at := AtlasTexture.new(); at.atlas = sheet
			at.region = Rect2(fi * KK_FRAME_W, 0, KK_FRAME_W, KK_FRAME_H)
			sf.add_frame("opening", at)
		# open: frame 2 (looping danger)
		var at2 := AtlasTexture.new(); at2.atlas = sheet
		at2.region = Rect2(2 * KK_FRAME_W, 0, KK_FRAME_W, KK_FRAME_H)
		sf.set_animation_loop("open", true)
		sf.add_frame("open", at2)
	else:
		sf.add_animation("closed")
		sf.set_animation_loop("closed", true)
		var img := Image.create(int(KK_FRAME_W), int(KK_FRAME_H), false, Image.FORMAT_RGBA8)
		img.fill(Color(0.55, 0.0, 0.80, 0.92))
		sf.add_frame("closed", ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
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
			_interval_timer = OPEN_INTERVAL if hp > 1 else 3.0
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

func take_damage(dmg: int) -> void:
	if not _eye_open: return
	if hit_cooldown > 0.0: return
	hp -= dmg
	GameManager.boss_take_damage(dmg)
	_flash_timer = FLASH_DURATION
	modulate     = Color(1.0, 1.0, 1.0, 1.0)
	hit_cooldown = 0.4
	if hp <= 0: _die()

func _die() -> void:
	GameManager.clear_boss()
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
