extends Node2D

var height: float = 185.0
var lean:   float = 0.08

# Crown sway — gentle sinusoidal animation unique to each tree
var _sway_t:     float = 0.0
var _sway_phase: float = 0.0   # set in _ready based on position.x
const SWAY_AMP   := 2.8        # max pixel offset of crown
const SWAY_SPEED := 0.55       # cycles per second

const TREE_SPRITE_PATH := "res://assets/sprites/coconut_tree.png"
var _spr: Sprite2D = null

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
	_load_sprite()

func _load_sprite() -> void:
	# Painted Kerala palm sprite — replaces the old procedural _draw() trunk + circles.
	if not ResourceLoader.exists(TREE_SPRITE_PATH):
		return
	_spr = Sprite2D.new()
	_spr.texture  = load(TREE_SPRITE_PATH)
	_spr.centered = false   # anchor at top-left so we can position the base at origin
	# Texture is ~1024x2048 (768x1536 source upscaled). Scale so visible height matches `height`.
	var tex_h: float = float(_spr.texture.get_height())
	var s: float = height / tex_h
	_spr.scale = Vector2(s, s)
	# Position the sprite so its bottom-center sits at the tree's origin (0,0 in local).
	var tex_w: float = float(_spr.texture.get_width()) * s
	_spr.position = Vector2(-tex_w * 0.5, -height)
	# Draw the sprite BEHIND the climb/crown areas so collision hover still works.
	_spr.z_index = -1
	add_child(_spr)

func _process(delta: float) -> void:
	_sway_t += delta * SWAY_SPEED
	if _spr != null:
		# Gentle rotation sway — pivot from the trunk base.
		var sway := sin(_sway_t * TAU + _sway_phase)
		_spr.rotation = sway * 0.012   # ~0.7° max tilt
	# Keep the crown area in sync with the sway crown position
	$CrownArea.position = get_crown_position() - position

func _on_climb_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_tree = self

func _on_climb_trigger_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.near_tree == self:
		body.near_tree = null

func _on_crown_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.perch_on(self)
