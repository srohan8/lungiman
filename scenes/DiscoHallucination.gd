extends Node2D

## DiscoHallucination — Scene 12.
## Triggers after Odiyan's venom bite. 6-phase hallucination sequence.
## Phase 1: Collapse       (~8s,  non-interactive)
## Phase 2: Disorientation (~10s, non-interactive)
## Phase 3: Dance minigame (~75s, DDR-style, 20 prompts)
## Phase 4: The Turn       (~5s,  non-interactive)
## Phase 5: Fight phase    (~90s, Clarity drain, unavoidable collapse)
## Phase 6: Wake-up        (~15s, non-interactive → loads Act4)

const NEXT_SCENE        := "res://scenes/Act4.tscn"
const _DancePromptScript := preload("res://scenes/DancePrompt.gd")

# ── Dance sequence (20 prompts, builds speed from #12 onward) ────────────────
const DANCE_SEQ := [
	"right","right","left","jump","right","left","up",
	"right","down","right","right","jump","left","right",
	"up","down","right","left","jump","up"
]
const BEAT_INTERVAL_SLOW := 0.90   # prompts 1–11
const BEAT_INTERVAL_FAST := 0.60   # prompts 12–20

# ── Fight phase ────────────────────────────────────────────────────────────────
const CLARITY_START   := 100.0
const CLARITY_DRAIN   := 8.0    # per second
const CLARITY_PER_KILL := 3.0
const ENEMY_SPAWN_INTERVAL := 5.0
const MAX_ENEMIES := 6

# ── Screen dimensions (480×270 viewport — matches project.godot) ─────────────
const VP_W := 480.0
const VP_H := 270.0

# ── State ──────────────────────────────────────────────────────────────────────
var _clarity:         float = CLARITY_START
var _disco_score:     int   = 0
var _misses_in_row:   int   = 0
var _phase5_active:   bool  = false
var _enemy_timer:     float = 0.0
var _enemies:         Array = []

# Node refs built in _build_scene()
var _chroma_layer:    CanvasLayer = null
var _chroma_rect:     ColorRect   = null
var _clarity_bar:     ColorRect   = null
var _clarity_label:   Label       = null
var _hint_label:      Label       = null
var _dance_prompt_layer: Node2D   = null
var _disco_ball:      Node2D      = null
var _floor_tiles:     Array       = []

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_scene()
	_run_sequence()

func _process(delta: float) -> void:
	if _phase5_active:
		# Drain clarity
		_clarity = maxf(0.0, _clarity - CLARITY_DRAIN * delta)
		_update_clarity_bar()
		# Spin disco ball
		if is_instance_valid(_disco_ball):
			_disco_ball.rotation += delta * 1.2
		# Spawn enemies
		_enemy_timer -= delta
		if _enemy_timer <= 0.0 and _enemies.size() < MAX_ENEMIES:
			_enemy_timer = ENEMY_SPAWN_INTERVAL
			_spawn_disco_enemy()
		# Clarity collapsed → phase 5 ends (handled in _run_fight_phase via poll)

# ─────────────────────────────────────────────────────────────────────────────
## SCENE CONSTRUCTION
# ─────────────────────────────────────────────────────────────────────────────

func _build_scene() -> void:
	# Black floor background
	var bg := ColorRect.new()
	bg.color    = Color(0.02, 0.01, 0.04)
	bg.size     = Vector2(VP_W, VP_H)
	bg.position = Vector2.ZERO
	add_child(bg)

	# Disco floor tiles (5×3 grid of coloured squares)
	var tile_colors := [
		Color(0.8, 0.1, 0.6), Color(0.1, 0.6, 0.9), Color(0.9, 0.8, 0.1),
		Color(0.1, 0.9, 0.4), Color(0.8, 0.3, 0.1),
	]
	var tile_w := VP_W / 5.0
	var tile_h := 90.0
	for col: int in 5:
		for row: int in 3:
			var tile := ColorRect.new()
			var ci   := (col + row) % tile_colors.size()
			tile.color    = Color(tile_colors[ci].r, tile_colors[ci].g, tile_colors[ci].b, 0.18)
			tile.size     = Vector2(tile_w - 2.0, tile_h - 2.0)
			tile.position = Vector2(col * tile_w + 1.0, VP_H - tile_h * (row + 1) + 1.0)
			add_child(tile)
			_floor_tiles.append(tile)

	# Disco ball (top-centre)
	_disco_ball = Node2D.new()
	_disco_ball.position = Vector2(VP_W * 0.5, 28.0)
	add_child(_disco_ball)
	var ball_body := ColorRect.new()
	ball_body.size         = Vector2(28.0, 28.0)
	ball_body.color        = Color(0.85, 0.85, 0.85)
	ball_body.pivot_offset = Vector2(14.0, 14.0)
	ball_body.position     = Vector2(-14.0, -14.0)
	_disco_ball.add_child(ball_body)
	# Mirror facets on ball
	for i: int in 8:
		var facet := ColorRect.new()
		var angle := i * TAU / 8.0
		facet.size     = Vector2(5.0, 5.0)
		facet.color    = Color.WHITE
		facet.position = Vector2(cos(angle) * 12.0 - 2.5, sin(angle) * 12.0 - 2.5)
		_disco_ball.add_child(facet)

	# Crowd NPCs — 7 dancers spread evenly across the full viewport width
	for i: int in 7:
		_spawn_npc_dancer(
				Vector2(VP_W * (float(i) + 0.5) / 7.0, VP_H - 80.0),
				Color(randf_range(0.4,1.0), randf_range(0.2,0.7), randf_range(0.5,1.0)))

	# Dance prompt layer (prompts fall through this node)
	_dance_prompt_layer = Node2D.new()
	_dance_prompt_layer.position = Vector2(VP_W * 0.5, 0.0)
	add_child(_dance_prompt_layer)

	# Target line
	var target_line := ColorRect.new()
	target_line.color    = Color(0.9, 0.8, 0.1, 0.65)
	target_line.size     = Vector2(VP_W, 3.0)
	target_line.position = Vector2(0.0, _DancePromptScript.TARGET_Y)   # must match DancePrompt.TARGET_Y
	add_child(target_line)

	# Hint label (centre screen)
	_hint_label = Label.new()
	_hint_label.text                = ""
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color.WHITE)
	_hint_label.position            = Vector2(VP_W * 0.5 - 200.0, VP_H * 0.5 - 16.0)
	_hint_label.size                = Vector2(400.0, 32.0)
	add_child(_hint_label)

	# Clarity bar (fight phase — hidden until phase 5)
	var bar_bg := ColorRect.new()
	bar_bg.color    = Color(0.12, 0.06, 0.06)
	bar_bg.size     = Vector2(260.0, 18.0)
	bar_bg.position = Vector2(VP_W * 0.5 - 130.0, 12.0)
	bar_bg.visible  = false
	add_child(bar_bg)
	_clarity_bar = ColorRect.new()
	_clarity_bar.color    = Color(0.2, 0.9, 0.5)
	_clarity_bar.size     = Vector2(260.0, 18.0)
	_clarity_bar.position = Vector2(VP_W * 0.5 - 130.0, 12.0)
	_clarity_bar.visible  = false
	add_child(_clarity_bar)
	_clarity_label = Label.new()
	_clarity_label.text     = "CLARITY"
	_clarity_label.add_theme_font_size_override("font_size", 12)
	_clarity_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_clarity_label.position = Vector2(VP_W * 0.5 - 28.0, 13.0)
	_clarity_label.visible  = false
	add_child(_clarity_label)
	# Store bar_bg ref via meta so phase 5 can show it
	set_meta("clarity_bar_bg", bar_bg)

	# Chromatic aberration overlay (hidden until phase 4)
	_chroma_layer = CanvasLayer.new()
	_chroma_layer.layer = 15
	add_child(_chroma_layer)
	_chroma_rect = ColorRect.new()
	_chroma_rect.color   = Color(1, 1, 1, 1)
	_chroma_rect.visible = false
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/chromatic_aberration.gdshader") as Shader
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("aberration", 0.006)
		_chroma_rect.material = mat
	_chroma_layer.add_child(_chroma_rect)
	# PRESET_FULL_RECT must be called after add_child so the CanvasLayer parent is set
	_chroma_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _spawn_npc_dancer(pos: Vector2, col: Color) -> Node2D:
	var npc := Node2D.new()
	npc.position = pos
	# Body
	var body := ColorRect.new()
	body.color    = col
	body.size     = Vector2(20.0, 44.0)
	body.position = Vector2(-10.0, -44.0)
	npc.add_child(body)
	# Head
	var head := ColorRect.new()
	head.color    = col.lightened(0.3)
	head.size     = Vector2(16.0, 16.0)
	head.position = Vector2(-8.0, -62.0)
	npc.add_child(head)
	add_child(npc)
	# Loop dance tween
	var tw := npc.create_tween().set_loops()
	tw.tween_property(npc, "position:y", pos.y - 12.0, 0.38).set_trans(Tween.TRANS_SINE)
	tw.tween_property(npc, "position:y", pos.y,        0.38).set_trans(Tween.TRANS_SINE)
	return npc

# ─────────────────────────────────────────────────────────────────────────────
## MAIN SEQUENCE (async chain)
# ─────────────────────────────────────────────────────────────────────────────

func _run_sequence() -> void:
	await _phase1_collapse()
	await _phase2_disorientation()
	await _phase3_dance()
	await _phase4_turn()
	await _phase5_fight()
	await _phase6_wakeup()

# ── PHASE 1 — Collapse ────────────────────────────────────────────────────────

func _phase1_collapse() -> void:
	# Scene starts already in disco (cut from Odiyan fight via SceneManager.go_to)
	# Show "Something feels wrong" fade-in from black
	var black := ColorRect.new()
	black.color    = Color(0.0, 0.0, 0.0, 1.0)
	black.size     = Vector2(VP_W, VP_H)
	black.position = Vector2.ZERO
	black.z_index  = 50
	add_child(black)

	await get_tree().create_timer(0.3).timeout
	_show_hint("\"Something feels... wrong...\"")

	# Fade black out to reveal the disco
	var tw := create_tween()
	tw.tween_property(black, "color:a", 0.0, 1.8)
	await tw.finished
	black.queue_free()
	_show_hint("")

	# Screen tilts briefly
	var tilt_tw := create_tween().set_trans(Tween.TRANS_SINE)
	tilt_tw.tween_property(self, "rotation_degrees", 4.0, 0.6)
	tilt_tw.tween_property(self, "rotation_degrees", 0.0, 0.4)
	await tilt_tw.finished

	await get_tree().create_timer(1.0).timeout

	# Bass drop — flood of neon light
	_flash_neon(Color(1.0, 0.1, 0.8), 0.3)
	await get_tree().create_timer(1.2).timeout

func _flash_neon(col: Color, dur: float) -> void:
	var fl := ColorRect.new()
	fl.color    = Color(col.r, col.g, col.b, 0.0)
	fl.size     = Vector2(VP_W, VP_H)
	fl.z_index  = 40
	add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 0.55, dur * 0.3)
	tw.tween_property(fl, "color:a", 0.0,  dur * 0.7)
	tw.tween_callback(fl.queue_free)

# ── PHASE 2 — Disorientation ─────────────────────────────────────────────────

func _phase2_disorientation() -> void:
	_show_hint("\"Where... what is this place?\"")
	await get_tree().create_timer(3.0).timeout
	_show_hint("\"DANCE, machane! Follow the steps!\"")
	await get_tree().create_timer(2.5).timeout
	# Tile floor pulses to life
	for tile: ColorRect in _floor_tiles:
		var tw := create_tween()
		tw.tween_property(tile, "modulate:a", 0.85, randf_range(0.2, 0.6))
		tw.tween_property(tile, "modulate:a", 0.18, randf_range(0.3, 0.7))
		tw.set_loops()
	_show_hint("FOLLOW THE ARROWS! Press the key when it hits the line.")
	await get_tree().create_timer(3.0).timeout
	_show_hint("")

# ── PHASE 3 — Dance minigame ─────────────────────────────────────────────────

func _phase3_dance() -> void:
	# Show direction legend at bottom
	var legend := Label.new()
	legend.text     = "A=← D=→ W=↑ S=↓ SPACE=⬆"
	legend.add_theme_font_size_override("font_size", 13)
	legend.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
	legend.position = Vector2(VP_W * 0.5 - 170.0, VP_H - 22.0)
	add_child(legend)

	for seq_idx: int in DANCE_SEQ.size():
		var dir: String = DANCE_SEQ[seq_idx]
		var interval := BEAT_INTERVAL_SLOW if seq_idx < 12 else BEAT_INTERVAL_FAST

		# Spawn prompt
		var prompt := _spawn_prompt(dir)

		# Wait for fall + slight window either side
		await get_tree().create_timer(_DancePromptScript.FALL_DUR).timeout

		# Evaluate: check if matching key is pressed at target time
		var quality := "miss"
		var check_window := 0.35
		var t := 0.0
		while t < check_window:
			await get_tree().process_frame
			t += get_process_delta_time()
			if _direction_just_pressed(dir):
				var arrival_delta := t - 0.0   # 0 = perfect; window from centre
				prompt.evaluate(arrival_delta - check_window * 0.5)
				quality = _last_quality_from_prompt(prompt)
				break

		if not prompt.is_queued_for_deletion():
			prompt._resolve("miss")

		_apply_dance_result(quality, seq_idx)

		# Gap between prompts (minus fall time already waited)
		var gap := maxf(0.0, interval - _DancePromptScript.FALL_DUR * 0.1)
		await get_tree().create_timer(gap).timeout

	legend.queue_free()
	# Final flourish
	_show_hint("✨ Crowd goes wild!")
	_flash_neon(Color(1.0, 0.85, 0.1), 1.0)
	await get_tree().create_timer(2.5).timeout
	_show_hint("")

func _spawn_prompt(dir: String) -> Node2D:
	var prompt: Node2D = _DancePromptScript.new()
	prompt.set("direction", dir)
	_dance_prompt_layer.add_child(prompt)
	return prompt

func _direction_just_pressed(dir: String) -> bool:
	match dir:
		"left":  return Input.is_action_just_pressed("ui_left")  or Input.is_action_just_pressed("move_left")
		"right": return Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right")
		"up":    return Input.is_action_just_pressed("ui_up")    or Input.is_action_just_pressed("move_up")
		"down":  return Input.is_action_just_pressed("ui_down")  or Input.is_action_just_pressed("move_down")
		"jump":  return Input.is_action_just_pressed("jump")     or Input.is_action_just_pressed("ui_accept")
	return false

func _last_quality_from_prompt(prompt: Node2D) -> String:
	# The prompt emitted resolved() signal before we call this — quality stored via closure
	# For simplicity: if prompt is freed = resolved; otherwise miss
	if not is_instance_valid(prompt): return "miss"
	return "ok"

func _apply_dance_result(quality: String, idx: int) -> void:
	match quality:
		"perfect":
			_disco_score += 30
			_show_hint("PERFECT! ✨", 0.6)
			_misses_in_row = 0
		"good":
			_disco_score += 15
			_show_hint("GOOD!", 0.5)
			_misses_in_row = 0
		"ok":
			_disco_score += 5
			_show_hint("OK...", 0.4)
			_misses_in_row = 0
		"miss":
			_show_hint("MISS!", 0.5)
			_misses_in_row += 1
			if _misses_in_row >= 3:
				_show_hint("\"Relax, machane.\"", 1.5)
				_misses_in_row = 0
	GameManager.disco_score = _disco_score

# ── PHASE 4 — The Turn ────────────────────────────────────────────────────────

func _phase4_turn() -> void:
	# Music pitch drops (simulated with visual cue — audio handled by AudioManager later)
	_show_hint("")

	# Floor tiles shift to red
	for tile: ColorRect in _floor_tiles:
		var tw := create_tween()
		tw.tween_property(tile, "color", Color(0.6, 0.04, 0.04, 0.35), 1.2)

	# All NPC eyes glow red — add red eye dots to all children
	for child in get_children():
		if child is Node2D and not child is Label and not child is ColorRect:
			if child.get_child_count() >= 2:
				for eye_x: float in [-4.0, 4.0]:
					var eye := ColorRect.new()
					eye.color    = Color(1.0, 0.05, 0.05)
					eye.size     = Vector2(4.0, 4.0)
					eye.position = Vector2(eye_x - 2.0, -56.0)
					child.add_child(eye)
	await get_tree().create_timer(1.5).timeout

	# Crowd turns to face hero — stop dance tweens, pause briefly
	_show_hint("")
	await get_tree().create_timer(0.8).timeout

	# Chromatic aberration ON
	_chroma_rect.visible = true

	# Red vignette pulse begins
	var vignette := ColorRect.new()
	vignette.color    = Color(0.5, 0.0, 0.0, 0.0)
	vignette.size     = Vector2(VP_W, VP_H)
	vignette.z_index  = 8
	add_child(vignette)
	set_meta("vignette", vignette)
	var vt := create_tween().set_loops()
	vt.tween_property(vignette, "color:a", 0.30, 0.5)
	vt.tween_property(vignette, "color:a", 0.06, 0.5)

	_show_hint("\"No no no no no—\"")
	await get_tree().create_timer(1.2).timeout

	# Flash — they lunge
	_flash_neon(Color(1.0, 0.0, 0.0), 0.4)
	_show_hint("FIGHT YOUR WAY OUT!", 2.0)
	await get_tree().create_timer(0.8).timeout

# ── PHASE 5 — Fight phase ─────────────────────────────────────────────────────

func _phase5_fight() -> void:
	# Show clarity bar
	var bar_bg: ColorRect = get_meta("clarity_bar_bg") as ColorRect
	if bar_bg: bar_bg.visible = true
	_clarity_bar.visible   = true
	_clarity_label.visible = true
	_clarity            = CLARITY_START
	_phase5_active      = true
	_enemy_timer        = 1.0   # first enemy quickly

	# Poll until clarity reaches 0
	while _clarity > 0.0:
		await get_tree().process_frame

	_phase5_active = false

	# Scripted collapse
	_show_hint("\"I... can't...\"")
	var col_tw := create_tween()
	col_tw.tween_property(self, "modulate", Color(1,1,1,0.4), 0.6)
	await get_tree().create_timer(0.7).timeout

	# Screen to extreme white bloom
	var bloom := ColorRect.new()
	bloom.color    = Color(1.0, 1.0, 1.0, 0.0)
	bloom.size     = Vector2(VP_W, VP_H)
	bloom.z_index  = 60
	add_child(bloom)
	var bt := create_tween()
	bt.tween_property(bloom, "color:a", 1.0, 0.5)
	await bt.finished
	await get_tree().create_timer(0.4).timeout

func _update_clarity_bar() -> void:
	if not is_instance_valid(_clarity_bar): return
	_clarity_bar.size.x = 260.0 * (_clarity / CLARITY_START)
	var r := 1.0 - (_clarity / CLARITY_START)
	_clarity_bar.color = Color(0.2 + r * 0.7, 0.9 - r * 0.8, 0.2 + r * 0.1)

func _spawn_disco_enemy() -> void:
	var enemy := CharacterBody2D.new()
	enemy.collision_layer = 4
	enemy.collision_mask  = 1

	# Random side spawn
	var side := 1 if randf() > 0.5 else -1
	enemy.position = Vector2(VP_W * 0.5 + side * 340.0, VP_H - 100.0)

	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CapsuleShape2D = CapsuleShape2D.new()
	shape.radius = 14; shape.height = 44
	col.shape = shape
	enemy.add_child(col)

	# Disco-coloured body
	var body := ColorRect.new()
	var ec   := Color(randf_range(0.5,1.0), randf_range(0.1,0.5), randf_range(0.6,1.0))
	body.color    = ec
	body.size     = Vector2(22.0, 44.0)
	body.position = Vector2(-11.0, -44.0)
	enemy.add_child(body)
	# Red eyes
	for ex: float in [-4.0, 4.0]:
		var eye := ColorRect.new()
		eye.color    = Color(1.0, 0.05, 0.05)
		eye.size     = Vector2(4.0, 4.0)
		eye.position = Vector2(ex - 2.0, -40.0)
		enemy.add_child(eye)

	enemy.add_to_group("disco_enemies")
	enemy.set_meta("hp", 2)
	enemy.set_meta("speed", randf_range(55.0, 90.0))
	add_child(enemy)
	_enemies.append(enemy)

	# Simple move-toward-centre each frame
	var move_script := GDScript.new()
	move_script.source_code = """
extends CharacterBody2D
func _physics_process(delta):
	var target_x = get_viewport_rect().size.x * 0.5
	var dir = sign(target_x - global_position.x)
	velocity.x = get_meta("speed", 70.0) * dir
	velocity.y += 1800.0 * delta
	move_and_slide()
"""
	enemy.set_script(move_script)

# ── PHASE 6 — Wake-up ─────────────────────────────────────────────────────────

func _phase6_wakeup() -> void:
	# Silence — fade to white, then fade to real world
	_chroma_rect.visible   = false
	_phase5_active = false

	# Clear enemies
	for e in _enemies:
		if is_instance_valid(e): e.queue_free()
	_enemies.clear()

	await get_tree().create_timer(0.6).timeout

	# Fade to dark
	var fade := ColorRect.new()
	fade.color    = Color(0.0, 0.0, 0.0, 0.0)
	fade.size     = Vector2(VP_W, VP_H)
	fade.z_index  = 70
	add_child(fade)
	var fade_tw := create_tween()
	fade_tw.tween_property(fade, "color:a", 1.0, 1.2)
	await fade_tw.finished

	# Wake-up dialogue
	_show_hint("Ravi: \"Machane! You were out for almost an hour...\"")
	await get_tree().create_timer(2.8).timeout
	_show_hint("Ravi: \"...Kept shouting 'left! right! left!'\"")
	await get_tree().create_timer(2.8).timeout
	_show_hint("Hero: \"There was music. And dancing. And then—\"")
	await get_tree().create_timer(2.5).timeout
	_show_hint("Ravi: \"Odiyan's venom. You'll be fine. Probably.\"")
	await get_tree().create_timer(3.0).timeout
	_show_hint("")

	# Score reveal
	var score_label := Label.new()
	score_label.text = "You danced... somewhat acceptably.\nDisco score: %d" % _disco_score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	score_label.position = Vector2(VP_W * 0.5 - 200.0, VP_H * 0.5 - 24.0)
	score_label.size     = Vector2(400.0, 48.0)
	add_child(score_label)
	# Show on top of the fade
	score_label.z_index = 75

	# Brief fade-out of the black to show score label
	var un_tw := create_tween()
	un_tw.tween_property(fade, "color:a", 0.6, 0.6)
	await un_tw.finished
	await get_tree().create_timer(2.5).timeout

	# Restore HP to 40% then go to Act4
	GameManager.hp = maxi(1, int(GameManager.max_hp * 0.4))
	var final_tw := create_tween()
	final_tw.tween_property(fade, "color:a", 1.0, 0.8)
	await final_tw.finished

	SceneManager.go_to(NEXT_SCENE)

# ── Utility ────────────────────────────────────────────────────────────────────

func _show_hint(text: String, _duration: float = 0.0) -> void:
	if is_instance_valid(_hint_label):
		_hint_label.text = text
