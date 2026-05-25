extends CharacterBody2D

## Odiyan — Act III Boss. Shapeshifter. Only vulnerable during transform flash.
## weakness_revealed (from Tracks quest) extends the flash window 0.6s → 0.9s.

const MAX_HP           := 10   # 10 transform windows to close the fight
const GRAVITY          := 1800.0
const HUMAN_SPEED      := 0.0
const BULL_SPEED       := 200.0
const DOG_SPEED        := 140.0
const CYCLE_HUMAN      := 2.5
const TRANSFORM_WINDOW := 2.5          # vulnerable window (base) — 2.5s to react
const TRANSFORM_WINDOW_REVEALED := 3.5 # extended by Odiyan's Tracks quest
const BULL_CHARGE_DUR  := 1.2
const DOG_BITE_DUR     := 0.5
const BULL_DMG         := 30
const DOG_DMG          := 18
const FLASH_DURATION   := 0.25

enum Form { HUMAN, TRANSFORM, BULL, DOG }

var hp:               int   = MAX_HP
var form:             Form  = Form.HUMAN
var form_timer:       float = CYCLE_HUMAN
var dir:              int   = 1
var weakness_revealed: bool = false
var _flash_timer:     float = 0.0
var hit_cooldown:     float = 0.0
var _player: Node2D         = null
var _spr: AnimatedSprite2D  = null
var _pulse_tween:     Tween = null   # looping transform pulse — killed when form changes

const ODIYAN_FRAME_W := 672.0   # 56 SVG units × scale 12
const ODIYAN_FRAME_H := 816.0   # 68 SVG units × scale 12

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask  = 1
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	_player = get_tree().get_first_node_in_group("player")
	GameManager.set_boss(MAX_HP)
	_load_sprite()
	_apply_form_visual()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/odiyan_sheet.png"
	const TARGET_H := 110.0
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	# Sheet: 3 cells horizontal — human | bull | dog
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 3, 1, [
		{"name": "human",     "frames": [0],       "fps": 2.0,  "loop": true},
		{"name": "transform", "frames": [0, 1, 2], "fps": 4.0,  "loop": false},
		{"name": "bull",      "frames": [1],       "fps": 4.0,  "loop": true},
		{"name": "dog",       "frames": [2],       "fps": 6.0,  "loop": true},
	], Color(0.75, 0.75, 0.75, 1.0))
	var s: float = GameManager.grid_sheet_scale(PATH, 1, TARGET_H)
	_spr.scale = Vector2(s, s)
	_spr.play("human")
	add_child(_spr)
	$ColorRect.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			# Hit-flash done — if still in TRANSFORM, resume the pulse tween
			if form == Form.TRANSFORM:
				if _pulse_tween != null:
					_pulse_tween.play()
				else:
					_apply_form_visual()
			else:
				_apply_form_visual()

	form_timer -= delta
	match form:
		Form.HUMAN:
			velocity.x = 0.0
			if form_timer <= 0.0:
				form       = Form.TRANSFORM
				form_timer = TRANSFORM_WINDOW_REVEALED if weakness_revealed else TRANSFORM_WINDOW
		Form.TRANSFORM:
			velocity.x = 0.0
			if form_timer <= 0.0:
				form       = Form.BULL if randf() > 0.4 else Form.DOG
				form_timer = BULL_CHARGE_DUR if form == Form.BULL else DOG_BITE_DUR
				_apply_form_visual()
		Form.BULL:
			if is_instance_valid(_player):
				dir = int(sign(_player.global_position.x - global_position.x))
			velocity.x = BULL_SPEED * dir
			if _spr != null: _spr.flip_h = (dir < 0)
			if form_timer <= 0.0:
				form       = Form.HUMAN
				form_timer = CYCLE_HUMAN
				_apply_form_visual()
		Form.DOG:
			if is_instance_valid(_player):
				dir = int(sign(_player.global_position.x - global_position.x))
			velocity.x = DOG_SPEED * dir
			if _spr != null: _spr.flip_h = (dir < 0)
			if form_timer <= 0.0:
				form       = Form.HUMAN
				form_timer = CYCLE_HUMAN
				_apply_form_visual()

	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

func _apply_form_visual() -> void:
	# Kill any existing pulse tween whenever form changes
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null

	modulate = Color.WHITE
	if _spr == null: return
	match form:
		Form.HUMAN:
			if _spr.animation != "human": _spr.play("human")
		Form.TRANSFORM:
			if _spr.animation != "transform": _spr.play("transform")
			# ── Visible pulsing flash — player must know NOW is the moment ──
			# Rapid yellow ↔ white pulse so there's no way to miss the window.
			_pulse_tween = create_tween().set_loops()
			_pulse_tween.tween_property(self, "modulate",
					Color(1.0, 1.0, 0.10, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
			_pulse_tween.tween_property(self, "modulate",
					Color(1.0, 1.0, 1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
			# HUD hint — only on first transform (hint label may not exist yet)
			var hud: Node = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_hint"):
				hud.show_hint("⚡ ATTACK NOW — hit Odiyan during the flash!", 2.0)
		Form.BULL:
			if _spr.animation != "bull": _spr.play("bull")
		Form.DOG:
			if _spr.animation != "dog": _spr.play("dog")

func reveal_weakness() -> void:
	weakness_revealed = true

## Pre-boss tease — fires when the player finds hoof-print #3.
## Odiyan briefly appears in dog form, charges toward the player, then flees.
## No HP damage is dealt — this is a glimpse, not the real fight.
## If already in TRANSFORM/BULL/DOG from the boss-fight cycle, does nothing.
func lunge_tease(target_pos: Vector2) -> void:
	if form != Form.HUMAN: return   # real fight already underway
	form       = Form.DOG
	form_timer = 0.80
	dir        = int(sign(target_pos.x - global_position.x))
	_apply_form_visual()
	# After 0.85s: flee in the opposite direction, then return to idle
	get_tree().create_timer(0.85).timeout.connect(func() -> void:
		if not is_instance_valid(self): return
		if form != Form.DOG: return   # fight started meanwhile — don't interfere
		dir        = -dir
		form_timer = 1.6
		get_tree().create_timer(1.6).timeout.connect(func() -> void:
			if not is_instance_valid(self): return
			if form == Form.DOG:   # still in flee (not in real fight)
				form       = Form.HUMAN
				form_timer = CYCLE_HUMAN
				_apply_form_visual()
		)
	)

func take_damage(dmg: int) -> void:
	if form != Form.TRANSFORM: return
	hp -= 1   # hit-count system: 1 HP per hit
	GameManager.boss_take_damage(1)
	_flash_timer = FLASH_DURATION
	# Pause the pulse tween briefly while showing the hit-flash (red)
	if _pulse_tween != null: _pulse_tween.pause()
	modulate = Color(1.0, 0.3, 0.3, 1.0)
	if hp <= 0: _die()

func _die() -> void:
	GameManager.clear_boss()
	GameManager.boss_grit_drop()   # Grit: 60 → 40. Low → Flicker.
	GameManager.score += 220
	GameManager.show_score_popup(position + Vector2(0, -50), 220, Color(0.5, 0.8, 0.3))
	_drop_powerup()
	# 2-second beat before the venom takes hold — player walks a few steps, then collapses.
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		GameManager.trigger_hallucination()
	)
	queue_free()

func _drop_powerup() -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type     = "toddy"   # Odiyan's reward — earned it, but you'll wobble
	pu.position = position + Vector2(0, -20)
	get_parent().call_deferred("add_child", pu)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or hit_cooldown > 0.0: return
	var dmg := BULL_DMG if form == Form.BULL else DOG_DMG if form == Form.DOG else 0
	if dmg > 0:
		body.take_damage(dmg)
		hit_cooldown = 1.5
