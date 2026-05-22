extends Node2D

## ACT IV.5 — Pathalam
## Bioluminescent underground cave. No enemies. No combat. Just the weight of what came before.
##
## LungiMan falls through the forest floor after Karinkanni's defeat.
## The monsoon stops. The ground opens — not a collapse, a door.
## He meets Maveli. The lamp is restored. He goes up to face the last fight.
##
## Design principles:
##   - Total silence (no music, just drips and fireflies)
##   - No combat — player can swing, walk, climb, but nothing attacks
##   - Horizontal scroll LEFT to RIGHT to Maveli's chamber
##   - After blessing: brief fade-out → Act V

const NEXT_SCENE := "res://scenes/Act5.tscn"

# Cave geometry constants
const GROUND_Y    := 700.0
const CEILING_Y   := 240.0   # cave ceiling — narrow passage, oppressive
const CAVE_LENGTH := 5000.0

# Bioluminescent mushroom cluster positions (x, y_above_ground, radius)
const MUSHROOM_CLUSTERS := [
	[180.0,  0.0,  28.0],
	[550.0,  0.0,  20.0],
	[940.0,  0.0,  34.0],
	[1380.0, 0.0,  22.0],
	[1720.0, 0.0,  30.0],
	[2100.0, 0.0,  18.0],
	[2500.0, 0.0,  36.0],
	[2880.0, 0.0,  24.0],
	[3250.0, 0.0,  28.0],
	[3700.0, 0.0,  32.0],
	[4100.0, 0.0,  40.0],   # approach to Maveli's chamber — densest glow
	[4500.0, 0.0,  38.0],
]

# Oil lamp positions along the cave wall — warm amber dots
const OIL_LAMPS := [300.0, 750.0, 1200.0, 1650.0, 2100.0, 2600.0, 3000.0, 3500.0, 4000.0, 4600.0]

# Naga guardian stone pillar positions in the Corridor of Waiting (x=2800+)
const NAGA_PILLARS := [2850.0, 3200.0, 3550.0, 3900.0, 4250.0]

var _player: Node2D  = null
var _exit_started    := false

func _ready() -> void:
	_player = get_node_or_null("Player")
	_build_cave()
	_spawn_maveli()
	_start_ambient()
	_connect_player()
	_queue_entry_hint()

# ─────────────────────────────────────────────────────────────────────────────
# Scene connections
# ─────────────────────────────────────────────────────────────────────────────

func _connect_player() -> void:
	# Spawn PauseMenu so Escape works here too
	if not get_node_or_null("PauseMenu"):
		var pm: Node = preload("res://scenes/PauseMenu.tscn").instantiate()
		pm.name = "PauseMenu"
		pm.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(pm)
	# Wire player_died → GameOver overlay
	var go: Node = get_node_or_null("GameOver")
	if go and not GameManager.player_died.is_connected(go.show_game_over):
		GameManager.player_died.connect(go.show_game_over)
	# Wire climb prompt to HUD
	if _player:
		var hud := get_node_or_null("HUD")
		if hud and _player.has_signal("climb_prompt_changed"):
			if not _player.climb_prompt_changed.is_connected(hud.show_climb_prompt):
				_player.climb_prompt_changed.connect(hud.show_climb_prompt)

# ─────────────────────────────────────────────────────────────────────────────
# Exit sequence (triggered by Maveli's blessing_given signal)
# ─────────────────────────────────────────────────────────────────────────────

func _begin_exit() -> void:
	if _exit_started: return
	_exit_started = true

	# Show the staircase hint
	var hud := get_node_or_null("HUD")
	if hud and hud.has_method("show_hint"):
		hud.show_hint("⬆  The staircase glows above you. Act V awaits.", 4.0)

	# Fade to black after a beat, then load Act V
	get_tree().create_timer(3.5).timeout.connect(func() -> void:
		SceneManager.go_to(NEXT_SCENE)
	)

# ─────────────────────────────────────────────────────────────────────────────
# Cave builder
# ─────────────────────────────────────────────────────────────────────────────

func _build_cave() -> void:
	_build_ground()
	_build_ceiling()
	_build_mushrooms()
	_build_oil_lamps()
	_build_naga_pillars()
	_build_glowing_prints()
	_build_fireflies()
	_build_ambient_drips()

func _build_ground() -> void:
	# Cave floor — dark stone, slightly uneven colour zones
	var body := StaticBody2D.new()
	body.position = Vector2(CAVE_LENGTH * 0.5, GROUND_Y + 20.0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CAVE_LENGTH, 40.0)
	var col   := CollisionShape2D.new()
	col.shape  = shape
	body.add_child(col)

	var vis          := ColorRect.new()
	vis.size          = Vector2(CAVE_LENGTH, 40.0)
	vis.position      = Vector2(-CAVE_LENGTH * 0.5, -20.0)
	vis.color         = Color(0.08, 0.06, 0.10, 1.0)   # near-black stone
	body.add_child(vis)
	add_child(body)

	# Stone texture lines — subtle horizontal grooves
	for i: int in 6:
		var groove := ColorRect.new()
		groove.size     = Vector2(CAVE_LENGTH, 1.0)
		groove.position = Vector2(0.0, GROUND_Y + float(i) * 6.0)
		groove.color    = Color(0.05, 0.04, 0.07, 0.5)
		groove.z_index  = -2
		add_child(groove)

func _build_ceiling() -> void:
	# Cave ceiling — stalactites implied by a simple flat dark strip
	var vis      := ColorRect.new()
	vis.size      = Vector2(CAVE_LENGTH + 200.0, 60.0)
	vis.position  = Vector2(-100.0, CEILING_Y - 60.0)
	vis.color     = Color(0.05, 0.04, 0.08, 1.0)
	vis.z_index   = 1
	add_child(vis)

	# Random stalactite drops hanging down
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345   # deterministic
	for _i: int in 30:
		var drop := ColorRect.new()
		var w    := rng.randf_range(4.0, 14.0)
		var h    := rng.randf_range(10.0, 40.0)
		drop.size     = Vector2(w, h)
		drop.position = Vector2(rng.randf_range(0.0, CAVE_LENGTH), CEILING_Y - 60.0 + 60.0 - h * 0.5)
		drop.color    = Color(0.06, 0.05, 0.09, 1.0)
		drop.z_index  = 1
		add_child(drop)

func _build_mushrooms() -> void:
	# Bioluminescent mushroom clusters — teal/cyan glow dots
	for data: Array in MUSHROOM_CLUSTERS:
		var x: float = float(data[0])
		var r: float = float(data[2])
		var cx: float = x
		var cy: float = GROUND_Y - r * 0.5

		# Glow halo — larger, very transparent
		var glow      := ColorRect.new()
		glow.size      = Vector2(r * 3.2, r * 2.5)
		glow.position  = Vector2(cx - r * 1.6, cy - r * 1.25)
		glow.color     = Color(0.10, 0.78, 0.72, 0.12)
		glow.z_index   = -1
		add_child(glow)

		# Mushroom cap — teal circle approximation
		var cap       := ColorRect.new()
		cap.size       = Vector2(r, r * 0.7)
		cap.position   = Vector2(cx - r * 0.5, cy - r * 0.5)
		cap.color      = Color(0.15, 0.85, 0.78, 0.85)
		cap.z_index    = 0
		add_child(cap)

		# Mushroom stem
		var stem      := ColorRect.new()
		stem.size      = Vector2(r * 0.25, r * 0.6)
		stem.position  = Vector2(cx - r * 0.125, cy)
		stem.color     = Color(0.40, 0.70, 0.65, 0.90)
		stem.z_index   = 0
		add_child(stem)

func _build_oil_lamps() -> void:
	# Small amber dots on the cave wall at mid-height
	for x: float in OIL_LAMPS:
		var lamp       := ColorRect.new()
		lamp.size       = Vector2(6.0, 8.0)
		lamp.position   = Vector2(x, GROUND_Y - 120.0)
		lamp.color      = Color(1.0, 0.65, 0.15, 1.0)
		lamp.z_index    = 1
		add_child(lamp)

		# Tiny glow halo
		var glow       := ColorRect.new()
		glow.size       = Vector2(22.0, 22.0)
		glow.position   = Vector2(x - 8.0, GROUND_Y - 131.0)
		glow.color      = Color(1.0, 0.55, 0.10, 0.18)
		glow.z_index    = 0
		add_child(glow)

		# Animate lamp flicker via Tween
		var tw := lamp.create_tween().set_loops()
		tw.tween_property(lamp, "modulate:a", 0.65, randf_range(0.6, 1.2))
		tw.tween_property(lamp, "modulate:a", 1.0,  randf_range(0.4, 0.9))

func _build_naga_pillars() -> void:
	# Stone pillars in the Corridor of Waiting — ancient carvings watching
	for x: float in NAGA_PILLARS:
		# Pillar body
		var pillar     := ColorRect.new()
		pillar.size     = Vector2(18.0, GROUND_Y - CEILING_Y)
		pillar.position = Vector2(x - 9.0, CEILING_Y)
		pillar.color    = Color(0.14, 0.12, 0.18, 1.0)
		pillar.z_index  = 2
		add_child(pillar)

		# Carved eye marking — a small glowing slit
		var eye        := ColorRect.new()
		eye.size        = Vector2(6.0, 3.0)
		eye.position    = Vector2(x - 3.0, GROUND_Y - 180.0)
		eye.color       = Color(0.60, 0.20, 0.80, 0.70)   # faint purple
		eye.z_index     = 3
		add_child(eye)

func _build_glowing_prints() -> void:
	# Ancient ritual hoof-prints in the cave floor — echoes of the Kazhukans
	const PRINT_XS := [600.0, 900.0, 1200.0, 1500.0, 1800.0]
	for x: float in PRINT_XS:
		var print_vis  := ColorRect.new()
		print_vis.size  = Vector2(16.0, 10.0)
		print_vis.position = Vector2(x - 8.0, GROUND_Y - 5.0)
		print_vis.color = Color(0.20, 0.85, 0.80, 0.35)   # faint teal glow
		print_vis.z_index = 0
		add_child(print_vis)

		# Slow pulse
		var tw := print_vis.create_tween().set_loops()
		tw.tween_property(print_vis, "modulate:a", 0.3, 1.8)
		tw.tween_property(print_vis, "modulate:a", 1.0, 1.2)

func _build_fireflies() -> void:
	# Scattered fireflies drifting in Maveli's chamber area (x=3800+)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9999
	for i: int in 18:
		var ff         := ColorRect.new()
		ff.size         = Vector2(3.0, 3.0)
		var x: float    = rng.randf_range(3800.0, CAVE_LENGTH - 200.0)
		var y: float    = rng.randf_range(CEILING_Y + 30.0, GROUND_Y - 40.0)
		ff.position     = Vector2(x, y)
		ff.color        = Color(0.82, 0.95, 0.40, 0.85)   # yellow-green
		ff.z_index      = 4
		add_child(ff)

		# Drift tween — wander gently, loop
		var tw := ff.create_tween().set_loops()
		var drift_x: float = rng.randf_range(-18.0, 18.0)
		var drift_y: float = rng.randf_range(-12.0, 12.0)
		var dur: float     = rng.randf_range(2.2, 4.8)
		tw.tween_property(ff, "position", Vector2(x + drift_x, y + drift_y), dur).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ff, "position", Vector2(x, y), dur).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(ff, "modulate:a", 0.2, dur * 0.5)
		tw.parallel().tween_property(ff, "modulate:a", 1.0, dur * 0.5)

func _build_ambient_drips() -> void:
	# Falling water drop particles — visual only, thin blue-grey vertical flickers
	var rng := RandomNumberGenerator.new()
	rng.seed = 55555
	for _i: int in 8:
		var drip       := ColorRect.new()
		drip.size       = Vector2(1.0, 6.0)
		var x: float    = rng.randf_range(100.0, CAVE_LENGTH - 300.0)
		drip.position   = Vector2(x, CEILING_Y + 5.0)
		drip.color      = Color(0.55, 0.70, 0.90, 0.60)
		drip.z_index    = 1
		add_child(drip)

		# Drip from ceiling to floor, repeating
		var tw := drip.create_tween().set_loops()
		tw.tween_property(drip, "position:y", float(GROUND_Y - 8.0), rng.randf_range(1.2, 2.8)).set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(drip, "position:y", float(CEILING_Y + 5.0), 0.0)

# ─────────────────────────────────────────────────────────────────────────────
# Maveli spawn
# ─────────────────────────────────────────────────────────────────────────────

func _spawn_maveli() -> void:
	var maveli: Node2D = preload("res://scenes/Maveli.tscn").instantiate()
	maveli.position    = Vector2(4650.0, GROUND_Y)
	maveli.blessing_given.connect(_begin_exit)
	add_child(maveli)

	# Throne — a wide low stone platform behind Maveli
	var throne       := ColorRect.new()
	throne.size       = Vector2(120.0, 28.0)
	throne.position   = Vector2(4590.0, GROUND_Y - 28.0)
	throne.color      = Color(0.22, 0.18, 0.28, 1.0)   # dark stone purple-grey
	throne.z_index    = -1
	add_child(throne)

	# Throne back rest
	var back          := ColorRect.new()
	back.size          = Vector2(10.0, 55.0)
	back.position      = Vector2(4700.0, GROUND_Y - 83.0)
	back.color         = Color(0.22, 0.18, 0.28, 1.0)
	back.z_index       = -1
	add_child(back)

# ─────────────────────────────────────────────────────────────────────────────
# Ambient setup
# ─────────────────────────────────────────────────────────────────────────────

func _start_ambient() -> void:
	# Deep underground ambience — silence, distant drips
	# AudioManager.play_ambient("pathalam_cave") when .ogg exists
	pass

func _queue_entry_hint() -> void:
	# Delay so the HUD finishes loading
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		var hud := get_node_or_null("HUD")
		if hud and hud.has_method("show_hint"):
			hud.show_hint("🕯  The monsoon has stopped. Walk forward.", 5.0)
	)
