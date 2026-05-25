extends Node

# ── Sprite pipeline gate ──────────────────────────────────────────────────────
## Scenario.gg-generated sheets are now live. Set true again only to force
## coloured-rectangle fallbacks for debug. Each character script gates its sheet
## load behind this flag:
##   `if not GameManager.USE_PLACEHOLDER_SPRITES and ResourceLoader.exists(PATH):`
const USE_PLACEHOLDER_SPRITES := false

# ── One-shot tutorial flags (persist across scene resets within a session) ────
var hint_first_perch_seen: bool = false   # set when the rope-throw hint has been shown once

# ── Player stats ──────────────────────────────────────────────────────────────
var score:   int = 0
var hp:      int = 100
var max_hp:  int = 100
var ammo:    int = 6
var max_ammo: int = 14
var has_resurrection: bool = false
var maveli_blessed:   bool = false   ## Set true in Pathalam after Maveli's blessing. Persists for Act V. Golden lamp + golden tint on player.

# ── Status effects ────────────────────────────────────────────────────────────
var slow_mo_active: bool  = false
var slow_mo_timer:  float = 0.0
var rage_active:    bool  = false
var rage_timer:     float = 0.0
var hypnosis_active: bool  = false
var hypnosis_timer:  float = 0.0
var paralysis_active: bool  = false
var paralysis_timer:  float = 0.0
var toddy_active:   bool  = false   # dizzy — wobbly controls + camera sway
var toddy_timer:    float = 0.0
var fish_fry_active: bool  = false   # Fish Fry quest reward: HP regen 2× per regen tick
var fish_fry_timer:  float = 0.0

# ── Boss HP ───────────────────────────────────────────────────────────────────
var boss_hp:      int  = 0
var boss_max_hp:  int  = 0
var boss_visible: bool = false   ## true only after first hit — suppresses bar on scene load

# ── Progress (persists across resets within a session) ────────────────────────
var acts_unlocked: int = 0   # 0 = prologue only; 1 = Act I unlocked; etc.
var high_score:    int = 0   # best score ever, never reset

# ── Grit — cumulative journey wear ────────────────────────────────────────────
## HP goes up and down with combat. Grit only ever goes down (−20 per boss).
## Only Maveli's blessing restores it to 100. Drives the Nilavilakku lamp + sprite tints.
## Schedule:  start=100 → Yakshi −20 → Kuttichathan −20 → Odiyan −20 → Karinkanni −20
##             → Pathalam: Maveli restores 100 + sets maveli_blessed → Act V (stays gold)
var grit: int = 100
var bike_undamaged: bool = false   ## True if the player cleared the Act II bike ride without any hits → Ravi's Act V callback
var disco_score:    int  = 0       ## DDR score from the Disco Hallucination dance phase — saved for wake-up quip and Victory tally

# ── Mobile input ──────────────────────────────────────────────────────────────
var climb_press_pending: bool = false

# ── Signals ───────────────────────────────────────────────────────────────────
signal hp_changed(new_hp: int)
signal ammo_changed(new_ammo: int)
@warning_ignore("unused_signal")
signal score_changed(new_score: int)
signal boss_hp_changed(new_hp: int)
signal grit_changed(new_grit: int)
signal player_died
signal game_won

func _process(delta: float) -> void:
	if slow_mo_active:
		slow_mo_timer -= delta
		if slow_mo_timer <= 0.0:
			slow_mo_active = false
			Engine.time_scale = 1.0
	if rage_active:
		rage_timer -= delta
		if rage_timer <= 0.0:
			rage_active = false
	if hypnosis_active:
		hypnosis_timer -= delta
		if hypnosis_timer <= 0.0:
			hypnosis_active = false
	if paralysis_active:
		paralysis_timer -= delta
		if paralysis_timer <= 0.0:
			paralysis_active = false
	if toddy_active:
		toddy_timer -= delta
		if toddy_timer <= 0.0:
			toddy_active = false
	if fish_fry_active:
		fish_fry_timer -= delta
		if fish_fry_timer <= 0.0:
			fish_fry_active = false

func apply_powerup(type: String) -> void:
	match type:
		"heart":
			var heal := 80 if fish_fry_active else 40
			hp = mini(hp + heal, max_hp)
			hp_changed.emit(hp)
		"nut":
			ammo = mini(ammo + 4, max_ammo)
			ammo_changed.emit(ammo)
		"porotta":
			# Kerala flatbread — comfort food gives fighting spirit
			hp = mini(hp + 25, max_hp)
			hp_changed.emit(hp)
			rage_active = true
			rage_timer  = 4.0
		"chai":
			# Hot tea — clears the mind, slows the world
			_activate_slow_mo(6.0)
			hypnosis_active  = false
			paralysis_active = false
			toddy_active     = false   # chai sobers you up
		"toddy":
			# Kerala palm toddy — +20 HP but you get dizzy (wobbly controls for 5s)
			hp = mini(hp + 20, max_hp)
			hp_changed.emit(hp)
			toddy_active = true
			toddy_timer  = 5.0
		"resurrection":
			has_resurrection = true

func _activate_slow_mo(duration: float) -> void:
	slow_mo_active = true
	slow_mo_timer  = duration
	Engine.time_scale = 0.42

func damage_multiplier() -> int:
	return 2 if rage_active else 1

func consume_climb_press() -> bool:
	if climb_press_pending:
		climb_press_pending = false
		return true
	return false

signal player_revived   # emitted when resurrection token saves the player

func take_damage(amount: int) -> void:
	hp -= amount
	hp_changed.emit(hp)
	if hp <= 0:
		if has_resurrection:
			# Thoma's blessing kicks in — survive at 40 HP
			has_resurrection = false
			hp = 40
			hp_changed.emit(hp)
			Engine.time_scale = 1.0   # reset slow-mo if active
			slow_mo_active = false
			player_revived.emit()
		else:
			hp = 0
			Engine.time_scale = 1.0
			player_died.emit()

func activate_hypnosis(duration: float = 8.0) -> void:
	hypnosis_active = true
	hypnosis_timer  = duration

func activate_paralysis(duration: float = 2.0) -> void:
	paralysis_active = true
	paralysis_timer  = duration

func set_boss(new_max_hp: int) -> void:
	boss_hp      = new_max_hp
	boss_max_hp  = new_max_hp
	boss_visible = false   # hidden until first hit
	boss_hp_changed.emit(boss_hp)

func clear_boss() -> void:
	boss_hp      = 0
	boss_max_hp  = 0
	boss_visible = false
	boss_hp_changed.emit(0)

func boss_take_damage(amount: int) -> void:
	boss_visible = true   # reveal bar on first damage
	boss_hp = maxi(0, boss_hp - amount)
	boss_hp_changed.emit(boss_hp)

func unlock_act(act_index: int) -> void:
	acts_unlocked = maxi(acts_unlocked, act_index)
	# Auto-save whenever a new act is unlocked
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null: sm.save_game()

## Spawn a floating score popup at world_pos.
func show_score_popup(world_pos: Vector2, points: int, color: Color = Color(1.0, 0.92, 0.25)) -> void:
	var ft: Node2D = preload("res://scenes/FloatingText.tscn").instantiate()
	ft.text     = "+%d" % points
	ft.color    = color
	ft.position = world_pos
	var tree    := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(ft)

## Triggered by Odiyan._die() after a 2 s delay. Transitions to the
## Disco Hallucination interlude (poison dream — not a real act).
func trigger_hallucination() -> void:
	SceneManager.go_to("res://scenes/DiscoHallucination.tscn")

func win_game() -> void:
	if score > high_score:
		high_score = score
		var sm := get_node_or_null("/root/SaveManager")
		if sm != null: sm.save_game()
	game_won.emit()

## Called by each boss _die() after clear_boss(). Drops grit by 20 (min 0).
## The Nilavilakku lamp and sprite wear tints read this value.
func boss_grit_drop() -> void:
	grit = maxi(0, grit - 20)
	grit_changed.emit(grit)

## Called in Pathalam when Maveli places his hand on LungiMan's chest.
## Restores HP to full, resets grit to 100, locks maveli_blessed permanently.
func maveli_restore() -> void:
	hp = max_hp
	hp_changed.emit(hp)
	grit = 100
	maveli_blessed = true
	grit_changed.emit(grit)

func reset() -> void:
	score            = 0
	hp               = max_hp
	ammo             = 6
	has_resurrection = false
	reset_status_effects()
	boss_hp          = 0
	boss_max_hp      = 0
	boss_visible     = false
	Engine.time_scale = 1.0

## Clear all timed status effects between scenes — called by SceneManager on every transition.
## Does NOT touch hp/ammo/score/resurrection so carry-over progression is preserved.
func reset_status_effects() -> void:
	slow_mo_active   = false
	slow_mo_timer    = 0.0
	rage_active      = false
	rage_timer       = 0.0
	hypnosis_active  = false
	hypnosis_timer   = 0.0
	paralysis_active = false
	paralysis_timer  = 0.0
	toddy_active     = false
	toddy_timer      = 0.0
	fish_fry_active  = false
	fish_fry_timer   = 0.0
	boss_hp          = 0
	boss_max_hp      = 0
	boss_visible     = false
	Engine.time_scale = 1.0

# ── Sprite helper for character grid sheets ───────────────────────────────────
## Builds a SpriteFrames from a horizontal grid sheet (Scenario.gg-generated).
## Each `anim_specs` entry: {name, frames: [cell_indices], fps, loop}.
## Falls back to coloured rects if USE_PLACEHOLDER_SPRITES or sheet missing.
func build_grid_sheet_frames(path: String, cols: int, rows: int,
		anim_specs: Array, fallback_color: Color = Color(0.7, 0.7, 0.7, 1.0)) -> SpriteFrames:
	var sf := SpriteFrames.new()
	var sheet: Texture2D = null
	var fw: int = 0
	var fh: int = 0
	if not USE_PLACEHOLDER_SPRITES and ResourceLoader.exists(path):
		sheet = load(path)
		if sheet != null:
			@warning_ignore("integer_division")
			fw = int(sheet.get_width())  / cols
			@warning_ignore("integer_division")
			fh = int(sheet.get_height()) / rows
	for spec_v: Variant in anim_specs:
		var spec: Dictionary = spec_v
		var anim_name: String = spec["name"]
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, bool(spec.get("loop", true)))
		sf.set_animation_speed(anim_name, float(spec.get("fps", 8.0)))
		var frame_indices: Array = spec["frames"]
		for idx_v: Variant in frame_indices:
			var idx: int = int(idx_v)
			if sheet != null:
				@warning_ignore("integer_division")
				var col: int = idx % cols
				@warning_ignore("integer_division")
				var row: int = idx / cols
				var at := AtlasTexture.new()
				at.atlas  = sheet
				at.region = Rect2(col * fw, row * fh, fw, fh)
				sf.add_frame(anim_name, at)
			else:
				var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
				img.fill(fallback_color)
				sf.add_frame(anim_name, ImageTexture.create_from_image(img))
	return sf

## Compute the sprite scale that fits the grid-sheet cell to target_h game pixels.
## Returns 1.0 in placeholder mode (so coloured rects missing or sheet missing).
func grid_sheet_scale(path: String, rows: int, target_h: float) -> float:
	if USE_PLACEHOLDER_SPRITES or not ResourceLoader.exists(path):
		return 1.0
	var sheet: Texture2D = load(path)
	if sheet == null:
		return 1.0
	@warning_ignore("integer_division")
	var fh: float = float(int(sheet.get_height()) / rows)
	return target_h / fh
