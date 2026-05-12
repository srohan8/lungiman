extends Node2D

## ─── BaseAct ────────────────────────────────────────────────────────────────
## Shared scaffold inherited by Act1–Act5 and World.
## Each act sets _next_scene / _trigger_x in its own _ready().
##
## Provides: _linspace, _add_tree, _add_powerup, _add_platform,
##           _spawn_boat, _connect_player_to_hud, _get_player, _get_hud,
##           _queue_hint

const GROUND_Y := 375.0

var _act_triggered := false
var _next_scene    := ""
var _trigger_x     := 7800.0
var _unlocks_act   := 0     # set by each Act: completing this act unlocks _unlocks_act in LevelSelect

# ── Auto-transition ──────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if _act_triggered or _next_scene.is_empty():
		return
	var player := _get_player()
	if player and player.global_position.x >= _trigger_x:
		_act_triggered = true
		if _unlocks_act > 0:
			GameManager.unlock_act(_unlocks_act)
		SceneManager.go_to(_next_scene)

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

func _get_player() -> Node:
	return get_node_or_null("Player")

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

func _spawn_boat(parent: Node, x: float, water_y: float) -> void:
	var boat_w := 120.0
	var boat_h := 22.0
	var sb     := StaticBody2D.new()
	sb.name    = "Boat"
	sb.collision_layer = 1
	sb.collision_mask  = 0
	sb.position = Vector2(x, water_y - boat_h * 0.5)
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(boat_w, boat_h)
	col.shape  = shape
	sb.add_child(col)
	var hull      := ColorRect.new()
	hull.color    = Color(0.45, 0.30, 0.12, 1.0)
	hull.size     = Vector2(boat_w, boat_h)
	hull.position = Vector2(-boat_w * 0.5, -boat_h * 0.5)
	sb.add_child(hull)
	var stripe      := ColorRect.new()
	stripe.color    = Color(0.9, 0.9, 0.85, 1.0)
	stripe.size     = Vector2(boat_w, 4.0)
	stripe.position = Vector2(-boat_w * 0.5, -boat_h * 0.5)
	sb.add_child(stripe)
	parent.add_child(sb)

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
		const VIGN_PATH := "res://assets/vignette.png"
		if ResourceLoader.exists(VIGN_PATH):
			tex_rect.texture = load(VIGN_PATH)
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(tex_rect)
		add_child(cl)

# ── Utility ──────────────────────────────────────────────────────────────────

func _linspace(from: float, to: float, count: int) -> Array:
	var arr: Array = []
	if count <= 1:
		arr.append(from)
		return arr
	for i: int in range(count):
		arr.append(from + (to - from) * float(i) / float(count - 1))
	return arr
