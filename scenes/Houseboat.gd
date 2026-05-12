extends Node2D

## Houseboat — Bell of Bhadrakali sub-scene (Phase 5).
## A ghostly Kerala houseboat drifting on dark backwater.
## Player must find the Bell (Area2D) inside and bring it back to Sr. Devi.
## Entered via a warp from Act4 when quest is ACTIVE.
## Exiting: walk left off the boat → teleport back to Act4 entry point.

signal bell_retrieved

const BOAT_W     := 480.0
const BOAT_H     := 120.0
const WATER_COL  := Color(0.04, 0.08, 0.22, 1.0)
const HULL_COL   := Color(0.55, 0.48, 0.38, 1.0)
const PLANK_COL  := Color(0.42, 0.32, 0.18, 1.0)
const GHOST_COL  := Color(0.72, 0.82, 0.95, 0.55)

var _bell_found := false
var _player: Node2D = null

func _ready() -> void:
	_build_scene()
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.global_position = Vector2(60.0, 280.0)
		# Disable world gravity/movement — handled by houseboat platform
	_queue_hint_local("🔔 Find the temple bell...", 1.0, 4.0)

func _build_scene() -> void:
	# Sky/water background — CanvasLayer so camera scroll never reveals black void
	var sky_cl := CanvasLayer.new()
	sky_cl.layer = -10
	var bg := ColorRect.new()
	bg.color        = Color(0.02, 0.04, 0.12)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky_cl.add_child(bg)
	add_child(sky_cl)

	# Moon glow
	var moon := ColorRect.new()
	moon.color    = Color(0.9, 0.9, 0.75, 0.18)
	moon.size     = Vector2(80, 80)
	moon.position = Vector2(680, 30)
	add_child(moon)

	# Water
	var water := ColorRect.new()
	water.color    = WATER_COL
	water.size     = Vector2(820, 200)
	water.position = Vector2(0, 300)
	add_child(water)

	# Boat hull (StaticBody2D floor)
	var hull := StaticBody2D.new()
	hull.collision_layer = 1
	hull.collision_mask  = 0
	hull.position = Vector2(170.0, 310.0)
	var hcol := CollisionShape2D.new()
	var hshape := RectangleShape2D.new()
	hshape.size = Vector2(BOAT_W, 20.0)
	hcol.shape  = hshape
	hull.add_child(hcol)
	var hvis := ColorRect.new()
	hvis.color    = HULL_COL
	hvis.size     = Vector2(BOAT_W, 20.0)
	hvis.position = Vector2(-BOAT_W * 0.5, -10.0)
	hull.add_child(hvis)
	add_child(hull)

	# Boat deck planks (visual only)
	for i: int in 6:
		var plank := ColorRect.new()
		plank.color    = PLANK_COL
		plank.size     = Vector2(BOAT_W - 20.0, 6.0)
		plank.position = Vector2(175.0, 285.0 + i * 4.0)
		add_child(plank)

	# Cabin walls
	_build_cabin()

	# Bell
	_spawn_bell()

	# Ghostly guards (2 patrolling inside)
	_spawn_ghost_guards()

	# Exit trigger (left edge of boat)
	var exit := Area2D.new()
	exit.collision_layer = 0
	exit.collision_mask  = 2
	var ecol := CollisionShape2D.new()
	var eshape := RectangleShape2D.new()
	eshape.size = Vector2(30, 200)
	ecol.shape  = eshape
	exit.position = Vector2(30, 200)
	exit.add_child(ecol)
	exit.body_entered.connect(_on_exit_entered)
	add_child(exit)

	# Exit sign
	var exit_lbl := Label.new()
	exit_lbl.text     = "← Exit"
	exit_lbl.position = Vector2(8, 240)
	exit_lbl.add_theme_font_size_override("font_size", 13)
	exit_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	add_child(exit_lbl)

func _build_cabin() -> void:
	# Left wall
	var lw := StaticBody2D.new()
	lw.collision_layer = 1; lw.collision_mask = 0
	lw.position = Vector2(220, 240)
	var lwc := CollisionShape2D.new()
	var lws := RectangleShape2D.new()
	lws.size = Vector2(14, 80); lwc.shape = lws; lw.add_child(lwc)
	var lwv := ColorRect.new()
	lwv.color = HULL_COL; lwv.size = Vector2(14, 80)
	lwv.position = Vector2(-7, -40); lw.add_child(lwv)
	add_child(lw)

	# Right wall
	var rw := StaticBody2D.new()
	rw.collision_layer = 1; rw.collision_mask = 0
	rw.position = Vector2(580, 240)
	var rwc := CollisionShape2D.new()
	var rws := RectangleShape2D.new()
	rws.size = Vector2(14, 80); rwc.shape = rws; rw.add_child(rwc)
	var rwv := ColorRect.new()
	rwv.color = HULL_COL; rwv.size = Vector2(14, 80)
	rwv.position = Vector2(-7, -40); rw.add_child(rwv)
	add_child(rw)

	# Ceiling platform (interior)
	var ceiling_body := StaticBody2D.new()
	ceiling_body.collision_layer = 1; ceiling_body.collision_mask = 0
	ceiling_body.position = Vector2(400, 202)
	var cc := CollisionShape2D.new()
	var cs := RectangleShape2D.new()
	cs.size = Vector2(360, 14); cc.shape = cs; ceiling_body.add_child(cc)
	var cv := ColorRect.new()
	cv.color = PLANK_COL; cv.size = Vector2(360, 14)
	cv.position = Vector2(-180, -7); ceiling_body.add_child(cv)
	add_child(ceiling_body)

func _spawn_bell() -> void:
	var bell_area := Area2D.new()
	bell_area.collision_layer = 0
	bell_area.collision_mask  = 2
	bell_area.position = Vector2(400, 258)

	var bcol := CollisionShape2D.new()
	var bshape := CircleShape2D.new()
	bshape.radius = 20.0; bcol.shape = bshape
	bell_area.add_child(bcol)

	# Bell visual — golden circle
	var bvis := ColorRect.new()
	bvis.color    = Color(1.0, 0.85, 0.1, 1.0)
	bvis.size     = Vector2(24, 28)
	bvis.position = Vector2(-12, -14)
	bell_area.add_child(bvis)

	var blbl := Label.new()
	blbl.text     = "🔔"
	blbl.position = Vector2(-10, -28)
	blbl.add_theme_font_size_override("font_size", 18)
	bell_area.add_child(blbl)

	bell_area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player") and not _bell_found:
			_bell_found = true
			bell_area.queue_free()
			_on_bell_collected()
	)
	add_child(bell_area)

func _on_bell_collected() -> void:
	bell_retrieved.emit()
	_queue_hint_local("🔔 You have the bell! Get out!", 0.0, 4.0)
	GameManager.show_score_popup(Vector2(400, 220), 300, Color(1.0, 0.85, 0.1))
	GameManager.score += 300
	# Spawn 2 extra ghost guards to raise stakes
	_spawn_ghost_guards(true)

func _spawn_ghost_guards(extra: bool = false) -> void:
	var xs := [280.0, 500.0] if not extra else [340.0, 460.0]
	for gx: float in xs:
		var g := _make_ghost_guard(gx)
		add_child(g)

func _make_ghost_guard(start_x: float) -> Node2D:
	var ghost := CharacterBody2D.new()
	ghost.collision_layer = 4
	ghost.collision_mask  = 1
	ghost.position = Vector2(start_x, 270)

	var gcol := CollisionShape2D.new()
	var gshape := CapsuleShape2D.new()
	gshape.radius = 14; gshape.height = 40; gcol.shape = gshape
	ghost.add_child(gcol)

	var gvis := ColorRect.new()
	gvis.color    = GHOST_COL
	gvis.size     = Vector2(24, 44)
	gvis.position = Vector2(-12, -44)
	ghost.add_child(gvis)

	var glbl := Label.new()
	glbl.text     = "👻"
	glbl.position = Vector2(-10, -52)
	glbl.add_theme_font_size_override("font_size", 14)
	ghost.add_child(glbl)

	# Simple patrol script via metadata
	ghost.set_meta("patrol_dir", 1)
	ghost.set_meta("patrol_left", start_x - 80.0)
	ghost.set_meta("patrol_right", start_x + 80.0)
	ghost.set_meta("hp", 2)
	ghost.add_to_group("enemies")

	# Script-less movement via _process won't work on plain CharacterBody2D
	# Use a lightweight script attached at runtime
	ghost.set_script(preload("res://scenes/HouseboatGhost.gd"))
	return ghost

func _on_exit_entered(body: Node) -> void:
	if not body.is_in_group("player"): return
	# Complete quest if bell was found
	if _bell_found:
		var qm := get_node_or_null("/root/QuestManager")
		if qm != null: qm.complete_quest("bell_of_bhadrakali")
		GameManager.has_resurrection = true   # Totem Revival reward
		_queue_hint_local("✝️ Totem Revival granted! Sr. Devi thanks you.", 0.0, 5.0)
	# Return to Act4
	SceneManager.go_to("res://scenes/Act4.tscn")

func _queue_hint_local(text: String, delay: float, duration: float) -> void:
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_hint"):
			hud.show_hint(text, duration)
	)
