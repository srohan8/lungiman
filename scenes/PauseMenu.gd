extends CanvasLayer

## PauseMenu — Escape toggles overlay. Resume / Settings / Main Menu.
## Added to scene tree by BaseAct; removed on scene change.

func _ready() -> void:
	layer        = 20
	visible      = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$BG/Center/VBox/ResumeBtn.pressed.connect(_on_resume)
	$BG/Center/VBox/SettingsBtn.pressed.connect(_on_settings)
	$BG/Center/VBox/MenuBtn.pressed.connect(_on_main_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("ui_cancel"):
		_toggle()

func _toggle() -> void:
	visible = not visible
	Engine.time_scale = 0.0 if visible else 1.0
	get_tree().paused  = visible

func _on_resume() -> void:
	_toggle()

func _on_settings() -> void:
	var s: Node = preload("res://scenes/Settings.tscn").instantiate()
	get_tree().root.add_child(s)

func _on_main_menu() -> void:
	Engine.time_scale  = 1.0
	get_tree().paused  = false
	SceneManager.go_to("res://scenes/MainMenu.tscn")
