extends Node2D

## ACT II COLD OPEN — Ravi's Bullet
## Screen-space side-scrolling bike runner. No Player.tscn. No GameManager HP during the ride.
##
## Layout (480 × 270 viewport, Y down):
##   Road surface  y ≈ 195   (drawn as a flat strip)
##   Bike centre   y ≈ 178   (rider sits above road, feet at y ≈ 195)
##   Sky ceiling   y =   0
##   Ground strip  y = 195 – 270 (road + kerb + trees)
##
## The bike is fixed at screen x ≈ 150. The world scrolls left.
## Engine Health tracks punishment: 3 hard hits stall the bike.
## Undamaged run sets GameManager.bike_undamaged = true for Ravi's Act V callback.

const NEXT_SCENE       := "res://scenes/Act2.tscn"
const VIEWPORT_W       := 480.0
const VIEWPORT_H       := 270.0

# ── Physics ────────────────────────────────────────────────────────────────────
const ROAD_Y           := 195.0    # ground surface y
const BIKE_X           := 152.0    # fixed screen x
const BIKE_REST_Y      := 178.0    # bike centre y on ground
const JUMP_V           := -380.0   # initial upward velocity on jump
const GRAVITY          := 980.0    # px s⁻²
const MIN_SPEED        := 180.0    # px s⁻¹ (idle scroll)
const MAX_SPEED        := 320.0    # px s⁻¹ (full throttle)
const ACCEL_RATE       := 9.0      # px s⁻³

# ── Engine health ──────────────────────────────────────────────────────────────
const ENGINE_MAX       := 100
const OBSTACLE_DMG     := 34       # ~3 hits to stall (34×3 = 102)
const IFRAME_DURATION  := 0.9      # invincibility after a hit

# ── Ride distance ──────────────────────────────────────────────────────────────
const RIDE_DIST        := 7200.0   # world units before end-sequence fires
const END_DECEL        := 95.0     # px s⁻² deceleration during end-sequence

# ── Parallax speeds (fraction of scroll speed) ────────────────────────────────
const LAYER_SPEEDS: Array[float]  = [0.15, 0.45, 0.80]   # far / mid / near
const LAYER_Y: Array[float]       = [20.0, 60.0, 145.0]   # sky-glow / trees / road-cover
const LAYER_H: Array[float]       = [60.0, 80.0, 50.0]    # stripe heights
const LAYER_COLORS: Array[Color]  = [
	Color(0.95, 0.60, 0.15, 0.22),   # far  — warm orange glow of festival lights
	Color(0.15, 0.30, 0.10, 0.90),   # mid  — dark jungle trees
	Color(0.18, 0.14, 0.08, 0.80),   # near — road-edge mud / kerb
]
# Tile widths for each layer (visual variety)
const TILE_WIDTHS: Array[float]   = [480.0, 240.0, 160.0]

# ── Obstacle definitions [type, w, h, anim?] ──────────────────────────────────
const OBS_DEFS := {
	"pothole":     {"w": 36.0,  "h": 8.0,   "color": Color(0.10, 0.08, 0.06), "ground": true},
	"crowd":       {"w": 28.0,  "h": 64.0,  "color": Color(0.70, 0.45, 0.20), "ground": false},
	"goat":        {"w": 24.0,  "h": 28.0,  "color": Color(0.82, 0.80, 0.75), "ground": false},
	"cart":        {"w": 56.0,  "h": 36.0,  "color": Color(0.55, 0.38, 0.15), "ground": false},
	"firecracker": {"w": 14.0,  "h": 14.0,  "color": Color(1.00, 0.70, 0.10), "ground": false},
}
# Spawn schedule: [world_x, type]
const SPAWN_SCHEDULE := [
	[320.0,  "crowd"],
	[700.0,  "pothole"],
	[1050.0, "goat"],
	[1400.0, "crowd"],
	[1750.0, "pothole"],
	[2100.0, "cart"],
	[2500.0, "crowd"],
	[2850.0, "goat"],
	[3200.0, "firecracker"],
	[3600.0, "pothole"],
	[3900.0, "cart"],
	[4300.0, "crowd"],
	[4700.0, "pothole"],
	[5100.0, "goat"],
	[5500.0, "cart"],
	[5900.0, "firecracker"],
	[6300.0, "crowd"],
	[6700.0, "pothole"],
]

# ── State ──────────────────────────────────────────────────────────────────────
var _scroll_x       := 0.0      # world distance scrolled so far
var _speed          := MIN_SPEED
var _bike_y         := BIKE_REST_Y
var _bike_vy        := 0.0
var _on_ground      := true
var _engine_hp      := ENGINE_MAX
var _iframe_timer   := 0.0
var _undamaged      := true     # true unless any hit
var _phase          := "intro"  # "intro" | "ride" | "end" | "done"
var _end_timer      := 0.0
var _intro_timer    := 0.0
var _spawn_idx      := 0        # next index in SPAWN_SCHEDULE to check
var _obstacles      := []       # active obstacle ColorRects + screen_x metadata
var _did_end_quote  := false

# ── Visual nodes (built in _ready) ────────────────────────────────────────────
var _bike_rect      : ColorRect = null
var _wheel_f        : ColorRect = null
var _wheel_r        : ColorRect = null
var _rider_body     : ColorRect = null
var _rider_head     : ColorRect = null
var _engine_bar     : ColorRect = null
var _engine_label   : Label     = null
var _hud_layer      : CanvasLayer = null
var _dialogue_label : Label       = null
var _parallax_rects : Array       = []    # [[ColorRect, ColorRect], ...]  tile pairs per layer
var _tree_pairs     : Array       = []    # [[crown_rect, trunk_rect], ...] — jungle treeline

# ── Ravi handover NPC (screen-space, visible only during intro) ───────────────
const RAVI_SCREEN_X := BIKE_X + 56.0   # stands to the right of the bike
var _ravi_pieces    : Array = []        # all ColorRect/Label nodes; tweened off together
var _key_piece      : ColorRect = null  # the gold key — floats to hero at t=2.3s
var _arm_piece      : ColorRect = null  # the outstretched arm — waves on dismiss
var _key_tween      : Tween     = null  # looping bob tween on the key
var _key_taken      := false            # guard so key handover fires only once

# ── Forest transition (midpoint) ──────────────────────────────────────────────
var _sky_rect                : ColorRect = null   # ref to sky background
var _festival_dots           : Array     = []     # all amber dot ColorRects
var _forest_transition_done  : bool      = false  # fires only once

func _ready() -> void:
	_build_scene()
	_start_intro()

# ─────────────────────────────────────────────────────────────────────────────
# Scene construction
# ─────────────────────────────────────────────────────────────────────────────

func _build_scene() -> void:
	# Sky background — festival twilight
	var sky := ColorRect.new()
	sky.size     = Vector2(VIEWPORT_W, VIEWPORT_H)
	sky.position = Vector2.ZERO
	sky.color    = Color(0.10, 0.04, 0.12, 1.0)   # deep purple-black
	sky.z_index  = -10
	add_child(sky)
	_sky_rect = sky   # saved for forest transition

	# Festival light dots in the sky — static, scattered amber sparks
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for _i: int in 40:
		var dot := ColorRect.new()
		dot.size     = Vector2(rng.randf_range(2.0, 5.0), rng.randf_range(1.0, 3.0))
		dot.position = Vector2(rng.randf_range(0.0, VIEWPORT_W), rng.randf_range(5.0, 120.0))
		dot.color    = Color(rng.randf_range(0.85, 1.0), rng.randf_range(0.50, 0.80), 0.10, rng.randf_range(0.4, 0.9))
		dot.z_index  = -8
		add_child(dot)
		_festival_dots.append(dot)   # saved for forest transition fade-out

	# Parallax layers — two tiling ColorRects each so we can wrap without seam.
	# Layer 1 (mid / jungle trees) is replaced by _build_tree_skyline() below.
	for i: int in LAYER_SPEEDS.size():
		if i == 1:
			_parallax_rects.append([])   # placeholder so indices stay aligned
			continue
		var tile_w: float = TILE_WIDTHS[i]
		var pair: Array = []
		for t: int in 2:
			var r := ColorRect.new()
			r.size     = Vector2(tile_w + 2.0, LAYER_H[i])
			r.position = Vector2(tile_w * float(t), LAYER_Y[i])
			r.color    = LAYER_COLORS[i]
			r.z_index  = -6 + i
			add_child(r)
			pair.append(r)
		_parallax_rects.append(pair)

	_build_tree_skyline()

	# Road surface — two-tone asphalt strip
	var road := ColorRect.new()
	road.size     = Vector2(VIEWPORT_W, 75.0)
	road.position = Vector2(0.0, ROAD_Y)
	road.color    = Color(0.16, 0.14, 0.12, 1.0)
	road.z_index  = -4
	add_child(road)

	# Road centre line — scrolling dashed white
	for seg: int in 7:
		var dash := ColorRect.new()
		dash.size     = Vector2(28.0, 3.0)
		dash.position = Vector2(float(seg) * 70.0, ROAD_Y + 10.0)
		dash.color    = Color(0.90, 0.85, 0.70, 0.55)
		dash.z_index  = -3
		dash.set_meta("dash", true)
		dash.set_meta("base_x", float(seg) * 70.0)
		add_child(dash)

	# ── Bike (Royal Enfield Bullet silhouette) ──────────────────────────────
	# Rear wheel
	_wheel_r = ColorRect.new()
	_wheel_r.size     = Vector2(18.0, 18.0)
	_wheel_r.color    = Color(0.12, 0.10, 0.08, 1.0)
	add_child(_wheel_r)

	# Front wheel
	_wheel_f = ColorRect.new()
	_wheel_f.size     = Vector2(18.0, 18.0)
	_wheel_f.color    = Color(0.12, 0.10, 0.08, 1.0)
	add_child(_wheel_f)

	# Fuel tank / frame body — dark green classic Bullet
	_bike_rect = ColorRect.new()
	_bike_rect.size  = Vector2(54.0, 18.0)
	_bike_rect.color = Color(0.15, 0.28, 0.15, 1.0)   # deep forest green
	add_child(_bike_rect)

	# Rider torso — white mundu visible (he IS lungi man after all)
	_rider_body = ColorRect.new()
	_rider_body.size  = Vector2(16.0, 24.0)
	_rider_body.color = Color(0.88, 0.86, 0.80, 1.0)
	add_child(_rider_body)

	# Rider head
	_rider_head = ColorRect.new()
	_rider_head.size  = Vector2(12.0, 12.0)
	_rider_head.color = Color(0.72, 0.55, 0.38, 1.0)
	add_child(_rider_head)

	_position_bike(BIKE_REST_Y)
	_build_ravi_handover()

	# ── Engine HUD ──────────────────────────────────────────────────────────
	_hud_layer        = CanvasLayer.new()
	_hud_layer.layer  = 10
	add_child(_hud_layer)

	var eng_bg := ColorRect.new()
	eng_bg.size     = Vector2(102.0, 12.0)
	eng_bg.position = Vector2(8.0, 8.0)
	eng_bg.color    = Color(0.10, 0.08, 0.08, 0.85)
	_hud_layer.add_child(eng_bg)

	_engine_bar           = ColorRect.new()
	_engine_bar.size      = Vector2(100.0, 10.0)
	_engine_bar.position  = Vector2(9.0, 9.0)
	_engine_bar.color     = Color(0.20, 0.72, 0.28, 1.0)
	_hud_layer.add_child(_engine_bar)

	_engine_label           = Label.new()
	_engine_label.text      = "ENGINE"
	_engine_label.position  = Vector2(8.0, 20.0)
	_engine_label.add_theme_font_size_override("font_size", 8)
	_engine_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.60, 0.80))
	_hud_layer.add_child(_engine_label)

	# ── Dialogue label ──────────────────────────────────────────────────────
	_dialogue_label           = Label.new()
	_dialogue_label.position  = Vector2(8.0, VIEWPORT_H - 44.0)
	_dialogue_label.size      = Vector2(VIEWPORT_W - 16.0, 40.0)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_dialogue_label.add_theme_font_size_override("font_size", 9)
	_dialogue_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_dialogue_label.visible              = false
	_hud_layer.add_child(_dialogue_label)

## Jungle treeline — 24 crown+trunk pairs spread over 960 px (2× viewport) for seamless wrap.
## Each tree has a random height and width to break the uniform silhouette.
func _build_tree_skyline() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 54321
	var base_y: float = LAYER_Y[1] + LAYER_H[1]   # 140.0 — just above near-road strip

	for i: int in 24:
		var tx     := float(i) * 40.0 + rng.randf_range(-7.0, 7.0)
		var th     := rng.randf_range(52.0, 90.0)    # total tree height (px)
		var cw     := rng.randf_range(24.0, 44.0)    # crown width
		var tw_px  := rng.randf_range(5.0, 9.0)      # trunk width

		# Crown — the wide leafy mass
		var crown := ColorRect.new()
		crown.size     = Vector2(cw, th * 0.60)
		crown.position = Vector2(tx - cw * 0.5, base_y - th)
		crown.color    = Color(0.09, 0.20, 0.07, 1.0)   # dark jungle green
		crown.z_index  = -5
		add_child(crown)

		# Trunk — slim column below crown, slightly darker
		var trunk := ColorRect.new()
		trunk.size     = Vector2(tw_px, th * 0.45)
		trunk.position = Vector2(tx - tw_px * 0.5, base_y - th * 0.46)
		trunk.color    = Color(0.07, 0.12, 0.05, 1.0)
		trunk.z_index  = -5
		add_child(trunk)

		_tree_pairs.append([crown, trunk])

func _position_bike(cy: float) -> void:
	# cy = centre y of bike body
	_bike_rect.position    = Vector2(BIKE_X - 27.0, cy - 9.0)
	_wheel_r.position      = Vector2(BIKE_X - 30.0, cy + 4.0)
	_wheel_f.position      = Vector2(BIKE_X + 18.0, cy + 4.0)
	_rider_body.position   = Vector2(BIKE_X - 4.0,  cy - 30.0)
	_rider_head.position   = Vector2(BIKE_X - 2.0,  cy - 42.0)

## Mundakkal Ravi standing next to the bike for the handover — screen-space, visible only during intro.
## He holds a golden key toward LungiMan. When the ride phase starts he's tweened off-screen right.
func _build_ravi_handover() -> void:
	var ry := BIKE_REST_Y   # ground y

	# Mundu (white lower garment)
	var mundu := ColorRect.new()
	mundu.size     = Vector2(14.0, 16.0)
	mundu.position = Vector2(RAVI_SCREEN_X - 7.0, ry - 16.0)
	mundu.color    = Color(0.92, 0.90, 0.85, 1.0)
	mundu.z_index  = 5
	add_child(mundu)
	_ravi_pieces.append(mundu)

	# Shirt / torso
	var torso := ColorRect.new()
	torso.size     = Vector2(14.0, 14.0)
	torso.position = Vector2(RAVI_SCREEN_X - 7.0, ry - 30.0)
	torso.color    = Color(0.55, 0.30, 0.15, 1.0)   # brown kurta
	torso.z_index  = 5
	add_child(torso)
	_ravi_pieces.append(torso)

	# Head
	var head := ColorRect.new()
	head.size     = Vector2(10.0, 10.0)
	head.position = Vector2(RAVI_SCREEN_X - 5.0, ry - 42.0)
	head.color    = Color(0.68, 0.50, 0.32, 1.0)
	head.z_index  = 5
	add_child(head)
	_ravi_pieces.append(head)

	# Extended arm holding the key (toward LungiMan = leftward)
	var arm := ColorRect.new()
	arm.size     = Vector2(12.0, 4.0)
	arm.position = Vector2(RAVI_SCREEN_X - 18.0, ry - 26.0)
	arm.color    = Color(0.68, 0.50, 0.32, 1.0)
	arm.z_index  = 5
	add_child(arm)
	_ravi_pieces.append(arm)
	_arm_piece = arm   # saved for wave gesture on dismiss

	# Key — small golden shape at the tip of his arm
	var key := ColorRect.new()
	key.size     = Vector2(7.0, 4.0)
	key.position = Vector2(RAVI_SCREEN_X - 22.0, ry - 28.0)
	key.color    = Color(0.92, 0.76, 0.18, 1.0)
	key.z_index  = 6
	add_child(key)
	_ravi_pieces.append(key)
	_key_piece = key   # saved so we can animate the handover
	# Key bobs gently toward LungiMan — "here, take it"
	_key_tween = key.create_tween().set_loops()
	_key_tween.tween_property(key, "position:x", RAVI_SCREEN_X - 24.0, 0.35).set_trans(Tween.TRANS_SINE)
	_key_tween.tween_property(key, "position:x", RAVI_SCREEN_X - 20.0, 0.35).set_trans(Tween.TRANS_SINE)

	# Name label above his head
	var lbl := Label.new()
	lbl.text     = "Ravi"
	lbl.position = Vector2(RAVI_SCREEN_X - 10.0, ry - 56.0)
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.50, 0.85))
	lbl.z_index  = 6
	add_child(lbl)
	_ravi_pieces.append(lbl)

## Ravi stays behind — bike rides away to the right, Ravi slides LEFT off screen.
## The arm raises briefly first (goodbye wave), then everything scrolls out left.
func _dismiss_ravi() -> void:
	# Wave: arm raises upward while the rest of the slide begins
	if is_instance_valid(_arm_piece):
		var wave := _arm_piece.create_tween()
		wave.tween_property(_arm_piece, "position:y",
				_arm_piece.position.y - 18.0, 0.22).set_trans(Tween.TRANS_SINE)
		wave.tween_property(_arm_piece, "position:y",
				_arm_piece.position.y,        0.18).set_trans(Tween.TRANS_SINE)

	# All pieces slide off to the LEFT — bike is speeding away right
	for piece: Variant in _ravi_pieces:
		if not is_instance_valid(piece): continue
		var node: Node2D = piece as Node2D
		if node == null: continue
		var tw := node.create_tween()
		tw.tween_interval(0.20)   # brief pause so the wave reads first
		tw.tween_property(node, "position:x", -120.0, 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(node.queue_free)
	_ravi_pieces.clear()

# ─────────────────────────────────────────────────────────────────────────────
# Intro sequence
# ─────────────────────────────────────────────────────────────────────────────

func _start_intro() -> void:
	_phase       = "intro"
	_intro_timer = 0.0
	# Bike barely creeps during intro — engine idling while keys are handed over
	_speed = MIN_SPEED * 0.25
	_show_dialogue("Mundakkal Ravi: \"Take my bike, machane.\nBut when the trees start — you walk.\"")

func _show_dialogue(text: String, duration: float = 3.2) -> void:
	_dialogue_label.text    = text
	_dialogue_label.visible = true
	_dialogue_label.modulate.a = 0.0
	var tw := _dialogue_label.create_tween()
	tw.tween_property(_dialogue_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(duration - 0.6)
	tw.tween_property(_dialogue_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: _dialogue_label.visible = false)

# ─────────────────────────────────────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	match _phase:
		"intro":   _tick_intro(delta)
		"ride":    _tick_ride(delta)
		"end":     _tick_end(delta)
		"done":    pass

func _tick_intro(delta: float) -> void:
	_intro_timer += delta
	# Engine idling — very slow creep while Ravi hands over the key
	_scroll_scene(_speed, delta)
	# t=2.3s — hero reaches out and takes the key
	if not _key_taken and _intro_timer >= 2.3:
		_key_taken = true
		_hero_takes_key()
	# t=3.5s — Ravi steps back and waves as the bike rides away
	if _intro_timer >= 3.5:
		_dismiss_ravi()
		_speed = MIN_SPEED       # throttle opens
		_phase = "ride"

## Hero accepts the key: the gold key floats left onto the bike, then vanishes.
func _hero_takes_key() -> void:
	if not is_instance_valid(_key_piece): return
	# Stop the bobbing loop
	if _key_tween != null:
		_key_tween.kill()
		_key_tween = null
	# Float the key toward the bike handlebars, then fade it out
	var tw := _key_piece.create_tween()
	tw.tween_property(_key_piece, "position:x", BIKE_X + 10.0, 0.28).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_key_piece, "modulate:a", 0.0, 0.20)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_key_piece):
			_ravi_pieces.erase(_key_piece)
			_key_piece.queue_free()
			_key_piece = null
	)

func _tick_ride(delta: float) -> void:
	# Accelerate up to MAX_SPEED unless engine is stalled
	if _engine_hp > 0:
		_speed = minf(_speed + ACCEL_RATE * delta, MAX_SPEED)
	else:
		_speed = maxf(_speed - END_DECEL * delta, 0.0)

	# Jump input
	var jump_just := Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump")
	if jump_just and _on_ground and _engine_hp > 0:
		_bike_vy  = JUMP_V
		_on_ground = false

	# Vertical physics
	if not _on_ground:
		_bike_vy  += GRAVITY * delta
		_bike_y   += _bike_vy * delta
		if _bike_y >= BIKE_REST_Y:
			_bike_y    = BIKE_REST_Y
			_bike_vy   = 0.0
			_on_ground = true

	_position_bike(_bike_y)

	# Scroll
	_scroll_scene(_speed, delta)

	# iframe countdown
	if _iframe_timer > 0.0:
		_iframe_timer -= delta
		# Flash the rider
		var vis := int(_iframe_timer * 10) % 2 == 0
		_rider_body.visible = vis
		_rider_head.visible = vis
	else:
		_rider_body.visible = true
		_rider_head.visible = true

	# Spawn obstacles
	_check_spawns()

	# Collision
	_check_collisions()

	# Remove off-screen obstacles
	_cull_obstacles()

	# Forest transition — village festival gives way to Kanjiravanam at the midpoint
	if not _forest_transition_done and _scroll_x >= RIDE_DIST * 0.5:
		_begin_forest_transition()

	# Transition to end sequence
	if _scroll_x >= RIDE_DIST:
		_begin_end_sequence()

func _tick_end(delta: float) -> void:
	_end_timer += delta
	# Decelerate
	_speed = maxf(_speed - END_DECEL * delta, 0.0)
	_scroll_scene(_speed, delta)
	_position_bike(_bike_y)

	# First moment: burning trees appear + Ravi's closing line
	if not _did_end_quote and _end_timer >= 0.5:
		_did_end_quote = true
		_show_dialogue("Ravi: \"The Bullet won't go where the spirits live.\"", 3.5)
		_spawn_burning_trees()

	# Exit — wait for dialogue + full stop
	if _end_timer >= 5.0 and _speed <= 0.0:
		_finish()

# ─────────────────────────────────────────────────────────────────────────────
# Scrolling helpers
# ─────────────────────────────────────────────────────────────────────────────

func _scroll_scene(spd: float, delta: float) -> void:
	var dx := spd * delta
	_scroll_x += dx

	# Parallax layers — tile wrap (layer 1 is empty — replaced by tree silhouettes)
	for i: int in _parallax_rects.size():
		var pair: Array   = _parallax_rects[i]
		if pair.is_empty():
			continue
		var sf: float     = LAYER_SPEEDS[i]
		var tile_w: float = TILE_WIDTHS[i]
		for r_v: Variant in pair:
			var r: ColorRect = r_v
			r.position.x -= dx * sf
		# Wrap: if the first tile has scrolled fully off screen, push it to the right of the second
		var a: ColorRect = pair[0]
		var b: ColorRect = pair[1]
		if a.position.x + tile_w < 0.0:
			a.position.x = b.position.x + tile_w
		if b.position.x + tile_w < 0.0:
			b.position.x = a.position.x + tile_w

	# Jungle treeline — scroll at mid-layer speed, wrap every 960 px
	var sf_tree: float = LAYER_SPEEDS[1]
	for pair_v: Variant in _tree_pairs:
		var pair: Array    = pair_v as Array
		var crown: ColorRect = pair[0] as ColorRect
		var trunk_r: ColorRect = pair[1] as ColorRect
		crown.position.x   -= dx * sf_tree
		trunk_r.position.x -= dx * sf_tree
		# When the crown fully exits the left edge, jump both pieces back 960 px
		if crown.position.x + crown.size.x < -2.0:
			crown.position.x   += 960.0
			trunk_r.position.x += 960.0

	# Road dashes — faster (near layer)
	for child: Node in get_children():
		if child is ColorRect and child.has_meta("dash"):
			child.position.x -= dx * 0.95
			# Wrap
			if child.position.x < -30.0:
				child.position.x += 490.0

	# Move active obstacles left
	for entry: Dictionary in _obstacles:
		entry["rect"].position.x -= dx

# ─────────────────────────────────────────────────────────────────────────────
# Forest background transition
# ─────────────────────────────────────────────────────────────────────────────

## Halfway through the ride the village festival is behind us — Kanjiravanam forest closes in.
## Cross-fades sky, fades festival lights, darkens trees, rolls in fog, spawns fireflies.
func _begin_forest_transition() -> void:
	_forest_transition_done = true
	const DUR := 2.2   # seconds for the full cross-fade

	# 1. Sky: festival purple-black → deep forest ember-black
	if is_instance_valid(_sky_rect):
		var tw := _sky_rect.create_tween()
		tw.tween_property(_sky_rect, "color",
				Color(0.06, 0.04, 0.02, 1.0), DUR).set_trans(Tween.TRANS_SINE)

	# 2. Festival light dots — the village lights disappear behind you
	for dot_v: Variant in _festival_dots:
		if not is_instance_valid(dot_v): continue
		var dot: ColorRect = dot_v as ColorRect
		var dtw := dot.create_tween()
		dtw.tween_property(dot, "color:a", 0.0, DUR * 0.65).set_trans(Tween.TRANS_SINE)

	# 3. Far parallax (layer 0) warm orange glow → faint ember mist
	if _parallax_rects.size() > 0 and not _parallax_rects[0].is_empty():
		for r_v: Variant in _parallax_rects[0]:
			var r: ColorRect = r_v as ColorRect
			var rtw := r.create_tween()
			rtw.tween_property(r, "color",
					Color(0.25, 0.08, 0.02, 0.15), DUR).set_trans(Tween.TRANS_SINE)

	# 4. Tree silhouettes — darken into dense Kanjiravanam canopy
	for pair_v: Variant in _tree_pairs:
		var pair: Array = pair_v as Array
		if pair.size() < 2: continue
		var crown: ColorRect  = pair[0] as ColorRect
		var trunk_r: ColorRect = pair[1] as ColorRect
		var ctw := crown.create_tween()
		ctw.tween_property(crown, "color",
				Color(0.04, 0.09, 0.03, 1.0), DUR).set_trans(Tween.TRANS_SINE)
		var ttw := trunk_r.create_tween()
		ttw.tween_property(trunk_r, "color",
				Color(0.03, 0.06, 0.02, 1.0), DUR).set_trans(Tween.TRANS_SINE)

	# 5. Forest fog — dark mist rolls up from the tree line
	var fog := ColorRect.new()
	fog.size     = Vector2(VIEWPORT_W, 105.0)
	fog.position = Vector2(0.0, LAYER_Y[1] - 30.0)
	fog.color    = Color(0.04, 0.08, 0.03, 0.0)
	fog.z_index  = -4
	add_child(fog)
	var fog_tw := fog.create_tween()
	fog_tw.tween_interval(DUR * 0.55)
	fog_tw.tween_property(fog, "color:a", 0.38, DUR).set_trans(Tween.TRANS_SINE)

	# 6. Fireflies — replace the festival dots; faint green-amber sparks drifting upward
	var rng := RandomNumberGenerator.new()
	rng.seed = 33441
	for _fi: int in 14:
		var ff := ColorRect.new()
		ff.size     = Vector2(2.0, 2.0)
		ff.position = Vector2(rng.randf_range(15.0, VIEWPORT_W - 15.0),
				rng.randf_range(25.0, 135.0))
		ff.color    = Color(rng.randf_range(0.40, 0.72),
				rng.randf_range(0.80, 1.00), 0.28, 0.0)   # green-amber, starts hidden
		ff.z_index  = -7
		add_child(ff)
		# Fade in after sky finishes darkening, then pulse indefinitely
		var delay := rng.randf_range(DUR * 0.8, DUR * 2.0)
		var blink_hi := rng.randf_range(0.42, 0.80)
		var blink_dur := rng.randf_range(0.55, 1.30)
		var fftw := ff.create_tween().set_loops()
		fftw.tween_interval(delay)
		fftw.tween_property(ff, "color:a", blink_hi, blink_dur).set_trans(Tween.TRANS_SINE)
		fftw.tween_property(ff, "color:a", 0.0,      blink_dur).set_trans(Tween.TRANS_SINE)
		# Slow upward drift
		var base_y := ff.position.y
		var drift := rng.randf_range(10.0, 26.0)
		var ddur  := rng.randf_range(2.0, 4.5)
		var dftw := ff.create_tween().set_loops()
		dftw.tween_property(ff, "position:y", base_y - drift, ddur).set_trans(Tween.TRANS_SINE)
		dftw.tween_property(ff, "position:y", base_y,         ddur).set_trans(Tween.TRANS_SINE)

	# 7. Subtitle — the moment the forest swallows the road
	_show_dialogue("The trees are watching...\nKanjiravanam forest.", 3.2)

# ─────────────────────────────────────────────────────────────────────────────
# Obstacle system
# ─────────────────────────────────────────────────────────────────────────────

func _check_spawns() -> void:
	while _spawn_idx < SPAWN_SCHEDULE.size():
		var entry: Array = SPAWN_SCHEDULE[_spawn_idx]
		var world_x: float = float(entry[0])
		if _scroll_x + VIEWPORT_W >= world_x:
			_spawn_obstacle(entry[1] as String)
			_spawn_idx += 1
		else:
			break

func _spawn_obstacle(type: String) -> void:
	var def: Dictionary = OBS_DEFS[type]
	var w: float = float(def["w"])
	var h: float = float(def["h"])
	var is_ground: bool = bool(def["ground"])

	var r      := ColorRect.new()
	r.size      = Vector2(w, h)
	r.color     = def["color"] as Color
	r.z_index   = 2

	var ox: float = VIEWPORT_W + 10.0
	var oy: float
	if is_ground:
		oy = ROAD_Y + 6.0   # pothole sits on road surface
	else:
		oy = ROAD_Y - h     # bottom of obstacle sits on road surface

	# Goat bounces: give it an upward nudge via tween
	if type == "goat":
		r.position = Vector2(ox, oy)
		add_child(r)
		var tw := r.create_tween().set_loops()
		tw.tween_property(r, "position:y", oy - 12.0, 0.28).set_trans(Tween.TRANS_SINE)
		tw.tween_property(r, "position:y", oy,         0.28).set_trans(Tween.TRANS_SINE)
	elif type == "firecracker":
		# Flash / spark — amber, blink
		r.position = Vector2(ox, oy - 6.0)
		add_child(r)
		var tw2 := r.create_tween().set_loops()
		tw2.tween_property(r, "modulate:a", 0.2, 0.12)
		tw2.tween_property(r, "modulate:a", 1.0, 0.12)
	else:
		r.position = Vector2(ox, oy)
		add_child(r)

	_obstacles.append({"rect": r, "type": type, "hit": false})

func _check_collisions() -> void:
	if _iframe_timer > 0.0:
		return
	# Bike hitbox: rough rect around body + wheels
	var bx1 := BIKE_X - 28.0
	var bx2 := BIKE_X + 26.0
	var by1 := _bike_y - 14.0
	var by2 := _bike_y + 14.0

	for entry: Dictionary in _obstacles:
		if entry["hit"]:
			continue
		var r: ColorRect = entry["rect"]
		var rx1 := r.position.x
		var rx2 := rx1 + r.size.x
		var ry1 := r.position.y
		var ry2 := ry1 + r.size.y

		# AABB overlap
		if bx2 > rx1 and bx1 < rx2 and by2 > ry1 and by1 < ry2:
			entry["hit"] = true
			_take_hit(entry["type"] as String, r)

func _take_hit(_type: String, r: ColorRect) -> void:
	_engine_hp   -= OBSTACLE_DMG
	_iframe_timer = IFRAME_DURATION
	_undamaged    = false

	# Engine health bar update
	var ratio    := float(maxf(0, _engine_hp)) / float(ENGINE_MAX)
	_engine_bar.size.x = ratio * 100.0
	# Colour shift: green → orange → red
	if ratio > 0.6:
		_engine_bar.color = Color(0.20, 0.72, 0.28, 1.0)
	elif ratio > 0.3:
		_engine_bar.color = Color(0.95, 0.62, 0.10, 1.0)
	else:
		_engine_bar.color = Color(0.90, 0.15, 0.10, 1.0)

	# Screen flash red
	var cl    := CanvasLayer.new()
	cl.layer   = 15
	var flash  := ColorRect.new()
	flash.color = Color(1.0, 0.15, 0.10, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(flash)
	add_child(cl)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.55, 0.08)
	tw.tween_property(flash, "color:a", 0.0,  0.30)
	tw.tween_callback(cl.queue_free)

	# Shake bike
	var stw := _bike_rect.create_tween()
	stw.tween_property(_bike_rect, "position:x", _bike_rect.position.x - 4.0, 0.06)
	stw.tween_property(_bike_rect, "position:x", _bike_rect.position.x + 4.0, 0.06)
	stw.tween_property(_bike_rect, "position:x", _bike_rect.position.x,       0.06)

	# Hide the struck obstacle
	r.visible = false

	# If engine dead, flash a stall warning
	if _engine_hp <= 0:
		_show_stall_warning()

func _show_stall_warning() -> void:
	_show_dialogue("⚠  Engine stalled — coasting to a stop!", 2.0)

func _cull_obstacles() -> void:
	var i := _obstacles.size() - 1
	while i >= 0:
		var entry: Dictionary = _obstacles[i]
		var r: ColorRect = entry["rect"]
		if r.position.x < -80.0:
			r.queue_free()
			_obstacles.remove_at(i)
		i -= 1

# ─────────────────────────────────────────────────────────────────────────────
# End sequence
# ─────────────────────────────────────────────────────────────────────────────

func _begin_end_sequence() -> void:
	if _phase == "end" or _phase == "done":
		return
	_phase     = "end"
	_end_timer = 0.0

func _spawn_burning_trees() -> void:
	# Three burning trees block the road — orange-red columns
	for i: int in 3:
		var tree   := ColorRect.new()
		tree.size   = Vector2(22.0, 140.0)
		tree.position = Vector2(VIEWPORT_W + 20.0 + float(i) * 50.0, ROAD_Y - 135.0)
		tree.color  = Color(0.20, 0.12, 0.06, 1.0)   # dark trunk
		tree.z_index = 3
		add_child(tree)
		_obstacles.append({"rect": tree, "type": "tree", "hit": false})

		# Fire glow on top
		var glow   := ColorRect.new()
		glow.size   = Vector2(30.0, 40.0)
		glow.position = Vector2(tree.position.x - 4.0, tree.position.y - 36.0)
		glow.color  = Color(1.00, 0.45, 0.05, 0.80)
		glow.z_index = 4
		add_child(glow)
		_obstacles.append({"rect": glow, "type": "tree_fire", "hit": false})

		# Flicker tween
		var tw := glow.create_tween().set_loops()
		tw.tween_property(glow, "modulate:a", 0.45, 0.18)
		tw.tween_property(glow, "modulate:a", 1.00, 0.22)

func _finish() -> void:
	if _phase == "done": return
	_phase = "done"

	# Save undamaged flag — Ravi's Act V callback reads this
	GameManager.bike_undamaged = _undamaged

	# SceneManager handles fade-to-black and reset_status_effects
	SceneManager.go_to(NEXT_SCENE)

# ─────────────────────────────────────────────────────────────────────────────
# Mobile jump button — BtnUp / ui_accept
# ─────────────────────────────────────────────────────────────────────────────

func _input(_event: InputEvent) -> void:
	# MobileButtons fires "jump" action — handled in _tick_ride via Input.is_action_just_pressed
	pass
