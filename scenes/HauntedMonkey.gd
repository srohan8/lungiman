extends CharacterBody2D

## HauntedMonkey — patrol enemy. Used in Act I vines and Act II Monkey Swarm.
## Swarm mechanic: each death in the same group boosts survivors' speed.
## Set swarm_id to a shared string to link a group of monkeys together.

const GRAVITY         := 1800.0
const BASE_SPEED      := 80.0
const SPEED_PER_DEATH := 35.0   # bonus per fallen swarm-mate
const MAX_HP          := 2
const CONTACT_DMG     := 12
const FLASH_DURATION  := 0.20

var hp:            int   = MAX_HP
var dir:           int   = 1
var hit_cooldown:  float = 0.0
var _flash_timer:  float = 0.0
var swarm_id:      String = ""   # shared tag — leave empty for lone monkeys
var patrol_left:   float = 0.0
var patrol_right:  float = 8000.0

# Shared death counter per swarm_id — stored as metadata on a global group node
static var _swarm_deaths: Dictionary = {}

func _ready() -> void:
	add_to_group("enemies")
	if swarm_id != "":
		add_to_group("swarm_" + swarm_id)
	collision_layer = 4
	collision_mask  = 1
	$Hitbox.collision_layer = 0
	$Hitbox.collision_mask  = 2
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	_build_visual()

func _build_visual() -> void:
	var img := Image.create(22, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.30, 0.20, 0.08))   # dark brown
	var sf := SpriteFrames.new()
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", 8.0)
	sf.add_frame("walk", ImageTexture.create_from_image(img))
	$AnimatedSprite2D.sprite_frames = sf
	$AnimatedSprite2D.play("walk")

func _deaths_for_swarm() -> int:
	if swarm_id == "":
		return 0
	return _swarm_deaths.get(swarm_id, 0)

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE

	var spd := BASE_SPEED + SPEED_PER_DEATH * _deaths_for_swarm()
	velocity.x = spd * dir
	if position.x < patrol_left:  dir =  1
	elif position.x > patrol_right: dir = -1
	$AnimatedSprite2D.flip_h = (dir < 0)

	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

func take_damage(dmg: int) -> void:
	hp -= dmg
	_flash_timer = FLASH_DURATION
	modulate     = Color(1.0, 0.3, 0.3, 0.9)
	if hp <= 0: _die()

func _die() -> void:
	if swarm_id != "":
		_swarm_deaths[swarm_id] = _deaths_for_swarm() + 1
	if randf() < 0.50:
		_drop_powerup()
	GameManager.score += 8
	GameManager.show_score_popup(position - Vector2(0, 20), 8)
	queue_free()

func _drop_powerup() -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type     = "nut" if randf() > 0.4 else "heart"
	pu.position = position - Vector2(0.0, 20.0)
	get_parent().call_deferred("add_child", pu)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and hit_cooldown <= 0.0:
		body.take_damage(CONTACT_DMG)
		hit_cooldown = 1.2
