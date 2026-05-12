extends CanvasLayer

var _hint_timer:    float  = 0.0
var _active_quest:  String = ""

func _ready() -> void:
	add_to_group("hud")
	# Listen for quest updates to refresh the tracker
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm != null:
		qm.quest_updated.connect(_on_quest_updated)

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

func _on_quest_updated(quest_id: String, new_state: int) -> void:
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm == null: return
	if new_state == 1:   # ACTIVE
		_active_quest = quest_id
		$QuestPanel/QuestTitle.text = "📜 " + qm.get_title(quest_id)
		_refresh_quest_bar()
		$QuestPanel.visible = true
	elif new_state == 2:   # DONE
		if _active_quest == quest_id:
			$QuestPanel/QuestTitle.text = "✅ " + qm.get_title(quest_id)
			$QuestPanel/QuestProgress.text = "Complete!"
			$QuestPanel/QuestBar.value = $QuestPanel/QuestBar.max_value
			get_tree().create_timer(3.5).timeout.connect(func() -> void:
				$QuestPanel.visible = false
				_active_quest = ""
			)

func _refresh_quest_bar() -> void:
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm == null or _active_quest.is_empty(): return
	var prog:  int = qm.get_progress(_active_quest)
	var total: int = qm.get_total(_active_quest)
	$QuestPanel/QuestProgress.text = "%d / %d" % [prog, total]
	$QuestPanel/QuestBar.max_value = total
	$QuestPanel/QuestBar.value     = prog
