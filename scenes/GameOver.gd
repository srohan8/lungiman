extends CanvasLayer

func _ready() -> void:
	visible = false
	GameManager.player_died.connect(show_game_over)

func show_game_over() -> void:
	visible           = true
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	SceneManager.reload()   # restart the same act, not World

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	SceneManager.go_to("res://scenes/MainMenu.tscn")
