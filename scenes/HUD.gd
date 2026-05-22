extends CanvasLayer

var _hint_timer:    float  = 0.0
var _active_quest:  String = ""
var _lamp_glow:     ColorRect = null   # warm glow behind the Nilavilakku
var _lamp_flicker_t: float = 0.0      # flicker phase for critical state

## Nilavilakku (oil lamp) — the 5 states of LungiMan's life force.
## No number, no bar. The player reads health from the flame, like a real lamp.
##
## Full (100%)   : 🪔  tall amber flame    — WARM_GOLD
## Steady (75%)  : 🪔  steady burn         — AMBER
## Low (50%)     : 🪔  lower, dimmer       — DEEP_ORANGE
## Flickering(25%): 🕯️ struggling           — RED_ORANGE
## Sputtering(<25%): 🕯️ nearly out         — DEEP_RED (flickers in code)
## Maveli blessed : 🪔  gold, not orange   — SACRED_GOLD (lasts for Act V)
const LAMP_FULL      := Color(1.00, 0.72, 0.18, 1.0)
const LAMP_STEADY    := Color(1.00, 0.58, 0.10, 1.0)
const LAMP_LOW       := Color(1.00, 0.40, 0.04, 0.88)
const LAMP_FLICKER   := Color(1.00, 0.22, 0.02, 0.75)
const LAMP_SPUTTER   := Color(0.78, 0.10, 0.00, 0.60)
const LAMP_MAVELI    := Color(1.00, 0.88, 0.25, 1.0)   # sacred gold

func _ready() -> void:
	add_to_group("hud")
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm != null:
		qm.quest_updated.connect(_on_quest_updated)
	# Build lamp glow node — warm circle behind LblHP
	if has_node("Stats/LblHP"):
		_lamp_glow = ColorRect.new()
		_lamp_glow.color         = Color(1.0, 0.65, 0.1, 0.0)
		_lamp_glow.size          = Vector2(36.0, 36.0)
		_lamp_glow.position      = Vector2(-4.0, -4.0)
		_lamp_glow.z_index       = -1
		$Stats/LblHP.add_child(_lamp_glow)

func _process(delta: float) -> void:
	_update_nilavilakku(delta)
	$Stats/LblAmmo.text  = "🥥 %d"  % GameManager.ammo
	$Stats/LblScore.text = "Score: %d" % GameManager.score

	# Boss bar — only reveal after first hit (boss_visible) to avoid showing bar at scene load
	if GameManager.boss_visible and GameManager.boss_max_hp > 0:
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
		elif GameManager.fish_fry_active:
			lbl.text    = "🐟 Fish Fry!"
			lbl.visible = true
		else:
			lbl.visible = false

	# Hint timer
	if _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			$HintLabel.visible = false

## Nilavilakku — reads GRIT ratio + maveli_blessed flag, updates lamp flame.
## HP goes up/down with combat — the lamp shows the JOURNEY cost (grit), not the fight.
func _update_nilavilakku(delta: float) -> void:
	if not has_node("Stats/LblHP"): return
	var ratio: float = float(GameManager.grit) / 100.0
	var blessed: bool = GameManager.get("maveli_blessed") == true

	var flame:      String
	var col:        Color
	var glow_alpha: float

	if blessed and ratio > 0.10:
		flame      = "🪔"
		col        = LAMP_MAVELI
		glow_alpha = 0.92
	elif ratio >= 0.75:
		flame      = "🪔"
		col        = LAMP_FULL
		glow_alpha = 0.80
	elif ratio >= 0.50:
		flame      = "🪔"
		col        = LAMP_STEADY
		glow_alpha = 0.58
	elif ratio >= 0.25:
		flame      = "🪔"
		col        = LAMP_LOW
		glow_alpha = 0.35
	elif ratio >= 0.10:
		# Flickering — grit 10–25% (after Karinkanni defeat, before Maveli)
		_lamp_flicker_t += delta * 5.5
		flame      = "🕯️"
		col        = LAMP_FLICKER
		glow_alpha = 0.20 + 0.08 * ((sin(_lamp_flicker_t) + 1.0) * 0.5)
	else:
		# Sputtering — flicker the glow alpha in code
		_lamp_flicker_t += delta * 8.0
		flame      = "🕯️"
		col        = LAMP_SPUTTER.lerp(LAMP_FLICKER, (sin(_lamp_flicker_t) + 1.0) * 0.5)
		glow_alpha = 0.10 + 0.18 * ((sin(_lamp_flicker_t * 1.3) + 1.0) * 0.5)

	$Stats/LblHP.text = flame
	$Stats/LblHP.add_theme_color_override("font_color", col)
	if _lamp_glow != null:
		_lamp_glow.color   = Color(col.r, col.g * 0.8, col.b * 0.2, glow_alpha * 0.5)

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
