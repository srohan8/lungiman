extends Area2D

## Ustad Basheer — elder tracker. Activates Odiyan's Tracks quest in Act III.

const DIALOGUES := [
	"Odiyan left his marks.\nFind them before he finds you. 🐾",
	"Look for the spirit smoke.\nPress Z near it to read the signs.",
	"Four prints in these hills.\nEach one warns you of his true form.",
	"You found them all?\nNow you know where he is weak.",
	"He chose the wrong skin tonight.",
]

var _stage: int = 0
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/basheer_sheet.png"
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -32)
	var sf := SpriteFrames.new()
	for anim_name: String in ["idle", "talk"]:
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, true)
		sf.set_animation_speed(anim_name, 2.0)
	if ResourceLoader.exists(PATH):
		var sheet: Texture2D = load(PATH)
		for i: int in 2:
			var at := AtlasTexture.new()
			at.atlas  = sheet
			at.region = Rect2(i * 648, 0, 648, 1152)   # 36×64 SVG × scale 18
			sf.add_frame("idle" if i == 0 else "talk", at)
	else:
		for anim_name: String in ["idle", "talk"]:
			var img := Image.create(36, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.55, 0.42, 0.30))
			sf.add_frame(anim_name, ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.play("idle")
	add_child(_spr)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var idx := mini(_stage, DIALOGUES.size() - 1)
	$Label.text    = DIALOGUES[idx]
	$Label.visible = true
	if _spr != null: _spr.play("talk")
	_stage += 1
	get_tree().create_timer(3.5).timeout.connect(func() -> void:
		$Label.visible = false
		if _spr != null: _spr.play("idle")
	)
