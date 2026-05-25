extends Node2D

## Houseboat — Bell of Bhadrakali sub-scene (Phase 5).
## A ghostly Kerala houseboat drifting on dark backwater.
## Player must find the Bell (Area2D) inside and bring it back to Sr. Devi.
## Entered via a warp from Act4 when quest is ACTIVE.
## Exiting: walk left off the boat → teleport back to Act4 entry point.
##
## Layout fits the 480×270 internal viewport in a single screen:
##   Boat deck y≈205, cabin x=160–320, bell at centre x=240.

signal bell_retrieved

## ── Layout constants ────────────────────────────────────────────────────────
const BOAT_W     := 380.0   # hull width — fits 480px viewport with side margins
const DECK_Y     := 205.0   # top surface of hull (where the player walks)
const HULL_CY    := 215.0   # centre Y of hull StaticBody2D
const CAB_LEFT   := 160.0   # inner face of left cabin wall
const CAB_RIGHT  := 320.0   # inner face of right cabin wall
const CAB_CEIL_Y := 135.0   # underside of ceiling platform

## ── Colours ─────────────────────────────────────────────────────────────────
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
		_player.global_position = Vector2(70.0, DECK_Y - 20.0)

	# ── Static camera so standalone testing shows the whole boat ──────────────
	# When the player's Camera2D is present it takes over (higher priority).
	var cam := Camera2D.new()
	cam.position         = Vector2(240.0, 135.0)   # centre of 480×270 viewport
	cam.zoom             = Vector2(1.0, 1.0)
	cam.enabled          = true
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	add_child(cam)

	# ── Pause menu ────────────────────────────────────────────────────────────
	var pause_menu: CanvasLayer = preload("res://scenes/PauseMenu.tscn").instantiate()
	add_child(pause_menu)

	# ── Instructions (staggered so they don't overlap) ────────────────────────
	_queue_hint_local("🔔 Find the Bell of Bhadrakali — it's inside the cabin.", 0.8, 5.0)
	_queue_hint_local("👻 Guards deal 12 damage on contact — press [Z] to fight them.", 6.0, 5.5)
	_queue_hint_local("← Walk off the LEFT edge of the boat to escape.", 12.0, 5.0)

func _build_scene() -> void:
	# ── Sky / water CanvasLayer background ───────────────────────────────────
	var sky_cl := CanvasLayer.new()
	sky_cl.layer = -10
	var bg := ColorRect.new()
	bg.color        = Color(0.02, 0.04, 0.12)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky_cl.add_child(bg)
	add_child(sky_cl)

	# Moon glow — repositioned to stay inside viewport
	var moon := ColorRect.new()
	moon.color    = Color(0.9, 0.9, 0.75, 0.18)
	moon.size     = Vector2(70, 70)
	moon.position = Vector2(370, 18)
	add_child(moon)

	# Water — fills bottom of viewport
	var water := ColorRect.new()
	water.color    = WATER_COL
	water.size     = Vector2(480, 60)
	water.position = Vector2(0, 215)
	add_child(water)

	# ── Boat hull (StaticBody2D floor) ────────────────────────────────────────
	var hull := StaticBody2D.new()
	hull.collision_layer = 1
	hull.collision_mask  = 0
	hull.position = Vector2(240.0, HULL_CY)
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

	# Deck planks (visual only) — evenly spaced across hull width
	for i: int in 6:
		var plank := ColorRect.new()
		plank.color    = PLANK_COL
		plank.size     = Vector2(BOAT_W - 16.0, 5.0)
		plank.position = Vector2(240.0 - (BOAT_W - 16.0) * 0.5,
				DECK_Y - 20.0 + float(i) * 3.5)
		add_child(plank)

	# ── Cabin ─────────────────────────────────────────────────────────────────
	_build_cabin()

	# ── Bell ─────────────────────────────────────────────────────────────────
	_spawn_bell()

	# ── Ghost guards ──────────────────────────────────────────────────────────
	_spawn_ghost_guards()

	# ── Exit trigger (left edge of boat) ─────────────────────────────────────
	# 60 px wide so the player can't walk through without triggering
	var exit := Area2D.new()
	exit.collision_layer = 0
	exit.collision_mask  = 2
	var ecol := CollisionShape2D.new()
	var eshape := RectangleShape2D.new()
	eshape.size = Vector2(60, 270)
	ecol.shape  = eshape
	exit.position = Vector2(30, 135)
	exit.add_child(ecol)
	exit.body_entered.connect(_on_exit_entered)
	add_child(exit)

	# Exit sign — pulsing so the player can find it
	var exit_lbl := Label.new()
	exit_lbl.text     = "← EXIT"
	exit_lbl.position = Vector2(4, 192)
	exit_lbl.add_theme_font_size_override("font_size", 14)
	exit_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	add_child(exit_lbl)
	var sign_tw := create_tween().set_loops()
	sign_tw.tween_property(exit_lbl, "modulate:a", 0.4, 1.1)
	sign_tw.tween_property(exit_lbl, "modulate:a", 1.0, 1.1)

func _build_cabin() -> void:
	# Left wall
	var lw := StaticBody2D.new()
	lw.collision_layer = 1; lw.collision_mask = 0
	lw.position = Vector2(CAB_LEFT - 7.0, 175.0)
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
	rw.position = Vector2(CAB_RIGHT + 7.0, 175.0)
	var rwc := CollisionShape2D.new()
	var rws := RectangleShape2D.new()
	rws.size = Vector2(14, 80); rwc.shape = rws; rw.add_child(rwc)
	var rwv := ColorRect.new()
	rwv.color = HULL_COL; rwv.size = Vector2(14, 80)
	rwv.position = Vector2(-7, -40); rw.add_child(rwv)
	add_child(rw)

	# Ceiling
	var ceiling_body := StaticBody2D.new()
	ceiling_body.collision_layer = 1; ceiling_body.collision_mask = 0
	ceiling_body.position = Vector2(240.0, CAB_CEIL_Y)
	var cc := CollisionShape2D.new()
	var cs := RectangleShape2D.new()
	cs.size = Vector2(CAB_RIGHT - CAB_LEFT + 14.0, 14); cc.shape = cs
	ceiling_body.add_child(cc)
	var cv := ColorRect.new()
	cv.color    = PLANK_COL
	cv.size     = Vector2(CAB_RIGHT - CAB_LEFT + 14.0, 14)
	cv.position = Vector2(-(CAB_RIGHT - CAB_LEFT + 14.0) * 0.5, -7)
	ceiling_body.add_child(cv)
	add_child(ceiling_body)

func _spawn_bell() -> void:
	var bell_area := Area2D.new()
	bell_area.collision_layer = 0
	bell_area.collision_mask  = 2
	bell_area.position = Vector2(240.0, 175.0)   # centre of cabin

	var bcol := CollisionShape2D.new()
	var bshape := CircleShape2D.new()
	bshape.radius = 18.0; bcol.shape = bshape
	bell_area.add_child(bcol)

	var bvis := ColorRect.new()
	bvis.color    = Color(1.0, 0.85, 0.1, 1.0)
	bvis.size     = Vector2(22, 26)
	bvis.position = Vector2(-11, -13)
	bell_area.add_child(bvis)

	var blbl := Label.new()
	blbl.text     = "🔔"
	blbl.position = Vector2(-9, -26)
	blbl.add_theme_font_size_override("font_size", 16)
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
	GameManager.show_score_popup(Vector2(240, 160), 300, Color(1.0, 0.85, 0.1))
	GameManager.score += 300
	_spawn_ghost_guards(true)

func _spawn_ghost_guards(extra: bool = false) -> void:
	var xs := [195.0, 285.0] if not extra else [215.0, 265.0]
	for gx: float in xs:
		var g := _make_ghost_guard(gx)
		add_child(g)

func _make_ghost_guard(start_x: float) -> Node2D:
	var ghost := CharacterBody2D.new()
	ghost.collision_layer = 4
	ghost.collision_mask  = 1
	ghost.position = Vector2(start_x, 185.0)

	var gcol := CollisionShape2D.new()
	var gshape := CapsuleShape2D.new()
	gshape.radius = 12; gshape.height = 36; gcol.shape = gshape
	ghost.add_child(gcol)

	var gvis := ColorRect.new()
	gvis.color    = GHOST_COL
	gvis.size     = Vector2(22, 40)
	gvis.position = Vector2(-11, -40)
	ghost.add_child(gvis)

	var glbl := Label.new()
	glbl.text     = "👻"
	glbl.position = Vector2(-9, -48)
	glbl.add_theme_font_size_override("font_size", 13)
	ghost.add_child(glbl)

	ghost.set_meta("patrol_dir", 1)
	ghost.set_meta("patrol_left",  start_x - 50.0)
	ghost.set_meta("patrol_right", start_x + 50.0)
	ghost.set_meta("hp", 2)
	ghost.add_to_group("enemies")
	ghost.set_script(preload("res://scenes/HouseboatGhost.gd"))
	return ghost

func _on_exit_entered(body: Node) -> void:
	if not body.is_in_group("player"): return
	if _bell_found:
		var qm := get_node_or_null("/root/QuestManager")
		if qm != null: qm.complete_quest("bell_of_bhadrakali")
		GameManager.has_resurrection = true
	GameManager.warp_return_x = 1400.0
	SceneManager.go_to("res://scenes/Act4.tscn")

func _queue_hint_local(text: String, delay: float, duration: float) -> void:
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_hint"):
			hud.show_hint(text, duration)
	)
