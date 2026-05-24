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
const MIN_SPEED        := 150.0    # px s⁻¹ (idle scroll)
const MAX_SPEED        := 260.0    # px s⁻¹ (full throttle)
const ACCEL_RATE       := 7.0      # px s⁻³

# ── Engine health ──────────────────────────────────────────────────────────────
const ENGINE_MAX       := 100
const OBSTACLE_DMG     := 34       # ~3 hits to stall (34×3 = 102)
const IFRAME_DURATION  := 0.9      # invincibility after a hit

# ── Ride distance ──────────────────────────────────────────────────────────────
const RIDE_DIST        := 20000.0  # world units before end-sequence fires
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
	# Sizes reduced from original to match the lower jump height (JUMP_V = -380 / GRAVITY = 980)
	"pothole":     {"w": 26.0,  "h": 8.0,   "color": Color(0.10, 0.08, 0.06), "ground": true,  "collect": false},
	"crowd":       {"w": 26.0,  "h": 44.0,  "color": Color(0.70, 0.45, 0.20), "ground": false, "collect": false},
	"goat":        {"w": 22.0,  "h": 20.0,  "color": Color(0.82, 0.80, 0.75), "ground": false, "collect": false},
	"cart":        {"w": 50.0,  "h": 30.0,  "color": Color(0.55, 0.38, 0.15), "ground": false, "collect": false},
	"firecracker": {"w": 11.0,  "h": 11.0,  "color": Color(1.00, 0.70, 0.10), "ground": false, "collect": false},
	# Oil can — collectible, restores engine HP.
	"oil_can":     {"w": 14.0,  "h": 18.0,  "color": Color(0.22, 0.72, 0.28), "ground": false, "collect": true},
	# Low branch — hangs from above. DUCK (↓ / down arrow) to pass under. Can also be jumped over.
	"low_branch":  {"w": 68.0,  "h": 24.0,  "color": Color(0.18, 0.11, 0.04), "ground": false, "collect": false, "overhead": true},
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
	# ── Forest opens (40% mark ≈ 8000px) — jungle closes in, lights gone ──────
	[7100.0, "goat"],
	[7450.0, "oil_can"],     # reward for surviving — restore some engine
	[7650.0, "low_branch"],  # ↓ duck under first forest branch
	[7800.0, "firecracker"],
	[8100.0, "crowd"],
	[8450.0, "pothole"],
	[8750.0, "goat"],
	[9000.0, "cart"],
	[9200.0, "low_branch"],  # ↓ duck or ↑ jump
	[9300.0, "firecracker"],
	[9600.0, "crowd"],
	[9850.0, "pothole"],
	# ── Deep forest (50–65%) — road gets worse, animals scatter ───────────────
	[10200.0, "goat"],
	[10550.0, "pothole"],
	[10780.0, "low_branch"],
	[10900.0, "firecracker"],
	[11250.0, "cart"],
	[11600.0, "pothole"],
	[11950.0, "goat"],
	[12300.0, "oil_can"],    # second oil can — engine struggling by now
	[12500.0, "low_branch"],
	[12650.0, "firecracker"],
	[13000.0, "pothole"],    # mid-ride subtitle fires near here (65% ≈ 13000px)
	[13350.0, "cart"],
	[13700.0, "goat"],
	[14050.0, "pothole"],
	[14400.0, "firecracker"],
	# ── Final third (65–90%) — deep Kanjiravanam, spirits very close ──────────
	[14750.0, "cart"],
	[15100.0, "pothole"],
	[15320.0, "low_branch"],
	[15450.0, "goat"],
	[15800.0, "firecracker"],
	[16100.0, "oil_can"],    # last oil can — if you make it this far, you earned it
	[16450.0, "pothole"],
	[16800.0, "cart"],
	[17150.0, "goat"],
	[17350.0, "low_branch"],
	[17500.0, "firecracker"],
	[17850.0, "pothole"],
	[18200.0, "cart"],
	[18550.0, "goat"],
	[18900.0, "firecracker"],
	[19100.0, "low_branch"],
	[19250.0, "pothole"],
	[19600.0, "cart"],       # last obstacle before end sequence
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
var _did_end_quote      := false
var _did_mid_quote      := false   # "Kanjiravanam is close..." subtitle at 65%
var _near_miss_timer    := 0.0     # tracks closest obstacle this frame for near-miss flash
var _ducking            := false   # true while move_down is held on ground
var _touch_action_map   := {}      # touch index → action name (for simultaneous multi-touch)
var _dismount_prompt    : CanvasLayer = null   # "[E] Walk" overlay

# ── Visual nodes (built in _ready) ────────────────────────────────────────────
var _bike_rect      : ColorRect = null   # fallback only — replaced by _bike_spr when texture exists
var _wheel_f        : ColorRect = null
var _wheel_r        : ColorRect = null
var _rider_body     : ColorRect = null   # fallback rider body
var _rider_head     : ColorRect = null   # fallback rider head
var _bike_spr       : Sprite2D  = null   # generated sprite (ride frame / jump frame)
var _bike_base_scale: Vector2   = Vector2.ONE  # original scale saved for duck squish animation
var _engine_bar     : ColorRect = null
var _engine_label   : Label     = null
var _hud_layer      : CanvasLayer = null
var _dialogue_label : Label       = null
var _parallax_rects : Array       = []    # [[Node, Node], ...]  tile pairs per layer (TextureRect or ColorRect)
var _tree_pairs     : Array       = []    # [[crown_rect, trunk_rect], ...] — jungle treeline
var _bg_act1_tiles  : Array       = []    # two TextureRects for act1 bg scroll
var _bg_act2_tiles  : Array       = []    # two TextureRects for act2 bg (shown at midpoint)
var _act2_visible   := false              # guard so act2 bg only fades in once

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
	# ── Background layer: Act I scene (scrolling TextureRect tiles) ────────────
	const ACT1_BG := "res://assets/backgrounds/bg_act1_sky.png"
	const ACT2_BG := "res://assets/backgrounds/bg_act2_scene.png"

	if ResourceLoader.exists(ACT1_BG):
		# Two tiles side-by-side so one always covers the viewport while the other wraps
		for t: int in 2:
			var tr := TextureRect.new()
			tr.texture           = load(ACT1_BG)
			tr.stretch_mode      = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.size              = Vector2(VIEWPORT_W, VIEWPORT_H)
			tr.position          = Vector2(VIEWPORT_W * float(t), 0.0)
			tr.z_index           = -10
			add_child(tr)
			_bg_act1_tiles.append(tr)
		# Fallback sky colour sits behind the texture (invisible if texture loads)
		var sky := ColorRect.new()
		sky.size     = Vector2(VIEWPORT_W, VIEWPORT_H)
		sky.position = Vector2.ZERO
		sky.color    = Color(0.04, 0.07, 0.16, 1.0)
		sky.z_index  = -11
		add_child(sky)
		_sky_rect = sky
	else:
		# Pure colour fallback (no bg image generated yet)
		var sky := ColorRect.new()
		sky.size     = Vector2(VIEWPORT_W, VIEWPORT_H)
		sky.position = Vector2.ZERO
		sky.color    = Color(0.04, 0.07, 0.16, 1.0)   # Act I nightfall — deep indigo blue
		sky.z_index  = -10
		add_child(sky)
		_sky_rect = sky

	# Prepare Act 2 background tiles — hidden until midpoint transition
	if ResourceLoader.exists(ACT2_BG):
		for t: int in 2:
			var tr2 := TextureRect.new()
			tr2.texture           = load(ACT2_BG)
			tr2.stretch_mode      = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr2.size              = Vector2(VIEWPORT_W, VIEWPORT_H)
			tr2.position          = Vector2(VIEWPORT_W * float(t), 0.0)
			tr2.z_index           = -9   # in front of act1 tiles; shown over them
			tr2.modulate.a        = 0.0  # start fully transparent
			add_child(tr2)
			_bg_act2_tiles.append(tr2)

	# Festival light dots in the sky — static, scattered amber sparks
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for _i: int in 40:
		var dot := ColorRect.new()
		dot.size     = Vector2(rng.randf_range(2.0, 5.0), rng.randf_range(1.0, 3.0))
		dot.position = Vector2(rng.randf_range(0.0, VIEWPORT_W), rng.randf_range(5.0, 120.0))
		# Act I night sky — cool white-blue stars, not amber festival lights
		dot.color    = Color(rng.randf_range(0.75, 1.0), rng.randf_range(0.80, 1.0), rng.randf_range(0.90, 1.0), rng.randf_range(0.25, 0.65))
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

	# ── Bike + Rider — sprite if available, ColorRect fallback ─────────────────
	const BIKE_TEX := "res://assets/sprites/bike_rider_sheet.png"
	if ResourceLoader.exists(BIKE_TEX):
		# Sprite sheet: 2 frames wide (ride | jump), each 400×200 at generation size.
		# We use a single Sprite2D with hframes=2 and swap frame on jump.
		var tex: Texture2D = load(BIKE_TEX)
		_bike_spr           = Sprite2D.new()
		_bike_spr.texture   = tex
		_bike_spr.hframes   = 2
		_bike_spr.frame     = 0   # "ride" frame
		# Scale so the sprite height fits the bike height (~40px) in 270px viewport
		var native_h: float = tex.get_height()
		var target_h: float = 42.0
		var sc: float       = target_h / native_h
		_bike_spr.scale     = Vector2(sc, sc)
		_bike_base_scale    = _bike_spr.scale   # saved for duck squish animation
		_bike_spr.z_index   = 2
		add_child(_bike_spr)
	else:
		# ── ColorRect fallback — rendered when sprite hasn't been generated yet ──
		_wheel_r = ColorRect.new()
		_wheel_r.size  = Vector2(18.0, 18.0)
		_wheel_r.color = Color(0.12, 0.10, 0.08, 1.0)
		add_child(_wheel_r)

		_wheel_f = ColorRect.new()
		_wheel_f.size  = Vector2(18.0, 18.0)
		_wheel_f.color = Color(0.12, 0.10, 0.08, 1.0)
		add_child(_wheel_f)

		_bike_rect = ColorRect.new()
		_bike_rect.size  = Vector2(54.0, 18.0)
		_bike_rect.color = Color(0.15, 0.28, 0.15, 1.0)
		add_child(_bike_rect)

		_rider_body = ColorRect.new()
		_rider_body.size  = Vector2(16.0, 24.0)
		_rider_body.color = Color(0.88, 0.86, 0.80, 1.0)
		add_child(_rider_body)

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
	_dialogue_label.position  = Vector2(8.0, VIEWPORT_H - 54.0)
	_dialogue_label.size      = Vector2(VIEWPORT_W - 16.0, 52.0)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_dialogue_label.add_theme_font_size_override("font_size", 9)
	_dialogue_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_dialogue_label.visible              = false
	_hud_layer.add_child(_dialogue_label)

	# Touch-zone hints — shown on touchscreen devices so players know where to tap
	if DisplayServer.is_touchscreen_available():
		_build_touch_hints()

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
	if _bike_spr != null:
		# Centre the sprite on the bike's ride position
		_bike_spr.position = Vector2(BIKE_X, cy - 8.0)
		# Swap animation frame based on air state
		_bike_spr.frame    = 0 if _on_ground else 1
	else:
		# ColorRect fallback
		if _bike_rect  != null: _bike_rect.position  = Vector2(BIKE_X - 27.0, cy - 9.0)
		if _wheel_r    != null: _wheel_r.position    = Vector2(BIKE_X - 30.0, cy + 4.0)
		if _wheel_f    != null: _wheel_f.position    = Vector2(BIKE_X + 18.0, cy + 4.0)
		if _rider_body != null: _rider_body.position = Vector2(BIKE_X - 4.0,  cy - 30.0)
		if _rider_head != null: _rider_head.position = Vector2(BIKE_X - 2.0,  cy - 42.0)

## Mundakkal Ravi standing next to the bike for the handover — screen-space, visible only during intro.
## He holds a golden key toward LungiMan. When the ride phase starts he's tweened off-screen right.
func _build_ravi_handover() -> void:
	var ry := BIKE_REST_Y   # ground y
	const RAVI_TEX := "res://assets/sprites/ravi_sheet.png"

	if ResourceLoader.exists(RAVI_TEX):
		# ── Real Ravi sprite — 2 frames: idle (0) | talk (1) ─────────────────
		var tex    := load(RAVI_TEX) as Texture2D
		var spr    := Sprite2D.new()
		spr.texture = tex
		spr.hframes = 2
		spr.frame   = 0   # idle while key is being offered
		# Scale so sprite is 72px tall; center origin means feet land at ROAD_Y
		var target_h := 72.0
		var scale_f  := target_h / tex.get_height()
		spr.scale    = Vector2(scale_f, scale_f)
		spr.position = Vector2(RAVI_SCREEN_X, ROAD_Y - target_h * 0.5)
		spr.flip_h   = true   # faces left toward the hero
		spr.z_index  = 5
		add_child(spr)
		_ravi_pieces.append(spr)
		# Switch to talk frame when the dialogue line starts
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if is_instance_valid(spr): spr.frame = 1
		)
		# _arm_piece stays null — wave is not needed; sprite slide handles the goodbye
	else:
		# ── ColorRect fallback ────────────────────────────────────────────────
		var mundu := ColorRect.new()
		mundu.size     = Vector2(14.0, 16.0)
		mundu.position = Vector2(RAVI_SCREEN_X - 7.0, ry - 16.0)
		mundu.color    = Color(0.92, 0.90, 0.85, 1.0)
		mundu.z_index  = 5
		add_child(mundu)
		_ravi_pieces.append(mundu)

		var torso := ColorRect.new()
		torso.size     = Vector2(14.0, 14.0)
		torso.position = Vector2(RAVI_SCREEN_X - 7.0, ry - 30.0)
		torso.color    = Color(0.55, 0.30, 0.15, 1.0)
		torso.z_index  = 5
		add_child(torso)
		_ravi_pieces.append(torso)

		var head := ColorRect.new()
		head.size     = Vector2(10.0, 10.0)
		head.position = Vector2(RAVI_SCREEN_X - 5.0, ry - 42.0)
		head.color    = Color(0.68, 0.50, 0.32, 1.0)
		head.z_index  = 5
		add_child(head)
		_ravi_pieces.append(head)

		var arm := ColorRect.new()
		arm.size     = Vector2(12.0, 4.0)
		arm.position = Vector2(RAVI_SCREEN_X - 18.0, ry - 26.0)
		arm.color    = Color(0.68, 0.50, 0.32, 1.0)
		arm.z_index  = 5
		add_child(arm)
		_ravi_pieces.append(arm)
		_arm_piece = arm

	# ── Golden key — separate overlay so it can float to the hero ────────────
	# Positioned at the left edge of Ravi's sprite (toward the hero)
	var key := ColorRect.new()
	key.size     = Vector2(7.0, 4.0)
	key.position = Vector2(RAVI_SCREEN_X - 24.0, ROAD_Y - 28.0)
	key.color    = Color(0.92, 0.76, 0.18, 1.0)
	key.z_index  = 6
	add_child(key)
	_ravi_pieces.append(key)
	_key_piece = key
	# Key bobs gently toward LungiMan — "here, take it"
	_key_tween = key.create_tween().set_loops()
	_key_tween.tween_property(key, "position:x", RAVI_SCREEN_X - 26.0, 0.35).set_trans(Tween.TRANS_SINE)
	_key_tween.tween_property(key, "position:x", RAVI_SCREEN_X - 22.0, 0.35).set_trans(Tween.TRANS_SINE)

	# Name label above his head
	var lbl := Label.new()
	lbl.text     = "Ravi"
	lbl.position = Vector2(RAVI_SCREEN_X - 10.0, ROAD_Y - 88.0)
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
	_show_dialogue(
		"Mundakkal Ravi: \"The carnival grounds are 2km down —\n" +
		"take my bike, machane. But when the trees start, you walk.\n" +
		"The Bullet won't go where the spirits live.\"",
		4.8)

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
		"intro":          _tick_intro(delta)
		"ride":           _tick_ride(delta)
		"end":            _tick_end(delta)
		"wait_dismount":  _tick_dismount(delta)
		"game_over":      _tick_game_over(delta)
		"done":           pass

func _tick_intro(delta: float) -> void:
	_intro_timer += delta
	# Engine idling — very slow creep while Ravi hands over the key
	_scroll_scene(_speed, delta)
	# t=2.3s — hero reaches out and takes the key
	if not _key_taken and _intro_timer >= 2.3:
		_key_taken = true
		_hero_takes_key()
	# t=5.0s — Ravi steps back and waves as the bike rides away (after full 3-line dialogue)
	if _intro_timer >= 5.0:
		_dismiss_ravi()
		AudioManager.play_clip("bike_start")          # engine catches — one-shot SFX
		AudioManager.play_cinematic("bike_ride", true) # ride music — loops until scene ends
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

	# Jump: space / X (jump action) + up arrow as extra keyboard binding
	var jump_just := (Input.is_action_just_pressed("ui_accept")
				or  Input.is_action_just_pressed("jump")
				or  Input.is_key_just_pressed(KEY_UP))

	# Duck: down arrow / S — crouch to avoid low branches; blocks jumping while held
	_ducking = Input.is_action_pressed("move_down") and _on_ground

	if jump_just and _on_ground and _engine_hp > 0 and not _ducking:
		_bike_vy  = JUMP_V
		_on_ground = false
		_ducking   = false

	# Duck squish — animate sprite Y scale when crouching so there's visual feedback
	if _bike_spr != null and _bike_base_scale != Vector2.ZERO:
		var target_sy := _bike_base_scale.y * (0.65 if _ducking else 1.0)
		_bike_spr.scale.y = move_toward(_bike_spr.scale.y, target_sy, 4.0 * delta)

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
		# Flash the rider / bike sprite
		var vis := int(_iframe_timer * 10) % 2 == 0
		if _bike_spr != null:
			_bike_spr.visible = vis
		else:
			if _rider_body != null: _rider_body.visible = vis
			if _rider_head != null: _rider_head.visible = vis
	else:
		if _bike_spr != null:
			_bike_spr.visible = true
		else:
			if _rider_body != null: _rider_body.visible = true
			if _rider_head != null: _rider_head.visible = true

	# Spawn obstacles
	_check_spawns()

	# Collision
	_check_collisions()

	# Remove off-screen obstacles
	_cull_obstacles()

	# Forest transition — village festival gives way to Kanjiravanam at 40%
	if not _forest_transition_done and _scroll_x >= RIDE_DIST * 0.40:
		_begin_forest_transition()

	# Mid-ride subtitle — deep in the forest, spirits are close
	if not _did_mid_quote and _scroll_x >= RIDE_DIST * 0.65:
		_did_mid_quote = true
		_show_dialogue("Kanjiravanam is close...\nThe Bullet's getting nervous.", 3.2)

	# Near-miss flash — reward clean dodges with a satisfying "CLOSE!" burst
	_check_near_misses(delta)

	# Completed the full ride → normal end sequence → dismount
	if _scroll_x >= RIDE_DIST:
		_begin_end_sequence()
	elif _engine_hp <= 0 and _speed <= 0.0:
		# Engine dead before completing the ride → game over, NOT dismount.
		# The "[E] Walk" prompt must only appear on a SUCCESSFUL run.
		_begin_game_over()

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

	# Bike has fully stopped — hand control back to the player to dismount
	if _end_timer >= 5.0 and _speed <= 0.0:
		_begin_dismount()

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

	# Background image tiles — slow parallax (0.10 scroll factor for deep sky feel)
	for tile_v: Variant in _bg_act1_tiles:
		var tile: TextureRect = tile_v as TextureRect
		tile.position.x -= dx * 0.10
		if tile.position.x + VIEWPORT_W < 0.0:
			tile.position.x += VIEWPORT_W * 2.0
	for tile_v2: Variant in _bg_act2_tiles:
		var tile2: TextureRect = tile_v2 as TextureRect
		tile2.position.x -= dx * 0.10
		if tile2.position.x + VIEWPORT_W < 0.0:
			tile2.position.x += VIEWPORT_W * 2.0

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

	# 1. Background cross-fade: Act I scene → Act II carnival scene
	if not _bg_act2_tiles.is_empty():
		# Fade in Act 2 bg tiles (they overlay Act 1)
		for tile_v: Variant in _bg_act2_tiles:
			var tile2: TextureRect = tile_v as TextureRect
			var ttw := tile2.create_tween()
			ttw.tween_property(tile2, "modulate:a", 1.0, DUR).set_trans(Tween.TRANS_SINE)
		# Fade out Act 1 bg tiles behind it
		for tile_v: Variant in _bg_act1_tiles:
			var tile1: TextureRect = tile_v as TextureRect
			var ttw2 := tile1.create_tween()
			ttw2.tween_property(tile1, "modulate:a", 0.0, DUR).set_trans(Tween.TRANS_SINE)
		_act2_visible = true
	elif is_instance_valid(_sky_rect):
		# No texture — fall back to colour transition
		var tw := _sky_rect.create_tween()
		tw.tween_property(_sky_rect, "color",
				Color(0.20, 0.07, 0.02, 1.0), DUR).set_trans(Tween.TRANS_SINE)

	# 2. Festival light dots — the village lights disappear behind you
	for dot_v: Variant in _festival_dots:
		if not is_instance_valid(dot_v): continue
		var dot: ColorRect = dot_v as ColorRect
		var dtw := dot.create_tween()
		dtw.tween_property(dot, "color:a", 0.0, DUR * 0.65).set_trans(Tween.TRANS_SINE)

	# 3. Far parallax (layer 0) night blue glow → bright carnival orange (festival lights ahead)
	if _parallax_rects.size() > 0 and not _parallax_rects[0].is_empty():
		for r_v: Variant in _parallax_rects[0]:
			var r: ColorRect = r_v as ColorRect
			var rtw := r.create_tween()
			rtw.tween_property(r, "color",
					Color(0.90, 0.50, 0.10, 0.35), DUR).set_trans(Tween.TRANS_SINE)

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

	# 7. Subtitle — carnival lights ahead, forest closes in behind
	_show_dialogue("Carnival grounds ahead...\nThe forest is watching from behind.", 3.2)

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

	var r      := ColorRect.new()
	r.size      = Vector2(w, h)
	r.color     = def["color"] as Color
	r.z_index   = 2

	var ox: float = VIEWPORT_W + 10.0
	var oy: float
	if def.get("overhead", false):
		# Low branch — hangs from mid-air. Duck (↓) to pass under, or jump (↑) over.
		# Positioned so ducked hitbox (by1 += 12) just clears the branch bottom (ry2).
		oy = 144.0
	else:
		# All ground-level obstacles sit with their bottom edge at ROAD_Y.
		# Previously potholes used ROAD_Y + 6 which put them BELOW the bike hitbox — fixed.
		oy = ROAD_Y - h

	# Goat bounces: give it an upward nudge via tween
	if type == "goat":
		r.position = Vector2(ox, oy)
		add_child(r)
		var tw := r.create_tween().set_loops()
		tw.tween_property(r, "position:y", oy - 10.0, 0.28).set_trans(Tween.TRANS_SINE)
		tw.tween_property(r, "position:y", oy,         0.28).set_trans(Tween.TRANS_SINE)
	elif type == "firecracker":
		# Flash / spark — amber, blink
		r.position = Vector2(ox, oy - 4.0)
		add_child(r)
		var tw2 := r.create_tween().set_loops()
		tw2.tween_property(r, "modulate:a", 0.2, 0.12)
		tw2.tween_property(r, "modulate:a", 1.0, 0.12)
	elif type == "low_branch":
		# Dangling branch — hangs from a dark trunk line at the top
		r.position = Vector2(ox, oy)
		add_child(r)
		# Add a thin trunk above it for visual context
		var trunk := ColorRect.new()
		trunk.size     = Vector2(8.0, oy - 55.0)
		trunk.color    = Color(0.14, 0.08, 0.03, 1.0)
		trunk.position = Vector2(ox + (w - 8.0) * 0.5, 55.0)
		trunk.z_index  = 2
		add_child(trunk)
		# Slight wobble — the branch sways in the forest air
		var btw := r.create_tween().set_loops()
		btw.tween_property(r, "position:y", oy + 3.0, 0.70).set_trans(Tween.TRANS_SINE)
		btw.tween_property(r, "position:y", oy - 1.0, 0.70).set_trans(Tween.TRANS_SINE)
	else:
		r.position = Vector2(ox, oy)
		add_child(r)

	_obstacles.append({"rect": r, "type": type, "hit": false})

func _check_collisions() -> void:
	# Bike hitbox: rough rect around body + wheels.
	# When ducking, the top shrinks by 12 px — just enough to clear a low_branch (ry2 = 168).
	var bx1 := BIKE_X - 28.0
	var bx2 := BIKE_X + 26.0
	var by1 := _bike_y - 14.0 + (12.0 if _ducking else 0.0)
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
			var def: Dictionary = OBS_DEFS.get(entry["type"], {})
			if def.get("collect", false):
				_collect_oil_can(r)
			elif _iframe_timer <= 0.0:
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

	# Shake bike — guard for sprite vs ColorRect mode
	var shake_node: Node2D = _bike_spr if _bike_spr != null else _bike_rect
	if shake_node != null:
		var stw := shake_node.create_tween()
		stw.tween_property(shake_node, "position:x", shake_node.position.x - 4.0, 0.06)
		stw.tween_property(shake_node, "position:x", shake_node.position.x + 4.0, 0.06)
		stw.tween_property(shake_node, "position:x", shake_node.position.x,       0.06)

	# Hide the struck obstacle
	r.visible = false

	# If engine dead, flash a stall warning
	if _engine_hp <= 0:
		_show_stall_warning()

func _show_stall_warning() -> void:
	_show_dialogue("⚠  Engine stalled — coasting to a stop!", 2.0)

## Collecting an oil can restores engine HP and gives a green burst of feedback.
func _collect_oil_can(r: ColorRect) -> void:
	# Each can restores 28 HP — slightly less than one hit (34), keeps tension alive
	_engine_hp = mini(_engine_hp + 28, ENGINE_MAX)

	# Update engine bar colour + width
	var ratio := float(_engine_hp) / float(ENGINE_MAX)
	_engine_bar.size.x = ratio * 100.0
	if ratio > 0.6:
		_engine_bar.color = Color(0.20, 0.72, 0.28, 1.0)
	elif ratio > 0.3:
		_engine_bar.color = Color(0.95, 0.62, 0.10, 1.0)
	else:
		_engine_bar.color = Color(0.90, 0.15, 0.10, 1.0)

	# Floating "+OIL" text rises above the bike
	var popup       := Label.new()
	popup.text       = "+OIL"
	popup.add_theme_font_size_override("font_size", 11)
	popup.add_theme_color_override("font_color", Color(0.22, 0.95, 0.40, 1.0))
	popup.z_index    = 20
	popup.position   = Vector2(BIKE_X - 14.0, _bike_y - 36.0)
	add_child(popup)
	var ptw := popup.create_tween()
	ptw.tween_property(popup, "position:y", popup.position.y - 22.0, 0.70).set_trans(Tween.TRANS_SINE)
	ptw.parallel().tween_property(popup, "modulate:a", 0.0, 0.70)
	ptw.tween_callback(popup.queue_free)

	# Green screen flash — affirming juice
	var cl    := CanvasLayer.new()
	cl.layer   = 14
	var flash  := ColorRect.new()
	flash.color = Color(0.10, 0.90, 0.35, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(flash)
	add_child(cl)
	var ftw := flash.create_tween()
	ftw.tween_property(flash, "color:a", 0.28, 0.07)
	ftw.tween_property(flash, "color:a", 0.0,  0.22)
	ftw.tween_callback(cl.queue_free)

	# Hide the can immediately; _cull_obstacles frees the entry when it scrolls off-screen
	r.visible = false

## Detects obstacles that just narrowly cleared the bike hitbox — flashes "CLOSE!" for juice.
## Near-miss: obstacle right edge passed bike left edge within the last 16 px AND was vertically
## within 12 px of actually hitting. Suppressed by _near_miss_timer to avoid spam.
func _check_near_misses(delta: float) -> void:
	if _near_miss_timer > 0.0:
		_near_miss_timer -= delta
		return

	var bx1 := BIKE_X - 28.0
	var by1 := _bike_y - 14.0
	var by2 := _bike_y + 14.0

	for entry: Dictionary in _obstacles:
		if entry["hit"]:
			continue
		var t: String = entry["type"]
		if t == "oil_can" or t == "tree" or t == "tree_fire":
			continue   # collectibles and scenery don't count as near-misses
		var r: ColorRect = entry["rect"]
		var rx2 := r.position.x + r.size.x
		var ry1 := r.position.y
		var ry2 := ry1 + r.size.y

		# Obstacle right edge just cleared the bike's left edge (0–16 px gap)
		if rx2 >= bx1 - 16.0 and rx2 < bx1:
			# Positive vert_gap = clear air gap; negative = overlap (should have been a hit)
			var vert_gap := maxf(ry1 - by2, by1 - ry2)
			if vert_gap < 12.0:
				_near_miss_timer = 1.8   # suppress for 1.8 s
				_spawn_near_miss_flash()
				return   # one flash per scan pass is enough

func _spawn_near_miss_flash() -> void:
	var lbl := Label.new()
	lbl.text = "CLOSE!"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.20, 1.0))
	lbl.z_index  = 20
	lbl.position = Vector2(VIEWPORT_W * 0.5 - 24.0, VIEWPORT_H * 0.30)
	add_child(lbl)
	var ltw := lbl.create_tween()
	ltw.tween_property(lbl, "position:y", lbl.position.y - 16.0, 0.50).set_trans(Tween.TRANS_SINE)
	ltw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.50)
	ltw.tween_callback(lbl.queue_free)

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

## Bike has stopped at the forest edge — ask the player to dismount on their own terms.
func _begin_dismount() -> void:
	if _phase == "wait_dismount" or _phase == "dismounting" or _phase == "done": return
	_phase = "wait_dismount"
	_dialogue_label.visible = false

	# ── Persistent dismount overlay ───────────────────────────────────────────
	_dismount_prompt       = CanvasLayer.new()
	_dismount_prompt.layer = 12
	add_child(_dismount_prompt)

	# Dark pill background
	var bg       := ColorRect.new()
	bg.color      = Color(0.04, 0.09, 0.04, 0.86)
	bg.size       = Vector2(230.0, 44.0)
	bg.position   = Vector2((VIEWPORT_W - 230.0) * 0.5, VIEWPORT_H * 0.5 - 22.0)
	_dismount_prompt.add_child(bg)

	# "The forest won't let the Bullet through."
	var msg       := Label.new()
	msg.text       = "The forest won't let the Bullet through."
	msg.add_theme_font_size_override("font_size", 8)
	msg.add_theme_color_override("font_color", Color(0.95, 0.88, 0.60, 1.0))
	msg.size       = Vector2(222.0, 14.0)
	msg.position   = Vector2(bg.position.x + 4.0, bg.position.y + 5.0)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dismount_prompt.add_child(msg)

	# [E] key box
	var key_box   := ColorRect.new()
	key_box.color  = Color(0.88, 0.78, 0.22, 1.0)   # gold key cap
	key_box.size   = Vector2(16.0, 13.0)
	key_box.position = Vector2(bg.position.x + 42.0, bg.position.y + 24.0)
	_dismount_prompt.add_child(key_box)

	var key_lbl   := Label.new()
	key_lbl.text   = "E"
	key_lbl.add_theme_font_size_override("font_size", 9)
	key_lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0))
	key_lbl.position = Vector2(key_box.position.x + 4.0, key_box.position.y + 1.0)
	_dismount_prompt.add_child(key_lbl)

	# "Walk into the forest" text beside key box
	var walk_lbl   := Label.new()
	walk_lbl.text   = "Walk into the forest"
	walk_lbl.add_theme_font_size_override("font_size", 8)
	walk_lbl.add_theme_color_override("font_color", Color(0.72, 0.95, 0.55, 1.0))
	walk_lbl.position = Vector2(key_box.position.x + 20.0, key_box.position.y + 1.0)
	walk_lbl.size     = Vector2(130.0, 14.0)
	_dismount_prompt.add_child(walk_lbl)

	# Pulse the key box — draw the eye
	var pulse := key_box.create_tween().set_loops()
	pulse.tween_property(key_box, "modulate:a", 0.45, 0.42).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(key_box, "modulate:a", 1.00, 0.42).set_trans(Tween.TRANS_SINE)

func _tick_dismount(_delta: float) -> void:
	# Accept E (climb action), space/enter, or mobile confirm button
	var pressed: bool = (Input.is_action_just_pressed("ui_accept")
				or  Input.is_action_just_pressed("jump")
				or  Input.is_action_just_pressed("climb"))
	if pressed:
		_do_dismount()

func _do_dismount() -> void:
	_phase = "dismounting"   # lock out re-entry; _finish() checks "done" so keep distinct

	# Remove the prompt overlay
	if is_instance_valid(_dismount_prompt):
		_dismount_prompt.queue_free()
		_dismount_prompt = null

	# Fade out / hide the bike
	if _bike_spr != null:
		var tw := _bike_spr.create_tween()
		tw.tween_property(_bike_spr, "modulate:a", 0.0, 0.28)
		tw.tween_callback(_bike_spr.queue_free)
	else:
		for node_v: Variant in [_bike_rect, _wheel_f, _wheel_r]:
			var n := node_v as Node2D
			if n != null and is_instance_valid(n):
				var tw2 := n.create_tween()
				tw2.tween_property(n, "modulate:a", 0.0, 0.28)

	# Small walker figure strides from bike position into the forest (right)
	var body        := ColorRect.new()
	body.size        = Vector2(10.0, 22.0)
	body.color       = Color(0.92, 0.90, 0.82, 1.0)   # white mundu
	body.z_index     = 4
	body.position    = Vector2(BIKE_X - 5.0, BIKE_REST_Y - 22.0)
	add_child(body)

	var head        := ColorRect.new()
	head.size        = Vector2(9.0, 9.0)
	head.color       = Color(0.70, 0.52, 0.35, 1.0)
	head.z_index     = 4
	head.position    = Vector2(BIKE_X - 4.5, BIKE_REST_Y - 33.0)
	add_child(head)

	# Walk into the right edge (into the forest), then transition
	var dist   := VIEWPORT_W - BIKE_X + 24.0
	var dur    := 1.4
	var walk_b := body.create_tween()
	walk_b.tween_property(body, "position:x", body.position.x + dist, dur).set_trans(Tween.TRANS_SINE)
	walk_b.tween_callback(_finish)

	var walk_h := head.create_tween()
	walk_h.tween_property(head, "position:x", head.position.x + dist, dur).set_trans(Tween.TRANS_SINE)

	# Brief closing line as he walks
	_show_dialogue("Into Kanjiravanam...", 1.8)

func _finish() -> void:
	if _phase == "done": return
	_phase = "done"
	# (also covers the "dismounting" walk-anim path)

	# Stop ride music before transitioning — SceneManager crossfades to Act 2 BGM
	AudioManager.stop_cinematic()

	# Save undamaged flag — Ravi's Act V callback reads this
	GameManager.bike_undamaged = _undamaged

	# SceneManager handles fade-to-black and reset_status_effects
	SceneManager.go_to(NEXT_SCENE)

# ─────────────────────────────────────────────────────────────────────────────
# Game over — engine died before completing the ride
# ─────────────────────────────────────────────────────────────────────────────

## Engine stalled before the forest edge — show game-over screen, NOT the dismount prompt.
## The "[E] Walk" option is earned by completing the ride, not handed out for free.
func _begin_game_over() -> void:
	if _phase == "game_over" or _phase == "done": return
	_phase = "game_over"

	# Brief dramatic pause while the last scroll dust settles
	await get_tree().create_timer(0.85).timeout

	# Full-screen overlay — dark red tint
	var cl        := CanvasLayer.new()
	cl.layer       = 20
	add_child(cl)

	var cover     := ColorRect.new()
	cover.color    = Color(0.0, 0.0, 0.0, 0.0)
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(cover)
	var ctw := cover.create_tween()
	ctw.tween_property(cover, "color", Color(0.06, 0.01, 0.01, 0.84), 0.55)

	await get_tree().create_timer(0.40).timeout

	# Title
	var title     := Label.new()
	title.text     = "ENGINE DEAD"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.92, 0.18, 0.10, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size     = Vector2(VIEWPORT_W, 28.0)
	title.position = Vector2(0.0, VIEWPORT_H * 0.26)
	cl.add_child(title)
	# Fade the title in
	title.modulate.a = 0.0
	title.create_tween().tween_property(title, "modulate:a", 1.0, 0.30)

	# Flavour line
	var flavour   := Label.new()
	flavour.text   = "Kanjiravanam pushed back.\nThe forest will not be rushed."
	flavour.add_theme_font_size_override("font_size", 9)
	flavour.add_theme_color_override("font_color", Color(0.85, 0.76, 0.55, 0.90))
	flavour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavour.autowrap_mode         = TextServer.AUTOWRAP_WORD
	flavour.size     = Vector2(VIEWPORT_W - 48.0, 36.0)
	flavour.position = Vector2(24.0, VIEWPORT_H * 0.44)
	cl.add_child(flavour)

	# Distance reached — how far did they get?
	var pct       := int((_scroll_x / RIDE_DIST) * 100.0)
	var dist_lbl  := Label.new()
	dist_lbl.text  = "Reached %d%% of the ride" % pct
	dist_lbl.add_theme_font_size_override("font_size", 8)
	dist_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.60, 0.80))
	dist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dist_lbl.size     = Vector2(VIEWPORT_W, 14.0)
	dist_lbl.position = Vector2(0.0, VIEWPORT_H * 0.60)
	cl.add_child(dist_lbl)

	# Restart prompt — centred [R] key box + label
	var key_bg    := ColorRect.new()
	key_bg.color   = Color(0.82, 0.18, 0.10, 1.0)
	key_bg.size    = Vector2(16.0, 13.0)
	key_bg.position = Vector2(VIEWPORT_W * 0.5 - 48.0, VIEWPORT_H * 0.73)
	cl.add_child(key_bg)

	var key_lbl   := Label.new()
	key_lbl.text   = "R"
	key_lbl.add_theme_font_size_override("font_size", 9)
	key_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	key_lbl.position = Vector2(key_bg.position.x + 4.0, key_bg.position.y + 1.0)
	cl.add_child(key_lbl)

	var try_lbl   := Label.new()
	try_lbl.text   = "Try again"
	try_lbl.add_theme_font_size_override("font_size", 9)
	try_lbl.add_theme_color_override("font_color", Color(1.00, 0.88, 0.60, 1.0))
	try_lbl.position = Vector2(key_bg.position.x + 22.0, key_bg.position.y + 1.0)
	cl.add_child(try_lbl)

	# Pulse the key box to draw the eye
	var pulse := key_bg.create_tween().set_loops()
	pulse.tween_property(key_bg, "modulate:a", 0.38, 0.50).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(key_bg, "modulate:a", 1.00, 0.50).set_trans(Tween.TRANS_SINE)

## Watches for restart input while the game-over screen is visible.
## Any confirm input restarts the scene — phone tap, spacebar, or R key.
func _tick_game_over(_delta: float) -> void:
	if (Input.is_action_just_pressed("ui_accept")
			or Input.is_action_just_pressed("jump")):
		get_tree().reload_current_scene()

# ─────────────────────────────────────────────────────────────────────────────
# Input — desktop keyboard + mobile multi-touch zones
# ─────────────────────────────────────────────────────────────────────────────

## Mobile touch zones — right half of screen split into jump (top) and duck (bottom).
## Each finger tracked by its index so both actions can fire simultaneously.
## Left half is intentionally inactive (grip / observation area).
func _input(event: InputEvent) -> void:
	# Desktop: R key restarts during game over
	if _phase == "game_over" and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return

	# Touch zones
	if not (event is InputEventScreenTouch): return
	var e: InputEventScreenTouch = event
	var win := DisplayServer.window_get_size()
	var nx: float = e.position.x / float(maxi(win.x, 1))
	var ny: float = e.position.y / float(maxi(win.y, 1))

	if nx < 0.40: return   # left 40 % = passive grip area

	if e.pressed:
		var action: String = "jump" if ny < 0.52 else "move_down"
		_touch_action_map[e.index] = action
		Input.action_press(action)
	else:
		if _touch_action_map.has(e.index):
			Input.action_release(_touch_action_map[e.index])
			_touch_action_map.erase(e.index)

## Faint on-screen zone hints so first-time players know where to tap.
## Only built when a touchscreen is detected (called from _build_scene).
func _build_touch_hints() -> void:
	var hl        := CanvasLayer.new()
	hl.layer       = 9
	add_child(hl)

	# Top-right zone label — jump
	var jlbl      := Label.new()
	jlbl.text      = "↑ TAP"
	jlbl.add_theme_font_size_override("font_size", 7)
	jlbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.20))
	jlbl.position  = Vector2(VIEWPORT_W - 36.0, 8.0)
	hl.add_child(jlbl)

	# Bottom-right zone label — duck
	var dlbl      := Label.new()
	dlbl.text      = "↓ TAP"
	dlbl.add_theme_font_size_override("font_size", 7)
	dlbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.20))
	dlbl.position  = Vector2(VIEWPORT_W - 36.0, VIEWPORT_H - 17.0)
	hl.add_child(dlbl)
