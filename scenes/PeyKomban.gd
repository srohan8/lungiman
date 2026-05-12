extends CharacterBody2D

## Pey Komban — Act V Finale Boss. Ground charge is fatal. Safe only on trees.
## Phase 2 (hp <= 3): faster charge. Rage (hp <= 1): alternating L+R charges.

const MAX_HP           := 5
const GRAVITY          := 1800.0
const PATROL_SPEED     := 55.0
const CHARGE_SPEED_P1  := 420.0
const CHARGE_SPEED_P2  := 520.0
const WINDUP_DURATION  := 0.50
const CHARGE_DURATION  := 0.60
const RECOVER_DURATION_P1 := 1.20
const RECOVER_DURATION_P2 := 0.70
const CHARGE_DMG       := 999   # one-hit-kill on ground contact
const CONTACT_DMG      := 28
const SHAKE_ON_CHARGE  := 0.7
const FLASH_DURATION   := 0.25

enum State { PATROL, WINDUP, CHARGE, RECOVER }

var hp:           int   = MAX_HP
var state:        State = State.PATROL
var state_timer:  float = 0.0
var dir:          int   = 1
var hit_cooldown: float = 0.0
var _flash_timer: float = 0.0
var _player: Node2D     = null
var _spr: AnimatedSprite2D = null

const PK_FRAME_W := 80.0
const PK_FRAME_H := 90.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask  = 1
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	_player = get_tree().get_first_node_in_group("player")
	GameManager.set_boss(MAX_HP)
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/peykomban_sheet.png"
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -PK_FRAME_H * 0.5)
	var sf := SpriteFrames.new()
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		var anims := [["patrol", [0,1], 3.0, true], ["windup", [2], 4.0, false], ["charge", [3], 8.0, true]]
		for a: Array in anims:
			sf.add_animation(a[0])
			sf.set_animation_loop(a[0], a[3])
			sf.set_animation_speed(a[0], a[2])
			for fi: int in a[1]:
				var at := AtlasTexture.new()
				at.atlas  = sheet
				at.region = Rect2(fi * PK_FRAME_W, 0, PK_FRAME_W, PK_FRAME_H)
				sf.add_frame(a[0], at)
	else:
		sf.add_animation("patrol")
		sf.set_animation_loop("patrol", true)
		var img := Image.create(int(PK_FRAME_W), int(PK_FRAME_H), false, Image.FORMAT_RGBA8)
		img.fill(Color(0.20, 0.12, 0.08, 1.0))
		sf.add_frame("patrol", ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.play("patrol")
	add_child(_spr)
	$ColorRect.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color(0.20, 0.12, 0.08, 1.0)

	match state:
		State.PATROL:
			velocity.x = PATROL_SPEED * dir
			if position.x < 500.0:   dir =  1
			elif position.x > 7400.0: dir = -1
			if _spr != null:
				_spr.flip_h = (dir < 0)
				if _spr.animation != "patrol": _spr.play("patrol")
			# Wind up when player is on ground in facing direction
			if is_instance_valid(_player) and not _player.is_safe_from_charge():
				var dx := _player.global_position.x - global_position.x
				if int(sign(dx)) == dir and absf(dx) < 800.0:
					state       = State.WINDUP
					state_timer = WINDUP_DURATION
					modulate    = Color(1.0, 0.55, 0.05, 1.0)   # orange glow

		State.WINDUP:
			velocity.x   = 0.0
			if _spr != null and _spr.animation != "windup": _spr.play("windup")
			state_timer -= delta
			if state_timer <= 0.0:
				state       = State.CHARGE
				state_timer = CHARGE_DURATION
				if _spr != null: _spr.play("charge")
				if is_instance_valid(_player):
					_player.add_trauma(SHAKE_ON_CHARGE)

		State.CHARGE:
			var spd := CHARGE_SPEED_P2 if hp <= 3 else CHARGE_SPEED_P1
			velocity.x   = spd * dir
			if _spr != null: _spr.flip_h = (dir < 0)
			state_timer -= delta
			if state_timer <= 0.0:
				state       = State.RECOVER
				state_timer = RECOVER_DURATION_P2 if hp <= 3 else RECOVER_DURATION_P1
				if _spr != null: _spr.play("patrol")
			# Rage phase: reverse on edge
			if hp <= 1 and (position.x < 500.0 or position.x > 7400.0):
				dir = -dir

		State.RECOVER:
			velocity.x   = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.PATROL

	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

func take_damage(dmg: int) -> void:
	if state == State.CHARGE: return   # immune during charge
	hp -= dmg
	GameManager.boss_take_damage(dmg)
	_flash_timer = FLASH_DURATION
	modulate     = Color(1.0, 0.3, 0.3, 0.9)
	if hp <= 0: _die()

func _die() -> void:
	GameManager.clear_boss()
	GameManager.win_game()
	_drop_powerup()
	queue_free()

func _drop_powerup() -> void:
	for t: String in ["heart", "nut", "porotta"]:
		var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
		pu.type     = t
		pu.position = position + Vector2(randf_range(-40, 40), -20)
		get_parent().add_child(pu)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or hit_cooldown > 0.0: return
	var dmg := CHARGE_DMG if state == State.CHARGE else CONTACT_DMG
	body.take_damage(dmg)
	hit_cooldown = 1.0
