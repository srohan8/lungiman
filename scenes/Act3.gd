extends "res://scenes/BaseAct.gd"

## Act III — "Odiyan's Hunt"
## Foggy hills. Only attack during Odiyan's 0.6s transform flash.
## Odiyan's Tracks mini-quest: find 4 hoof-prints → weakness_revealed on boss.

const NEXT_SCENE    := "res://scenes/Act4.tscn"
const ACT_TRIGGER_X := 7800.0

const ZONE_TREES   := 20
const ZONE_X_FROM  := 250.0
const ZONE_X_TO    := 7500.0
const ZONE_H       := 295.0   # crown y≈405 (GROUND_Y now 700, trunk longer)

# Hoof-print positions (Odiyan's Tracks quest)
const TRACK_XS     := [700.0, 1800.0, 3200.0, 4000.0]

var _tracks_found      := 0
var _odiyan_ref:       Node2D = null   # set when boss spawns
var _bull_chase_running: bool  = false  # prevents re-entry

func _get_hud() -> CanvasLayer:
	return get_tree().get_first_node_in_group("hud") as CanvasLayer

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 4
	_init_sprite_parallax(Color(0.12, 0.16, 0.26),   # Odiyan's Hunt deep blue-purple night
			"res://assets/backgrounds/bg_act3_trees.png")   # atmospheric blue-purple forest clearing
	# No parallax layers — bg_act3_props at alpha 0.50 was too opaque (muddy).
	# bg_act3_sky/clouds have characters, mountains has an animal. Single base is cleanest.
	_spawn_trees()
	_spawn_odiyan()
	_spawn_tracks()
	_spawn_powerups()
	_spawn_npcs()
	_spawn_props()
	_spawn_fog()
	_connect_player_to_hud()
	# Opening hint — atmospheric, not mechanical (mechanic is revealed by bull chase)
	_queue_hint("🌫️ Something stalks these hills...\nTalk to the elder.", 1.5, 5.0)

func _spawn_trees() -> void:
	var tint := Color(0.7, 0.7, 0.65, 1.0)   # foggy grey-green
	var xs   := _linspace(ZONE_X_FROM, ZONE_X_TO, ZONE_TREES)
	for i: int in xs.size():
		_add_tree($Trees, xs[i], ZONE_H, 0.03 * (1 if i % 2 == 0 else -1), tint)

func _spawn_odiyan() -> void:
	var boss: Node2D = preload("res://scenes/Odiyan.tscn").instantiate()
	boss.position = Vector2(4500.0, GROUND_Y)
	$Enemies.add_child(boss)
	_odiyan_ref = boss

## Spawn 4 hoof-print markers (Area2D + spirit smoke visual)
func _spawn_tracks() -> void:
	# Hoof print #2 sits on an elevated platform — teaches climbing to investigate
	_add_platform(1800.0, 455.0, 120.0)

	for i: int in TRACK_XS.size():
		var x: float = TRACK_XS[i]
		var y   := 455.0 if i == 1 else GROUND_Y - 10.0   # #2 is elevated (on platform)

		var marker := Area2D.new()
		marker.collision_layer = 0
		marker.collision_mask  = 2

		var col   := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 30.0
		col.shape    = shape
		marker.add_child(col)

		# Hoof-print sprite — dormant frame (left half of hoof_marker_sheet.png).
		# image 4800×3584, each frame 2400 wide; content bottom ≈95% → 1613px
		# below image centre; scale 0.018 → 29px below sprite → local y = −29.
		var sheet: Texture2D = preload("res://assets/sprites/hoof_marker_sheet.png")
		var dormant_atlas := AtlasTexture.new()
		dormant_atlas.atlas  = sheet
		dormant_atlas.region = Rect2(0, 0, 2400, 3584)
		var vis := Sprite2D.new()
		vis.name     = "HoofSprite"
		vis.texture  = dormant_atlas
		vis.scale    = Vector2(0.018, 0.018)
		vis.position = Vector2(0.0, -29.0)
		var mat := _get_prop_mat()
		if mat != null: vis.material = mat
		marker.add_child(vis)

		marker.position = Vector2(x, y)

		# Each marker tracks its index so we can show different flashes
		var idx := i
		marker.body_entered.connect(func(body: Node) -> void:
			_on_track_entered(body, marker, idx)
		)
		add_child(marker)

func _on_track_entered(body: Node, marker: Node2D, idx: int) -> void:
	if not body.is_in_group("player"):
		return
	if not Input.is_action_pressed("sword"):
		return   # must press Z near the smoke to "read" it
	_tracks_found += 1
	# Swap to the "discovered" frame (right half of sheet) then fade out
	var spr: Sprite2D = marker.get_node_or_null("HoofSprite") as Sprite2D
	if spr != null:
		var sheet: Texture2D = preload("res://assets/sprites/hoof_marker_sheet.png")
		var disc := AtlasTexture.new()
		disc.atlas  = sheet
		disc.region = Rect2(2400, 0, 2400, 3584)
		spr.texture = disc
		# Disable collision immediately so re-triggering is impossible
		(marker as Area2D).monitoring = false
		var tw := marker.create_tween()
		tw.tween_interval(0.30)
		tw.tween_property(spr, "modulate:a", 0.0, 0.45)
		tw.tween_callback(marker.queue_free)
	else:
		marker.queue_free()
	var qm := get_node_or_null("/root/QuestManager")
	if qm != null: qm.advance_quest("odiyan_tracks")
	# Flash HUD message per track found
	var hud := _get_hud()
	if hud and hud.has_method("show_hint"):
		hud.show_hint("🐾 Track %d/4 found!" % _tracks_found, 2.5)
	# Track #3 (idx 2) — Odiyan lunges in dog form then flees: a terrifying preview
	if idx == 2 and is_instance_valid(_odiyan_ref) and _odiyan_ref.has_method("lunge_tease"):
		var target_pos: Vector2 = (body as Node2D).global_position   # capture value
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if is_instance_valid(_odiyan_ref): _odiyan_ref.lunge_tease(target_pos)
		)
		# Show "something moved" after the track-found hint expires
		get_tree().create_timer(2.9).timeout.connect(func() -> void:
			var h := _get_hud()
			if h: h.show_hint("🐕 Something lunged from the fog and retreated...", 3.5)
		)
	# All 4 found — trigger bull chase cinematic, then reveal Odiyan's weakness
	if _tracks_found >= TRACK_XS.size():
		_begin_bull_chase()   # async — runs in background; calls reveal_weakness at the end

func _spawn_powerups() -> void:
	var data := [
		[ 700.0, GROUND_Y, "heart"],
		[2200.0, GROUND_Y, "nut"],
		[3800.0, GROUND_Y, "toddy"],
		[5500.0, GROUND_Y, "nut"],
		[7000.0, GROUND_Y, "heart"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(200.0, GROUND_Y)
	add_child(thoma)
	var basheer: Node2D = preload("res://scenes/UstadBasheer.tscn").instantiate()
	basheer.position = Vector2(400.0, GROUND_Y)
	add_child(basheer)
	# Kili the Spirit Crow at x=1400 shrine
	var kili: Node2D = preload("res://scenes/KiliCrow.tscn").instantiate()
	kili.position = Vector2(1400.0, GROUND_Y - 10.0)
	add_child(kili)
	# 3 porotta powerups near Kili so player can feed her
	_add_powerup($PowerUps, 1500.0, GROUND_Y, "porotta")
	_add_powerup($PowerUps, 1600.0, GROUND_Y, "porotta")
	_add_powerup($PowerUps, 1700.0, GROUND_Y, "porotta")

func _spawn_props() -> void:
	_build_crossroads_stone(400.0)   # marker where Basheer stands
	_build_shrine(1400.0)            # Kili's spirit shrine

## Stone crossroads marker — an ancient standing stone
func _build_crossroads_stone(x: float) -> void:
	var stone := ColorRect.new()
	stone.size     = Vector2(16.0, 50.0)
	stone.position = Vector2(x + 30.0, GROUND_Y - 50.0)
	stone.color    = Color(0.38, 0.36, 0.40, 1.0)
	stone.z_index  = 1
	add_child(stone)
	# Carving mark — a faint amber symbol
	var mark := ColorRect.new()
	mark.size     = Vector2(8.0, 6.0)
	mark.position = Vector2(x + 34.0, GROUND_Y - 38.0)
	mark.color    = Color(0.85, 0.60, 0.10, 0.55)
	mark.z_index  = 2
	add_child(mark)

## Kili's forest shrine — Scenario.gg sprite (shrine_sheet.png).
## image 4800×3584; scale 0.030 → content bottom 48px below sprite centre.
func _build_shrine(x: float) -> void:
	_prop_sprite("res://assets/sprites/shrine_sheet.png",
			x, GROUND_Y - 48.0, 0.030, 1)

# ─────────────────────────────────────────────────────────────────────────────
## BULL CHASE CINEMATIC — fires when all 4 hoof-prints are found.
## Camera pulls behind the player ("over-the-shoulder"), Odiyan charges as a
## massive bull silhouette, single Jump/Roll vault window, then snap back.
## Duration ~3 seconds total.  Emotional register: TERROR.
# ─────────────────────────────────────────────────────────────────────────────

func _begin_bull_chase() -> void:
	if _bull_chase_running: return
	_bull_chase_running = true

	var player := _get_player()
	if not is_instance_valid(player):
		_finish_bull_chase(false); return

	# ── Step 1: Freeze player; pull camera behind shoulder (0.42s) ───────────
	player.set_physics_process(false)
	player.set_process(false)
	player.velocity = Vector2.ZERO

	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(cam, "offset:x", -90.0, 0.42)
		await tw.finished
	else:
		await get_tree().create_timer(0.42).timeout

	# ── Step 2: Odiyan bull silhouette charges toward camera ─────────────────
	# (CanvasLayer so it renders over the world, screen-space coords)
	var cl := CanvasLayer.new()
	cl.layer = 12
	add_child(cl)

	# Bull body — starts tiny (far away) and scales up (charging at us)
	var bull := ColorRect.new()
	bull.size         = Vector2(44.0, 34.0)
	bull.color        = Color(0.12, 0.05, 0.03, 0.93)
	bull.position     = Vector2(218.0, 118.0)   # centre of 480×270 viewport
	bull.pivot_offset = Vector2(22.0, 17.0)
	bull.scale        = Vector2(0.18, 0.18)
	cl.add_child(bull)

	# Glowing red eyes (paired, symmetric)
	for ex: float in [-6.0, 6.0]:
		var eye := ColorRect.new()
		eye.size         = Vector2(4.0, 4.0)
		eye.color        = Color(1.0, 0.08, 0.03, 1.0)
		eye.position     = Vector2(222.0 + ex - 2.0, 122.0)
		eye.pivot_offset = Vector2(2.0, 2.0)
		eye.scale        = Vector2(0.18, 0.18)
		cl.add_child(eye)
		create_tween().tween_property(eye, "scale", Vector2(3.4, 3.4), 1.5).set_trans(Tween.TRANS_EXPO)

	create_tween().tween_property(bull, "scale", Vector2(4.2, 3.6), 1.5).set_trans(Tween.TRANS_EXPO)

	# Rumble builds as bull closes distance — timers unrolled to avoid closure-capture bug
	if player.has_method("add_trauma"):
		player.add_trauma(0.50)
	get_tree().create_timer(0.30).timeout.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("add_trauma"):
			player.add_trauma(0.30)
	)
	get_tree().create_timer(0.60).timeout.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("add_trauma"):
			player.add_trauma(0.42)
	)
	get_tree().create_timer(0.90).timeout.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("add_trauma"):
			player.add_trauma(0.54)
	)

	# ── Step 3: Input window — VAULT! (1.1 s) ────────────────────────────────
	await get_tree().create_timer(0.55).timeout
	var hud := _get_hud()
	if hud: hud.show_hint("⚡ VAULT — JUMP OR ROLL!", 1.2)

	var vaulted := false
	for _f: int in 66:   # ~1.1 s at 60 fps
		await get_tree().process_frame
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("roll"):
			vaulted = true
			if hud: hud.show_hint("✅ Clean vault!", 1.5)
			break

	# ── Step 4: Impact — black flash as bull hits ─────────────────────────────
	if player.has_method("add_trauma"):
		player.add_trauma(0.85)
	var flash := ColorRect.new()
	flash.color    = Color(0.0, 0.0, 0.0, 0.0)
	flash.size     = Vector2(480.0, 270.0)
	flash.position = Vector2.ZERO
	cl.add_child(flash)
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 0.82, 0.07)
	ft.tween_property(flash, "color:a", 0.00, 0.38)

	await get_tree().create_timer(0.52).timeout
	cl.queue_free()

	# ── Step 5: Camera snaps back to side-scroll view ────────────────────────
	if is_instance_valid(cam):
		var back_tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		back_tw.tween_property(cam, "offset:x", 0.0, 0.28)
		await back_tw.finished

	_finish_bull_chase(vaulted)

func _finish_bull_chase(vaulted: bool) -> void:
	# Re-enable the player
	var player := _get_player()
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.set_process(true)
	# Reveal Odiyan's vulnerability window (2.5s → 3.5s)
	if is_instance_valid(_odiyan_ref) and _odiyan_ref.has_method("reveal_weakness"):
		_odiyan_ref.reveal_weakness()
	var hud := _get_hud()
	if hud:
		var vault_line := "💡 Odiyan's weakness revealed — attack window EXTENDED!" if vaulted \
				else "💡 Odiyan's weakness revealed! Attack window extended!"
		hud.show_hint(vault_line, 4.5)
	# NOW tell the player HOW to fight — earned after the reveal, not spoiled at scene start
	_queue_hint("⚡ Attack Odiyan ONLY during the transform flash!", 5.5, 6.0)

## Atmospheric fog overlay — dark vignette that deepens as player moves right.
func _spawn_fog() -> void:
	var fog := ColorRect.new()
	fog.color    = Color(0.03, 0.06, 0.04, 0.0)
	fog.z_index  = 10
	# Fill the entire viewport using CanvasLayer would be ideal but
	# a wide world-space rect covers the visible area effectively
	fog.size     = Vector2(8200.0, 460.0)
	fog.position = Vector2(0.0, 0.0)
	add_child(fog)
	# Tween fog darker as a one-shot at mid-level
	get_tree().create_timer(15.0).timeout.connect(func() -> void:
		var tw := create_tween()
		tw.tween_property(fog, "color", Color(0.0, 0.02, 0.01, 0.45), 12.0)
	)
