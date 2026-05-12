extends CharacterBody2D

## Lightweight patrol guard for the Houseboat sub-scene.
## State stored as node metadata by Houseboat.gd at spawn time.

const SPEED   := 60.0
const GRAVITY := 1800.0
const DMG     := 12

var _hit_cd := 0.0

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	var dir: int    = get_meta("patrol_dir", 1)
	var left: float = get_meta("patrol_left",  position.x - 60.0)
	var right: float= get_meta("patrol_right", position.x + 60.0)
	velocity.x = SPEED * dir
	if position.x <= left:  set_meta("patrol_dir",  1)
	if position.x >= right: set_meta("patrol_dir", -1)
	_hit_cd = maxf(0.0, _hit_cd - delta)
	move_and_slide()
	# Contact damage
	for i: int in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other and other.is_in_group("player") and _hit_cd <= 0.0:
			other.take_damage(DMG)
			_hit_cd = 1.2

func take_damage(dmg: int) -> void:
	var hp: int = get_meta("hp", 2)
	hp -= dmg
	set_meta("hp", hp)
	modulate = Color(1.0, 0.3, 0.3)
	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		if is_inside_tree(): modulate = Color.WHITE
	)
	if hp <= 0:
		GameManager.score += 20
		GameManager.show_score_popup(position + Vector2(0, -30), 20, Color(0.7, 0.8, 1.0))
		queue_free()
