extends Node2D

## Ambient crow silhouette that drifts leftward across the sky and wraps
## seamlessly at the level edges. Purely procedural — no texture required.
## Spawn via World.gd _spawn_crows().

@export var speed        := 22.0   ## px / sec  (leftward)
@export var bird_size    :=  4.5   ## half-wingspan in world pixels
@export var flap_freq    :=  3.0   ## wing flaps per second
@export var phase_offset :=  0.0   ## time offset so crows don't all flap together

const LEVEL_RIGHT := 8700.0   ## x where a crow reappears after wrapping
const LEVEL_LEFT  := -300.0   ## x where a crow wraps (off left edge + margin)

var _t := 0.0

func _ready() -> void:
	_t     = phase_offset
	z_index = -1   # behind game objects, above parallax background (z=-10)

func _process(delta: float) -> void:
	_t        += delta
	position.x -= speed * delta
	if position.x < LEVEL_LEFT:
		position.x = LEVEL_RIGHT
	queue_redraw()

func _draw() -> void:
	# Wings animate like a real bird: tips rise on upstroke, fall on downstroke.
	# sin > 0  →  wings up  (∧ shape)
	# sin < 0  →  wings down (∨ shape)
	var flap := sin(_t * flap_freq * TAU) * bird_size * 0.65
	var col  := Color(0.06, 0.03, 0.03, 0.82)
	var s    := bird_size

	# Left wing: body centre → tip
	draw_line(Vector2(0.0, 0.0), Vector2(-s, -flap), col, 1.3)
	# Right wing: mirror
	draw_line(Vector2(0.0, 0.0), Vector2( s, -flap), col, 1.3)
	# Tiny body dot
	draw_circle(Vector2(0.0, 0.0), 0.85, col)
