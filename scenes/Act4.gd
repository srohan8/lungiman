extends "res://scenes/BaseAct.gd"

## Act IV — Karinkanni's Curse
## Rain-drenched mangroves. Karinkanni floats at y~315 (above tree crowns at y~350).
## MUST be on a tree crown to hit her with coconuts.

const NEXT_SCENE    := "res://scenes/Pathalam.tscn"   # IV.5 interlude before the finale
const ACT_TRIGGER_X := 7800.0

const ZONE_TREES   := 22
const ZONE_X_FROM  := 200.0
const ZONE_X_TO    := 7600.0
const ZONE_H       := 350.0   # crown y≈350 (GROUND_Y now 700, trunk longer)

func _ready() -> void:
	_next_scene  = NEXT_SCENE
	_trigger_x   = ACT_TRIGGER_X
	_unlocks_act = 5
	_init_sprite_parallax(Color(0.06, 0.12, 0.08),   # rain-soaked mangrove dark green
			"res://assets/backgrounds/bg_act4.png")   # rain-drenched mangroves with exposed roots + flooded water
	_add_parallax_layers([
		# bg_act4_props.png has CHARACTERS — intentionally skipped
		# Full-colour scenes: MAX alpha 0.18 — any higher = muddy colour soup over the base
		{"path": "res://assets/backgrounds/bg_act4_mountains.png",
			"scroll": 0.10, "tile": true, "alpha": 0.15},   # mangrove village + stilt houses (far ghost)
		{"path": "res://assets/backgrounds/bg_act4_trees.png",
			"scroll": 0.24, "tile": true, "alpha": 0.18},   # mangrove roots in water (near ghost)
	])
	_spawn_trees()
	_spawn_karinkanni()
	_spawn_powerups()
	_spawn_npcs()
	_spawn_props()
	_spawn_rising_water()
	_spawn_rain()
	_connect_player_to_hud()
	# Karinkanni hint fires early so players know BEFORE they waste ammo from ground
	_queue_hint("🥥 CLIMB a tree — Karinkanni floats too high to hit from the ground!", 1.5, 7.0)

func _spawn_trees() -> void:
	var tint := Color(0.3, 0.5, 0.4, 1.0)   # dark rain-soaked green
	var xs   := _linspace(ZONE_X_FROM, ZONE_X_TO, ZONE_TREES)
	for i: int in xs.size():
		_add_tree($Trees, xs[i], ZONE_H, 0.04 * (1 if i % 2 == 0 else -1), tint)

func _spawn_karinkanni() -> void:
	var boss: Node2D = preload("res://scenes/Karinkanni.tscn").instantiate()
	boss.position = Vector2(4000.0, 315.0)
	$Enemies.add_child(boss)

func _spawn_powerups() -> void:
	var data := [
		[600.0,  GROUND_Y, "nut"],
		[2000.0, GROUND_Y, "heart"],
		[3500.0, GROUND_Y, "nut"],
		[5000.0, GROUND_Y, "toddy"],
		[6500.0, GROUND_Y, "heart"],
	]
	for d: Array in data:
		_add_powerup($PowerUps, d[0], float(d[1]), d[2])

func _spawn_npcs() -> void:
	var thoma: Node2D = preload("res://scenes/BrotherThoma.tscn").instantiate()
	thoma.position = Vector2(200.0, GROUND_Y)
	add_child(thoma)
	var soniya: Node2D = preload("res://scenes/SoniyaChechi.tscn").instantiate()
	soniya.position = Vector2(500.0, GROUND_Y)
	add_child(soniya)
	# Sr. Devi — Bell of Bhadrakali quest giver (Phase 5 quest, NPC present now)
	var devi: Node2D = preload("res://scenes/SrDevi.tscn").instantiate()
	devi.position = Vector2(1400.0, GROUND_Y)
	add_child(devi)

func _spawn_props() -> void:
	_build_raft(200.0)          # Thoma's half-built escape raft
	_build_flooded_hut(500.0)   # Soniya's flooded hut (chai still on)
	_build_shrine(1400.0)       # Sr. Devi's riverside shrine

## Thoma's escape raft — planks lashed together, rope visible
func _build_raft(x: float) -> void:
	# Main plank body
	var raft := ColorRect.new()
	raft.size     = Vector2(82.0, 12.0)
	raft.position = Vector2(x - 41.0, GROUND_Y - 12.0)
	raft.color    = Color(0.42, 0.28, 0.12, 1.0)
	raft.z_index  = 1
	add_child(raft)
	# Plank groove lines
	for i: int in 4:
		var groove := ColorRect.new()
		groove.size     = Vector2(2.0, 12.0)
		groove.position = Vector2(x - 30.0 + float(i) * 18.0, GROUND_Y - 12.0)
		groove.color    = Color(0.28, 0.18, 0.07, 0.70)
		groove.z_index  = 2
		add_child(groove)
	# Rope binding on edge
	var rope := ColorRect.new()
	rope.size     = Vector2(6.0, 4.0)
	rope.position = Vector2(x + 37.0, GROUND_Y - 16.0)
	rope.color    = Color(0.76, 0.62, 0.36, 1.0)
	rope.z_index  = 2
	add_child(rope)

## Soniya's flooded hut — walls + palm-leaf roof + water stain mark
func _build_flooded_hut(x: float) -> void:
	# Hut back wall
	var wall := ColorRect.new()
	wall.size     = Vector2(80.0, 68.0)
	wall.position = Vector2(x - 40.0, GROUND_Y - 68.0)
	wall.color    = Color(0.28, 0.20, 0.12, 1.0)
	wall.z_index  = 1
	add_child(wall)
	# Left roof slope
	var roof_l := ColorRect.new()
	roof_l.size     = Vector2(50.0, 14.0)
	roof_l.position = Vector2(x - 48.0, GROUND_Y - 82.0)
	roof_l.color    = Color(0.26, 0.36, 0.12, 1.0)
	roof_l.z_index  = 2
	add_child(roof_l)
	# Right roof slope
	var roof_r := ColorRect.new()
	roof_r.size     = Vector2(50.0, 14.0)
	roof_r.position = Vector2(x - 2.0, GROUND_Y - 82.0)
	roof_r.color    = Color(0.26, 0.36, 0.12, 1.0)
	roof_r.z_index  = 2
	add_child(roof_r)
	# Door
	var door := ColorRect.new()
	door.size     = Vector2(22.0, 34.0)
	door.position = Vector2(x - 11.0, GROUND_Y - 34.0)
	door.color    = Color(0.18, 0.12, 0.06, 1.0)
	door.z_index  = 2
	add_child(door)
	# Flood waterline stain on lower wall
	var stain := ColorRect.new()
	stain.size     = Vector2(80.0, 16.0)
	stain.position = Vector2(x - 40.0, GROUND_Y - 16.0)
	stain.color    = Color(0.22, 0.42, 0.70, 0.40)
	stain.z_index  = 3
	add_child(stain)

## Sr. Devi's riverside shrine — Scenario.gg sprite (shrine_sheet.png).
## image 4800×3584; scale 0.030 → content bottom 48px below sprite centre.
func _build_shrine(x: float) -> void:
	_prop_sprite("res://assets/sprites/shrine_sheet.png",
			x, GROUND_Y - 48.0, 0.030, 1)

## Rising water visual — cosmetic pressure. Water line creeps up over 90 seconds.
func _spawn_rising_water() -> void:
	var water := ColorRect.new()
	water.color    = Color(0.06, 0.18, 0.55, 0.50)
	water.size     = Vector2(8200.0, 30.0)
	water.position = Vector2(0.0, GROUND_Y - 5.0)
	water.z_index  = 2
	add_child(water)
	# Slow tween upward — purely visual, creates urgency without instant death
	var tw := create_tween()
	tw.tween_property(water, "position:y", GROUND_Y - 80.0, 90.0)
	# Rain drops visual — thin streaks falling
	for i: int in 18:
		var drop := ColorRect.new()
		drop.color    = Color(0.5, 0.7, 1.0, 0.30)
		drop.size     = Vector2(2.0, 14.0)
		drop.position = Vector2(randf_range(0.0, 8200.0), randf_range(0.0, 720.0))
		drop.z_index  = 3
		add_child(drop)
		var dt := create_tween()
		dt.set_loops()
		dt.tween_property(drop, "position:y", drop.position.y + 720.0, randf_range(1.2, 2.2))
		dt.tween_property(drop, "position:y", -14.0, 0.0)

## Screen-space CPUParticles2D rain — CanvasLayer so it follows the camera.
func _spawn_rain() -> void:
	var cl := CanvasLayer.new()
	cl.name  = "RainLayer"
	cl.layer = 8
	var p := CPUParticles2D.new()
	p.emitting               = true
	p.amount                 = 180
	p.lifetime               = 0.75
	p.emission_shape         = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents  = Vector2(640, 8)
	p.position               = Vector2(410, -8)
	p.direction              = Vector2(0.12, 1.0).normalized()
	p.spread                 = 3.0
	p.gravity                = Vector2(0, 0)
	p.initial_velocity_min   = 440.0
	p.initial_velocity_max   = 520.0
	p.color                  = Color(0.6, 0.78, 1.0, 0.38)
	p.scale_amount_min       = 2.0
	p.scale_amount_max       = 5.0
	cl.add_child(p)
	add_child(cl)
