extends Control

## MainMenu — Kerala-styled title screen.
## Panels: main (Play / Level Select / Quests) and quests (inline overlay).

const COL_BG      := Color(0.04, 0.10, 0.06)        # deep forest night
const COL_PANEL   := Color(0.06, 0.16, 0.09, 0.95)  # dark canopy
const COL_GOLD    := Color(1.00, 0.84, 0.28)         # temple gold
const COL_MUTED   := Color(0.70, 0.90, 0.65)         # moonlit leaf
const COL_BTN     := Color(0.10, 0.28, 0.14)         # dark teal
const COL_BTN_HOV := Color(0.16, 0.40, 0.20)         # hover brightened
const COL_LOCKED  := Color(0.25, 0.25, 0.25)
const COL_DONE    := Color(0.20, 0.65, 0.35)
const COL_ACTIVE  := Color(0.85, 0.70, 0.15)

var _main_panel:   Control
var _quest_panel:  Control
var _qm:           Node     # QuestManager — resolved at runtime via /root path

# Quest state ints (mirrors QuestManager.QuestState to avoid compile-time autoload lookup)
const _QS_LOCKED := 0
const _QS_ACTIVE := 1
const _QS_DONE   := 2

func _ready() -> void:
	_qm = get_node_or_null("/root/QuestManager")
	# Load persistent save data on every MainMenu visit
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null: sm.load_game()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_main_panel  = _build_main_panel()
	_quest_panel = _build_quest_panel()
	_quest_panel.visible = false
	add_child(_main_panel)
	add_child(_quest_panel)

# ── Background ────────────────────────────────────────────────────────────────

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Silhouette trees — simple dark rects suggest a treeline
	for i: int in 14:
		var trunk := ColorRect.new()
		trunk.color = Color(0.02, 0.07, 0.03)
		var tw := randf_range(8.0, 18.0)
		var th := randf_range(90.0, 180.0)
		trunk.size     = Vector2(tw, th)
		trunk.position = Vector2(i * 62.0 + randf_range(-10, 10),
				460.0 - th + randf_range(-10, 20))
		add_child(trunk)


# ── Main Panel ────────────────────────────────────────────────────────────────

func _build_main_panel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(360, 0)
	vbox.offset_left   = -180
	vbox.offset_right  =  180
	vbox.offset_top    = -132
	vbox.offset_bottom =  132
	vbox.add_theme_constant_override("separation", 4)   # tight stack so all 5 buttons fit

	# Title
	var title := Label.new()
	title.text = "🌴 Kanjiravanam Chronicles"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COL_GOLD)
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "A Kerala Mythology Platformer"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", COL_MUTED)
	sub.add_theme_font_size_override("font_size", 10)
	vbox.add_child(sub)

	# High score
	if GameManager.high_score > 0:
		var hs := Label.new()
		hs.text = "🏆 Best: %d" % GameManager.high_score
		hs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hs.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28, 0.75))
		hs.add_theme_font_size_override("font_size", 11)
		vbox.add_child(hs)

	# Spacer
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(sp)

	# Buttons
	var sm := get_node_or_null("/root/SaveManager")
	var has_save: bool = sm != null and sm.has_save()

	if has_save:
		var btn_continue := _make_button("▶  Continue")
		btn_continue.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		btn_continue.pressed.connect(func() -> void:
			SceneManager.go_to("res://scenes/World.tscn")
		)
		vbox.add_child(btn_continue)

	var btn_play     := _make_button("🌱  New Game" if has_save else "▶  New Game")
	var btn_level    := _make_button("🗺  Level Select")
	var btn_quest    := _make_button("📜  Side Quests")
	var btn_settings := _make_button("⚙️  Settings")

	btn_play.pressed.connect(func() -> void:
		if sm != null: sm.delete_save()
		GameManager.reset()
		if _qm != null: _qm.reset()
		SceneManager.go_to("res://scenes/World.tscn")
	)
	btn_level.pressed.connect(_open_level_select)
	btn_quest.pressed.connect(func() -> void:
		_refresh_quest_panel()
		_quest_panel.visible = true
		_main_panel.visible  = false
	)
	btn_settings.pressed.connect(func() -> void:
		var s: Node = preload("res://scenes/Settings.tscn").instantiate()
		get_tree().root.add_child(s)
	)

	vbox.add_child(btn_play)
	vbox.add_child(btn_level)
	vbox.add_child(btn_quest)
	vbox.add_child(btn_settings)
	root.add_child(vbox)
	return root


# ── Level Select (inline) ─────────────────────────────────────────────────────

func _open_level_select() -> void:
	# Rebuild to refresh unlock + quest state every open
	var existing := get_node_or_null("LevelSelectPanel")
	if existing: existing.queue_free()

	# Hide the main panel so the level-select overlay doesn't bleed visually into it
	_main_panel.visible = false

	var root := Control.new()
	root.name = "LevelSelectPanel"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dim backdrop
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	# ── Outer panel — uses nearly the full 480×270 viewport so both Acts AND
	# Side Quests fit on-screen without scrolling. (Previously offset_bottom=120
	# made the panel 240 tall, hiding the Side Quests section below the fold.)
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	outer.custom_minimum_size = Vector2(456, 0)
	outer.offset_left   = -232
	outer.offset_right  =  232
	outer.offset_top    = -134
	outer.offset_bottom =  134
	outer.add_theme_constant_override("separation", 2)

	var panel_bg := ColorRect.new()
	panel_bg.color = COL_PANEL
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.z_index = -1
	root.add_child(panel_bg)
	panel_bg.offset_left   = outer.offset_left   - 10
	panel_bg.offset_right  = outer.offset_right  + 10
	panel_bg.offset_top    = outer.offset_top    - 10
	panel_bg.offset_bottom = outer.offset_bottom + 10

	# Header (outside scroll — always visible)
	var hdr := Label.new()
	hdr.text = "🗺  Select Level"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_color_override("font_color", COL_GOLD)
	hdr.add_theme_font_size_override("font_size", 18)
	outer.add_child(hdr)

	# ── ScrollContainer holds all the cards ──────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = false   # don't auto-scroll when a button gains focus
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)   # tight: every row counts
	scroll.add_child(content)

	# ── Acts section (no section header — the grid layout itself separates from
	# the Side Quests list visually via the gold divider line below it).

	# 4 columns × 2 rows packs 8 acts into ~half the vertical space of a 2-col grid,
	# freeing up room for the Side Quests section below the divider.
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)

	const LEVELS: Array = [
		["🌅  Prologue",               "res://scenes/World.tscn",     0],
		["🏍  Bike Ride",               "res://scenes/BikeRide.tscn",  1],
		["🌿  Act I — Yakshi",          "res://scenes/Act1.tscn",      1],
		["🔥  Act II — Kuttichathan",   "res://scenes/Act2.tscn",      2],
		["🌫  Act III — Odiyan",        "res://scenes/Act3.tscn",           3],
		["✨  Disco Hallucination",     "res://scenes/DiscoHallucination.tscn", 3],
		["🌧  Act IV — Karinkanni",     "res://scenes/Act4.tscn",           4],
		["🕯  Pathalam — Maveli",       "res://scenes/Pathalam.tscn",       4],
		["🌑  Act V — Pey Komban",      "res://scenes/Act5.tscn",           5],
		["🏚  Houseboat",               "res://scenes/Houseboat.tscn", 4],
	]

	var unlocked: int = 99   # DEV: all unlocked — swap for GameManager.acts_cleared in prod

	for level_data: Array in LEVELS:
		var label_text: String = level_data[0]
		var scene_path: String = level_data[1]
		var required:   int    = level_data[2]
		var is_unlocked: bool  = (required <= unlocked)

		var btn := Button.new()
		btn.text = label_text if is_unlocked else "🔒  " + label_text.substr(4)
		btn.custom_minimum_size = Vector2(105, 28)   # 4-col grid → 4×105+3×4 = 432 px fits inside 464-px panel
		btn.disabled = not is_unlocked
		btn.add_theme_font_size_override("font_size", 9)
		btn.clip_text = true
		btn.add_theme_color_override("font_color",
				COL_MUTED if is_unlocked else COL_LOCKED)
		btn.add_theme_color_override("font_color_disabled", COL_LOCKED)
		btn.add_theme_stylebox_override("normal",
				_make_stylebox(COL_BTN if is_unlocked else Color(0.10, 0.10, 0.10)))
		btn.add_theme_stylebox_override("hover",
				_make_stylebox(COL_BTN_HOV if is_unlocked else Color(0.10, 0.10, 0.10)))
		if is_unlocked:
			var path := scene_path
			btn.pressed.connect(func() -> void:
				GameManager.reset()
				SceneManager.go_to(path)
			)
		grid.add_child(btn)

	content.add_child(grid)

	# ── Side Quests section ───────────────────────────────────────────────────────
	var div := ColorRect.new()
	div.color = Color(COL_GOLD, 0.22)
	div.custom_minimum_size = Vector2(0, 1)
	content.add_child(div)

	var quests_lbl := Label.new()
	quests_lbl.text = "─── Side Quests ───"
	quests_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quests_lbl.add_theme_color_override("font_color", Color(COL_GOLD, 0.60))
	quests_lbl.add_theme_font_size_override("font_size", 11)
	content.add_child(quests_lbl)

	# quest_id → scene the NPC / activity lives in
	const QUEST_SCENES: Dictionary = {
		"fish_fry_for_gods":   "res://scenes/World.tscn",
		"swing_off_race":      "res://scenes/Act1.tscn",
		"chaya_kada_showdown": "res://scenes/Act1.tscn",
		"odiyan_tracks":       "res://scenes/Act3.tscn",
		"bell_of_bhadrakali":  "res://scenes/Houseboat.tscn",
	}

	for quest_id: String in QUEST_SCENES:
		var state:  int    = _qm.get_state(quest_id)   if _qm != null else _QS_LOCKED
		var title:  String = _qm.get_title(quest_id)   if _qm != null else quest_id
		var _reward: String = _qm.get_reward(quest_id)  if _qm != null else ""   # kept for future tooltip
		var dest:   String = QUEST_SCENES[quest_id]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.custom_minimum_size = Vector2(0, 18)

		# State badge
		var badge := Label.new()
		badge.text = _quest_icon(state)
		badge.custom_minimum_size = Vector2(16, 18)
		badge.add_theme_font_size_override("font_size", 11)
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(badge)

		# Single-line title (no sub-label — quest state is implied by the badge colour)
		var tlabel := Label.new()
		tlabel.text = title
		tlabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tlabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tlabel.add_theme_font_size_override("font_size", 10)
		tlabel.add_theme_color_override("font_color", _quest_color(state))
		row.add_child(tlabel)

		# DEV: all quests playable regardless of lock state
		if true:
			var qbtn := Button.new()
			qbtn.text = "▶"
			qbtn.custom_minimum_size = Vector2(32, 18)
			qbtn.add_theme_font_size_override("font_size", 10)
			qbtn.add_theme_color_override("font_color", COL_MUTED)
			qbtn.add_theme_stylebox_override("normal", _make_stylebox(COL_BTN))
			qbtn.add_theme_stylebox_override("hover",  _make_stylebox(COL_BTN_HOV))
			var path := dest
			qbtn.pressed.connect(func() -> void:
				GameManager.reset()
				SceneManager.go_to(path)
			)
			row.add_child(qbtn)

		content.add_child(row)
		# Note: VBoxContainer.separation handles inter-row spacing — no ColorRect
		# divider needed. Removing it frees ~5 px per quest, enough to show all 5.

	# ── Back button (outside scroll — always at bottom) ───────────────────────────
	var back := _make_button("← Back")
	back.pressed.connect(func() -> void:
		root.queue_free()
		_main_panel.visible = true   # restore the main menu underneath
	)
	outer.add_child(back)

	root.add_child(outer)
	add_child(root)

	# Strip keyboard focus from every button in this panel and reset scroll to 0
	# next frame. Without this, the last-created button (often "← Back" or a
	# quest "▶") grabs focus and the ScrollContainer auto-scrolls to it,
	# pushing the Acts section off the top of the panel.
	_disable_focus_recursive(root)
	scroll.set_deferred("scroll_vertical", 0)


## Recursively flip focus_mode → NONE on every Control descendant of `node`.
func _disable_focus_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_focus_recursive(child)


# ── Quest Panel ───────────────────────────────────────────────────────────────

func _build_quest_panel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	# Panel — fits within 480 × 270 viewport (256 px tall)
	var panel := ColorRect.new()
	panel.color = COL_PANEL
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(460, 0)
	panel.offset_left   = -230
	panel.offset_right  =  230
	panel.offset_top    = -128
	panel.offset_bottom =  128
	root.add_child(panel)

	# ScrollContainer — quest rows scroll inside the fixed panel
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	scroll.custom_minimum_size = Vector2(440, 0)
	scroll.offset_left   = -220
	scroll.offset_right  =  220
	scroll.offset_top    = -120
	scroll.offset_bottom =  120
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)
	root.set_meta("quest_vbox", vbox)

	return root


func _refresh_quest_panel() -> void:
	var vbox: VBoxContainer = _quest_panel.get_meta("quest_vbox")
	for c in vbox.get_children():
		c.queue_free()

	var hdr := Label.new()
	hdr.text = "📜  Side Quests"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_color_override("font_color", COL_GOLD)
	hdr.add_theme_font_size_override("font_size", 18)
	vbox.add_child(hdr)

	var div := ColorRect.new()
	div.color = Color(COL_GOLD, 0.3)
	div.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(div)

	if _qm == null: return
	for quest_id: String in _qm.QUEST_DATA:
		var state:    int    = _qm.get_state(quest_id)
		var progress: int    = _qm.get_progress(quest_id)
		var total:    int    = _qm.get_total(quest_id)
		var title:    String = _qm.get_title(quest_id)
		var desc:     String = _qm.get_desc(quest_id)
		var reward:   String = _qm.get_reward(quest_id)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		# State icon
		var icon := Label.new()
		icon.text = _quest_icon(state)
		icon.custom_minimum_size = Vector2(24, 0)
		icon.add_theme_font_size_override("font_size", 16)
		hbox.add_child(icon)

		# Text block
		var tbox := VBoxContainer.new()
		tbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbox.add_theme_constant_override("separation", 2)

		var tlabel := Label.new()
		tlabel.text = title
		tlabel.add_theme_font_size_override("font_size", 13)
		tlabel.add_theme_color_override("font_color", _quest_color(state))
		tbox.add_child(tlabel)

		var dlabel := Label.new()
		dlabel.text = desc
		dlabel.autowrap_mode = TextServer.AUTOWRAP_WORD
		dlabel.add_theme_font_size_override("font_size", 10)
		dlabel.add_theme_color_override("font_color", Color(0.70, 0.80, 0.70))
		tbox.add_child(dlabel)

		if state == _QS_ACTIVE and total > 1:
			var prog_label := Label.new()
			prog_label.text = "Progress: %d / %d" % [progress, total]
			prog_label.add_theme_font_size_override("font_size", 10)
			prog_label.add_theme_color_override("font_color", COL_ACTIVE)
			tbox.add_child(prog_label)

		if state == _QS_DONE:
			var rew := Label.new()
			rew.text = "✔ " + reward
			rew.add_theme_font_size_override("font_size", 10)
			rew.add_theme_color_override("font_color", COL_DONE)
			tbox.add_child(rew)
		elif state == _QS_LOCKED:
			var act_data: Dictionary = _qm.QUEST_DATA[quest_id]
			var rew := Label.new()
			rew.text = "🔒 Available in Act %d" % act_data["act"]
			rew.add_theme_font_size_override("font_size", 10)
			rew.add_theme_color_override("font_color", COL_LOCKED)
			tbox.add_child(rew)

		hbox.add_child(tbox)
		vbox.add_child(hbox)

		# Divider
		var sep := ColorRect.new()
		sep.color = Color(1.0, 1.0, 1.0, 0.06)
		sep.custom_minimum_size = Vector2(0, 1)
		vbox.add_child(sep)

	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(sp)

	var back := _make_button("← Back")
	back.pressed.connect(func() -> void:
		_quest_panel.visible = false
		_main_panel.visible  = true
	)
	vbox.add_child(back)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _quest_icon(state: int) -> String:
	match state:
		_QS_DONE:   return "✅"
		_QS_ACTIVE: return "⚡"
		_:          return "🔒"

func _quest_color(state: int) -> Color:
	match state:
		_QS_DONE:   return COL_DONE
		_QS_ACTIVE: return COL_ACTIVE
		_:          return COL_LOCKED

func _make_button(label: String) -> Button:
	var btn := Button.new()
	btn.text                = label
	btn.custom_minimum_size = Vector2(200, 26)   # compact — 5 buttons need to fit in 270 px viewport
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", COL_MUTED)
	btn.add_theme_stylebox_override("normal", _make_stylebox(COL_BTN))
	btn.add_theme_stylebox_override("hover",  _make_stylebox(COL_BTN_HOV))
	return btn

func _make_stylebox(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color           = bg
	sb.border_width_left  = 1
	sb.border_width_right = 1
	sb.border_width_top   = 1
	sb.border_width_bottom = 1
	sb.border_color       = Color(COL_GOLD, 0.35)
	sb.corner_radius_top_left     = 4
	sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_left  = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left   = 10
	sb.content_margin_right  = 10
	sb.content_margin_top    = 6
	sb.content_margin_bottom = 6
	return sb
