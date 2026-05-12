extends CharacterBody2D

const SPEED         := 54.0
const GRAVITY       := 1800.0
const MAX_HP        := 40
const PATROL_LEFT   := 100.0
const PATROL_RIGHT  := 2780.0
const CONTACT_DMG   := 15
const CRAB_SHEET_COLS := 8
const CRAB_FRAME_W    := 250
const CRAB_FRAME_H    := 125

var hp:           int   = MAX_HP
var dir:          int   = 1
var hit_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask  = 1
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	_build_anim()

func _build_anim() -> void:
	const PATH := "res://assets/sprites/crab_sheet.png"
	var sf := SpriteFrames.new()
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", 10.0)
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		for i: int in CRAB_SHEET_COLS:
			var at := AtlasTexture.new()
			at.atlas  = sheet
			at.region = Rect2(i * CRAB_FRAME_W, 0, CRAB_FRAME_W, CRAB_FRAME_H)
			sf.add_frame("walk", at)
	else:
		var img := Image.create(50, 28, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.90, 0.45, 0.10))
		sf.add_frame("walk", ImageTexture.create_from_image(img))
	$AnimatedSprite2D.sprite_frames = sf
	$AnimatedSprite2D.play("walk")

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	velocity.x  = SPEED * dir
	if position.x < PATROL_LEFT:  dir =  1
	elif position.x > PATROL_RIGHT: dir = -1
	$AnimatedSprite2D.flip_h = (dir < 0)
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0: _die()

func _die() -> void:
	if randf() < 0.55: _drop_powerup()
	GameManager.score += 10
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and hit_cooldown <= 0.0:
		body.take_damage(CONTACT_DMG)
		hit_cooldown = 1.0

func _drop_powerup() -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type = (["heart","nut","porotta","toddy","chai"])[randi() % 5]
	pu.position = position - Vector2(0.0, 20.0)
	get_parent().add_child(pu)
