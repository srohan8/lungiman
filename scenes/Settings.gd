extends CanvasLayer

## Settings screen — music/SFX volume sliders, back button.
## Pushed on top of MainMenu via SceneManager or direct add_child.

func _ready() -> void:
	$Center/VBox/MusicSlider.value = AudioManager.music_volume * 100.0
	$Center/VBox/SFXSlider.value   = AudioManager.sfx_volume   * 100.0
	$Center/VBox/MusicSlider.value_changed.connect(_on_music_changed)
	$Center/VBox/SFXSlider.value_changed.connect(_on_sfx_changed)
	$Center/VBox/BackBtn.pressed.connect(_on_back)

func _on_music_changed(val: float) -> void:
	AudioManager.set_music_volume(val / 100.0)
	$Center/VBox/MusicValue.text = "%d%%" % int(val)

func _on_sfx_changed(val: float) -> void:
	AudioManager.set_sfx_volume(val / 100.0)
	$Center/VBox/SFXValue.text = "%d%%" % int(val)

func _on_back() -> void:
	queue_free()
