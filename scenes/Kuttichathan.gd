extends CharacterBody2D

## Kuttichathan — Act II Boss. Spawns decoy clones. Vulnerable during landing stun.

const MAX_HP           := 4
const SPEED            := 72.0
const GRAVITY          := 1800.0
const CLONE_RANGE      := 500.0
const CLONE_INTERVAL   := 6.0
const LUNGE_SPEED      := 340.0
const LUNGE_DURATION   := 0.35
const STUN_DURATION    := 0.80
const FLASH_DURATION   := 0.25

var hp:           int   = MAX_HP
var dir:          int   = 1
var clone_timer:  float = CLONE_INTERVAL
var _lunge_t:     float = 0.0
var _stun_t:      float = 0.0
var _lunging:     bool  = false
var _stunned:     bool  = false
var _flash_timer: float = 0.0
var _player: Node2D        = null
var _spr: AnimatedSprite2D = null
var _eye: ColorRect        = null
var _eye_t: float          = 0.0
const EYE_BLINK_CYCLE := 0.8

const KUTTI_FRAME_W := 1936.0   # 44 SVG units × scale 44
const KUTTI_FRAME_H := 2640.0   # 60 SVG units × scale 44

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask  = 1
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	_player = get_tree().get_first_node_in_group("player")
	GameManager.set_boss(MAX_HP)
	_load_sprite()
	_add_eye()

func _add_eye() -> void:
	_eye = ColorRect.new()
	_eye.color    = Color(1.0, 0.85, 0.0, 1.0)   # bright amber eye
	_eye.size     = Vector2(10.0, 10.0)
	_eye.position = Vector2(-5.0, -42.0)
	add_child(_eye)

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/kuttichathan_sheet.png"
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -60.0 * 0.5)
	var sf := SpriteFrames.new()
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		var anims := [["idle", [0,1], 4.0, true], ["spawn", [2], 6.0, false], ["ride", [3], 8.0, true]]
		for a: Array in anims:
			sf.add_animation(a[0])
			sf.set_animation_loop(a[0], a[3])
			sf.set_animation_speed(a[0], a[2])
			for fi: int in a[1]:
				var at := AtlasTexture.new()
				at.atlas  = sheet
				at.region = Rect2(fi * KUTTI_FRAME_W, 0, KUTTI_FRAME_W, KUTTI_FRAME_H)
				sf.add_frame(a[0], at)
	else:
		sf.add_animation("idle")
		sf.set_animation_loop("idle", true)
		var img := Image.create(int(KUTTI_FRAME_W), int(KUTTI_FRAME_H), false, Image.FORMAT_RGBA8)
		img.fill(Color(1.0, 0.45, 0.05, 0.95))
		sf.add_frame("idle", ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.scale = Vector2(60.0 / KUTTI_FRAME_H, 60.0 / KUTTI_FRAME_H)
	_spr.play("idle")
	add_child(_spr)
	$ColorRect.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color(1.0, 0.45, 0.05, 0.95)

	if _stunned:
		velocity.x  = 0.0
		_stun_t    -= delta
		if _stun_t <= 0.0: _stunned = false
		move_and_slide()
		return

	if _lunging:
		var spd := LUNGE_SPEED * (1.6 if hp <= 2 else 1.0)
		velocity.x = spd * dir
		_lunge_t  -= delta
		if _lunge_t <= 0.0:
			_lunging  = false
			_stunned  = true
			_stun_t   = STUN_DURATION
	else:
		velocity.x   = SPEED * dir
		clone_timer -= delta
		if clone_timer <= 0.0:
			clone_timer = CLONE_INTERVAL
			_spawn_clone()
		if position.x < 200.0:    dir =  1
		elif position.x > 7400.0: dir = -1
		if _spr != null:
			_spr.flip_h = (dir < 0)
			if _spr.animation != "idle": _spr.play("idle")
		# Lunge at player — Phase 2 (hp ≤ 2): faster ride lunge
		if is_instance_valid(_player):
			var dx := _player.global_position.x - global_position.x
			if absf(dx) < CLONE_RANGE and absf(dx) > 80.0:
				dir      = int(sign(dx))
				_lunging = true
				_lunge_t = LUNGE_DURATION
				if hp <= 2 and _spr != null: _spr.play("ride")

	move_and_slide()
	# Blink the eye open/closed — visual cue that this is the real one
	if _eye != null:
		_eye_t += delta
		var cycle := fmod(_eye_t, EYE_BLINK_CYCLE)
		_eye.size.y = 10.0 if cycle < EYE_BLINK_CYCLE * 0.85 else 2.0

func _spawn_clone() -> void:
	var clone: Node2D = preload("res://scenes/GhostClone.tscn").instantiate()
	clone.position = position + Vector2(randf_range(-120, 120), 0)
	clone.is_real  = false
	get_parent().add_child(clone)

func take_damage(dmg: int) -> void:
	if not _stunned: return
	hp -= dmg
	GameManager.boss_take_damage(dmg)
	_flash_timer = FLASH_DURATION
	modulate     = Color(1.0, 1.0, 0.2, 1.0)
	if hp <= 2 and hp > 0:
		# Phase 2: shorter clone interval
		clone_timer = minf(clone_timer, 3.5)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_hint"):
			hud.show_hint("🔥 He\'s riding fireballs now!", 3.0)
	if hp <= 0: _die()

func _die() -> void:
	GameManager.clear_boss()
	GameManager.score += 250
	GameManager.show_score_popup(position - Vector2(0, 40), 250, Color(1.0, 0.55, 0.10))
	_drop_powerup()
	queue_free()

func _drop_powerup() -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type     = "nut"
	pu.position = position + Vector2(0, -20)
	get_parent().add_child(pu)
