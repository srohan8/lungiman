extends CharacterBody2D

# ── Physics ───────────────────────────────────────────────────────────────────
const GRAVITY               := 1800.0
const JUMP_VELOCITY         := -480.0   # single hop — short, grounded feel
const DOUBLE_JUMP_VELOCITY  := -760.0   # second press in air — reaches current height
const SPEED                 := 294.0
const AIR_SPEED             := 186.0

# ── Platformer feel ───────────────────────────────────────────────────────────
const COYOTE_TIME       := 0.10
const JUMP_BUFFER_TIME  := 0.15
const JUMP_RELEASE_MULT := 0.50
const FALL_GRAV_MULT    := 1.60
const MAX_FALL_SPEED    := 900.0

# ── Tree climbing & catapult slingshot ───────────────────────────────────────
const CLIMB_DURATION       := 0.55    # time to climb trunk (DK side-climb)
const HERO_HALF_H          := -70.0   # body offset below crown (head clears leaf bunch)
## Catapult: hold [jump] → charge OSCILLATES 0→1→0→1 — player must time the release at peak.
## Releasing early (low charge) = weak hop; releasing at peak (charge≈1) = full fling.
const CATAPULT_CHARGE_TIME := 1.40    # half-period seconds (0→peak); full cycle = 2.80 s
const CATAPULT_SPEED_X     := 560.0   # max horizontal speed at full charge
const CATAPULT_MIN_SPEED_Y := -260.0  # vertical at charge 0 (barely lifts off)
const CATAPULT_MAX_SPEED_Y := -700.0  # vertical at charge 1 (full launch)

# ── River / water ─────────────────────────────────────────────────────────────
const WADE_SPEED_MULT    := 0.55
const WATER_DMG_INTERVAL := 2.5
const RIVER_DMG_COOLDOWN := 1.0

# ── Combat / roll ─────────────────────────────────────────────────────────────
const ROLL_SPEED    := 480.0
const ROLL_DURATION := 0.35
const ROLL_IFRAMES  := 0.40

# ── Mundu Whip (Odiyan's Tracks quest reward) ─────────────────────────────────
## Hold Z / sword for MUNDU_WHIP_HOLD seconds → cloth-arc lasso spins out and
## stuns/damages all enemies within MUNDU_WHIP_RADIUS.  Unlocked once the
## odiyan_tracks quest reaches state DONE (2).
const MUNDU_WHIP_HOLD   := 0.60   # seconds to hold sword button before whip fires
const MUNDU_WHIP_STUN   := 1.20   # whip animation + cooldown duration in seconds
const MUNDU_WHIP_RADIUS := 140.0  # area-of-effect radius (pixels)

# ── Screen shake ─────────────────────────────────────────────────────────────
const SHAKE_DECAY  := 3.8
const CAM_OFFSET_Y := -37.0    # ground at ~75% on 480×270; base for shake/sway

# ── Sprite sheet ─────────────────────────────────────────────────────────────
# Generated via Scenario.gg (Gemini 3 Flash + LungiMan reference + pose prompts).
# Each sheet is a 4×3 grid of 12 frames (idle is 6×3 = 18 cells, last 2 empty).
# Cell size derives from sheet size: width / cols, height / rows.
const HERO_SHEETS := {
	"idle":        {"path": "res://assets/sprites/Hero-idle.png",        "cols": 4, "rows": 3, "frames": 12, "fps":  8.0, "loop": true},
	"walk":        {"path": "res://assets/sprites/Hero-walk.png",        "cols": 4, "rows": 3, "frames": 12, "fps": 12.0, "loop": true},
	"run":         {"path": "res://assets/sprites/Hero-run.png",         "cols": 4, "rows": 3, "frames": 12, "fps": 16.0, "loop": true},
	"sword":       {"path": "res://assets/sprites/Hero-sword.png",       "cols": 4, "rows": 3, "frames": 12, "fps": 18.0, "loop": false},
	"sword2":      {"path": "res://assets/sprites/Hero-sword.png",       "cols": 4, "rows": 3, "frames": 12, "fps": 18.0, "loop": false},
	"swing_grab":  {"path": "res://assets/sprites/Hero-swing-grab.png",  "cols": 4, "rows": 3, "frames": 12, "fps": 12.0, "loop": false},
	"swing":       {"path": "res://assets/sprites/Hero-swing.png",       "cols": 4, "rows": 3, "frames": 12, "fps": 12.0, "loop": true},
	"throw":       {"path": "res://assets/sprites/Hero-throw.png",       "cols": 4, "rows": 3, "frames": 12, "fps": 14.0, "loop": false},
	"chai":        {"path": "res://assets/sprites/Hero-chai.png",        "cols": 4, "rows": 3, "frames": 12, "fps":  6.0, "loop": true},
	"mundu_lasso": {"path": "res://assets/sprites/Hero-mundu-lasso.png", "cols": 4, "rows": 3, "frames": 12, "fps": 12.0, "loop": false},
	"boxer_idle":  {"path": "res://assets/sprites/Hero-boxer-idle.png",  "cols": 4, "rows": 3, "frames": 12, "fps":  6.0, "loop": true},
}
const ANIM_COLORS := {
	"walk":       Color(0.20, 0.55, 1.00),
	"run":        Color(0.20, 0.55, 1.00),
	"idle":       Color(0.20, 0.55, 1.00),
	"swing_grab": Color(0.20, 0.80, 0.50),
	"swing":      Color(0.10, 0.90, 0.70),
	"sword":      Color(1.00, 0.85, 0.10),
	"sword2":     Color(1.00, 0.65, 0.10),
	"chai":       Color(0.85, 0.40, 0.10),
	"throw":      Color(0.90, 0.60, 0.10),
}

var   _throw_anim_timer  := 0.0
const THROW_ANIM_DUR     := 0.70   # display cap for the throw animation

enum TreeState { NONE, CLIMBING, PERCHED, FLYING }

# ── State ─────────────────────────────────────────────────────────────────────
var tree_state   := TreeState.NONE
var climb_tree:  Node2D = null
var near_tree:   Node2D = null
var climb_start  := Vector2.ZERO
var climb_target := Vector2.ZERO
var climb_t      := 0.0
var face         := 1

var _catapult_charge: float = 0.0   # 0.0–1.0, builds while jump held at crown
var _catapult_held:   float = 0.0   # seconds since jump first pressed at crown

var coyote_timer      := 0.0
var jump_buffer       := 0.0
var _can_double_jump  := false   # armed after first jump, consumed by second

var sword_phase   := 0
var sword_t       := 0.0
var sword_hit     := false

var _mundu_whip_charge: float = 0.0   # > 0 = charging; after fire = cooldown countdown
var _mundu_whip_active: bool  = false  # true while whip animation/cooldown blocks sword

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
var _qm: Node = null   # QuestManager resolved at runtime

## Worn-down visual tiers — sprite wear mirrors the Nilavilakku lamp states.
## No number. The character himself shows how close he is to finished.
## Tier 0 = full  · Tier 1 = 75%  · Tier 2 = 50%  · Tier 3 = 25%  · Tier 4 = critical
var _wear_tier: int = 0

## Tints per tier — subtle desaturation + warm-red shift as damage accumulates.
## Maveli-blessed override: golden tint replaces all worn states.
const WEAR_TINTS := [
	Color(1.0,  1.0,  1.0,  1.0),   # 0 — full, no tint
	Color(1.0,  0.97, 0.94, 1.0),   # 1 — 75%, barely perceptible warmth
	Color(1.0,  0.90, 0.82, 1.0),   # 2 — 50%, slight sepia
	Color(1.0,  0.80, 0.72, 1.0),   # 3 — 25%, visible wear
	Color(1.0,  0.68, 0.60, 1.0),   # 4 — critical, reddish, he's done
]
const WEAR_TINT_MAVELI := Color(1.0, 0.95, 0.75, 1.0)   # Maveli gold, replaces all tiers

signal climb_prompt_changed(is_visible: bool)

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	z_index = 6   # render in front of ground tile (z=5)
	collision_layer = 2
	collision_mask  = 1
	_qm = get_node_or_null("/root/QuestManager")
	_load_sprite_frames()

## Flip to true to revert to flat-rectangle placeholders if a sheet load fails or
## you want to debug game state without sprite art. Default false now that the
## Scenario.gg sheets are wired.
const USE_PLACEHOLDER_SPRITES := false

func _build_placeholder_frames() -> void:
	var sf := SpriteFrames.new()
	for anim_name: String in ANIM_COLORS:
		var img := Image.create(30, 60, false, Image.FORMAT_RGBA8)
		img.fill(ANIM_COLORS[anim_name])
		var tex := ImageTexture.create_from_image(img)
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, anim_name != &"throw" and anim_name != &"sword" and anim_name != &"sword2")
		sf.set_animation_speed(anim_name, 8.0)
		sf.add_frame(anim_name, tex)
	$AnimatedSprite2D.sprite_frames = sf
	$AnimatedSprite2D.scale         = Vector2.ONE
	$AnimatedSprite2D.play("idle")

## Loads each Scenario.gg sheet as an AtlasTexture grid into one SpriteFrames.
## Falls back to placeholders if no sheet exists on disk.
func _load_sprite_frames() -> void:
	if USE_PLACEHOLDER_SPRITES:
		_build_placeholder_frames()
		return
	var sf := SpriteFrames.new()
	for anim_name: String in HERO_SHEETS:
		var d: Dictionary = HERO_SHEETS[anim_name]
		var path: String  = d["path"]
		if not ResourceLoader.exists(path):
			push_warning("Hero sprite sheet missing: " + path)
			continue
		var sheet: Texture2D = load(path)
		var cols: int  = d["cols"]
		var rows: int  = d["rows"]
		var total: int = d["frames"]
		var fw: int = int(float(sheet.get_width())  / float(cols))
		var fh: int = int(float(sheet.get_height()) / float(rows))
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, d["loop"])
		sf.set_animation_speed(anim_name, d["fps"])
		var added := 0
		for row: int in rows:
			for col: int in cols:
				if added >= total: break
				var at := AtlasTexture.new()
				at.atlas  = sheet
				at.region = Rect2(col * fw, row * fh, fw, fh)
				sf.add_frame(anim_name, at)
				added += 1
			if added >= total: break
	$AnimatedSprite2D.sprite_frames = sf
	$AnimatedSprite2D.play("idle")

## Worn-down tier — driven by GRIT (journey wear), not HP (combat health).
## Grit only drops per boss defeated, so tints reflect cumulative toll not moment-to-moment damage.
## Maveli's blessing in Pathalam overrides all tiers with sacred gold tint.
func _update_wear_tier() -> void:
	var ratio: float = float(GameManager.grit) / 100.0
	var new_tier: int
	if   ratio > 0.75: new_tier = 0
	elif ratio > 0.50: new_tier = 1
	elif ratio > 0.25: new_tier = 2
	elif ratio > 0.10: new_tier = 3
	else:              new_tier = 4

	if new_tier == _wear_tier: return   # no change — skip modulate write
	_wear_tier = new_tier

	var blessed: bool = GameManager.get("maveli_blessed") == true
	var tint: Color   = WEAR_TINT_MAVELI if blessed else WEAR_TINTS[_wear_tier]

	# Tween the modulate change — sudden color shifts feel cheap, slow feels earned
	var tw := create_tween()
	tw.tween_property($AnimatedSprite2D, "modulate", tint, 0.8).set_trans(Tween.TRANS_SINE)

	# Tier 4 (critical): slow the idle animation — fatigue visible in the body
	if $AnimatedSprite2D.animation == "idle":
		$AnimatedSprite2D.speed_scale = 0.55 if new_tier == 4 else 1.0

func _process(delta: float) -> void:
	_update_wear_tier()
	# Always queue_redraw — guarantees the rope line is cleared the frame after
	# lasso_state goes to 0 (otherwise the last drawn frame stays burned in).
	queue_redraw()
	if _shake_trauma > 0.0:
		_shake_trauma = maxf(0.0, _shake_trauma - SHAKE_DECAY * delta)
		var shake := _shake_trauma * _shake_trauma
		$Camera2D.offset = Vector2(randf_range(-1.0, 1.0) * shake * 18.0,
								   CAM_OFFSET_Y + randf_range(-1.0, 1.0) * shake * 18.0)
	elif GameManager.toddy_active:
		# Toddy dizziness — slow rolling sway, gets worse mid-duration
		var sway := sin(Time.get_ticks_msec() * 0.0025) * 14.0
		$Camera2D.offset = Vector2(sway, CAM_OFFSET_Y + sin(Time.get_ticks_msec() * 0.004) * 5.0)
	else:
		$Camera2D.offset = Vector2(0.0, CAM_OFFSET_Y)
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
	river_dmg_cooldown  = maxf(0.0, river_dmg_cooldown - delta)
	iframe_timer        = maxf(0.0, iframe_timer - delta)
	_throw_anim_timer   = maxf(0.0, _throw_anim_timer - delta)
	if in_water:
		_water_dmg_timer -= delta
		if _water_dmg_timer <= 0.0:
			_water_dmg_timer = WATER_DMG_INTERVAL
			take_damage(8)
	move_and_slide()
	emit_signal("climb_prompt_changed", near_tree != null and tree_state == TreeState.NONE)

func _process_none(delta: float, do_climb: bool) -> void:
	if is_on_floor():
		coyote_timer     = COYOTE_TIME
		_can_double_jump = false   # reset on landing
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
		# First jump (ground or coyote window)
		velocity.y       = JUMP_VELOCITY
		jump_buffer      = 0.0
		coyote_timer     = 0.0
		_can_double_jump = true    # arm double-jump
	elif Input.is_action_just_pressed("jump") and _can_double_jump:
		# Double jump — second press while airborne
		velocity.y       = DOUBLE_JUMP_VELOCITY
		_can_double_jump = false
		jump_buffer      = 0.0
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
		face         = int(sign(climb_tree.position.x - position.x))   # face the trunk
		tree_state   = TreeState.CLIMBING
		velocity     = Vector2.ZERO

func _process_climbing(delta: float) -> void:
	climb_t += delta / CLIMB_DURATION
	var t    := minf(climb_t, 1.0)
	# DK style: phase 1 (0–20%) slide to trunk side; phase 2 (20–100%) climb straight up
	var trunk_x := climb_tree.position.x - float(face) * 14.0
	var crown_y: float = (climb_tree.get_crown_position() - Vector2(0.0, HERO_HALF_H)).y
	if t < 0.20:
		position.x = lerpf(climb_start.x, trunk_x, t / 0.20)
		position.y = climb_start.y
	else:
		var t2    := (t - 0.20) / 0.80
		var eased := 1.0 - (1.0 - t2) * (1.0 - t2)
		position.x = trunk_x
		position.y = lerpf(climb_start.y, crown_y, eased)
	velocity = Vector2.ZERO
	if climb_t >= 1.0:
		position   = climb_tree.get_crown_position() - Vector2(0.0, HERO_HALF_H)
		tree_state = TreeState.PERCHED
		_show_first_perch_hint()

func _process_perched(delta: float, do_climb: bool) -> void:
	position = climb_tree.get_crown_position() - Vector2(0.0, HERO_HALF_H)
	velocity = Vector2.ZERO
	var h := Input.get_axis("move_left", "move_right")
	if h != 0.0: face = int(sign(h))
	$AnimatedSprite2D.flip_h = (face < 0)
	# E / climb button → drop from crown
	if do_climb:
		_abort_catapult()
		velocity.y = 300.0
		tree_state = TreeState.NONE
		climb_tree = null
		return
	# Hold [jump] → charge oscillates 0→1→0→1; release at peak for a full-power launch.
	# Releasing at a trough = weak hop. Holding longer = more chances to hit the peak.
	if Input.is_action_pressed("jump"):
		_catapult_held  += delta
		# (1 − cos θ) / 2  gives a smooth 0→1→0→1 wave with period = 2 × CATAPULT_CHARGE_TIME
		var angle := _catapult_held * PI / CATAPULT_CHARGE_TIME
		_catapult_charge = (1.0 - cos(angle)) * 0.5
		if climb_tree != null and climb_tree.has_method("set_catapult_bend"):
			climb_tree.set_catapult_bend(_catapult_charge, face)
	elif Input.is_action_just_released("jump"):
		_fire_catapult()   # always launch — charge level determines power

func _process_flying(delta: float) -> void:
	# Appam Glide (quest reward): hold jump while falling to slow descent
	var has_glide: bool = _qm != null and _qm.get_state("swing_off_race") == 2
	if has_glide and velocity.y > 0.0 and Input.is_action_just_pressed("jump"):
		glide_timer = GLIDE_DURATION
	if glide_timer > 0.0:
		glide_timer -= delta
		velocity.y   = minf(velocity.y + GRAVITY * GLIDE_GRAV_MULT * delta, GLIDE_MAX_FALL)
	else:
		velocity.y   = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	var move_dir := Input.get_axis("move_left", "move_right")
	if move_dir != 0.0:
		face       = int(sign(move_dir))
		velocity.x = move_dir * AIR_SPEED
	if is_on_floor():
		tree_state  = TreeState.NONE
		glide_timer = 0.0


func _fire_catapult() -> void:
	var c      := _catapult_charge
	velocity.x  = float(face) * CATAPULT_SPEED_X * c
	velocity.y  = lerpf(CATAPULT_MIN_SPEED_Y, CATAPULT_MAX_SPEED_Y, c)
	if climb_tree != null and climb_tree.has_method("spring_back"):
		climb_tree.spring_back()
	_catapult_charge = 0.0
	_catapult_held   = 0.0
	tree_state = TreeState.FLYING
	climb_tree = null

func _abort_catapult() -> void:
	if _catapult_charge > 0.001:
		if climb_tree != null and climb_tree.has_method("spring_back"):
			climb_tree.spring_back()
	_catapult_charge = 0.0
	_catapult_held   = 0.0

func _draw() -> void:
	# While charging catapult at crown: draw a growing arc above player's head.
	# Green (low charge) → orange-red (full charge). Radius grows with charge.
	if tree_state == TreeState.PERCHED and _catapult_charge > 0.001:
		var c   := _catapult_charge
		var col := Color(0.12 + c * 0.88, 0.92 - c * 0.72, 0.05, 0.90)
		draw_arc(Vector2(0.0, -55.0), 14.0 + c * 10.0,
			-PI * 0.5, -PI * 0.5 + c * TAU, 20, col, 3.5)

func perch_on(tree: Node2D) -> void:
	if tree_state != TreeState.FLYING: return
	tree_state = TreeState.PERCHED
	climb_tree = tree
	velocity   = Vector2.ZERO
	position   = tree.get_crown_position() - Vector2(0.0, HERO_HALF_H)
	_show_first_perch_hint()

## First time the player lands on a crown — surface the rope mechanic.
## The hint is owned by GameManager so it doesn't re-fire on scene reload.
func _show_first_perch_hint() -> void:
	if GameManager.hint_first_perch_seen: return
	GameManager.hint_first_perch_seen = true
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_hint"):
		hud.show_hint("🌴 Hold [Space] to bend the tree — release to catapult!", 5.0)

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
	# ── Whip cooldown — blocks normal sword while animation plays ────────────
	if _mundu_whip_active:
		_mundu_whip_charge = maxf(0.0, _mundu_whip_charge - delta)
		if _mundu_whip_charge <= 0.0:
			_mundu_whip_active = false
		return

	# ── Sword phase in progress — tick phases and bail ────────────────────────
	if sword_phase > 0:
		sword_t += delta
		match sword_phase:
			1:
				if sword_t > 0.15: sword_phase = 2; sword_t = 0.0
			2:
				if not sword_hit: _check_sword_hit()
				if sword_t > 0.20: sword_phase = 3; sword_t = 0.0
			3:
				if sword_t > 0.15: sword_phase = 0
		return

	# ── sword_phase == 0: accept new input ────────────────────────────────────
	var has_whip: bool = _qm != null and _qm.get_state("odiyan_tracks") == 2

	if has_whip and tree_state == TreeState.NONE:
		# Charged-hold system: tap → normal sword; hold 0.6s → mundu whip
		if Input.is_action_just_pressed("sword"):
			_mundu_whip_charge = 0.001   # non-zero = "charging" sentinel

		if _mundu_whip_charge > 0.0:
			if Input.is_action_pressed("sword"):
				_mundu_whip_charge += delta
				if _mundu_whip_charge >= MUNDU_WHIP_HOLD:
					# Threshold reached — fire the whip
					_mundu_whip_charge = MUNDU_WHIP_STUN   # repurposed as cooldown
					_mundu_whip_active = true
					_fire_mundu_whip()
					return
			else:
				# Released before threshold — treat as quick tap, fire normal sword
				_mundu_whip_charge = 0.0
				sword_phase = 1; sword_t = 0.0; sword_hit = false
	else:
		# Whip not yet unlocked — instant normal sword on just_pressed
		_mundu_whip_charge = 0.0
		if Input.is_action_just_pressed("sword") and tree_state == TreeState.NONE:
			sword_phase = 1; sword_t = 0.0; sword_hit = false

func _check_sword_hit() -> void:
	sword_hit   = true
	var reach   := 50.0
	var hit_off := Vector2(face * (20.0 + reach * 0.5), 0.0)
	var hit_box := Rect2(global_position + hit_off - Vector2(reach * 0.5, 30.0), Vector2(reach, 60.0))
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy): continue
		if hit_box.has_point(enemy.global_position):
			enemy.take_damage(30 * GameManager.damage_multiplier())

## Mundu Whip — cloth arc spins 360° and damages every enemy within MUNDU_WHIP_RADIUS.
## Visual: white-and-gold ColorRect spins out in world-space as a 2-frame gesture.
## Mechanical: calls whip_stun(duration) if available, otherwise take_damage(20).
## Fired from _handle_sword when sword button is held for MUNDU_WHIP_HOLD seconds.
func _fire_mundu_whip() -> void:
	# ── Visual: spinning cloth arc in world-space ────────────────────────────
	var cloth := ColorRect.new()
	cloth.color        = Color(0.95, 0.93, 0.82, 0.90)   # white mundu fabric
	cloth.size         = Vector2(52.0, 9.0)
	cloth.pivot_offset = Vector2(0.0, 4.5)
	cloth.global_position = global_position + Vector2(float(face) * 8.0, -28.0)
	cloth.rotation     = 0.0
	get_parent().add_child(cloth)

	# Gold border stripe
	var gold := ColorRect.new()
	gold.color    = Color(1.0, 0.80, 0.10, 1.0)
	gold.size     = Vector2(52.0, 4.0)
	gold.position = Vector2(0.0, 5.0)
	cloth.add_child(gold)

	# Arc tween: full 360° spin then fade
	var tw := cloth.create_tween()
	tw.tween_property(cloth, "rotation", float(face) * TAU, 0.42).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cloth, "modulate:a", 0.0, 0.22)
	tw.tween_callback(cloth.queue_free)

	# ── Play mundu_lasso anim if it exists ────────────────────────────────────
	var spr := $AnimatedSprite2D
	if spr.sprite_frames.has_animation("mundu_lasso"):
		spr.play("mundu_lasso")

	# ── Hit all enemies within radius ────────────────────────────────────────
	var hit_count := 0
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy): continue
		if global_position.distance_to(enemy.global_position) > MUNDU_WHIP_RADIUS: continue
		if enemy.has_method("whip_stun"):
			enemy.whip_stun(MUNDU_WHIP_STUN)
		else:
			enemy.take_damage(20 * GameManager.damage_multiplier())
		hit_count += 1

	if hit_count > 0:
		add_trauma(0.22)   # mild impact shake

func _handle_coconut() -> void:
	# Allow throws from ground AND from tree crown (key tactic vs aerial bosses)
	var can_throw := tree_state == TreeState.NONE or tree_state == TreeState.PERCHED
	if Input.is_action_just_pressed("coconut") and GameManager.ammo > 0 and can_throw:
		GameManager.ammo -= 1
		_throw_anim_timer = THROW_ANIM_DUR
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
	if _qm == null or _qm.get_state("chaya_kada_showdown") != 2:
		return false
	for npc: Node in get_tree().get_nodes_in_group("tea_shop"):
		if global_position.distance_to(npc.global_position) < 300.0:
			return true
	return false

# Scale for all hero sheets (Scenario.gg 4K grids, 1194px tall cell → 110px on-screen).
# 110 / 1194 ≈ 0.092  →  sprite bottom lands at y≈-17, collision bottom at y=-18 (1px error).
# Matches NPC TARGET_H=110 so hero, Thoma, Soniya, and Biju all render at the same height.
const GRID_SHEET_SCALE := 0.060

func _set_sprite_scale(_anim: StringName) -> void:
	if USE_PLACEHOLDER_SPRITES:
		if $AnimatedSprite2D.scale != Vector2.ONE:
			$AnimatedSprite2D.scale = Vector2.ONE
		return
	$AnimatedSprite2D.scale = Vector2(GRID_SHEET_SCALE, GRID_SHEET_SCALE)

func _update_animation() -> void:
	var spr := $AnimatedSprite2D
	# Priority: sword > throw > tree states > run/idle
	if sword_phase > 0:
		var anim: StringName = &"sword" if sword_phase <= 2 else &"sword2"
		if spr.animation != anim: spr.play(anim)
		_set_sprite_scale(anim)
		spr.flip_h = (face < 0)
		return
	if _throw_anim_timer > 0.0 and tree_state == TreeState.NONE:
		if spr.sprite_frames.has_animation(&"throw"):
			if spr.animation != &"throw": spr.play(&"throw")
			_set_sprite_scale(&"throw")
			spr.flip_h = (face < 0)
			return
	var target_anim: StringName
	match tree_state:
		TreeState.CLIMBING, TreeState.PERCHED:
			target_anim = &"swing_grab"
		TreeState.FLYING:
			target_anim = &"swing_grab"   # airborne after catapult
		_:
			if not is_on_floor():
				# Airborne — freeze on idle pose, no leg cycling mid-air
				target_anim = &"idle"
			else:
				var move_anim: StringName = &"run" if spr.sprite_frames.has_animation(&"run") else &"walk"
				target_anim = move_anim if absf(velocity.x) > 10.0 else &"idle"
	if spr.sprite_frames.has_animation(target_anim) and spr.animation != target_anim:
		spr.play(target_anim)
	_set_sprite_scale(target_anim)
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
