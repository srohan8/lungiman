extends Node2D

## ─── BaseAct ────────────────────────────────────────────────────────────────
## Shared scaffold inherited by Act1–Act5 and World.
## Each act sets _next_scene / _trigger_x in its own _ready().
##
## Provides: _linspace, _add_tree, _add_powerup, _add_platform,
##           _spawn_boat, _connect_player_to_hud, _get_player, _get_hud,
##           _queue_hint

const GROUND_Y := 700.0   # swing room: trunks 80px longer so the pendulum arc bottoms out mid-trunk, never clips ground

var _act_triggered     := false
var _next_scene        := ""
var _trigger_x         := 7800.0
var _unlocks_act       := 0     # set by each Act: completing this act unlocks _unlocks_act in LevelSelect
var _boss_block_hinted := false  # fires the "boss still alive" hint at most once
var _exit_wall:  Node2D = null   # physical barrier at _trigger_x — removed on boss death
var _exit_pulse: Tween  = null   # looping pulse tween on the barrier visual

# ── Auto-transition ──────────────────────────────────────────────────────────

const KILL_ZONE_Y := 1000.0  # 300px below GROUND_Y (700) — instant death if player falls off world

func _process(_delta: float) -> void:
	if _act_triggered or _next_scene.is_empty():
		return
	var player := _get_player()
	if player == null:
		return
	# Kill zone — player fell off the bottom or left edge of the world
	if player.global_position.y > KILL_ZONE_Y or player.global_position.x < -100.0:
		GameManager.take_damage(999)
		return
	# Spawn the exit barrier early — when boss is alive and player is within 400px of the exit.
	# This prevents the player reaching the world edge before the wall appears.
	if GameManager.boss_max_hp > 0 and _exit_wall == null \
			and player.global_position.x >= _trigger_x - 400.0:
		_spawn_exit_wall()

	if player.global_position.x >= _trigger_x:
		# Gate: if a boss is still alive, block the exit and hint the player once.
		if GameManager.boss_max_hp > 0:
			if not _boss_block_hinted:
				_boss_block_hinted = true
				var hud := _get_hud()
				if hud and hud.has_method("show_hint"):
					hud.show_hint("⚠️ Defeat the boss to proceed!", 4.0)
			return
		_act_triggered = true
		if _unlocks_act > 0:
			GameManager.unlock_act(_unlocks_act)
		SceneManager.go_to(_next_scene)

# ── Boss exit barrier ────────────────────────────────────────────────────────

## Spawns a visible physical wall at the right exit while the boss is alive.
## Pulsing red stripe + sign; dissolves with a flash when the boss is defeated.
func _spawn_exit_wall() -> void:
	if _exit_wall != null or _next_scene.is_empty(): return

	var wall := StaticBody2D.new()
	wall.name            = "ExitWall"
	wall.collision_layer = 1
	wall.collision_mask  = 0
	wall.position        = Vector2(_trigger_x - 40.0, GROUND_Y - 350.0)

	var shape_node := CollisionShape2D.new()
	var rect       := RectangleShape2D.new()
	rect.size       = Vector2(18.0, 800.0)
	shape_node.shape = rect
	wall.add_child(shape_node)

	# Pulsing red barrier strip
	var bar := ColorRect.new()
	bar.color    = Color(0.88, 0.18, 0.08, 0.82)
	bar.size     = Vector2(10.0, 800.0)
	bar.position = Vector2(-5.0, -400.0)
	bar.z_index  = 8
	wall.add_child(bar)

	# Warning stripe pattern — alternating dark bands
	for i: int in 8:
		var stripe := ColorRect.new()
		stripe.color    = Color(0.0, 0.0, 0.0, 0.30)
		stripe.size     = Vector2(10.0, 40.0)
		stripe.position = Vector2(-5.0, -400.0 + i * 100.0 + 30.0)
		wall.add_child(stripe)

	# Sign: arrow pointing left toward boss
	var sign := ColorRect.new()
	sign.color    = Color(0.12, 0.08, 0.04, 0.92)
	sign.size     = Vector2(90.0, 26.0)
	sign.position = Vector2(-95.0, -320.0)
	sign.z_index  = 9
	wall.add_child(sign)
	var sign_label := ColorRect.new()   # amber arrow strip inside sign
	sign_label.color    = Color(1.0, 0.70, 0.10, 0.90)
	sign_label.size     = Vector2(70.0, 6.0)
	sign_label.position = Vector2(-85.0, -307.0)
	sign_label.z_index  = 10
	wall.add_child(sign_label)
	# Arrow tip (triangle-ish via small square rotated)
	var arrow := ColorRect.new()
	arrow.color    = Color(1.0, 0.70, 0.10, 0.90)
	arrow.size     = Vector2(10.0, 10.0)
	arrow.position = Vector2(-88.0, -310.0)
	arrow.z_index  = 10
	wall.add_child(arrow)

	add_child(wall)
	_exit_wall = wall

	# Pulse the barrier — slow red throb
	_exit_pulse = create_tween().set_loops()
	_exit_pulse.tween_property(bar, "modulate:a", 0.35, 0.7)
	_exit_pulse.tween_property(bar, "modulate:a", 1.00, 0.7)

	# Listen for boss death to dissolve the wall
	if not GameManager.boss_hp_changed.is_connected(_on_boss_hp_changed):
		GameManager.boss_hp_changed.connect(_on_boss_hp_changed)

func _on_boss_hp_changed(new_hp: int) -> void:
	if new_hp > 0 or _exit_wall == null: return
	# Boss is dead — dissolve the wall
	if _exit_pulse != null:
		_exit_pulse.kill()
		_exit_pulse = null
	if GameManager.boss_hp_changed.is_connected(_on_boss_hp_changed):
		GameManager.boss_hp_changed.disconnect(_on_boss_hp_changed)
	# Flash white then fade out
	var tw := create_tween()
	tw.tween_property(_exit_wall, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.08)
	tw.tween_property(_exit_wall, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.35)
	tw.tween_callback(_exit_wall.queue_free)
	_exit_wall = null
	var hud := _get_hud()
	if hud and hud.has_method("show_hint"):
		hud.show_hint("✅ Path clear — keep going!", 2.5)

# ── HUD wiring ───────────────────────────────────────────────────────────────

func _connect_player_to_hud() -> void:
	# Spawn PauseMenu so Escape works in every act
	if not get_node_or_null("PauseMenu"):
		var pm: Node = preload("res://scenes/PauseMenu.tscn").instantiate()
		pm.name = "PauseMenu"
		# Must process while paused
		pm.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(pm)
	var player := _get_player()
	var hud    := _get_hud()
	if player and hud:
		if not player.climb_prompt_changed.is_connected(hud.show_climb_prompt):
			player.climb_prompt_changed.connect(hud.show_climb_prompt)
	var go := get_node_or_null("GameOver")
	if go and not GameManager.player_died.is_connected(go.show_game_over):
		GameManager.player_died.connect(go.show_game_over)
	var vic := get_node_or_null("Victory")
	if vic and not GameManager.game_won.is_connected(vic.show_victory):
		GameManager.game_won.connect(vic.show_victory)
	# Resurrection revival — show dramatic HUD message
	if hud and not GameManager.player_revived.is_connected(_on_player_revived):
		GameManager.player_revived.connect(_on_player_revived)

func _on_player_revived() -> void:
	var hud := _get_hud()
	if hud and hud.has_method("show_hint"):
		hud.show_hint("✝️ Brother Thoma's blessing — you live!", 4.0)

func _get_player() -> Node2D:
	return get_node_or_null("Player") as Node2D

func _get_hud() -> CanvasLayer:
	return get_node_or_null("HUD") as CanvasLayer

# ── Spawner helpers ──────────────────────────────────────────────────────────

func _add_tree(parent: Node, x: float, h: float, lean: float,
		tint: Color = Color.WHITE) -> void:
	var tree: Node2D = preload("res://scenes/CoconutTree.tscn").instantiate()
	tree.height   = h
	tree.lean     = lean
	tree.position = Vector2(x, GROUND_Y)
	if tint != Color.WHITE:
		tree.modulate = tint
	parent.add_child(tree)

func _add_powerup(parent: Node, x: float, y: float, type: String) -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type     = type
	pu.position = Vector2(x, y - 10.0)
	parent.add_child(pu)

func _add_platform(x: float, y: float, w: float,
		tint: Color = Color(0.30, 0.20, 0.10, 1.0)) -> void:
	var sb    := StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask  = 0
	sb.position = Vector2(x, y)
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, 18.0)
	col.shape  = shape
	sb.add_child(col)
	var vis      := ColorRect.new()
	vis.color    = tint
	vis.size     = Vector2(w, 18.0)
	vis.position = Vector2(-w * 0.5, -9.0)
	sb.add_child(vis)
	add_child(sb)

## Returns (and lazily creates) a shared ShaderMaterial that discards near-black
## pixels — used by all Scenario.gg prop sprites whose background is solid black.
var _prop_mat_cached: ShaderMaterial = null
func _get_prop_mat() -> ShaderMaterial:
	if _prop_mat_cached != null:
		return _prop_mat_cached
	const SHADER_PATH := "res://assets/shaders/black_bg_remove.gdshader"
	if not ResourceLoader.exists(SHADER_PATH):
		return null
	var sh: Shader = load(SHADER_PATH)
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_prop_mat_cached = mat
	return mat

## Place a single-frame Scenario.gg prop sprite at world position (x, y).
## centered = true, so (x, y) is the image centre in world space.
## Black background is removed via the shared shader.
## Returns the Sprite2D so callers can further configure it.
func _prop_sprite(tex_path: String, x: float, y: float,
		sc: float, z: int = 1) -> Sprite2D:
	var spr := Sprite2D.new()
	if ResourceLoader.exists(tex_path):
		spr.texture = load(tex_path)
	spr.scale    = Vector2(sc, sc)
	spr.position = Vector2(x, y)
	spr.z_index  = z
	var mat := _get_prop_mat()
	if mat != null:
		spr.material = mat
	add_child(spr)
	return spr

func _spawn_boat(parent: Node, x: float, water_y: float) -> void:
	# Kerala kettuvallam houseboat — wide hull + raised cabin + thatch roof
	var hull_w := 240.0   # was 120 — doubled for a proper Kerala houseboat
	var hull_h := 18.0
	var sb     := StaticBody2D.new()
	sb.name    = "Boat"
	sb.collision_layer = 1
	sb.collision_mask  = 0
	sb.position = Vector2(x, water_y - hull_h * 0.5)
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(hull_w, hull_h)
	col.shape  = shape
	sb.add_child(col)

	const BOAT_TEX := "res://assets/sprites/boat_sheet.png"
	if ResourceLoader.exists(BOAT_TEX):
		# Larger scale to match the wider hull
		const SC := 0.068
		var spr  := Sprite2D.new()
		spr.texture  = load(BOAT_TEX)
		spr.scale    = Vector2(SC, SC)
		spr.position = Vector2(0.0, -44.0)   # raised for cabin height
		spr.z_index  = 3
		var mat := _get_prop_mat()
		if mat != null: spr.material = mat
		sb.add_child(spr)
	else:
		# Fallback: hand-drawn Kerala kettuvallam houseboat
		# Hull — wide dark teak base
		var hull      := ColorRect.new()
		hull.color    = Color(0.38, 0.22, 0.06, 1.0)
		hull.size     = Vector2(hull_w, hull_h)
		hull.position = Vector2(-hull_w * 0.5, -hull_h * 0.5)
		sb.add_child(hull)
		var stripe      := ColorRect.new()   # waterline trim
		stripe.color    = Color(0.62, 0.42, 0.16, 1.0)
		stripe.size     = Vector2(hull_w, 4.0)
		stripe.position = Vector2(-hull_w * 0.5, -hull_h * 0.5)
		sb.add_child(stripe)
		# Cabin — raised wicker structure mid-ship
		var cabin_w := 160.0
		var cabin_h := 40.0
		var cabin      := ColorRect.new()
		cabin.color    = Color(0.50, 0.30, 0.08, 1.0)
		cabin.size     = Vector2(cabin_w, cabin_h)
		cabin.position = Vector2(-cabin_w * 0.5, -hull_h * 0.5 - cabin_h)
		sb.add_child(cabin)
		# Arched palm-thatch roof
		var roof_w := 184.0
		var roof_h := 20.0
		var roof      := ColorRect.new()
		roof.color    = Color(0.20, 0.14, 0.04, 1.0)
		roof.size     = Vector2(roof_w, roof_h)
		roof.position = Vector2(-roof_w * 0.5, -hull_h * 0.5 - cabin_h - roof_h + 3.0)
		sb.add_child(roof)
		var peak      := ColorRect.new()   # roof ridge cap
		peak.color    = Color(0.14, 0.09, 0.02, 1.0)
		peak.size     = Vector2(144.0, 7.0)
		peak.position = Vector2(-72.0, -hull_h * 0.5 - cabin_h - roof_h - 4.0)
		sb.add_child(peak)
		# Windows — warm lantern glow, 3 across the cabin
		for wx: float in [-44.0, 0.0, 44.0]:
			var win      := ColorRect.new()
			win.color    = Color(0.95, 0.82, 0.45, 0.85)
			win.size     = Vector2(16.0, 14.0)
			win.position = Vector2(wx - 8.0, -hull_h * 0.5 - cabin_h + 12.0)
			sb.add_child(win)
		# Bow flag post
		var post      := ColorRect.new()
		post.color    = Color(0.52, 0.32, 0.10, 1.0)
		post.size     = Vector2(4.0, 30.0)
		post.position = Vector2(hull_w * 0.5 - 16.0, -hull_h * 0.5 - cabin_h - 30.0)
		sb.add_child(post)

	parent.add_child(sb)

## Builds a proper animated river channel — deep water body, animated wave shader,
## and earth bank walls so the river looks sunken into the ground, not floating on it.
## Call this from act scripts instead of a plain ColorRect water surface.
## river_x : world-x of the LEFT edge of the river
## river_w : width of the river zone in pixels
func _build_river_visual(river_x: float, river_w: float) -> void:
	const WATER_TOP   := 20.0    # surface closer to ground level
	const WATER_DEPTH := 180.0   # deep body extends this far below surface
	const BANK_W      := 32.0    # earth bank width on each side
	const BANK_H      := 78.0    # bank height above GROUND_Y
	var surface_y := GROUND_Y - WATER_TOP
	var bank_col  := Color(0.28, 0.18, 0.07, 1.0)   # Kerala laterite clay

	# Deep water body — extends below ground so the channel has visual depth
	# Kerala backwater colour: dark murky olive-brown, not open-ocean blue.
	var deep := ColorRect.new()
	deep.color    = Color(0.06, 0.09, 0.05, 1.0)   # dark greenish-brown backwater
	deep.size     = Vector2(river_w, WATER_TOP + WATER_DEPTH)
	deep.position = Vector2(river_x, surface_y)
	deep.z_index  = 6    # above ground tile (z_index 5)
	add_child(deep)

	# Animated surface — texture scroll when tile exists, procedural fallback
	const WATER_TILE := "res://assets/backgrounds/bg_water_tile.png"
	var mat := ShaderMaterial.new()
	var sh  := Shader.new()
	if ResourceLoader.exists(WATER_TILE):
		# Sprite2D with tiled water texture + scrolling UV shader
		var wtex: Texture2D = load(WATER_TILE)
		var surface := Sprite2D.new()
		surface.texture        = wtex
		surface.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		surface.centered       = false
		# Scale so the tile fills the river width and correct height
		var sx := river_w / float(wtex.get_width())
		var sy := (WATER_TOP + 6.0) / float(wtex.get_height())
		surface.scale    = Vector2(sx, sy)
		surface.position = Vector2(river_x, surface_y - 6.0)
		surface.z_index  = 7
		# Shader: scroll UV + bake amber-brown Kerala backwater tint directly in GLSL.
		# Tint multiplied per-channel: suppresses ocean blue, warms the water.
		sh.code = """shader_type canvas_item;
uniform float speed : hint_range(0.0, 3.0) = 0.38;
void fragment() {
	vec2 scrolled = vec2(fract(UV.x + TIME * speed), UV.y);
	vec4 tex = texture(TEXTURE, scrolled);
	// Kerala backwater at dusk — murky olive-amber, not ocean blue
	vec3 tint = vec3(0.50, 0.40, 0.22);
	COLOR = vec4(tex.rgb * tint, tex.a * 0.92);
}
"""
		mat.shader       = sh
		surface.material = mat
		add_child(surface)
	else:
		# Procedural fallback — multi-layer sine waves (no PNG needed)
		# Warm murky backwater colours instead of ocean blue.
		var surface := ColorRect.new()
		surface.size     = Vector2(river_w, WATER_TOP + 6.0)
		surface.position = Vector2(river_x, surface_y - 6.0)
		surface.z_index  = 7
		sh.code = """shader_type canvas_item;
uniform float speed : hint_range(0.0, 5.0) = 0.9;
void fragment() {
	float w1 = sin(UV.x * 14.0 + TIME * speed) * 0.06 + 0.94;
	float w2 = sin(UV.x *  9.0 - TIME * speed * 0.7 + 1.2) * 0.04 + 0.96;
	float w3 = sin(UV.x *  5.0 + TIME * speed * 0.4 + 2.5) * 0.05 + 0.95;
	float wave = w1 * w2 * w3;
	vec4 deep  = vec4(0.06, 0.09, 0.05, 0.96);   // dark murky backwater
	vec4 light = vec4(0.28, 0.22, 0.12, 0.88);   // amber surface catch-light
	COLOR = mix(deep, light, wave * (1.0 - UV.y * 0.45));
}
"""
		mat.shader       = sh
		surface.material = mat
		add_child(surface)

	# Specular highlight strip at waterline — warm amber from the setting sun
	var glint := ColorRect.new()
	glint.color    = Color(0.96, 0.78, 0.42, 0.38)
	glint.size     = Vector2(river_w, 4.0)
	glint.position = Vector2(river_x, surface_y - 8.0)
	glint.z_index  = 8
	add_child(glint)

	# Left earth bank — covers the ground tile edge, makes channel look sunken
	var bl := ColorRect.new()
	bl.color    = bank_col
	bl.size     = Vector2(BANK_W, BANK_H)
	bl.position = Vector2(river_x - BANK_W * 0.6, GROUND_Y - BANK_H * 0.6)
	bl.z_index  = 9
	add_child(bl)
	var sl := ColorRect.new()   # inner shadow
	sl.color    = Color(0.0, 0.0, 0.0, 0.32)
	sl.size     = Vector2(10.0, BANK_H * 0.75)
	sl.position = Vector2(river_x, GROUND_Y - BANK_H * 0.55)
	sl.z_index  = 10
	add_child(sl)

	# Right earth bank
	var br := ColorRect.new()
	br.color    = bank_col
	br.size     = Vector2(BANK_W, BANK_H)
	br.position = Vector2(river_x + river_w - BANK_W * 0.4, GROUND_Y - BANK_H * 0.6)
	br.z_index  = 9
	add_child(br)
	var sr := ColorRect.new()   # inner shadow
	sr.color    = Color(0.0, 0.0, 0.0, 0.32)
	sr.size     = Vector2(10.0, BANK_H * 0.75)
	sr.position = Vector2(river_x + river_w - 10.0, GROUND_Y - BANK_H * 0.55)
	sr.z_index  = 10
	add_child(sr)

func _queue_hint(text: String, delay: float = 1.5, duration: float = 5.0) -> void:
	get_tree().create_timer(delay).timeout.connect(
		func() -> void:
			var hud := _get_hud()
			if hud and hud.has_method("show_hint"):
				hud.show_hint(text, duration)
	)

# ── Atmosphere ───────────────────────────────────────────────────────────────

## Call from each act's _ready() to set the sky background colour.
## Automatically adds a screen-space vignette overlay on first call.
func _apply_sky(sky_color: Color) -> void:
	# Sky background in a CanvasLayer so it's camera-independent.
	# Without this, climbing tall trees scrolls the camera above the rect → black screen.
	if not get_node_or_null("SkyLayer"):
		var sky_cl := CanvasLayer.new()
		sky_cl.name  = "SkyLayer"
		sky_cl.layer = -10   # below everything; HUD is at 100
		var bg := ColorRect.new()
		bg.name         = "SkyBackground"
		bg.color        = sky_color
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sky_cl.add_child(bg)
		add_child(sky_cl)
	# Vignette CanvasLayer — persists above game world, below HUD (layer 10)
	if not get_node_or_null("Vignette"):
		var cl := CanvasLayer.new()
		cl.name  = "Vignette"
		cl.layer = 10
		var tex_rect := TextureRect.new()
		var grad := GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
		g.set_offset(0, 0.0)
		g.set_color(1, Color(0.0, 0.0, 0.0, 0.65))
		g.set_offset(1, 1.0)
		grad.gradient  = g
		grad.fill      = GradientTexture2D.FILL_RADIAL
		grad.fill_from = Vector2(0.5, 0.5)
		grad.fill_to   = Vector2(1.0, 0.5)
		grad.width     = 512
		grad.height    = 512
		tex_rect.texture      = grad
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(tex_rect)
		add_child(cl)

# ── Parallax background ──────────────────────────────────────────────────────

const GROUND_TILE_PATH := "res://assets/backgrounds/ground_tile.png"

## True 3-layer parallax background system.
##
## Layer stack (back → front):
##   -12  SkyLayer      CanvasLayer, camera-independent solid colour + optional sky PNG (0.0×)
##   -10  ParallaxBackground:
##          layer[0]  far_bg  (the full painterly scene)   motion_scale 0.15
##          layer[1]  mid_bg  (optional mid-distance strip) motion_scale 0.45
##            if mid_path given → load the PNG;
##            else              → reuse far_bg texture at 0.55 alpha (free depth bonus)
##    10  Vignette      CanvasLayer, above game world
##
## bg_path   : res:// path to the full-scene background (1920×1080).
## sky_color : fallback + SkyLayer colour.
## sky_path  : optional sky-only PNG (just sky, 1920×540); drawn STATIC in SkyLayer.
## mid_path  : optional mid-distance silhouette strip PNG (1920×1080, sky bg baked in);
##             drifts at 0.10× — only created when this is provided (no fallback).
func _apply_background(bg_path: String, sky_color: Color,
		sky_path: String = "", mid_path: String = "") -> void:

	# ── Layer -12: Sky (static CanvasLayer) ─────────────────────────────────
	if not get_node_or_null("SkyLayer"):
		var sky_cl := CanvasLayer.new()
		sky_cl.name  = "SkyLayer"
		sky_cl.layer = -12
		# Solid-colour fallback — always present
		var bg_rect := ColorRect.new()
		bg_rect.color        = sky_color
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sky_cl.add_child(bg_rect)
		# Optional sky PNG (pure sky, no foreground) at 0.0× — fully static.
		# Scale by the LARGER of the two ratios so the image always covers the full
		# 480×270 viewport with no gaps, regardless of the PNG's exact dimensions.
		if sky_path != "" and ResourceLoader.exists(sky_path):
			var sky_spr := Sprite2D.new()
			sky_spr.texture  = load(sky_path)
			sky_spr.centered = false
			var sw  := float(sky_spr.texture.get_width())
			var sh  := float(sky_spr.texture.get_height())
			var vp  := get_viewport().get_visible_rect().size
			var s   := maxf(vp.x / sw, vp.y / sh)
			sky_spr.scale    = Vector2(s, s)
			sky_cl.add_child(sky_spr)
		add_child(sky_cl)

	# ── Layers -10: ParallaxBackground with 2 layers ─────────────────────────
	if not get_node_or_null("BackgroundParallax") and ResourceLoader.exists(bg_path):
		var pbg := ParallaxBackground.new()
		pbg.name  = "BackgroundParallax"
		pbg.layer = -10
		# Lock vertical scroll — background must not jump when player jumps.
		pbg.scroll_base_scale = Vector2(1.0, 0.0)

		# Sky crop: skip the top fraction of the background (where the background has its
		# own painted sky). The separate SkyLayer image fills that gap instead.
		# 0.35 = show only the lower 65% of the background (trees, foliage, mid-ground).
		const SKY_CROP := 0.35
		var far_tex: Texture2D    = load(bg_path)
		var tex_w   := float(far_tex.get_width())
		var tex_h   := float(far_tex.get_height())
		var s_far   := 270.0 / tex_h   # scale so full image fills 270px height
		var vp_w    := get_viewport().get_visible_rect().size.x
		var crop_y  := tex_h * SKY_CROP  # texture-space y where background starts

		# --- Far layer (0.0× = static) — the main painterly scene, lower 65% ----
		# Static (motion_scale=0) guarantees the background always fills the viewport
		# regardless of how far the camera scrolls.  Depth is provided by the sky crop
		# above and the drifting mid layer below.
		var far_layer := ParallaxLayer.new()
		far_layer.motion_scale    = Vector2(0.0, 0.0)
		far_layer.motion_mirroring = Vector2(0.0, 0.0)
		var far_spr := Sprite2D.new()
		far_spr.texture        = far_tex
		far_spr.centered       = false
		far_spr.scale          = Vector2(maxf(vp_w / tex_w, s_far), s_far)
		far_spr.region_enabled = true
		far_spr.region_rect    = Rect2(0, crop_y, tex_w, tex_h - crop_y)
		# Shift sprite down so it sits at the correct screen-space y (sky gap above)
		far_spr.position = Vector2(0, crop_y * s_far)
		far_layer.add_child(far_spr)
		pbg.add_child(far_layer)

		# --- Mid layer (0.10×) — mid-distance palm silhouette strip ----
		# Only created when a dedicated mid_path PNG is provided.
		# motion_mirroring = sprite display width (tex_w * scale) so tiles are seamless
		# at any camera position along the 7800px level.
		# Without dedicated artwork we skip this layer — a semi-transparent copy of the
		# far background drifting at a different speed looks like visual noise, not depth.
		if mid_path != "" and ResourceLoader.exists(mid_path):
			var mid_layer := ParallaxLayer.new()
			var mid_tex: Texture2D = load(mid_path)
			var s_mid     := 270.0 / float(mid_tex.get_height())
			var display_w := float(mid_tex.get_width()) * s_mid
			mid_layer.motion_scale    = Vector2(0.10, 0.0)
			mid_layer.motion_mirroring = Vector2(display_w, 0.0)
			var mid_spr := Sprite2D.new()
			mid_spr.texture  = mid_tex
			mid_spr.centered = false
			mid_spr.scale    = Vector2(s_mid, s_mid)
			mid_spr.position = Vector2(0, 0)
			mid_layer.add_child(mid_spr)
			pbg.add_child(mid_layer)

		add_child(pbg)

	# ── Ground tile overlay ───────────────────────────────────────────────────
	var ground_node := get_node_or_null("Ground")
	if ground_node and ground_node.get_node_or_null("GroundTile") == null \
			and ResourceLoader.exists(GROUND_TILE_PATH):
		var tile_tex: Texture2D = load(GROUND_TILE_PATH)
		var tile := Sprite2D.new()
		tile.name = "GroundTile"
		tile.texture = tile_tex
		tile.centered = false
		tile.region_enabled = true
		var tile_h: float = float(tile_tex.get_height())
		var target_h: float = 90.0   # taller ground strip; characters at z=6 render in front of tile (z=5)
		var s: float = target_h / tile_h
		tile.scale = Vector2(s, s)
		var world_w: float = 8200.0 / s
		tile.region_rect = Rect2(0, 0, world_w, tile_h)
		tile.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tile.position = Vector2(-4100.0, -target_h * 0.5)   # centre on ground surface
		tile.z_index = 5
		ground_node.add_child(tile)

	# ── Vignette overlay ─────────────────────────────────────────────────────
	if not get_node_or_null("Vignette"):
		var cl := CanvasLayer.new()
		cl.name  = "Vignette"
		cl.layer = 10
		var tex_rect := TextureRect.new()
		var grad := GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
		g.set_offset(0, 0.0)
		g.set_color(1, Color(0.0, 0.0, 0.0, 0.55))
		g.set_offset(1, 1.0)
		grad.gradient  = g
		grad.fill      = GradientTexture2D.FILL_RADIAL
		grad.fill_from = Vector2(0.5, 0.5)
		grad.fill_to   = Vector2(1.0, 0.5)
		grad.width     = 512
		grad.height    = 512
		tex_rect.texture      = grad
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(tex_rect)
		add_child(cl)

# ── Sprite-only parallax initialiser ────────────────────────────────────────

## Use this instead of _apply_background() when the background is built
## entirely from individual sprite layers via _add_parallax_layers() —
## i.e. no flat full-scene PNG is needed.
## Creates: SkyLayer (colour + optional sky PNG) · empty BackgroundParallax
##          · ground tile overlay · vignette.
func _init_sprite_parallax(sky_color: Color, sky_path: String = "") -> void:
	if not get_node_or_null("SkyLayer"):
		var sky_cl := CanvasLayer.new()
		sky_cl.name  = "SkyLayer"
		sky_cl.layer = -12
		var bg_rect := ColorRect.new()
		bg_rect.color        = sky_color
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sky_cl.add_child(bg_rect)
		if sky_path != "" and ResourceLoader.exists(sky_path):
			var sky_spr := Sprite2D.new()
			sky_spr.texture  = load(sky_path)
			sky_spr.centered = false
			var sw  := float(sky_spr.texture.get_width())
			var sh  := float(sky_spr.texture.get_height())
			var vp2 := get_viewport().get_visible_rect().size
			var s   := maxf(vp2.x / sw, vp2.y / sh)
			sky_spr.scale = Vector2(s, s)
			sky_cl.add_child(sky_spr)
		add_child(sky_cl)
	# Empty container — layers filled by _add_parallax_layers()
	if not get_node_or_null("BackgroundParallax"):
		var pbg := ParallaxBackground.new()
		pbg.name  = "BackgroundParallax"
		pbg.layer = -10
		# Lock vertical scroll completely — background must never jump when player jumps.
		# scroll_base_scale.y = 0 means camera y movement contributes 0 to all layer offsets.
		pbg.scroll_base_scale = Vector2(1.0, 0.0)
		add_child(pbg)
	# Ground tile (same logic as _apply_background)
	var ground_node := get_node_or_null("Ground")
	if ground_node and ground_node.get_node_or_null("GroundTile") == null \
			and ResourceLoader.exists(GROUND_TILE_PATH):
		var tile_tex: Texture2D = load(GROUND_TILE_PATH)
		var tile := Sprite2D.new()
		tile.name           = "GroundTile"
		tile.texture        = tile_tex
		tile.centered       = false
		tile.region_enabled = true
		var tile_h:  float = float(tile_tex.get_height())
		var target_h:float = 90.0   # taller ground strip; characters at z=6 render in front of tile (z=5)
		var s: float       = target_h / tile_h
		tile.scale         = Vector2(s, s)
		var world_w: float = 8200.0 / s
		tile.region_rect   = Rect2(0, 0, world_w, tile_h)
		tile.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tile.position      = Vector2(-4100.0, -target_h * 0.5)   # centre on ground surface
		tile.z_index       = 5
		ground_node.add_child(tile)
	if not get_node_or_null("Vignette"):
		var cl := CanvasLayer.new()
		cl.name  = "Vignette"
		cl.layer = 10
		var tex_rect := TextureRect.new()
		var grad := GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0,  Color(0.0, 0.0, 0.0, 0.0))
		g.set_offset(0, 0.0)
		g.set_color(1,  Color(0.0, 0.0, 0.0, 0.55))
		g.set_offset(1, 1.0)
		grad.gradient  = g
		grad.fill      = GradientTexture2D.FILL_RADIAL
		grad.fill_from = Vector2(0.5, 0.5)
		grad.fill_to   = Vector2(1.0, 0.5)
		grad.width     = 512
		grad.height    = 512
		tex_rect.texture      = grad
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(tex_rect)
		add_child(cl)

# ── Multi-layer parallax compositor ─────────────────────────────────────────

## Add sprite layers to the existing BackgroundParallax.
## Call after _apply_background() or _init_sprite_parallax().
##
## layers: Array[Dictionary] — ordered back → front. Each entry:
##   path   : String — res:// path to the PNG
##   scroll : float  — parallax motion_scale.x (alias: "scale")
##                     0.0 = fully static (sky)  ·  1.0 = scrolls with camera
##   y      : float  — screen-space Y offset in px (default 0, i.e. top of viewport)
##   tile   : bool   — true = tile horizontally (default); false = single copy
##   alpha  : float  — layer opacity 0–1 (default 1.0)
##
## Scale and display width are computed from the actual image dimensions, so any
## PNG size works — the image is always scaled to fill 270 px of viewport height.
##
## Any layer whose path doesn't exist yet is silently skipped — safe to call
## before all art files are present.
func _add_parallax_layers(layers: Array) -> void:
	var pbg: ParallaxBackground = get_node_or_null("BackgroundParallax")
	if pbg == null:
		return
	for entry: Dictionary in layers:
		var path: String = entry.get("path", "")
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		# Scale to viewport height (270 px) using the image's actual dimensions.
		# Works for any PNG resolution — no hardcoded canvas size needed.
		var S      := 270.0 / float(tex.get_height())
		var disp_w := float(tex.get_width()) * S
		var pl     := ParallaxLayer.new()
		var do_tile: bool = bool(entry.get("tile", true))
		# Accept both "scroll" (World.gd convention) and "scale" (Act1-5 convention)
		var scroll: float = float(entry.get("scroll", entry.get("scale", 0.2)))
		pl.motion_scale     = Vector2(scroll, 0.0)
		pl.motion_mirroring = Vector2(disp_w if do_tile else 0.0, 0.0)
		var spr := Sprite2D.new()
		spr.texture  = tex
		spr.centered = false
		spr.scale    = Vector2(S, S)
		spr.position = Vector2(0.0, float(entry.get("y", 0.0)))
		# alpha can be a float (opacity) or the string "white" → apply white-bg removal shader
		var remove_white: bool = bool(entry.get("remove_white", false))
		if remove_white:
			const WHITE_SHADER := "res://assets/shaders/white_bg_remove.gdshader"
			if ResourceLoader.exists(WHITE_SHADER):
				var wsh: Shader = load(WHITE_SHADER)
				var wmat := ShaderMaterial.new()
				wmat.shader = wsh
				spr.material = wmat
		else:
			var a_val = entry.get("alpha", 1.0)
			if (a_val is float or a_val is int) and float(a_val) < 1.0:
				spr.modulate = Color(1.0, 1.0, 1.0, float(a_val))
		pl.add_child(spr)
		pbg.add_child(pl)

# ── Utility ──────────────────────────────────────────────────────────────────

func _linspace(from: float, to: float, count: int) -> Array:
	var arr: Array = []
	if count <= 1:
		arr.append(from)
		return arr
	for i: int in range(count):
		arr.append(from + (to - from) * float(i) / float(count - 1))
	return arr
