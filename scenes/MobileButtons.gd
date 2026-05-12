extends CanvasLayer

const ACTION_MAP := {
	"BtnLeft":   "move_left",
	"BtnRight":  "move_right",
	"BtnUp":     "jump",
	"BtnDown":   "move_down",
	"BtnSword":  "sword",
	"BtnCoconut":"coconut",
}

func _ready() -> void:
	for btn_name: String in ACTION_MAP:
		if has_node(btn_name):
			var btn: Button = get_node(btn_name)
			btn.button_down.connect(_on_pressed.bind(btn_name))
			btn.button_up.connect(_on_released.bind(btn_name))
	if has_node("BtnClimb"):
		$BtnClimb.button_down.connect(_on_climb_pressed)

func _on_pressed(btn_name: String) -> void:
	Input.action_press(ACTION_MAP[btn_name])

func _on_released(btn_name: String) -> void:
	Input.action_release(ACTION_MAP[btn_name])

func _on_climb_pressed() -> void:
	GameManager.climb_press_pending = true
