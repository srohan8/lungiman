extends Area2D

## Soniya Chechi — Chaya Kada owner. 3-stage multi-line dialogue.
## Stage 1: intro quip  Stage 2: serves chai  Stage 3+: repeat quips

const DIALOGUES := [
	"You smell like Old Monk\nand wet banana leaf. Sit.",
	"☕ Here. Drink before\nyou face whatever that is.",
	"Wait — three drunks just came in.\nThey're breaking my stall! Help!",
	"I saw what charged through.\nYou need more than chai.",
	"...want chai?",
]

var _stage:          int  = 0
var _served:         bool = false
var _showdown_done:  bool = false
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	add_to_group("tea_shop")
	z_index = 6   # render in front of ground tile (z=5)
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/soniya_sheet.png"
	const TARGET_H := 72.0
	# Sheet is 4800×3584 in a 4-col × 3-row grid (same format as hero sheets).
	# idle = cols 0-1 (standing with flask), talk = cols 2-3 (extending chai cup).
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 4, 3, [
		{"name": "idle", "frames": [0, 1, 4, 5], "fps": 3.0, "loop": true},
		{"name": "talk", "frames": [2, 3, 6, 7], "fps": 5.0, "loop": true},
	], Color(0.5, 0.7, 0.5, 1.0))
	var s: float = GameManager.grid_sheet_scale(PATH, 3, TARGET_H)
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
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm != null and qm.get_state("chaya_kada_showdown") == 2: return
	_showdown_done = true
	if qm != null: qm.activate_quest("chaya_kada_showdown")
	get_tree().create_timer(3.2).timeout.connect(func() -> void:
		var sd: Node = preload("res://scenes/ChayadaShowdown.tscn").instantiate()
		get_tree().root.add_child(sd)
		sd.start()
	)
