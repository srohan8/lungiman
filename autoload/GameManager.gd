extends Node

# ── Player stats ──────────────────────────────────────────────────────────────
var score:   int = 0
var hp:      int = 100
var max_hp:  int = 100
var ammo:    int = 6
var max_ammo: int = 14
var has_resurrection: bool = false

# ── Status effects ────────────────────────────────────────────────────────────
var slow_mo_active: bool  = false
var slow_mo_timer:  float = 0.0
var rage_active:    bool  = false
var rage_timer:     float = 0.0
var hypnosis_active: bool  = false
var hypnosis_timer:  float = 0.0
var paralysis_active: bool  = false
var paralysis_timer:  float = 0.0

# ── Boss HP ───────────────────────────────────────────────────────────────────
var boss_hp:     int = 0
var boss_max_hp: int = 0

# ── Mobile input ──────────────────────────────────────────────────────────────
var climb_press_pending: bool = false

# ── Signals ───────────────────────────────────────────────────────────────────
signal hp_changed(new_hp: int)
signal ammo_changed(new_ammo: int)
@warning_ignore("unused_signal")
signal score_changed(new_score: int)
signal boss_hp_changed(new_hp: int)
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

func apply_powerup(type: String) -> void:
	match type:
		"heart":
			hp = mini(hp + 40, max_hp)
			hp_changed.emit(hp)
		"nut":
			ammo = mini(ammo + 4, max_ammo)
			ammo_changed.emit(ammo)
		"rum":
			_activate_slow_mo(6.0)
		"curry":
			hp = mini(hp + 22, max_hp)
			hp_changed.emit(hp)
			_activate_slow_mo(3.7)
			rage_active = true
			rage_timer  = 3.7
		"chai":
			_activate_slow_mo(2.0)
			hypnosis_active = false
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

func take_damage(amount: int) -> void:
	hp -= amount
	hp_changed.emit(hp)
	if hp <= 0:
		hp = 0
		player_died.emit()

func activate_hypnosis(duration: float = 8.0) -> void:
	hypnosis_active = true
	hypnosis_timer  = duration

func activate_paralysis(duration: float = 2.0) -> void:
	paralysis_active = true
	paralysis_timer  = duration

func set_boss(new_max_hp: int) -> void:
	boss_hp     = new_max_hp
	boss_max_hp = new_max_hp
	boss_hp_changed.emit(boss_hp)

func clear_boss() -> void:
	boss_hp     = 0
	boss_max_hp = 0
	boss_hp_changed.emit(0)

func boss_take_damage(amount: int) -> void:
	boss_hp = maxi(0, boss_hp - amount)
	boss_hp_changed.emit(boss_hp)

func win_game() -> void:
	game_won.emit()

func reset() -> void:
	score            = 0
	hp               = max_hp
	ammo             = 6
	has_resurrection = false
	slow_mo_active   = false
	rage_active      = false
	hypnosis_active  = false
	paralysis_active = false
	boss_hp          = 0
	boss_max_hp      = 0
	Engine.time_scale = 1.0
