extends Node2D

## FloatingText — brief score/event popup that floats up and fades out.
## Usage: spawn at world position, set .text and optionally .color before add_child.

var text:  String = "+10"
var color: Color  = Color(1.0, 0.92, 0.25)   # gold by default

func _ready() -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.position = Vector2(-20.0, -10.0)
	add_child(lbl)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 48.0, 0.9)
	tw.tween_property(lbl,  "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(queue_free)
