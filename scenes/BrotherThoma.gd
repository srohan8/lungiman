extends Area2D

## Brother Thoma — grants 1 resurrection token per act.

var _blessed := false
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	z_index = 6   # render in front of ground tile (z=5)
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/thoma_sheet.png"
	const TARGET_H := 72.0
	# Sheet is 4800×3584 in a 4-col × 3-row grid (same format as hero sheets).
	# idle = cols 0-1 (holding bible), talk = cols 2-3 (hand raised in blessing).
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 4, 3, [
		{"name": "idle", "frames": [0, 1, 4, 5], "fps": 3.0, "loop": true},
		{"name": "talk", "frames": [2, 3, 6, 7], "fps": 5.0, "loop": true},
	], Color(0.9, 0.9, 0.85, 1.0))
	var s: float = GameManager.grid_sheet_scale(PATH, 3, TARGET_H)
	_spr.scale = Vector2(s, s)
	_spr.play("idle")
	add_child(_spr)
	# Hide the placeholder ColorRect that comes from the .tscn template
	var vis := get_node_or_null("Visual")
	if vis: vis.hide()

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
