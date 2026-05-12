extends Node2D

var height: float = 185.0
var lean:   float = 0.08

func get_crown_position() -> Vector2:
	return Vector2(
		position.x + lean * height * 0.6,
		position.y - height + lean * height * 0.15
	)

func _ready() -> void:
	add_to_group("trees")
	$ClimbTrigger/CollisionShape2D.shape.radius = 36.0
	var crown_shape := $CrownArea/CollisionShape2D.shape as RectangleShape2D
	crown_shape.size = Vector2(45.0, 55.0)
	# Position crown area at local crown offset
	$CrownArea.position = get_crown_position() - position

func _draw() -> void:
	var crown_local := get_crown_position() - position
	# Trunk
	draw_line(Vector2.ZERO, crown_local, Color(0.55, 0.38, 0.15), 9.0)
	# Mid-trunk texture rings
	for t: float in [0.3, 0.55, 0.75]:
		var mid := crown_local * t
		draw_line(mid - Vector2(6, 0), mid + Vector2(6, 0), Color(0.42, 0.28, 0.10), 2.0)
	# Crown foliage (3 overlapping circles)
	draw_circle(crown_local,                          30.0, Color(0.22, 0.52, 0.18))
	draw_circle(crown_local + Vector2(-18.0, -8.0),  22.0, Color(0.18, 0.48, 0.14))
	draw_circle(crown_local + Vector2( 18.0, -8.0),  22.0, Color(0.18, 0.48, 0.14))
	draw_circle(crown_local + Vector2(  0.0, -16.0), 18.0, Color(0.25, 0.58, 0.20))

func _on_climb_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_tree = self

func _on_climb_trigger_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.near_tree == self:
		body.near_tree = null

func _on_crown_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.perch_on(self)
