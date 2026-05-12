extends Area2D

## Biju Ettan — Village elder. Prologue NPC. Introduces the world.
## Gives the player their first coconut and warns about the forest.

const DIALOGUES := [
	"Son, the forest is stirring.\nTake this coconut. 🥥",
	"Kanjiravanam was peaceful\nonce. Before the spirits woke.",
	"Stay on the trees at night.\nThe ground belongs to them.",
	"You're still here?\nThe village needs you, machane.",
	"🐟 Fish fry is ready!\nEat — it will strengthen you.",
]

var _stage:        int  = 0
var _gave_coconut: bool = false
var _quest_done:   bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_build_sprite()

func _build_sprite() -> void:
	var img := Image.create(36, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.72, 0.55, 0.35))   # warm brown — elder's mundu
	var spr := AnimatedSprite2D.new()
	spr.position = Vector2(0, -32)
	var sf := SpriteFrames.new()
	for anim: String in ["idle", "talk"]:
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		sf.set_animation_speed(anim, 2.0)
		sf.add_frame(anim, ImageTexture.create_from_image(img))
	spr.sprite_frames = sf
	spr.play("idle")
	add_child(spr)
	set_meta("_spr", spr)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var idx := mini(_stage, DIALOGUES.size() - 1)
	$Label.text    = DIALOGUES[idx]
	$Label.visible = true
	var spr: AnimatedSprite2D = get_meta("_spr")
	spr.play("talk")
	_stage += 1
	# First meeting: drop a coconut, activate Fish Fry quest
	if not _gave_coconut and _stage == 1:
		_gave_coconut = true
		var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
		pu.type     = "nut"
		pu.position = position + Vector2(40, -10)
		get_parent().call_deferred("add_child", pu)
		var qm := get_node_or_null("/root/QuestManager")
		if qm != null: qm.activate_quest("fish_fry_for_gods")
	# 5th meeting: fish fry reward — double HP regen flag + complete quest
	if _stage == 5 and not _quest_done:
		_quest_done = true
		var qm := get_node_or_null("/root/QuestManager")
		if qm != null: qm.complete_quest("fish_fry_for_gods")
		GameManager.fish_fry_active = true
		GameManager.fish_fry_timer  = 300.0   # 5 minutes of double regen
		GameManager.show_score_popup(position + Vector2(0, -50), 50, Color(1.0, 0.7, 0.3))
		GameManager.score += 50
	get_tree().create_timer(3.5).timeout.connect(func() -> void:
		$Label.visible = false
		spr.play("idle")
	)
