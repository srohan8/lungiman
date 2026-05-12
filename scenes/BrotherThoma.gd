extends Area2D

## Brother Thoma — grants 1 resurrection token per act.

var _blessed := false
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/thoma_sheet.png"
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
			at.region = Rect2(i * 2048, 0, 2048, 4096)   # 32×64 SVG × scale 64
			sf.add_frame("idle" if i == 0 else "talk", at)
	else:
		for anim_name: String in ["idle", "talk"]:
			var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.9, 0.9, 0.85))
			sf.add_frame(anim_name, ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.scale = Vector2(64.0 / 4096.0, 64.0 / 4096.0)
	_spr.play("idle")
	add_child(_spr)

func _on_body_entered(body: Node) -> void:
	if _blessed or not body.is_in_group("player"):
		return
	if GameManager.has_resurrection:
		return
	_blessed = true
	GameManager.has_resurrection = true
	_show_blessing()

func _show_blessing() -> void:
	$Label.visible = true
	$Label.text    = "✝️ Stay on the trees.\n(Resurrection granted)"
	if _spr != null: _spr.play("talk")
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		$Label.visible = false
		if _spr != null: _spr.play("idle")
	)
