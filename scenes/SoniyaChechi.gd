extends Area2D

## Soniya Chechi — Chaya Kada owner. 3-stage multi-line dialogue.
## Stage 1: intro quip  Stage 2: serves chai  Stage 3+: repeat quips

const DIALOGUES := [
	"You smell like Old Monk\nand wet banana leaf. Sit.",
	"☕ Here. Drink before\nyou face whatever that is.",
	"Back already?\nThe chai is extra hot this time.",
	"I saw what charged through.\nYou need more than chai.",
	"...want chai?",
]

var _stage:          int  = 0
var _served:         bool = false
var _showdown_done:  bool = false
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	add_to_group("tea_shop")
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/soniya_sheet.png"
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
			at.region = Rect2(i * 36, 0, 36, 64)
			sf.add_frame("idle" if i == 0 else "talk", at)
	else:
		for anim_name: String in ["idle", "talk"]:
			var img := Image.create(36, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.5, 0.7, 0.5))
			sf.add_frame(anim_name, ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.play("idle")
	add_child(_spr)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_show_stage()
	if not _served and _stage >= 1:
		_served = true
		_drop_chai()
	# Stage 3 in Act I: Chaya Kada Showdown (drunkards arrive)
	if _stage == 3:
		_trigger_showdown()

func _show_stage() -> void:
	var idx    := mini(_stage, DIALOGUES.size() - 1)
	$Label.text    = DIALOGUES[idx]
	$Label.visible = true
	if _spr != null: _spr.play("talk")
	_stage        += 1
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		$Label.visible = false
		if _spr != null: _spr.play("idle")
	)

func _drop_chai() -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type     = "chai"
	pu.position = position + Vector2(35.0, -15.0)
	get_parent().call_deferred("add_child", pu)

## Triggered on stage 3 visit in Act I — drunkards crash the stall.
func _trigger_showdown() -> void:
	if _showdown_done: return
	if QuestManager.get_state("chaya_kada_showdown") == 2: return
	_showdown_done = true
	QuestManager.activate_quest("chaya_kada_showdown")
	get_tree().create_timer(3.2).timeout.connect(func() -> void:
		var sd: Node = preload("res://scenes/ChayadaShowdown.tscn").instantiate()
		get_tree().root.add_child(sd)
		sd.start()
	)
