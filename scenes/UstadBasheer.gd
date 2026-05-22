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
	const TARGET_H := 110.0
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 2, 1, [
		{"name": "idle", "frames": [0], "fps": 2.0, "loop": true},
		{"name": "talk", "frames": [1], "fps": 2.0, "loop": true},
	], Color(0.55, 0.42, 0.30, 1.0))
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
	var idx := mini(_stage, DIALOGUES.size() - 1)
	$Label.text    = DIALOGUES[idx]
	$Label.visible = true
	if _spr != null: _spr.play("talk")
	_stage += 1
	get_tree().create_timer(3.5).timeout.connect(func() -> void:
		$Label.visible = false
		if _spr != null: _spr.play("idle")
	)
