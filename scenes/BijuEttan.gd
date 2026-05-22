extends Area2D

## Captain Biju — Houseboat captain. Prologue NPC. Introduces the world.
## Ex-fighter. Retired the day he transported timber out of the sacred grove.
## Helps LungiMan without explaining why. He owes this to someone.

const DIALOGUES := [
	"Machane... take this.\nThe forest is restless again. 🥥",
	"Kanjiravanam was peaceful once.\nI know exactly when it changed.",
	"Stay on the trees at night.\nThe ground belongs to them now.",
	"You're still going?\nGood. Don't stop.",
	"🐟 Fish fry is ready.\nEat. You'll need your strength.",
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
	const PATH := "res://assets/sprites/biju_sheet.png"
	const TARGET_H := 110.0
	var spr := AnimatedSprite2D.new()
	spr.position = Vector2(0, -TARGET_H * 0.5)
	spr.sprite_frames = GameManager.build_grid_sheet_frames(PATH, 2, 1, [
		{"name": "idle", "frames": [0], "fps": 2.0, "loop": true},
		{"name": "talk", "frames": [1], "fps": 2.0, "loop": true},
	], Color(0.72, 0.55, 0.35, 1.0))
	var s: float = GameManager.grid_sheet_scale(PATH, 1, TARGET_H)
	spr.scale = Vector2(s, s)
	spr.play("idle")
	add_child(spr)
	set_meta("_spr", spr)
	# Hide the placeholder ColorRect from the .tscn template
	var vis := get_node_or_null("Visual")
	if vis: vis.hide()

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
	# Second meeting: launch the fishing mini-game (quest must be ACTIVE and not yet won)
	if _stage == 2 and not _quest_done:
		var qm := get_node_or_null("/root/QuestManager")
		if qm != null and qm.get_state("fish_fry_for_gods") == 1:   # ACTIVE = 1
			get_tree().create_timer(3.7).timeout.connect(_launch_fishing_game)
	# 5th meeting fallback: fish fry reward if fishing mini-game was skipped / never won
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

## Spawn the fishing mini-game and listen for result.
func _launch_fishing_game() -> void:
	var game: Node = preload("res://scenes/FishingGame.tscn").instantiate()
	get_tree().root.add_child(game)
	(game as Node).call("start")
	game.fishing_done.connect(func(won: bool) -> void:
		if won: _quest_done = true
	)
