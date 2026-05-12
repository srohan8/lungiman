extends CanvasLayer

func _ready() -> void:
	visible = false
	GameManager.game_won.connect(show_victory)

func show_victory() -> void:
	Engine.time_scale = 1.0   # ensure slow-mo is cleared
	$Center/VBox/TitleLabel.text  = "🌴 KANJIRAVANAM SAVED!"
	var hs_tag := " 🏆 NEW BEST!" if GameManager.score >= GameManager.high_score and GameManager.score > 0 else ""
	$Center/VBox/ScoreLabel.text  = "Final Score: %d%s" % [GameManager.score, hs_tag]
	$Center/VBox/QuoteA.text      = "“Kanjiravanam breathes again.”"
	$Center/VBox/QuoteB.text      = "✂️ “I told you. Stay on the trees.”"
	$Center/VBox/QuoteC.text      = "☕ “...want chai?”"
	visible           = true
	get_tree().paused = true
	# Dramatic fade-in via child container
	$Center.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property($Center, "modulate:a", 1.0, 1.2)

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	SceneManager.go_to("res://scenes/World.tscn")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	SceneManager.go_to("res://scenes/MainMenu.tscn")
