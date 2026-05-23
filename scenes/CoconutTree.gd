extends Node2D

var height: float = 185.0
var lean:   float = 0.08

const TREE_SPRITE_PATH := "res://assets/sprites/coconut_tree.png"
var _spr: Sprite2D = null

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
	$CrownArea.position = get_crown_position() - position
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
	_spr.z_index = 6   # world z=6 (tree node z=0 + local 6) renders in front of ground tile (z=5)
	add_child(_spr)

func _process(_delta: float) -> void:
	# Trunk stays still — bend only happens via set_catapult_bend() when player charges.
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

## Called by Player while charging catapult. Bends the trunk toward direction.
## charge: 0.0–1.0   direction: +1=right, -1=left
func set_catapult_bend(charge: float, direction: int) -> void:
	if _spr == null: return
	_spr.rotation = float(direction) * charge * 0.36   # max ~21° lean

## Called when player fires or aborts. Springs trunk back to vertical.
func spring_back() -> void:
	if _spr == null: return
	var tw := create_tween()
	tw.tween_property(_spr, "rotation", 0.0, 0.50)\
		.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
