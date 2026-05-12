extends Node2D

## Kili — Spirit Crow companion. Act III shrine.
## Feed 3 rice grains (porotta powerup = rice proxy) → Kili follows the player.
## While following: caws 1s before each Odiyan transform, giving early warning.

const FOLLOW_DIST  := 80.0    # stay this far behind the player
const FOLLOW_SPEED := 220.0
const RICE_NEEDED  := 3
const CAW_LEAD     := 1.0     # seconds before Odiyan transform to caw

var _rice_fed:    int   = 0
var _following:   bool  = false
var _player: Node2D     = null
var _odiyan: Node2D     = null
var _caw_timer:   float = 0.0
var _caw_cd:      float = 0.0   # prevent spam

func _ready() -> void:
	add_to_group("kili")
	_player = get_tree().get_first_node_in_group("player")
	# Find Odiyan boss when it spawns
	get_tree().create_timer(0.5).timeout.connect(_find_odiyan)
	_build_visual()
	_show_label("🐦 Kili\n[Feed me rice]")

func _build_visual() -> void:
	const PATH := "res://assets/sprites/kili_sheet.png"
	const FRAME_W := 280.0   # 20 SVG units × scale 14
	const FRAME_H := 504.0   # 36 SVG units × scale 14
	var spr := AnimatedSprite2D.new()
	spr.position = Vector2(0, -18)
	var sf := SpriteFrames.new()
	for anim_name: String in ["perch", "caw"]:
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, true)
		sf.set_animation_speed(anim_name, 4.0)
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		for i: int in 2:
			var at := AtlasTexture.new()
			at.atlas  = sheet
			at.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
			sf.add_frame("perch" if i == 0 else "caw", at)
	else:
		for anim_name: String in ["perch", "caw"]:
			var img := Image.create(20, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.08, 0.08, 0.10))
			sf.add_frame(anim_name, ImageTexture.create_from_image(img))
	spr.sprite_frames = sf
	spr.play("perch")
	add_child(spr)

func _find_odiyan() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e: Node in enemies:
		if e.get_class() != "" and e.has_method("reveal_weakness"):
			_odiyan = e
			return
	# Try again briefly if not found yet
	get_tree().create_timer(1.0).timeout.connect(_find_odiyan)

func feed_rice() -> void:
	if _following: return
	_rice_fed += 1
	_show_label("🐦 Kili\n%d / %d rice" % [_rice_fed, RICE_NEEDED])
	if _rice_fed >= RICE_NEEDED:
		_start_following()

func _start_following() -> void:
	_following = true
	_show_label("🐦 Kili follows!")
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		_clear_label()
	)

func _process(delta: float) -> void:
	_caw_cd = maxf(0.0, _caw_cd - delta)
	if not _following or _player == null: return

	# Smooth follow
	var target := _player.global_position + Vector2(-FOLLOW_DIST * sign(_player.get("face") if _player.get("face") != null else 1.0), -30.0)
	global_position = global_position.lerp(target, FOLLOW_SPEED * delta / 100.0)

	# Watch Odiyan's transform_timer to caw CAW_LEAD seconds before flash
	if _odiyan != null and is_instance_valid(_odiyan) and _caw_cd <= 0.0:
		var form_timer: float = _odiyan.get("form_timer") if _odiyan.get("form_timer") != null else 99.0
		if form_timer <= CAW_LEAD:
			_caw(_caw_timer)
			_caw_cd = 2.5

func _caw(_t: float) -> void:
	_show_label("🐦 CAW CAW!")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_hint"):
		hud.show_hint("🐦 Kili warns — Odiyan transforms soon!", 1.8)
	# Play caw animation
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null:
		for c: Node in get_children():
			if c is AnimatedSprite2D: spr = c; break
	if spr != null: spr.play("caw")
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		_clear_label()
		if spr != null and is_instance_valid(spr): spr.play("perch")
	)

func _show_label(txt: String) -> void:
	var lbl := get_node_or_null("Lbl")
	if lbl == null:
		lbl = Label.new()
		lbl.name = "Lbl"
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		lbl.position = Vector2(-28, -32)
		add_child(lbl)
	lbl.text = txt

func _clear_label() -> void:
	var lbl := get_node_or_null("Lbl")
	if lbl: lbl.text = ""
