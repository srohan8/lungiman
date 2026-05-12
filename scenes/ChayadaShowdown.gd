extends CanvasLayer

## ChayadaShowdown — Phase 3 button-mash mini-game.
## 3 drunkards crash Soniya's stall. Mash [sword] to fill a bar before time runs out.
## Win  → quest complete, +ammo regen 2× near tea shops.
## Lose → resume normally (can retry next visit).

signal showdown_finished(won: bool)

const MASH_TARGET  := 28       # hits needed to win
const TIME_LIMIT   := 8.0      # seconds
const DECAY_RATE   := 1.8      # bar drains per second if not mashing

var _hits:     int   = 0
var _timer:    float = TIME_LIMIT
var _active:   bool  = false
var _bar:      ProgressBar
var _lbl:      Label
var _time_lbl: Label

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color             = Color(0.05, 0.02, 0.0, 0.80)
	bg.anchors_preset    = 15
	bg.anchor_right      = 1.0
	bg.anchor_bottom     = 1.0
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	vbox.custom_minimum_size = Vector2(320, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	var title := Label.new()
	title.text = "☕ CHAYA KADA SHOWDOWN!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Mash [Z / Sword] to drive them out!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	vbox.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(300, 28)
	_bar.max_value           = MASH_TARGET
	_bar.value               = 0
	vbox.add_child(_bar)

	_lbl = Label.new()
	_lbl.text = "💪 Mash!"
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_lbl)

	_time_lbl = Label.new()
	_time_lbl.text = "⏱ 8s"
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_lbl.add_theme_font_size_override("font_size", 13)
	_time_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
	vbox.add_child(_time_lbl)

func start() -> void:
	_active = true
	_hits   = 0
	_timer  = TIME_LIMIT
	_bar.value = 0
	Engine.time_scale = 1.0   # ensure normal speed

func _process(delta: float) -> void:
	if not _active: return
	# Bar decays slowly if player isn't mashing
	_bar.value = maxf(0.0, _bar.value - DECAY_RATE * delta)
	_timer    -= delta
	_time_lbl.text = "⏱ %.1fs" % maxf(0.0, _timer)
	if _timer <= 0.0:
		_finish(false)
		return
	if Input.is_action_just_pressed("sword"):
		_hits      += 1
		_bar.value  = minf(_hits, MASH_TARGET)
		_lbl.text   = "💪 " + "█".repeat(mini(_hits, 10))
		if _hits >= MASH_TARGET:
			_finish(true)

func _finish(won: bool) -> void:
	_active = false
	if won:
		_lbl.text = "🎉 You drove them out!"
		var qm := get_node_or_null("/root/QuestManager")
		if qm != null: qm.complete_quest("chaya_kada_showdown")
		GameManager.score += 100
		GameManager.show_score_popup(Vector2(410, 300), 100, Color(1.0, 0.75, 0.2))
	else:
		_lbl.text = "😅 They're still drinking..."
	showdown_finished.emit(won)
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		queue_free()
	)
