extends CanvasLayer

var _hint_timer: float = 0.0

func _process(delta: float) -> void:
	$Stats/LblHP.text    = "HP: %d" % GameManager.hp
	$Stats/LblAmmo.text  = "🥥 %d"  % GameManager.ammo
	$Stats/LblScore.text = "Score: %d" % GameManager.score

	# Boss bar
	if GameManager.boss_max_hp > 0:
		$BossBarContainer.visible   = true
		$BossBarContainer/BossBar.max_value   = GameManager.boss_max_hp
		$BossBarContainer/BossBar.value       = GameManager.boss_hp
		$BossBarContainer/BossBarLabel.text   = "BOSS  %d / %d" % [GameManager.boss_hp, GameManager.boss_max_hp]
	else:
		$BossBarContainer.visible = false

	# Toddy dizzy indicator
	if has_node("StatusLabel"):
		var lbl := $StatusLabel
		if GameManager.toddy_active:
			lbl.text    = "🏺 Dizzy!"
			lbl.visible = true
		elif GameManager.hypnosis_active:
			lbl.text    = "👁 Hypnotised!"
			lbl.visible = true
		elif GameManager.paralysis_active:
			lbl.text    = "❄️ Paralysed!"
			lbl.visible = true
		else:
			lbl.visible = false

	# Hint timer
	if _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			$HintLabel.visible = false

func show_climb_prompt(climb_visible: bool) -> void:
	$ClimbPrompt.visible = climb_visible

func show_hint(text: String, duration: float = 4.0) -> void:
	$HintLabel.text    = text
	$HintLabel.visible = true
	_hint_timer        = duration
