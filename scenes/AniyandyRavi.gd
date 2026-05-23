extends Area2D

## Mundakkal Ravi — Toddy stall owner. Swing-off Race quest giver.
## Acts I and II. Drops toddy on first meeting.
## Built his shop with timber from the sacred grove. Never stops talking.
## Terrified of the silence at 2am when the shop is empty.

const DIALOGUES := [
	"Old Monk? HANG on that\ntree 5 seconds first! 🏺",
	"🏺 Here — earned it.\nDon't blame me for the wobble.",
	"You still alive? Ha!\nThat's more than I expected.",
	"Want to race me across\nthose trees? First to 5 wins.",
	"Mundakkal family's been\nhere forever. We know things.",
]

var _stage:       int  = 0
var _served:      bool = false
var _race_started: bool = false
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	z_index = 6   # render in front of ground tile (z=5)
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/ravi_sheet.png"
	const TARGET_H := 72.0
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 2, 1, [
		{"name": "idle", "frames": [0], "fps": 2.0, "loop": true},
		{"name": "talk", "frames": [1], "fps": 2.0, "loop": true},
	], Color(0.75, 0.55, 0.25, 1.0))
	var s: float = GameManager.grid_sheet_scale(PATH, 1, TARGET_H)
	_spr.scale = Vector2(s, s)
	_spr.play("idle")
	add_child(_spr)
	# Hide the placeholder ColorRect from the .tscn template
	var vis := get_node_or_null("Visual")
	if vis: vis.hide()

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
