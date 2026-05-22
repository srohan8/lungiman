extends CanvasLayer

## FishingGame — Fish Fry for the Gods mini-game (Phase 5 quest).
## An amber indicator sweeps left↔right across a power bar.
## Press JUMP (or SWORD) when the indicator is inside the green sweet zone.
## Catch CATCHES_NEEDED fish before TIME_LIMIT seconds → quest completes.
## Reward: double HP regen for 5 minutes (GameManager.fish_fry_active).

signal fishing_done(won: bool)

const CATCHES_NEEDED := 3
const TIME_LIMIT     := 25.0
const SWING_SPEED    := 2.4    # oscillator angular speed (rad/s)
const SWEET_FRAC     := 0.26   # fraction of bar that is the "sweet zone"
const BAR_W          := 260.0
const BAR_H          := 20.0

var _catches:    int   = 0
var _timer:      float = TIME_LIMIT
var _active:     bool  = false
var _phase:      float = 0.0
var _pending:    bool  = false   # brief pause after each successful catch

var _indicator:  ColorRect = null
var _sweet_rect: ColorRect = null
var _status_lbl: Label     = null
var _time_lbl:   Label     = null
var _hint_lbl:   Label     = null
var _bobber_lbl: Label     = null

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	# Translucent backdrop
	var bg := ColorRect.new()
	bg.color          = Color(0.02, 0.06, 0.14, 0.88)
	bg.anchors_preset = 15
	bg.anchor_right   = 1.0
	bg.anchor_bottom  = 1.0
	bg.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.alignment           = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	_lbl(vbox, "🎣 FISHING FOR THE GODS", 20, Color(0.40, 0.85, 1.0))
	_lbl(vbox, "Press JUMP when the bobber hits the green zone!", 11, Color.WHITE)
	_spacer(vbox, 10)

	_bobber_lbl = _lbl(vbox, "🎣", 30, Color.WHITE)
	_spacer(vbox, 8)

	# Power-bar container
	var bar_cont := Control.new()
	bar_cont.custom_minimum_size = Vector2(BAR_W, BAR_H + 6)
	vbox.add_child(bar_cont)

	var track := ColorRect.new()
	track.color    = Color(0.12, 0.12, 0.12)
	track.size     = Vector2(BAR_W, BAR_H)
	track.position = Vector2(0.0, 3.0)
	bar_cont.add_child(track)

	var sz_w := BAR_W * SWEET_FRAC
	_sweet_rect = ColorRect.new()
	_sweet_rect.color    = Color(0.14, 0.75, 0.22, 0.62)
	_sweet_rect.size     = Vector2(sz_w, BAR_H)
	_sweet_rect.position = Vector2((BAR_W - sz_w) * 0.5, 3.0)
	bar_cont.add_child(_sweet_rect)

	_indicator = ColorRect.new()
	_indicator.color    = Color(1.0, 0.62, 0.08)
	_indicator.size     = Vector2(10.0, BAR_H)
	_indicator.position = Vector2(0.0, 3.0)
	bar_cont.add_child(_indicator)

	_spacer(vbox, 8)
	_hint_lbl   = _lbl(vbox, "🐟  Cast!", 16, Color.WHITE)
	_status_lbl = _lbl(vbox, "Fish caught: 0 / %d" % CATCHES_NEEDED, 13, Color.WHITE)
	_time_lbl   = _lbl(vbox, "⏱ %.0fs" % TIME_LIMIT, 12, Color(1.0, 0.58, 0.38))

## Helper — create a centred Label and return it.
func _lbl(parent: Node, text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text                    = text
	l.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

## Helper — invisible spacer.
func _spacer(parent: Node, h: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0.0, h)
	parent.add_child(s)

## Called by BijuEttan after a brief dialogue delay.
func start() -> void:
	_active   = true
	_catches  = 0
	_timer    = TIME_LIMIT
	_phase    = 0.0
	_pending  = false
	if _hint_lbl:    _hint_lbl.text = "🐟  Cast!"
	if _status_lbl:  _status_lbl.text = "Fish caught: 0 / %d" % CATCHES_NEEDED
	if _time_lbl:    _time_lbl.text = "⏱ %.0fs" % TIME_LIMIT

func _process(delta: float) -> void:
	if not _active: return

	_timer -= delta
	if _timer <= 0.0:
		_finish(false); return

	if _time_lbl: _time_lbl.text = "⏱ %.0fs" % maxf(0.0, _timer)

	# Advance oscillator: smooth sine sweep
	_phase         = fmod(_phase + SWING_SPEED * delta, TAU)
	var t  : float = (sin(_phase) + 1.0) * 0.5        # 0.0 → 1.0
	var ix : float = t * (BAR_W - 10.0)
	if _indicator: _indicator.position.x = ix

	# Bobber emoji dips when inside sweet zone
	var in_sweet := _in_sweet(ix)
	if _bobber_lbl: _bobber_lbl.text = "🐟" if in_sweet else "🎣"

	if _pending: return

	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("sword"):
		if in_sweet:
			_register_catch()
		else:
			if _hint_lbl:
				_hint_lbl.text = "💧 Too early! Wait for the dip..."
				_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38))

func _in_sweet(ix: float) -> bool:
	if _sweet_rect == null: return false
	var left  := _sweet_rect.position.x
	var right := left + _sweet_rect.size.x - 10.0
	return ix >= left and ix <= right

func _register_catch() -> void:
	_catches += 1
	_pending  = true
	if _hint_lbl:
		_hint_lbl.text = "🐟  Got one! (%d / %d)" % [_catches, CATCHES_NEEDED]
		_hint_lbl.add_theme_color_override("font_color", Color(0.28, 1.0, 0.48))
	if _status_lbl:
		_status_lbl.text = "Fish caught: %d / %d" % [_catches, CATCHES_NEEDED]
	if _catches >= CATCHES_NEEDED:
		_finish(true); return
	get_tree().create_timer(0.75).timeout.connect(func() -> void:
		_pending = false
		if is_instance_valid(self) and _hint_lbl != null:
			_hint_lbl.text = "🎣  Cast again!"
			_hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	)

func _finish(won: bool) -> void:
	_active = false
	if won:
		if _hint_lbl:
			_hint_lbl.text = "🎉  Biju Ettan is very pleased!"
			_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.22))
		var qm := get_node_or_null("/root/QuestManager")
		if qm != null: qm.complete_quest("fish_fry_for_gods")
		GameManager.fish_fry_active = true
		GameManager.fish_fry_timer  = 300.0
		GameManager.score += 80
		GameManager.show_score_popup(Vector2(240.0, 135.0), 80, Color(1.0, 0.75, 0.22))
	else:
		if _hint_lbl:
			_hint_lbl.text = "😅  The fish got away! Talk to Biju to try again."
			_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.40))
	fishing_done.emit(won)
	get_tree().create_timer(2.8).timeout.connect(queue_free)
