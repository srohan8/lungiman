extends Area2D

## Aniyandi Ravi — Toddy stall owner. Swing-off Race quest giver.
## Acts I and II. Drops toddy on first meeting.

const DIALOGUES := [
	"Old Monk? HANG on that\ntree 5 seconds first! 🏺",
	"🏺 Here — earned it.\nDon't blame me for the wobble.",
	"You still alive?\nThat's surprising.",
	"Want to race me across\nthose trees? First to 5 wins.",
	"I've been here since\nyour grandfather's time, boy.",
]

var _stage:       int  = 0
var _served:      bool = false
var _race_started: bool = false
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/ravi_sheet.png"
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
			img.fill(Color(0.75, 0.55, 0.25))   # warm Kerala brown
			sf.add_frame(anim_name, ImageTexture.create_from_image(img))
	_spr.sprite_frames = sf
	_spr.scale = Vector2(64.0 / 1152.0, 64.0 / 1152.0)
	_spr.play("idle")
	add_child(_spr)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_show_stage()
	if not _served and _stage >= 1:
		_served = true
		_drop_toddy()
	# Stage 3 (index 3): race challenge dialogue — trigger race on next visit
	if _stage == 4 and not _race_started:
		_race_started = true
		get_tree().create_timer(3.5).timeout.connect(_launch_race)

func _show_stage() -> void:
	var idx        := mini(_stage, DIALOGUES.size() - 1)
	$Label.text    = DIALOGUES[idx]
	$Label.visible = true
	if _spr != null: _spr.play("talk")
	_stage        += 1
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		$Label.visible = false
		if _spr != null: _spr.play("idle")
	)

func _drop_toddy() -> void:
	var pu: Node2D = preload("res://scenes/PowerUp.tscn").instantiate()
	pu.type     = "toddy"
	pu.position = position + Vector2(35.0, -15.0)
	get_parent().call_deferred("add_child", pu)

func _launch_race() -> void:
	# Already completed? Skip.
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm == null: return
	if qm.get_state("swing_off_race") == 2: return
	qm.activate_quest("swing_off_race")
	# Gather the 5 nearest trees to the right of Ravi as race checkpoints
	var race_trees: Array = []
	var all_trees: Array = get_tree().get_nodes_in_group("trees")
	var candidates: Array = []
	for t: Node in all_trees:
		if t.global_position.x > global_position.x:
			candidates.append(t)
	candidates.sort_custom(func(a, b) -> bool:
		return a.global_position.x < b.global_position.x
	)
	for i: int in mini(5, candidates.size()):
		race_trees.append(candidates[i])
	if race_trees.size() < 2:
		return   # not enough trees to race
	var race: Node2D = preload("res://scenes/SwingOffRace.tscn").instantiate()
	get_parent().add_child(race)
	race.setup(global_position, race_trees)
