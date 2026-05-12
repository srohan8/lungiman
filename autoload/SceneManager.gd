extends CanvasLayer

## SceneManager — fade-to-black scene transitions.
## Usage: SceneManager.go_to("res://scenes/Act1.tscn")

const FADE_DURATION := 0.5

var _transitioning := false
var _overlay: ColorRect

func _ready() -> void:
	layer = 128
	_overlay = ColorRect.new()
	_overlay.color        = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Explicit size guards against anchors not resolving in CanvasLayer on first frame
	_overlay.size         = Vector2(820, 460)
	add_child(_overlay)

func go_to(scene_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_in()
	get_tree().change_scene_to_file(scene_path)
	await _fade_out()
	_transitioning = false

func reload() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_in()
	get_tree().reload_current_scene()
	await _fade_out()
	_transitioning = false

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 1), FADE_DURATION)
	await tween.finished

func _fade_out() -> void:
	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 0), FADE_DURATION)
	await tween.finished
