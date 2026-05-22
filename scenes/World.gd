extends "res://scenes/BaseAct.gd"

## PROLOGUE — "Muruthikudi at Dusk"
## Tutorial scene. Golden hour. Teaches climb, combat, river crossing.

const NEXT_SCENE    := "res://scenes/Act1.tscn"
const ACT_TRIGGER_X := 7800.0

# Ambient sky animation
const CLOUD_SPEED := 6.0    # px/sec autonomous cloud drift — slow, peaceful Kerala dusk
var _sky_layer: ParallaxLayer = null

const ZONE1_TREES  := 14
const ZONE1_X_FROM := 320.0
const ZONE1_X_TO   := 2780.0
const ZONE1_H      := 280.0   # crown y≈420 (GROUND_Y now 700, trunk longer)

const ZONE2_TREES  := 9
const ZONE2_X_FROM := 2900.0
const ZONE2_X_TO   := 4350.0
const ZONE2_H      := 300.0   # crown y≈400 (GROUND_Y now 700, trunk longer)

const ZONE3_TREES  := 12
const ZONE3_X_FROM := 4450.0
const ZONE3_X_TO   := 6750.0
const ZONE3_H      := 330.0   # crown y≈370 (GROUND_Y now 700, trunk longer)

const RIVER_X := 2860.0
const RIVER_W := 500.0

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_unlocks_act = 1   # completing prologue unlocks Act I
	_trigger_x  = ACT_TRIGGER_X
	# Kerala dusk — 9 isolated white-background elements from ChatGPT, layered back→front.
	# All use remove_white shader (white canvas → transparent, coloured art → visible).
	# No static base PNG — the sky colour + layered elements build the full scene.
	_init_sprite_parallax(Color("#EC8150"))   # amber dusk fill — shows through transparent areas
	_add_parallax_layers([
		{"path": "res://assets/backgrounds/prologue_el_sky.png",
			"scroll": 0.03, "tile": true, "remove_white": true},   # amber sky + clouds — farthest
		{"path": "res://assets/backgrounds/prologue_el_sun.png",
			"scroll": 0.06, "tile": true, "remove_white": true},   # pale sun disc
		{"path": "res://assets/backgrounds/prologue_el_mountains.png",
			"scroll": 0.07, "tile": true, "remove_white": true},   # layered amber mountains
		{"path": "res://assets/backgrounds/prologue_el_temple_far.png",
			"scroll": 0.10, "tile": true, "remove_white": true},   # faded distant temple spire
		{"path": "res://assets/backgrounds/prologue_el_palms_mid.png",
			"scroll": 0.14, "tile": true, "remove_white": true},   # misty mid-ground palms
		{"path": "res://assets/backgrounds/prologue_el_treeline.png",
			"scroll": 0.18, "tile": true, "remove_white": true},   # dense jungle treeline
		{"path": "res://assets/backgrounds/prologue_el_skyline.png",
			"scroll": 0.24, "tile": true, "remove_white": true},   # Kerala temple+tree skyline
		{"path": "res://assets/backgrounds/prologue_el_palm_near.png",
			"scroll": 0.32, "tile": true, "remove_white": true},   # single tall near palm
		{"path": "res://assets/backgrounds/prologue_el_grass.png",
			"scroll": 0.40, "tile": true, "remove_white": true},   # foreground grass — nearest
	])
	_spawn_trees()
	_spawn_river()
	_spawn_crabs()
	_spawn_ghosts()
	_spawn_npcs()
	_spawn_powerups()
	_connect_player_to_hud()
	_queue_hint("🌴 Press [E] near a tree to climb!", 2.0, 5.5)
	# Grab the sky parallax layer (first child = sky, scroll 0.03) for autonomous drift
	var pbg: ParallaxBackground = get_node_or_null("BackgroundParallax")
	if pbg and pbg.get_child_count() > 0:
		_sky_layer = pbg.get_child(0) as ParallaxLayer
	_spawn_crows()

func _process(delta: float) -> void:
	super._process(delta)
	# Drift clouds leftward even when the player is standing still.
	# Read-modify-write the full Vector2 to avoid GDScript "sub-property" edge cases.
	if _sky_layer:
		var off := _sky_layer.motion_offset
		off.x   -= CLOUD_SPEED * delta
		_sky_layer.motion_offset = off

func _spawn_crows() -> void:
	# Five crows at varied sky depths, speeds and flap rhythms.
	# Camera centre ≈ world y 621, viewport 270 px → visible y 486–756.
	# Crows at y 495–545 appear in the upper ~20% of the visible sky.
	const CROW_SCRIPT := "res://scenes/FlyingCrow.gd"
	var data := [
		{"x":  300.0, "y": 500.0, "speed": 20.0, "size": 4.5, "freq": 2.8, "phase": 0.0},
		{"x": 1400.0, "y": 515.0, "speed": 15.0, "size": 3.5, "freq": 3.3, "phase": 1.1},
		{"x": 2900.0, "y": 498.0, "speed": 25.0, "size": 5.5, "freq": 2.5, "phase": 0.6},
		{"x": 4600.0, "y": 530.0, "speed": 18.0, "size": 4.0, "freq": 3.0, "phase": 1.8},
		{"x": 6500.0, "y": 510.0, "speed": 22.0, "size": 5.0, "freq": 2.7, "phase": 0.9},
	]
	var scr: Script = load(CROW_SCRIPT)
	for d: Dictionary in data:
		var crow := Node2D.new()
		crow.set_script(scr)
		crow.position = Vector2(float(d["x"]), float(d["y"]))
		# Use set() so GDScript resolves against the runtime script type,
		# not the static Node2D type — avoids "Invalid set index" crash.
		crow.set("speed",        d["speed"])
		crow.set("bird_size",    d["size"])
		crow.set("flap_freq",    d["freq"])
		crow.set("phase_offset", d["phase"])
		add_child(crow)

func _spawn_trees() -> void:
	var tint := Color(0.95, 0.85, 0.45, 1.0)   # golden hour
	var z1 := _linspace(ZONE1_X_FROM, ZONE1_X_TO, ZONE1_TREES)
	for i: int in z1.size():
		_add_tree($Trees, z1[i], ZONE1_H, 0.08 * (1 if i % 2 == 0 else -1), tint)
	var z2 := _linspace(ZONE2_X_FROM, ZONE2_X_TO, ZONE2_TREES)
	for x: float in z2:
		_add_tree($Trees, x, ZONE2_H, 0.0, tint)
	var z3 := _linspace(ZONE3_X_FROM, ZONE3_X_TO, ZONE3_TREES)
	for i: int in z3.size():
		_add_tree($Trees, z3[i], ZONE3_H, 0.06 * (1 if i % 2 == 0 else -1), tint)

func _spawn_river() -> void:
	var water_y := GROUND_Y - 18.0
	_build_river_visual(RIVER_X, RIVER_W)
	var river := Area2D.new()
	river.collision_layer = 0
	river.collision_mask  = 2
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size     = Vector2(RIVER_W, 55.0)
	col.shape      = shape
	river.position = Vector2(RIVER_X + RIVER_W * 0.5, GROUND_Y + 5.0)
	river.add_child(col)
	river.body_entered.connect(_on_river_entered)
	river.body_exited.connect(_on_river_exited)
	add_child(river)
	_spawn_boat($Trees, RIVER_X + 80.0,  water_y)
	_spawn_boat($Trees, RIVER_X + 250.0, water_y)
	_spawn_boat($Trees, RIVER_X + 420.0, water_y)
	var croc: Node2D = preload("res://scenes/Crocodile.tscn").instantiate()
	croc.position    = Vector2(RIVER_X + RIVER_W * 0.5, GROUND_Y)
	croc.patrol_left  = RIVER_X
	croc.patrol_right = RIVER_X + RIVER_W
	$Enemies.add_child(croc)

func _on_river_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("enter_water"):
		body.enter_water()

func _on_river_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("exit_water"):
		body.exit_water()

func _spawn_crabs() -> void:
	for x: float in [900.0, 1300.0, 1600.0, 1900.0, 2500.0]:
		var crab: Node2D = preload("res://scenes/CoconutCrab.tscn").instantiate()
		crab.position = Vector2(x, GROUND_Y)
		$Enemies.add_child(crab)

func _spawn_ghosts() -> void:
	var xs := _linspace(4500.0, 6700.0, 6)
	for i: int in xs.size():
		var ghost: Node2D = preload("res://scenes/GhostClone.tscn").instantiate()
		ghost.position = Vector2(xs[i], GROUND_Y)
		ghost.is_real  = (i == 3)
		$Enemies.add_child(ghost)

func _spawn_npcs() -> void:
	var biju: Node2D = preload("res://scenes/BijuEttan.tscn").instantiate()
	biju.position = Vector2(150.0, GROUND_Y)
	add_child(biju)
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(400.0, GROUND_Y)
	add_child(thoma)
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(3400.0, GROUND_Y)
	add_child(soniya)
	_spawn_throw_tutorial()

func _spawn_throw_tutorial() -> void:
	# Stationary practice target at x=620 — throw a coconut to knock it down
	var post := StaticBody2D.new()
	post.position = Vector2(620.0, GROUND_Y - 24.0)
	var vis := ColorRect.new()
	vis.size     = Vector2(24.0, 48.0)
	vis.position = Vector2(-12.0, -48.0)
	vis.color    = Color(0.85, 0.35, 0.15)
	post.add_child(vis)
	var lbl := Label.new()
	lbl.text = "🥥 Throw!"
	lbl.position = Vector2(-30.0, -80.0)
	lbl.add_theme_font_size_override("font_size", 11)
	post.add_child(lbl)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24.0, 48.0)
	col.shape  = shape
	post.add_child(col)
	# Area2D detects coconut hits — coconut has collision_layer=16 (layer 5)
	var hit_area := Area2D.new()
	hit_area.collision_layer = 0
	hit_area.collision_mask  = 16   # layer 5 = coconuts
	var hcol := CollisionShape2D.new()
	var hshape := RectangleShape2D.new()
	hshape.size = Vector2(32.0, 56.0)
	hcol.shape  = hshape
	hit_area.add_child(hcol)
	hit_area.area_entered.connect(func(_a: Area2D) -> void:
		if post.is_inside_tree(): post.queue_free()
		GameManager.show_score_popup(Vector2(620.0, GROUND_Y - 60.0), 5, Color(1.0, 0.9, 0.3))
	)
	post.add_child(hit_area)
	add_child(post)
	_queue_hint("🥥 Press [Q] to throw a coconut at the target!", 6.0, 5.0)

func _spawn_powerups() -> void:
	var data := [
		[450.0,  470.0,    "heart"],
		[920.0,  470.0,    "nut"],
		[1520.0, GROUND_Y, "heart"],
		[1820.0, GROUND_Y, "nut"],
		[3920.0, GROUND_Y, "nut"],
		[4820.0, GROUND_Y, "heart"],
		[5220.0, GROUND_Y, "porotta"],
		[5620.0, GROUND_Y, "nut"],
		[6020.0, GROUND_Y, "toddy"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])
	_add_platform(RIVER_X + RIVER_W * 0.5, 440.0, 100.0)
	_add_powerup($PowerUps, RIVER_X + RIVER_W * 0.5, 432.0, "chai")
