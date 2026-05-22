extends Node

## AudioManager — full audio system for Kanjiravanam Chronicles.
## Buses: Master → Music / SFX / Ambient
## Drop .ogg files into res://assets/audio/ and they wire in automatically.
## All play_*() calls are no-ops if the file doesn't exist yet — safe to call always.

# ── Constants ─────────────────────────────────────────────────────────────────
const FADE_TIME      := 1.2    # music crossfade duration (seconds)
const BOSS_FADE_IN   := 0.6    # boss music fade-in
const BOSS_FADE_OUT  := 1.5    # restore act music after boss dies

# ── Track map — act key → music file ──────────────────────────────────────────
const ACT_TRACKS := {
	"World": "res://assets/audio/music_prologue.ogg",
	"Act1":  "res://assets/audio/music_act1.ogg",
	"Act2":  "res://assets/audio/music_act2.ogg",
	"Act3":  "res://assets/audio/music_act3.ogg",
	"Act4":  "res://assets/audio/music_act4.ogg",
	"Act5":  "res://assets/audio/music_act5.ogg",
}

const BOSS_TRACKS := {
	"Yakshi":        "res://assets/audio/music_boss_yakshi.ogg",
	"Kuttichathan":  "res://assets/audio/music_boss_kuttichathan.ogg",
	"Odiyan":        "res://assets/audio/music_boss_odiyan.ogg",
	"Karinkanni":    "res://assets/audio/music_boss_karinkanni.ogg",
	"PeyKomban":     "res://assets/audio/music_boss_peykomban.ogg",
}

const AMBIENT_TRACKS := {
	"river":        "res://assets/audio/ambience_river.ogg",
	"rain":         "res://assets/audio/ambience_rain.ogg",
	"fire":         "res://assets/audio/ambience_fire.ogg",
	"forest_night": "res://assets/audio/ambience_forest_night.ogg",
}

const STINGS := {
	"powerup":      "res://assets/audio/sting_powerup.ogg",
	"resurrection": "res://assets/audio/sting_resurrection.ogg",
	"hint":         "res://assets/audio/sting_hint.ogg",
	"boss_die":     "res://assets/audio/sting_boss_die.ogg",
	"level_clear":  "res://assets/audio/sting_level_clear.ogg",
	"victory":      "res://assets/audio/music_victory.ogg",
	"game_over":    "res://assets/audio/music_gameover.ogg",
}

const CINEMATICS := {
	"bike_ride":       "res://assets/audio/music_bike_ride.ogg",
	"bull_chase":      "res://assets/audio/music_bull_chase.ogg",
	"peykomban_reveal":"res://assets/audio/music_peykomban_reveal.ogg",
}

# ── Volume settings ───────────────────────────────────────────────────────────
var music_volume:   float = 0.8
var sfx_volume:     float = 1.0
var ambient_volume: float = 0.5

# ── Internal state ────────────────────────────────────────────────────────────
var _current_act:   String = ""
var _boss_active:   bool   = false
var _cinematic_on:  bool   = false

var _music_a:   AudioStreamPlayer   # crossfade player A
var _music_b:   AudioStreamPlayer   # crossfade player B
var _active:    AudioStreamPlayer   # whichever is currently audible
var _ambient:   AudioStreamPlayer   # ambient loop (river, rain, fire, forest)
var _cinematic: AudioStreamPlayer   # one-shot cinematic tracks

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_music_a   = _make_player("Music")
	_music_b   = _make_player("Music")
	_ambient   = _make_player("Ambient")
	_cinematic = _make_player("SFX")
	_active    = _music_a
	_setup_buses()
	get_tree().root.child_entered_tree.connect(_on_scene_added)
	# Wire GameManager signals for boss music
	if GameManager.has_signal("boss_started"):
		GameManager.boss_started.connect(play_boss_music)
	if GameManager.has_signal("boss_cleared"):
		GameManager.boss_cleared.connect(restore_act_music)
	if GameManager.has_signal("player_died"):
		GameManager.player_died.connect(func() -> void: play_sting("game_over"))
	if GameManager.has_signal("game_won"):
		GameManager.game_won.connect(func() -> void: play_sting("victory"))

# ── Bus setup ─────────────────────────────────────────────────────────────────
func _setup_buses() -> void:
	_ensure_bus("Music",   "Master")
	_ensure_bus("SFX",     "Master")
	_ensure_bus("Ambient", "Master")
	_apply_volumes()

func _ensure_bus(bus_name: String, send_to: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, send_to)

func _apply_volumes() -> void:
	_set_bus_vol("Music",   music_volume)
	_set_bus_vol("SFX",     sfx_volume)
	_set_bus_vol("Ambient", ambient_volume)

func _set_bus_vol(bus_name: String, vol: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(vol, 0.001, 1.0)))

# ── Scene detection ───────────────────────────────────────────────────────────
func _on_scene_added(node: Node) -> void:
	var scene_name := node.name as String
	if ACT_TRACKS.has(scene_name) and scene_name != _current_act:
		_current_act  = scene_name
		_boss_active  = false
		_cinematic_on = false
		play_act_music(scene_name)

# ── Act music ─────────────────────────────────────────────────────────────────
func play_act_music(act_key: String) -> void:
	if not ACT_TRACKS.has(act_key): return
	if _boss_active or _cinematic_on:  return   # don't interrupt boss / cinematic
	_crossfade_to(ACT_TRACKS[act_key], music_volume)

# ── Boss music ────────────────────────────────────────────────────────────────
func play_boss_music(boss_key: String) -> void:
	if not BOSS_TRACKS.has(boss_key): return
	_boss_active = true
	_crossfade_to(BOSS_TRACKS[boss_key], music_volume, BOSS_FADE_IN)

func restore_act_music() -> void:
	_boss_active = false
	if _current_act != "" and not _cinematic_on:
		_crossfade_to(ACT_TRACKS.get(_current_act, ""), music_volume, BOSS_FADE_OUT)

# ── Cinematic one-shots ───────────────────────────────────────────────────────
## Plays a cinematic track (bike ride, bull chase, etc.) on the cinematic player.
## Act music is ducked while it plays. Auto-restores when done.
func play_cinematic(key: String) -> void:
	if not CINEMATICS.has(key): return
	var path: String = CINEMATICS[key]
	if not ResourceLoader.exists(path): return
	_cinematic_on = true
	# Duck music
	var tw := create_tween()
	tw.tween_property(_active, "volume_db", linear_to_db(0.05), 0.5)
	_cinematic.stream = load(path)
	_cinematic.play()
	_cinematic.finished.connect(_on_cinematic_finished, CONNECT_ONE_SHOT)

func _on_cinematic_finished() -> void:
	_cinematic_on = false
	if not _boss_active:
		var tw := create_tween()
		tw.tween_property(_active, "volume_db", linear_to_db(music_volume), 1.0)

## Stop cinematic early (e.g. scene transition mid-bike-ride)
func stop_cinematic() -> void:
	if not _cinematic.playing: return
	_cinematic.stop()
	_on_cinematic_finished()

# ── Ambient layers ────────────────────────────────────────────────────────────
func play_ambient(key: String) -> void:
	if not AMBIENT_TRACKS.has(key): return
	var path: String = AMBIENT_TRACKS[key]
	if not ResourceLoader.exists(path): return
	_ambient.stream = load(path)
	_ambient.play()

func stop_ambient() -> void:
	var tw := create_tween()
	tw.tween_property(_ambient, "volume_db", linear_to_db(0.0), 1.0)
	tw.tween_callback(_ambient.stop)

# ── Stings ────────────────────────────────────────────────────────────────────
## One-shot SFX sting — powerup, boss die, victory, etc.
func play_sting(key: String) -> void:
	if not STINGS.has(key): return
	var path: String = STINGS[key]
	if not ResourceLoader.exists(path): return
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus    = "SFX"
	p.autoplay = true
	p.finished.connect(p.queue_free)
	add_child(p)

## Generic SFX helper for positional sounds (sword, coconut, damage, etc.)
func play_sfx(stream: AudioStream, pos: Vector2 = Vector2.ZERO, pitch: float = 1.0) -> void:
	if stream == null: return
	var p := AudioStreamPlayer2D.new()
	p.stream      = stream
	p.bus         = "SFX"
	p.pitch_scale = pitch
	p.position    = pos
	p.autoplay    = true
	p.finished.connect(p.queue_free)
	get_tree().root.add_child(p)

# ── Volume controls (call from Settings menu) ─────────────────────────────────
func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_set_bus_vol("Music", music_volume)
	if _active.playing:
		_active.volume_db = linear_to_db(music_volume)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_set_bus_vol("SFX", sfx_volume)

func set_ambient_volume(vol: float) -> void:
	ambient_volume = clampf(vol, 0.0, 1.0)
	_set_bus_vol("Ambient", ambient_volume)

# ── Crossfade helper ──────────────────────────────────────────────────────────
func _crossfade_to(path: String, target_vol: float, fade: float = FADE_TIME) -> void:
	var inactive := _music_b if _active == _music_a else _music_a
	if ResourceLoader.exists(path):
		inactive.stream     = load(path)
		inactive.volume_db  = linear_to_db(0.001)
		inactive.play()
	else:
		inactive.stream = null   # file not dropped in yet — silent crossfade

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_active, "volume_db", linear_to_db(0.001), fade)
	if inactive.stream != null:
		tw.tween_property(inactive, "volume_db", linear_to_db(target_vol), fade)
	tw.chain().tween_callback(func() -> void:
		_active.stop()
		_active = inactive
	)

# ── Node factory ─────────────────────────────────────────────────────────────
func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p
