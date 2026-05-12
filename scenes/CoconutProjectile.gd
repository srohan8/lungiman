extends Area2D

const GRAVITY := 1800.0
const DAMAGE  := 25

var velocity := Vector2.ZERO

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 4   # hits Enemies (layer 3)
	body_entered.connect(_on_body_entered)

func launch(dir: int) -> void:
	velocity = Vector2(dir * 420.0, -300.0)

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position   += velocity * delta
	# Despawn if off-screen
	if position.y > 600.0 or absf(position.x) > 9000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(DAMAGE * GameManager.damage_multiplier())
	queue_free()
