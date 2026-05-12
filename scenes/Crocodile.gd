extends CharacterBody2D

const GRAVITY       := 1800.0
const PATROL_SPEED  := 68.0
const LUNGE_SPEED   := 260.0
const LUNGE_DMG     := 22
const LUNGE_RANGE   := 220.0
const LUNGE_DURATION  := 0.45
const RECOVER_DURATION := 0.90
const MAX_HP        := 55
const CROC_W        := 900.0   # 90 SVG units × scale 10
const CROC_H        := 440.0   # 44 SVG units × scale 10

enum State { PATROL, LUNGE, RECOVER }

var hp:          int   = MAX_HP
var state:       State = State.PATROL
var dir:         int   = 1
var state_timer: float = 0.0
var hit_cooldown: float = 0.0
var _player: Node2D = null
var _flash_timer: float = 0.0
var _spr: AnimatedSprite2D = null

@export var patrol_left:  float = 0.0
@export var patrol_right: float = 1000.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask  = 1
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	_player = get_tree().get_first_node_in_group("player")
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/croc_sheet.png"
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(CROC_W * 0.05, CROC_H * 0.05)
	var sf := SpriteFrames.new()
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		for anim_name: String in ["patrol", "lunge", "submerged"]:
			sf.add_animation(anim_name)
			sf.set_animation_loop(anim_name, true)
			sf.set_animation_speed(anim_name, 4.0)
		# patrol: frames 0,1
		for i: int in [0, 1]:
			var at := AtlasTexture.new()
			at.atlas  = sheet
			at.region = Rect2(i * CROC_W, 0, CROC_W, CROC_H)
			sf.add_frame("patrol", at)
		# lunge: frame 2
		var at_l := AtlasTexture.new()
		at_l.atlas  = sheet
		at_l.region = Rect2(2 * CROC_W, 0, CROC_W, CROC_H)
		sf.add_frame("lunge", at_l)
		# submerged: frame 3
		var at_s := AtlasTexture.new()
		at_s.atlas  = sheet
		at_s.region = Rect2(3 * CROC_W, 0, CROC_W, CROC_H)
		sf.add_frame("submerged", at_s)
	else:
		sf.add_animation("patrol")
		sf.set_animation_loop("patrol", true)
		var img := Image.create(int(CROC_W), int(CROC_H), false, Image.FORMAT_RGBA8)
		img.fill(Color(0.25, 0.45, 0.20))
		sf.add_frame("patrol", ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.scale = Vector2(0.1, 0.1)
	_spr.play("patrol")
	add_child(_spr)
	$ColorRect.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE

	match state:
		State.PATROL:
			velocity.x = PATROL_SPEED * dir
			if position.x <= patrol_left:  dir =  1
			elif position.x >= patrol_right: dir = -1
			# Check for lunge
			if is_instance_valid(_player):
				var dx := _player.global_position.x - global_position.x
				if absf(dx) < LUNGE_RANGE and absf(_player.global_position.y - global_position.y) < 80.0:
					dir        = int(sign(dx))
					state      = State.LUNGE
					state_timer = LUNGE_DURATION
					modulate   = Color(0.55, 0.12, 0.12)

		State.LUNGE:
			velocity.x   = LUNGE_SPEED * dir
			state_timer -= delta
			if state_timer <= 0.0:
				state       = State.RECOVER
				state_timer = RECOVER_DURATION
				velocity.x  = 0.0

		State.RECOVER:
			velocity.x   = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				state    = State.PATROL
				modulate = Color.WHITE

	if _spr != null:
		_spr.flip_h = (dir < 0)
		var target_anim := "lunge" if state == State.LUNGE else "patrol"
		if _spr.animation != target_anim: _spr.play(target_anim)
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

func take_damage(dmg: int) -> void:
	hp -= dmg
	_flash_timer = 0.25
	modulate     = Color(1.0, 0.3, 0.3, 0.9)
	if hp <= 0: _die()

func _die() -> void:
	GameManager.score += 15
	GameManager.show_score_popup(position - Vector2(0, 24), 15, Color(0.4, 1.0, 0.5))
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and hit_cooldown <= 0.0:
		body.take_damage(LUNGE_DMG)
		hit_cooldown = 1.2
