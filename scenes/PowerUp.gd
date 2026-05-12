extends Area2D

var type:  String = "heart"
var bob_t: float  = 0.0

const ICONS := {
	"heart":       "❤️",
	"nut":         "🥥",
	"porotta":     "🫓",
	"toddy":       "🏺",
	"chai":        "☕",
	"resurrection":"🪙",
}

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	$Label.text     = ICONS.get(type, "?")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob_t      += delta * 3.0
	position.y += sin(bob_t) * 0.5

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.apply_powerup(type)
		queue_free()
