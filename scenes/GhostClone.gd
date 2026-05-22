extends CharacterBody2D

const SPEED        := 54.0
const GRAVITY      := 1800.0
const MAX_HP_REAL  := 35
const MAX_HP_FAKE  := 1
const CONTACT_DMG  := 12

var is_real:      bool  = false
var hp:           int   = 0
var dir:          int   = 1
var hit_cooldown: float = 0.0
var _bob_t:       float = 0.0
var _spr: AnimatedSprite2D = null

const GHOST_FRAME_W := 600.0   # 30 SVG units × scale 20
const GHOST_FRAME_H := 1200.0  # 60 SVG units × scale 20

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask  = 1
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	hp = MAX_HP_REAL if is_real else MAX_HP_FAKE
	_load_sprite()
	# Real clone: add a shadow sprite below feet (visual cue: no shadow = fake)
	if is_real:
		var shadow := ColorRect.new()
		shadow.color    = Color(0.0, 0.0, 0.0, 0.45)
		shadow.size     = Vector2(22.0, 6.0)
		shadow.position = Vector2(-11.0, 28.0)
		add_child(shadow)

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/ghost_sheet.png"
	const TARGET_H := 90.0
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	# Sheet: 2 cells horizontal — float1 | float2 (subtle drift)
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 2, 1, [
		{"name": "float", "frames": [0, 1], "fps": 3.0, "loop": true},
	], Color(0.4, 0.4, 1.0, 0.65))
	var s: float = GameManager.grid_sheet_scale(PATH, 1, TARGET_H)
	_spr.scale = Vector2(s, s)
	_spr.play("float")
	# Real = slightly opaque; fake = more transparent with pulse
	_spr.modulate = Color(1.0, 0.85, 1.0, 0.88) if is_real else Color(0.7, 0.7, 1.0, 0.65)
	add_child(_spr)
	$Visual.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	velocity.x  = SPEED * dir
	if position.x < 1400.0:   dir =  1
	elif position.x > 6600.0: dir = -1
	# Fake clone alpha pulse on sprite
	if not is_real and _spr != null:
		_bob_t          += delta * 3.0
		_spr.modulate.a  = 0.55 + 0.15 * sin(_bob_t)
	if _spr != null: _spr.flip_h = (dir < 0)
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0: _die()

func _die() -> void:
	if is_real and randf() < 0.5: _drop_powerup()
	GameManager.score += 15
	GameManager.show_score_popup(position + Vector2(0, -20), 15, Color(0.7, 0.7, 1.0))
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and hit_cooldown <= 0.0:
		body.take_damage(CONTACT_DMG)
		hit_cooldown = 1.0

func _drop_powerup() -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type = (["heart","nut","porotta","toddy","chai"])[randi() % 5]
	pu.position = position
	get_parent().add_child(pu)
