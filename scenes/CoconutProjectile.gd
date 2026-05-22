extends Area2D

const GRAVITY := 1800.0
const DAMAGE  := 25

var velocity := Vector2.ZERO

func _ready() -> void:
	add_to_group("coconut")
	collision_layer = 16  # layer 5 — lets bells/targets detect the coconut
	collision_mask  = 4   # hits Enemies (layer 3)
	body_entered.connect(_on_body_entered)
	# Visual: dark brown coconut with lighter husk ring
	$Visual.color = Color(0.28, 0.16, 0.05)
	# Husk highlight ring
	var ring := ColorRect.new()
	ring.color    = Color(0.55, 0.38, 0.18)
	ring.size     = Vector2(8, 8)
	ring.position = Vector2(-4, -4)
	$Visual.add_child(ring)
	# ── Bhadrakali blessing glow ──────────────────────────────────────────────
	# The coconut carries the goddess's mark. Sacred gold aura, always visible.
	var glow := ColorRect.new()
	glow.color         = Color(1.0, 0.72, 0.08, 0.38)
	glow.size          = Vector2(26.0, 26.0)
	glow.position      = Vector2(-13.0, -13.0)
	glow.z_index       = -1
	$Visual.add_child(glow)
	# Pulse the glow — it breathes like a living blessing
	var glow_tw := create_tween()
	glow_tw.set_loops()
	glow_tw.tween_property(glow, "modulate:a", 0.18, 0.22)
	glow_tw.tween_property(glow, "modulate:a", 1.00, 0.22)

func launch(dir: int) -> void:
	velocity = Vector2(dir * 420.0, -300.0)

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position   += velocity * delta
	# Spin the coconut while airborne
	$Visual.rotation += delta * 8.0
	# Proximity hit — catches Node2D bosses (Karinkanni, Yakshi, etc.)
	# that don't have a PhysicsBody2D child for body_entered to detect.
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy): continue
		if enemy is Node2D and global_position.distance_to((enemy as Node2D).global_position) < 40.0:
			_hit_enemy(enemy)
			return
	# Despawn if off-screen
	if position.y > 600.0 or absf(position.x) > 9000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		_hit_enemy(body)
	else:
		queue_free()

func _hit_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy): return
	if enemy.has_method("take_damage"):
		enemy.take_damage(DAMAGE * GameManager.damage_multiplier())
	_spawn_blessing_burst()
	queue_free()

## Bhadrakali impact burst — sacred red-gold particles where the coconut lands.
## Visual language: this is not a normal hit. The goddess's power makes contact.
func _spawn_blessing_burst() -> void:
	var burst := CPUParticles2D.new()
	burst.emitting              = true
	burst.one_shot              = true
	burst.amount                = 10
	burst.lifetime              = 0.45
	burst.emission_shape        = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 4.0
	burst.direction             = Vector2(0.0, -1.0)
	burst.spread                = 180.0
	burst.gravity               = Vector2(0.0, 120.0)
	burst.initial_velocity_min  = 55.0
	burst.initial_velocity_max  = 110.0
	burst.scale_amount_min      = 3.0
	burst.scale_amount_max      = 6.0
	burst.color                 = Color(1.0, 0.75, 0.10, 1.0)   # sacred gold
	burst.global_position       = global_position
	get_parent().add_child(burst)
	# Red flash on the burst peak — Bhadrakali's vermillion
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if is_instance_valid(burst):
			burst.color = Color(0.88, 0.12, 0.05, 0.80)
	)
	get_tree().create_timer(0.55).timeout.connect(func() -> void:
		if is_instance_valid(burst): burst.queue_free()
	)
