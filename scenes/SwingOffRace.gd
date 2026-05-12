extends Node2D

## SwingOffRace — Phase 3 quest. AI Aniyandi Ravi races the player crown-to-crown.
## Spawned by AniyandyRavi when the player accepts the challenge.
## Ravi leaps 5 target trees; if the player reaches tree #5 crown before Ravi → WIN.
## Reward: QuestManager marks swing_off_race DONE → unlocks Appam Glide ability.

signal race_finished(player_won: bool)

const RAVI_COLOR    := Color(0.95, 0.60, 0.10)   # saffron
const RAVI_SPEED    := 260.0                       # px/s ground walk
const LEAP_INTERVAL := 0.85                        # seconds between AI leaps
const COUNTDOWN     := 3.0                         # "3-2-1-GO!" before start

var _trees:         Array = []      # ordered Array[Node2D] of 5 race trees
var _ravi_idx:      int   = 0       # which tree Ravi is currently perched on
var _player:        Node2D = null
var _player_idx:    int   = -1      # which tree the player is on (-1 = ground)
var _leap_timer:    float = 0.0
var _countdown:     float = COUNTDOWN
var _started:       bool  = false
var _finished:      bool  = false

# Visual
var _ravi_rect: ColorRect

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_ravi_rect = ColorRect.new()
	_ravi_rect.size  = Vector2(28, 52)
	_ravi_rect.color = RAVI_COLOR
	_ravi_rect.position = Vector2(-14, -52)
	add_child(_ravi_rect)

## Called by AniyandyRavi with the 5 race trees and Ravi's start position.
func setup(start_pos: Vector2, race_trees: Array) -> void:
	position = start_pos
	_trees   = race_trees
	# Place Ravi on the first tree's crown
	if _trees.size() > 0:
		var crown: Vector2 = _trees[0].get_crown_position()
		position = crown - Vector2(0, 52)
		_ravi_idx = 0

func _process(delta: float) -> void:
	if _finished: return
	if not _started:
		_countdown -= delta
		if _countdown <= 0.0:
			_started = true
			_show_hud_hint("🏁 GO! Beat Ravi to tree #5!")
		return
	_leap_timer -= delta
	if _leap_timer <= 0.0 and _ravi_idx < _trees.size() - 1:
		_leap_timer = LEAP_INTERVAL
		_ravi_idx  += 1
		var crown: Vector2 = _trees[_ravi_idx].get_crown_position()
		# Tween Ravi to the next crown in an arc
		var tw := create_tween()
		var arc_peak := (position + crown) * 0.5 - Vector2(0, 80)
		tw.tween_property(self, "position", arc_peak, LEAP_INTERVAL * 0.4)
		tw.tween_property(self, "position", crown - Vector2(0, 52), LEAP_INTERVAL * 0.6)
		if _ravi_idx == _trees.size() - 1:
			tw.chain().tween_callback(func() -> void: _ravi_finished())
	_check_player_position()

func _check_player_position() -> void:
	if _player == null or not is_instance_valid(_player): return
	# Check if player is perched on the final tree
	var final_crown: Vector2 = _trees[-1].get_crown_position()
	var dist := _player.global_position.distance_to(final_crown)
	if dist < 80.0 and not _finished:
		_finish(true)

func _ravi_finished() -> void:
	if not _finished:
		_finish(false)

func _finish(player_won: bool) -> void:
	_finished = true
	if player_won:
		_show_hud_hint("🏆 You beat Ravi! Appam Glide unlocked!")
		QuestManager.complete_quest("swing_off_race")
		GameManager.score += 150
		GameManager.show_score_popup(position + Vector2(0, -60), 150, Color(1.0, 0.85, 0.2))
	else:
		_show_hud_hint("😤 Ravi wins... \"Practice on the trees, machane!\"")
	race_finished.emit(player_won)
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func _show_hud_hint(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_hint"):
		hud.show_hint(text, 4.0)
