extends CanvasLayer

func _ready() -> void:
	visible = false
	GameManager.game_won.connect(show_victory)

func show_victory() -> void:
	$Center/VBox/ScoreLabel.text = "Final Score: %d" % GameManager.score
	visible           = true
	get_tree().paused = true

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	SceneManager.go_to("res://scenes/World.tscn")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	SceneManager.go_to("res://scenes/MainMenu.tscn")
