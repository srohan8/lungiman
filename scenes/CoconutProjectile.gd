extends Area2D

const GRAVITY := 1800.0
const DAMAGE  := 25

var velocity := Vector2.ZERO

func _ready() -> void:
	add_to_group("coconut")
	collision_layer = 16  # layer 5 — lets bells/targets detect the coconut
	collision_mask  = 4   # hits Enemies (layer 3)
	body_entered.connect(_on_body_entered)
	# ── Coconut sprite — real image, spins while airborne ─────────────────────
	const COCO_PATH := "res://assets/sprites/COCNUT.png"
	$Visual.color = Color(0, 0, 0, 0)   # hide the placeholder ColorRect
	if ResourceLoader.exists(COCO_PATH):
		var tex := load(COCO_PATH) as Texture2D
		var spr := Sprite2D.new()
		spr.texture = tex
		# Scale to 36px tall — visible from across the screen, not overwhelming
		var scale_f := 36.0 / maxf(tex.get_height(), 1.0)
		spr.scale = Vector2(scale_f, scale_f)
		$Visual.add_child(spr)
	else:
		# Fallback if asset missing — restore plain brown shape
		$Visual.color = Color(0.28, 0.16, 0.05)
		var ring := ColorRect.new()
		ring.color    = Color(0.55, 0.38, 0.18)
		ring.size     = Vector2(8, 8)
		ring.position = Vector2(-4, -4)
		$Visual.add_child(ring)
	# ── Bhadrakali blessing glow ──────────────────────────────────────────────
	# The coconut carries the goddess's mark. Sacred gold aura, always visible.
	var glow := ColorRect.new()
	glow.color         = Color(1.0, 0.72, 0.08, 0.38)
	glow.size          = Vector2(44.0, 44.0)
	glow.position      = Vector2(-22.0, -22.0)
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
	# ── Bright impact flash — confirms the hit instantly ──────────────────────
	var flash := ColorRect.new()
	flash.color    = Color(1.0, 0.85, 0.20, 0.85)   # hot gold
	flash.size     = Vector2(48.0, 48.0)
	flash.position = Vector2(-24.0, -24.0)
	flash.z_index  = 20
	get_parent().add_child(flash)
	flash.global_position = global_position + Vector2(-24.0, -24.0)
	var flash_tw := flash.create_tween()
	flash_tw.tween_property(flash, "modulate:a", 0.0, 0.18)
	flash_tw.tween_callback(flash.queue_free)

	# ── Gold → vermillion particle spray ─────────────────────────────────────
	var burst := CPUParticles2D.new()
	burst.emitting               = true
	burst.one_shot               = true
	burst.amount                 = 18
	burst.lifetime               = 0.55
	burst.emission_shape         = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 5.0
	burst.direction              = Vector2(0.0, -1.0)
	burst.spread                 = 180.0
	burst.gravity                = Vector2(0.0, 160.0)
	burst.initial_velocity_min   = 70.0
	burst.initial_velocity_max   = 140.0
	burst.scale_amount_min       = 3.0
	burst.scale_amount_max       = 7.0
	burst.color                  = Color(1.0, 0.75, 0.10, 1.0)   # sacred gold
	burst.global_position        = global_position
	get_parent().add_child(burst)
	# Shift to Bhadrakali's vermillion at burst peak
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if is_instance_valid(burst):
			burst.color = Color(0.88, 0.12, 0.05, 0.80)
	)
	get_tree().create_timer(0.65).timeout.connect(func() -> void:
		if is_instance_valid(burst): burst.queue_free()
	)
