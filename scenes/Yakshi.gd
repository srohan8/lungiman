extends CharacterBody2D

## Yakshi — Act I Boss. Hypnotises player at range, vulnerable when stunned.

const MAX_HP         := 3
const SPEED          := 60.0
const GRAVITY        := 1800.0
const HYPNO_RANGE    := 280.0
const STUN_DURATION  := 0.40
const FLASH_DURATION := 0.25

var hp:           int   = MAX_HP
var phase:        int   = 0   # 0 patrol  1 hypnotising  2 stunned
var stun_timer:   float = 0.0
var _flash_timer: float = 0.0
var dir:          int   = 1
var _player: Node2D     = null
var _spr: AnimatedSprite2D = null

const YAKSHI_FRAME_W := 52.0
const YAKSHI_FRAME_H := 80.0

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
	const PATH := "res://assets/sprites/yakshi_sheet.png"
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -YAKSHI_FRAME_H * 0.5)
	var sf := SpriteFrames.new()
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		var anims := [["float", [0,1], 4.0, true], ["hypno", [2,3], 6.0, true], ["stun", [4], 2.0, false]]
		for a: Array in anims:
			sf.add_animation(a[0])
			sf.set_animation_loop(a[0], a[3])
			sf.set_animation_speed(a[0], a[2])
			for fi: int in a[1]:
				var at := AtlasTexture.new()
				at.atlas  = sheet
				at.region = Rect2(fi * YAKSHI_FRAME_W, 0, YAKSHI_FRAME_W, YAKSHI_FRAME_H)
				sf.add_frame(a[0], at)
	else:
		sf.add_animation("float")
		sf.set_animation_loop("float", true)
		var img := Image.create(int(YAKSHI_FRAME_W), int(YAKSHI_FRAME_H), false, Image.FORMAT_RGBA8)
		img.fill(Color(0.85, 0.95, 1.0, 0.88))
		sf.add_frame("float", ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.play("float")
	add_child(_spr)
	$ColorRect.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color(0.85, 0.95, 1.0, 0.88)

	match phase:
		0:   # Patrol
			velocity.x = SPEED * dir
			if position.x < 200.0:   dir =  1
			elif position.x > 7400.0: dir = -1
			if _spr != null:
				_spr.flip_h = (dir < 0)
				if _spr.animation != "float": _spr.play("float")
			if is_instance_valid(_player):
				if global_position.distance_to(_player.global_position) < HYPNO_RANGE:
					phase = 1
					GameManager.activate_hypnosis(8.0)
		1:   # Hypnotising
			velocity.x = 0.0
			if _spr != null and _spr.animation != "hypno": _spr.play("hypno")
			if not is_instance_valid(_player) or \
					global_position.distance_to(_player.global_position) >= HYPNO_RANGE:
				phase = 0
		2:   # Stunned
			velocity.x  = 0.0
			if _spr != null and _spr.animation != "stun": _spr.play("stun")
			stun_timer  -= delta
			if stun_timer <= 0.0:
				phase = 0

	move_and_slide()

func take_damage(dmg: int) -> void:
	if phase == 1 or phase == 2:
		hp -= dmg
		GameManager.boss_take_damage(dmg)
		_flash_timer = FLASH_DURATION
		modulate     = Color(1.0, 0.3, 0.3, 0.9)
		phase        = 2
		stun_timer   = STUN_DURATION
		if hp <= 0: _die()

func _die() -> void:
	GameManager.clear_boss()
	_drop_powerup()
	queue_free()

func _drop_powerup() -> void:
	for t: String in ["chai", "heart"]:
		var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
		pu.type     = t
		pu.position = position + Vector2(randf_range(-30, 30), -20)
		get_parent().add_child(pu)
