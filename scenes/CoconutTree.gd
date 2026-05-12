extends Node2D

var height: float = 185.0
var lean:   float = 0.08

# Crown sway — gentle sinusoidal animation unique to each tree
var _sway_t:     float = 0.0
var _sway_phase: float = 0.0   # set in _ready based on position.x
const SWAY_AMP   := 2.8        # max pixel offset of crown
const SWAY_SPEED := 0.55       # cycles per second

func get_crown_position() -> Vector2:
	var sway := sin(_sway_t * TAU + _sway_phase) * SWAY_AMP
	return Vector2(
		position.x + lean * height * 0.6 + sway,
		position.y - height + lean * height * 0.15 + abs(sway) * 0.15
	)

func _ready() -> void:
	add_to_group("trees")
	$ClimbTrigger/CollisionShape2D.shape.radius = 36.0
	var crown_shape := $CrownArea/CollisionShape2D.shape as RectangleShape2D
	crown_shape.size = Vector2(45.0, 55.0)
	$CrownArea.position = get_crown_position() - position
	# Unique phase so nearby trees don't sway in sync
	_sway_phase = fmod(position.x * 0.031, TAU)


func _process(delta: float) -> void:
	_sway_t += delta * SWAY_SPEED
	queue_redraw()

func _draw() -> void:
	var crown_local := get_crown_position() - position
	# Apply sway: crown shifts left/right by a sine wave
	var sway := sin(_sway_t * TAU + _sway_phase) * SWAY_AMP
	var crown_swayed := crown_local + Vector2(sway, abs(sway) * 0.15)
	# Trunk (tip follows sway)
	draw_line(Vector2.ZERO, crown_swayed, Color(0.55, 0.38, 0.15), 9.0)
	# Mid-trunk texture rings
	for t: float in [0.3, 0.55, 0.75]:
		var mid := crown_swayed * t
		draw_line(mid - Vector2(6, 0), mid + Vector2(6, 0), Color(0.42, 0.28, 0.10), 2.0)
	# Crown foliage (3 overlapping circles, all follow sway)
	draw_circle(crown_swayed,                          30.0, Color(0.22, 0.52, 0.18))
	draw_circle(crown_swayed + Vector2(-18.0, -8.0),  22.0, Color(0.18, 0.48, 0.14))
	draw_circle(crown_swayed + Vector2( 18.0, -8.0),  22.0, Color(0.18, 0.48, 0.14))
	draw_circle(crown_swayed + Vector2(  0.0, -16.0), 18.0, Color(0.25, 0.58, 0.20))

func _on_climb_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_tree = self

func _on_climb_trigger_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.near_tree == self:
		body.near_tree = null

func _on_crown_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.perch_on(self)
