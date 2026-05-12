extends CharacterBody2D

## Odiyan — Act III Boss. Shapeshifter. Only vulnerable during transform flash.
## weakness_revealed (from Tracks quest) extends the flash window 0.6s → 0.9s.

const MAX_HP           := 4
const GRAVITY          := 1800.0
const HUMAN_SPEED      := 0.0
const BULL_SPEED       := 200.0
const DOG_SPEED        := 140.0
const CYCLE_HUMAN      := 2.5
const TRANSFORM_WINDOW := 0.6   # vulnerable window (base)
const TRANSFORM_WINDOW_REVEALED := 0.9
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
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -70.0 * 0.5)
	var sf := SpriteFrames.new()
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		var anims := [["human", [0], 2.0, true], ["transform", [0,1,2,3,4], 12.0, false],
					  ["bull", [1,2], 4.0, true], ["dog", [3,4], 6.0, true]]
		for a: Array in anims:
			sf.add_animation(a[0])
			sf.set_animation_loop(a[0], a[3])
			sf.set_animation_speed(a[0], a[2])
			for fi: int in a[1]:
				var at := AtlasTexture.new()
				at.atlas  = sheet
				at.region = Rect2(fi * ODIYAN_FRAME_W, 0, ODIYAN_FRAME_W, ODIYAN_FRAME_H)
				sf.add_frame(a[0], at)
	else:
		sf.add_animation("human")
		sf.set_animation_loop("human", true)
		var img := Image.create(int(ODIYAN_FRAME_W), int(ODIYAN_FRAME_H), false, Image.FORMAT_RGBA8)
		img.fill(Color(0.75, 0.75, 0.75))
		sf.add_frame("human", ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.scale = Vector2(70.0 / ODIYAN_FRAME_H, 70.0 / ODIYAN_FRAME_H)
	_spr.play("human")
	add_child(_spr)
	$ColorRect.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
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
	modulate = Color.WHITE
	if _spr == null: return
	match form:
		Form.HUMAN:
			if _spr.animation != "human": _spr.play("human")
		Form.TRANSFORM:
			modulate = Color(1.0, 1.0, 0.2, 1.0)   # bright flash overlay
			if _spr.animation != "transform": _spr.play("transform")
		Form.BULL:
			if _spr.animation != "bull": _spr.play("bull")
		Form.DOG:
			if _spr.animation != "dog": _spr.play("dog")

func reveal_weakness() -> void:
	weakness_revealed = true

func take_damage(dmg: int) -> void:
	if form != Form.TRANSFORM: return
	hp -= dmg
	GameManager.boss_take_damage(dmg)
	_flash_timer = FLASH_DURATION
	modulate     = Color(1.0, 0.3, 0.3, 1.0)
	if hp <= 0: _die()

func _die() -> void:
	GameManager.clear_boss()
	GameManager.score += 220
	GameManager.show_score_popup(position + Vector2(0, -50), 220, Color(0.5, 0.8, 0.3))
	_drop_powerup()
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
