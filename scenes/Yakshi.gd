extends CharacterBody2D

## Yakshi — Act I Boss. Hypnotises player at range, vulnerable when stunned.

const MAX_HP         := 3
const SPEED          := 60.0
const GRAVITY        := 1800.0
const HYPNO_RANGE    := 280.0
const STUN_DURATION  := 0.40
const FLASH_DURATION := 0.25

var hp:               int   = MAX_HP
var phase:            int   = 0   # 0 patrol  1 hypnotising  2 stunned
var stun_timer:       float = 0.0
var _flash_timer:     float = 0.0
var _hypno_pulse_t:   float = 0.0   # Phase 3: repeat hypnosis every 5s
var dir:              int   = 1
var _clones_p2:       bool  = false
var _clones_p3:       bool  = false
var _player: Node2D         = null
var _spr: AnimatedSprite2D  = null

const YAKSHI_FRAME_W := 624.0   # 52 SVG units × scale 12
const YAKSHI_FRAME_H := 960.0   # 80 SVG units × scale 12

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
	const TARGET_H := 120.0
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	# Sheet: 3 cells horizontal — float | hypno | stun
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 3, 1, [
		{"name": "float", "frames": [0], "fps": 2.0, "loop": true},
		{"name": "hypno", "frames": [1], "fps": 3.0, "loop": true},
		{"name": "stun",  "frames": [2], "fps": 2.0, "loop": false},
	], Color(0.85, 0.95, 1.0, 0.88))
	var s: float = GameManager.grid_sheet_scale(PATH, 1, TARGET_H)
	_spr.scale = Vector2(s, s)
	_spr.play("float")
	add_child(_spr)
	$ColorRect.visible = false

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color(0.85, 0.95, 1.0, 0.88)
	# Phase 3: hypnosis pulses every 5s
	if _clones_p3 and hp > 0:
		_hypno_pulse_t -= delta
		if _hypno_pulse_t <= 0.0:
			_hypno_pulse_t = 5.0
			GameManager.activate_hypnosis(6.0)

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
		# Phase 2 (<2 HP): spawn 2 ghost clones mid-fight
		if hp <= 1 and not _clones_p2:
			_clones_p2 = true
			_spawn_fight_clones(2)
			_show_hint("🧙‍♀️ Yakshi summons her mirrors!")
		# Phase 3 (<1 HP): enable repeating hypnosis pulse
		if hp <= 0 and not _clones_p3:
			_clones_p3 = true
			_spawn_fight_clones(2)
			_hypno_pulse_t = 5.0
			_show_hint("🌙 The veil drops — don’t be caught on the ground!")
		if hp <= 0: _die()

func _spawn_fight_clones(count: int) -> void:
	for i: int in count:
		var g: Node2D = preload("res://scenes/GhostClone.tscn").instantiate()
		g.position = position + Vector2(randf_range(-180, 180), 0)
		g.is_real  = (i == 0)   # first one is real
		get_parent().add_child(g)

func _show_hint(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_hint"):
		hud.show_hint(text, 3.5)

func _die() -> void:
	GameManager.clear_boss()
	GameManager.boss_grit_drop()   # Grit: 100 → 80. Lamp dims — the forest takes its toll.
	GameManager.score += 200
	GameManager.show_score_popup(position - Vector2(0, 40), 200, Color(0.85, 0.50, 1.0))
	_drop_powerup()
	queue_free()

func _drop_powerup() -> void:
	for t: String in ["chai", "heart"]:
		var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
		pu.type     = t
		pu.position = position + Vector2(randf_range(-30, 30), -20)
		get_parent().add_child(pu)
