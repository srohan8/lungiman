extends Area2D

## Maveli (Mahabali) — the legendary Kerala king waiting in Pathalam.
## He is not a boss. He heals. He is patient. He has been waiting a long time.
##
## When the player enters his presence:
##   1. Dialogue plays in 4 beats (auto-advance on timer)
##   2. Blessing fires: GameManager.maveli_restore() — HP to full, Grit to 100, maveli_blessed=true
##   3. Golden flash effect
##   4. Pathalam triggers the exit sequence to Act V

signal blessing_given   ## Pathalam.gd listens to this to begin the exit sequence

const DIALOGUES := [
	"I brought you down here. I hope that was acceptable.",
	"I have been watching since the first grove fell.\nI watched you take four of them.",
	"Kanjiravanam was protected once.\nBy better men than either of us.\nThey are gone now. You are what is left.",
	"Go up. Finish it.\nOnam is coming — my people need a home to come back to.",
]

const DIALOGUE_DURATION := 3.2   # seconds per line
const BLESSING_AFTER    := 2     # bless the player after dialogue line index 2

var _stage:       int  = 0
var _playing:     bool = false
var _blessed:     bool = false
var _spr: AnimatedSprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	$Label.visible = false
	_load_sprite()

func _load_sprite() -> void:
	const PATH := "res://assets/sprites/maveli_sheet.png"
	const TARGET_H := 160.0   # Maveli is taller than ordinary men — impossibly regal
	_spr = AnimatedSprite2D.new()
	_spr.position = Vector2(0, -TARGET_H * 0.5)
	_spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 4, 3, [
		{"name": "seated", "frames": [0, 1, 4, 5], "fps": 2.0, "loop": true},
		{"name": "stand",  "frames": [2, 3, 6, 7], "fps": 3.0, "loop": false},
		{"name": "bless",  "frames": [8, 9, 10],   "fps": 4.0, "loop": false},
	], Color(1.0, 0.85, 0.40, 1.0))   # fallback: warm gold rect
	var s: float = GameManager.grid_sheet_scale(PATH, 3, TARGET_H)
	_spr.scale = Vector2(s, s)
	_spr.play("seated")
	add_child(_spr)
	var vis := get_node_or_null("Visual")
	if vis: vis.hide()

func _on_body_entered(body: Node) -> void:
	if _playing or not body.is_in_group("player"):
		return
	_playing = true
	_advance_dialogue()

func _advance_dialogue() -> void:
	if _stage >= DIALOGUES.size():
		# All lines done — initiate exit after a pause
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			blessing_given.emit()
		)
		return

	$Label.text    = DIALOGUES[_stage]
	$Label.visible = true

	# Blessing fires mid-dialogue — at line index BLESSING_AFTER
	if _stage == BLESSING_AFTER and not _blessed:
		_blessed = true
		_give_blessing()

	_stage += 1

	get_tree().create_timer(DIALOGUE_DURATION).timeout.connect(func() -> void:
		_advance_dialogue()
	)

func _give_blessing() -> void:
	# Maveli stands and extends his hand
	if _spr != null:
		_spr.play("stand")
		get_tree().create_timer(0.8).timeout.connect(func() -> void:
			if is_instance_valid(_spr): _spr.play("bless")
		)

	# Restore HP + Grit, lock maveli_blessed
	GameManager.maveli_restore()

	# Sacred gold flash — a ColorRect on a CanvasLayer so it covers the whole screen
	var cl := CanvasLayer.new()
	cl.layer = 20
	var flash := ColorRect.new()
	flash.color      = Color(1.0, 0.88, 0.25, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(flash)
	get_tree().current_scene.add_child(cl)

	# Fade in → hold → fade out
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.72, 0.35)
	tw.tween_interval(0.55)
	tw.tween_property(flash, "color:a", 0.0,  0.60)
	tw.tween_callback(cl.queue_free)
