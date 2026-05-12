extends CharacterBody2D

# ── Physics ───────────────────────────────────────────────────────────────────
const GRAVITY          := 1800.0
const JUMP_VELOCITY    := -780.0
const SPEED            := 294.0
const AIR_SPEED        := 186.0

# ── Platformer feel ───────────────────────────────────────────────────────────
const COYOTE_TIME       := 0.10
const JUMP_BUFFER_TIME  := 0.15
const JUMP_RELEASE_MULT := 0.50
const FALL_GRAV_MULT    := 1.60
const MAX_FALL_SPEED    := 900.0

# ── Tree climbing ─────────────────────────────────────────────────────────────
const LEAP_DIST_MAX     := 550.0
const LEAP_SPEED_FACTOR := 11.0
const LEAP_TOF_MIN      := 20.0
const CLIMB_DURATION    := 0.50
const HERO_HALF_H       := 60.0

# ── River / water ─────────────────────────────────────────────────────────────
const WADE_SPEED_MULT    := 0.55
const WATER_DMG_INTERVAL := 2.5
const RIVER_DMG_COOLDOWN := 1.0

# ── Combat / roll ─────────────────────────────────────────────────────────────
const ROLL_SPEED    := 480.0
const ROLL_DURATION := 0.35
const ROLL_IFRAMES  := 0.40

# ── Screen shake ─────────────────────────────────────────────────────────────
const SHAKE_DECAY := 3.8

# ── Sprite sheet ─────────────────────────────────────────────────────────────
# hero_sheet.png: single horizontal row, FRAME_H tall, variable-width frames.
# Falls back to solid-colour placeholders if sheet is missing.
const FRAME_H    := 98
const FRAME_DATA := {
	"walk":       {"fps": 10.0, "loop": true,  "frames": [[0,58],[58,57],[115,58]]},
	"idle":       {"fps":  4.0, "loop": true,  "frames": [[173,68],[241,70]]},
	"swing_grab": {"fps":  1.0, "loop": false, "frames": [[311,79]]},
	"swing":      {"fps": 12.0, "loop": true,  "frames": [[390,65],[455,66],[521,47]]},
	"sword":      {"fps": 16.0, "loop": false, "frames": [[568,90],[658,90],[748,90],[838,89]]},
	"sword2":     {"fps": 16.0, "loop": false, "frames": [[927,55],[982,58],[1040,72]]},
	"chai":       {"fps":  8.0, "loop": true,  "frames": [[1112,96],[1208,109],[1317,46]]},
}
const ANIM_COLORS := {
	"walk":       Color(0.20, 0.55, 1.00),
	"idle":       Color(0.20, 0.55, 1.00),
	"swing_grab": Color(0.20, 0.80, 0.50),
	"swing":      Color(0.10, 0.90, 0.70),
	"sword":      Color(1.00, 0.85, 0.10),
	"sword2":     Color(1.00, 0.65, 0.10),
	"chai":       Color(0.85, 0.40, 0.10),
}

enum TreeState { NONE, CLIMBING, PERCHED, FLYING }

# ── State ─────────────────────────────────────────────────────────────────────
var tree_state   := TreeState.NONE
var climb_tree:  Node2D = null
var near_tree:   Node2D = null
var climb_start  := Vector2.ZERO
var climb_target := Vector2.ZERO
var climb_t      := 0.0
var face         := 1

var coyote_timer  := 0.0
var jump_buffer   := 0.0

var sword_phase   := 0
var sword_t       := 0.0
var sword_hit     := false

var in_water           := false
var _water_dmg_timer   := 0.0
var river_dmg_cooldown := 0.0

var rolling      := false
var roll_timer   := 0.0
var iframe_timer := 0.0

# ── Appam Glide (Swing-off Race reward) ────────────────────────────────
const GLIDE_GRAV_MULT  := 0.18   # gravity fraction during glide
const GLIDE_MAX_FALL   := 80.0   # max fall speed while gliding
const GLIDE_DURATION   := 1.5
var   glide_timer      := 0.0    # > 0 = currently gliding

var _shake_trauma     := 0.0
var ammo_regen_timer  := 0.0
const AMMO_REGEN_INTERVAL := 6.0

signal climb_prompt_changed(is_visible: bool)

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask  = 1
	_build_sprite_frames()

func _build_sprite_frames() -> void:
	const PATH := "res://assets/sprites/hero_sheet.png"
	var sf := SpriteFrames.new()
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		for anim_name: String in FRAME_DATA:
			var d: Dictionary = FRAME_DATA[anim_name]
			sf.add_animation(anim_name)
			sf.set_animation_loop(anim_name, d["loop"])
			sf.set_animation_speed(anim_name, d["fps"])
			for f: Array in d["frames"]:
				var at := AtlasTexture.new()
				at.atlas  = sheet
				at.region = Rect2(f[0], 0, f[1], FRAME_H)
				sf.add_frame(anim_name, at)
	else:
		for anim_name: String in ANIM_COLORS:
			var img := Image.create(30, 60, false, Image.FORMAT_RGBA8)
			img.fill(ANIM_COLORS[anim_name])
			var tex := ImageTexture.create_from_image(img)
			sf.add_animation(anim_name)
			sf.set_animation_loop(anim_name, true)
			sf.set_animation_speed(anim_name, 8.0)
			sf.add_frame(anim_name, tex)
	$AnimatedSprite2D.sprite_frames = sf
	$AnimatedSprite2D.play("idle")

func _process(delta: float) -> void:
	if _shake_trauma > 0.0:
		_shake_trauma = maxf(0.0, _shake_trauma - SHAKE_DECAY * delta)
		var shake := _shake_trauma * _shake_trauma
		$Camera2D.offset = Vector2(randf_range(-1.0, 1.0) * shake * 18.0,
								   randf_range(-1.0, 1.0) * shake * 18.0)
	elif GameManager.toddy_active:
		# Toddy dizziness — slow rolling sway, gets worse mid-duration
		var sway := sin(Time.get_ticks_msec() * 0.0025) * 14.0
		$Camera2D.offset = Vector2(sway, sin(Time.get_ticks_msec() * 0.004) * 5.0)
	else:
		$Camera2D.offset = Vector2.ZERO
	if tree_state == TreeState.PERCHED and GameManager.ammo < GameManager.max_ammo:
		ammo_regen_timer -= delta
		# Chaya Kada reward: 2× faster regen near a SoniyaChechi / tea shop
		var near_tea := _is_near_tea_shop()
		var regen_interval := AMMO_REGEN_INTERVAL * (0.5 if near_tea else 1.0)
		if ammo_regen_timer <= 0.0:
			ammo_regen_timer = regen_interval
			GameManager.ammo = mini(GameManager.ammo + 1, GameManager.max_ammo)

func _physics_process(delta: float) -> void:
	if GameManager.paralysis_active:
		return
	var do_climb := Input.is_action_just_pressed("climb") or GameManager.consume_climb_press()
	match tree_state:
		TreeState.NONE:     _process_none(delta, do_climb)
		TreeState.CLIMBING: _process_climbing(delta)
		TreeState.PERCHED:  _process_perched(delta, do_climb)
		TreeState.FLYING:   _process_flying(delta)
	_handle_roll(delta)
	_handle_sword(delta)
	_handle_coconut()
	_update_animation()
	river_dmg_cooldown = maxf(0.0, river_dmg_cooldown - delta)
	iframe_timer       = maxf(0.0, iframe_timer - delta)
	if in_water:
		_water_dmg_timer -= delta
		if _water_dmg_timer <= 0.0:
			_water_dmg_timer = WATER_DMG_INTERVAL
			take_damage(8)
	move_and_slide()
	emit_signal("climb_prompt_changed", near_tree != null and tree_state == TreeState.NONE)

func _process_none(delta: float, do_climb: bool) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		if velocity.y > 0.0: velocity.y = 0.0
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		var grav := GRAVITY * (FALL_GRAV_MULT if velocity.y > 0.0 else 1.0)
		velocity.y = minf(velocity.y + grav * delta, MAX_FALL_SPEED)
	if is_on_ceiling() and velocity.y < 0.0:
		velocity.y = 0.0
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER_TIME
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if jump_buffer > 0.0 and coyote_timer > 0.0:
		velocity.y   = JUMP_VELOCITY
		jump_buffer  = 0.0
		coyote_timer = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_RELEASE_MULT
	var move_dir := Input.get_axis("move_left", "move_right")
	if GameManager.hypnosis_active:
		move_dir = -move_dir
	if GameManager.toddy_active:
		# Toddy dizziness — slight random drift, sometimes stumble
		move_dir = clampf(move_dir + randf_range(-0.35, 0.35), -1.0, 1.0)
	if move_dir != 0.0:
		face = int(sign(move_dir))
		var spd := AIR_SPEED if not is_on_floor() else SPEED
		if in_water: spd *= WADE_SPEED_MULT
		velocity.x = move_dir * spd
	else:
		var friction := SPEED * 8.0 if is_on_floor() else AIR_SPEED * 3.0
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if near_tree != null and do_climb:
		climb_tree   = near_tree
		climb_start  = position
		climb_target = climb_tree.get_crown_position() - Vector2(0.0, HERO_HALF_H)
		climb_t      = 0.0
		tree_state   = TreeState.CLIMBING
		velocity     = Vector2.ZERO

func _process_climbing(delta: float) -> void:
	climb_t += delta / CLIMB_DURATION
	var t     := minf(climb_t, 1.0)
	var eased := 1.0 - (1.0 - t) * (1.0 - t)
	position   = climb_start.lerp(climb_target, eased)
	velocity   = Vector2.ZERO
	if climb_t >= 1.0:
		position   = climb_target
		tree_state = TreeState.PERCHED

func _process_perched(_delta: float, do_climb: bool) -> void:
	position = climb_tree.get_crown_position() - Vector2(0.0, HERO_HALF_H)
	velocity = Vector2.ZERO
	var h := Input.get_axis("move_left", "move_right")
	if h != 0.0: face = int(sign(h))
	$AnimatedSprite2D.flip_h = (face < 0)
	# E / climb button (or mobile BtnClimb) → drop from crown
	if do_climb:
		velocity.y = 300.0
		tree_state = TreeState.NONE
		climb_tree = null
	# Jump (X / Space) → swing to the nearest crown in facing direction,
	# or leap off freely if no tree is in range
	elif Input.is_action_just_pressed("jump"):
		var target := _near_tree_in_facing()
		if target != null:
			_launch_to_tree(target)   # arc to next crown
		else:
			velocity.y = JUMP_VELOCITY
			tree_state = TreeState.FLYING
			climb_tree = null

func _process_flying(delta: float) -> void:
	# Appam Glide: hold Jump while FLYING to slow descent (requires quest reward)
	var has_glide := QuestManager.get_state("swing_off_race") == 2
	if has_glide and Input.is_action_pressed("jump") and velocity.y > 0.0:
		if glide_timer <= 0.0 and Input.is_action_just_pressed("jump"):
			glide_timer = GLIDE_DURATION
	if glide_timer > 0.0:
		glide_timer  -= delta
		velocity.y    = minf(velocity.y + GRAVITY * GLIDE_GRAV_MULT * delta, GLIDE_MAX_FALL)
	else:
		velocity.y += GRAVITY * delta
	if is_on_floor():
		tree_state  = TreeState.NONE
		glide_timer = 0.0

func _near_tree_in_facing() -> Node2D:
	var best: Node2D   = null
	var best_dx: float = INF
	var my_crown: Vector2 = climb_tree.get_crown_position() as Vector2
	for tree: Node2D in get_tree().get_nodes_in_group("trees"):
		if tree == climb_tree: continue
		var their_crown: Vector2 = tree.get_crown_position() as Vector2
		var dx: float    = their_crown.x - my_crown.x
		if face > 0 and dx <= 0.0: continue
		if face < 0 and dx >= 0.0: continue
		if absf(dx) > LEAP_DIST_MAX: continue
		if absf(dx) < best_dx:
			best_dx = absf(dx)
			best    = tree
	return best

func _launch_to_tree(target: Node2D) -> void:
	var src: Vector2  = climb_tree.get_crown_position() as Vector2 - Vector2(0.0, HERO_HALF_H)
	var dst: Vector2  = target.get_crown_position() as Vector2     - Vector2(0.0, HERO_HALF_H)
	var dist_x: float = dst.x - src.x
	var dist_y: float = dst.y - src.y
	var tof_f  := maxf(LEAP_TOF_MIN, absf(dist_x) / LEAP_SPEED_FACTOR)
	var tof    := tof_f / 60.0
	velocity.x  = dist_x / tof
	velocity.y  = (dist_y - 0.5 * GRAVITY * tof * tof) / tof
	tree_state  = TreeState.FLYING
	climb_tree  = null

func perch_on(tree: Node2D) -> void:
	if tree_state != TreeState.FLYING: return
	tree_state = TreeState.PERCHED
	climb_tree = tree
	velocity   = Vector2.ZERO
	position   = tree.get_crown_position() - Vector2(0.0, HERO_HALF_H)

func _handle_roll(delta: float) -> void:
	if rolling:
		roll_timer -= delta
		velocity.x  = face * ROLL_SPEED
		if roll_timer <= 0.0: rolling = false
	elif Input.is_action_just_pressed("move_down") and is_on_floor() and tree_state == TreeState.NONE:
		rolling      = true
		roll_timer   = ROLL_DURATION
		iframe_timer = ROLL_IFRAMES
		velocity.x   = face * ROLL_SPEED

func _handle_sword(delta: float) -> void:
	if sword_phase == 0:
		if Input.is_action_just_pressed("sword") and tree_state == TreeState.NONE:
			sword_phase = 1; sword_t = 0.0; sword_hit = false
		return
	sword_t += delta
	match sword_phase:
		1:
			if sword_t > 0.15: sword_phase = 2; sword_t = 0.0
		2:
			if not sword_hit: _check_sword_hit()
			if sword_t > 0.20: sword_phase = 3; sword_t = 0.0
		3:
			if sword_t > 0.15: sword_phase = 0

func _check_sword_hit() -> void:
	sword_hit   = true
	var reach   := 50.0
	var hit_off := Vector2(face * (20.0 + reach * 0.5), 0.0)
	var hit_box := Rect2(global_position + hit_off - Vector2(reach * 0.5, 30.0), Vector2(reach, 60.0))
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy): continue
		if hit_box.has_point(enemy.global_position):
			enemy.take_damage(30 * GameManager.damage_multiplier())

func _handle_coconut() -> void:
	# Allow throws from ground AND from tree crown (key tactic vs aerial bosses)
	var can_throw := tree_state == TreeState.NONE or tree_state == TreeState.PERCHED
	if Input.is_action_just_pressed("coconut") and GameManager.ammo > 0 and can_throw:
		GameManager.ammo -= 1
		var proj: Node2D = preload("res://scenes/CoconutProjectile.tscn").instantiate()
		proj.position = global_position
		get_parent().add_child(proj)
		proj.launch(face)

func take_damage(amount: int) -> void:
	if iframe_timer > 0.0: return
	GameManager.take_damage(amount)
	iframe_timer = 0.6
	add_trauma(0.4)

func take_river_damage(amount: int) -> void:
	if river_dmg_cooldown > 0.0: return
	river_dmg_cooldown = RIVER_DMG_COOLDOWN
	GameManager.take_damage(amount)
	velocity.x = -face * 200.0

func enter_water() -> void:
	in_water         = true
	_water_dmg_timer = WATER_DMG_INTERVAL

func exit_water() -> void:
	in_water = false

func is_safe_from_charge() -> bool:
	return tree_state == TreeState.PERCHED or tree_state == TreeState.FLYING

func add_trauma(amount: float) -> void:
	_shake_trauma = minf(1.0, _shake_trauma + amount)

func _is_near_tea_shop() -> bool:
	if QuestManager.get_state("chaya_kada_showdown") != 2:
		return false
	for npc: Node in get_tree().get_nodes_in_group("tea_shop"):
		if global_position.distance_to(npc.global_position) < 300.0:
			return true
	return false

func _update_animation() -> void:
	var spr := $AnimatedSprite2D
	if sword_phase > 0:
		var anim: StringName = &"sword" if sword_phase <= 2 else &"sword2"
		if spr.animation != anim: spr.play(anim)
		spr.flip_h = (face < 0)
		return
	var target_anim: StringName
	match tree_state:
		TreeState.CLIMBING, TreeState.PERCHED: target_anim = &"swing_grab"
		TreeState.FLYING:                      target_anim = &"swing"
		_: target_anim = &"walk" if absf(velocity.x) > 10.0 else &"idle"
	if spr.animation != target_anim: spr.play(target_anim)
	spr.flip_h = (face < 0)
	if iframe_timer > 0.0:
		modulate = Color(1.0, 1.0, 1.0, 0.45)   # hit flash
	elif in_water:
		modulate = Color(0.55, 0.78, 1.0, 0.90)  # wade tint
	elif GameManager.rage_active:
		# Porotta rage — orange fire glow pulses with time
		var pulse := 0.85 + sin(Time.get_ticks_msec() * 0.008) * 0.15
		modulate = Color(1.0, 0.45 * pulse, 0.05, 1.0)
	elif GameManager.slow_mo_active:
		modulate = Color(0.70, 0.95, 1.0, 1.0)   # chai slow-mo — cool blue shimmer
	else:
		modulate = Color.WHITE
