extends Node2D
class_name DancePrompt

## DancePrompt — single falling arrow for the DiscoHallucination DDR minigame.
## Spawned by DiscoHallucination.gd, one per beat.
## Slides from TOP_Y → TARGET_Y in FALL_DURATION seconds.
## On arrival, the parent reads input and calls evaluate(delta_sec).

signal resolved(quality: String)   # "perfect" | "good" | "ok" | "miss"

const TOP_Y      := -40.0
const TARGET_Y   := 310.0    # glowing target line y (screen-space)
const FALL_DUR   := 1.20     # seconds to fall

const WINDOW_PERFECT := 0.10
const WINDOW_GOOD    := 0.25
const WINDOW_OK      := 0.35

const ARROW_ICONS := {
	"left":  "←",
	"right": "→",
	"up":    "↑",
	"down":  "↓",
	"jump":  "⬆",
}
const ARROW_COLORS := {
	"left":  Color(0.20, 0.70, 1.00),
	"right": Color(1.00, 0.35, 0.80),
	"up":    Color(0.30, 1.00, 0.45),
	"down":  Color(1.00, 0.75, 0.10),
	"jump":  Color(1.00, 1.00, 1.00),
}

var direction: String = "right"
var _elapsed: float   = 0.0
var _done:    bool    = false
var _label:   Label   = null

func _ready() -> void:
	position.y = TOP_Y
	_label = Label.new()
	_label.text = ARROW_ICONS.get(direction, "?")
	_label.add_theme_font_size_override("font_size", 36)
	_label.add_theme_color_override("font_color", ARROW_COLORS.get(direction, Color.WHITE))
	_label.position = Vector2(-18, -22)
	add_child(_label)

func _process(delta: float) -> void:
	if _done: return
	_elapsed += delta
	var t := minf(_elapsed / FALL_DUR, 1.0)
	position.y = lerpf(TOP_Y, TARGET_Y, t)
	if _elapsed >= FALL_DUR + WINDOW_OK and not _done:
		_resolve("miss")

func evaluate(time_delta: float) -> void:
	## Called by parent when player presses matching key.
	if _done: return
	var dt := absf(time_delta)
	if   dt <= WINDOW_PERFECT: _resolve("perfect")
	elif dt <= WINDOW_GOOD:    _resolve("good")
	elif dt <= WINDOW_OK:      _resolve("ok")
	else:                       _resolve("miss")

func _resolve(quality: String) -> void:
	if _done: return
	_done = true
	resolved.emit(quality)
	# Flash colour feedback
	var flash_colors := {
		"perfect": Color(1.0, 0.95, 0.2),
		"good":    Color(0.3, 1.0, 0.4),
		"ok":      Color(1.0, 1.0, 1.0),
		"miss":    Color(1.0, 0.2, 0.2),
	}
	if _label:
		_label.add_theme_color_override("font_color",
				flash_colors.get(quality, Color.WHITE))
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	tw.tween_callback(queue_free)
