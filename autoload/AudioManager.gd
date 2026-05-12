extends Node

## AudioManager — handles ambient music and SFX routing per act.
## Autoload singleton. Fades between tracks when act changes.

const FADE_TIME := 1.2   # seconds to cross-fade between tracks

# Per-act ambient colour palettes (tone-mapped as AudioStreamGenerator pitches
# when real .ogg tracks are absent — replaced by real streams once audio drops in).
# Keys match scene filenames without extension.
const TRACK_MAP := {
	"World":  {"color": Color(1.0, 0.85, 0.4),  "pitch": 1.00, "label": "Golden Hour Dusk"},
	"Act1":   {"color": Color(0.3, 0.6, 0.4),   "pitch": 0.95, "label": "Yakshi's Hollow"},
	"Act2":   {"color": Color(1.0, 0.45, 0.15), "pitch": 1.05, "label": "Kuttichathan's Carnival"},
	"Act3":   {"color": Color(0.5, 0.5, 0.6),   "pitch": 0.90, "label": "Odiyan's Hunt"},
	"Act4":   {"color": Color(0.2, 0.35, 0.7),  "pitch": 0.85, "label": "Karinkanni's Curse"},
	"Act5":   {"color": Color(0.08, 0.08, 0.12),"pitch": 0.80, "label": "Pey Komban's Rampage"},
}

var _current_track: String   = ""
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_player:  AudioStreamPlayer

## SFX bus volumes (0.0–1.0). Serialised to user:// by SettingsManager when added.
var music_volume: float = 0.8
var sfx_volume:   float = 1.0

func _ready() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_b = AudioStreamPlayer.new()
	_music_player_a.bus = "Music"
	_music_player_b.bus = "Music"
	add_child(_music_player_a)
	add_child(_music_player_b)
	_active_player = _music_player_a
	_setup_buses()
	# Watch scene changes
	get_tree().root.child_entered_tree.connect(_on_root_child_added)

func _setup_buses() -> void:
	# Ensure Music and SFX buses exist; create them if missing.
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_apply_volumes()

func _apply_volumes() -> void:
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx   := AudioServer.get_bus_index("SFX")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))

func _on_root_child_added(node: Node) -> void:
	# Detect act changes by scene root name
	var scene_name := node.name
	if TRACK_MAP.has(scene_name) and scene_name != _current_track:
		play_act_music(scene_name)

## Switch to the ambient track for an act. Cross-fades over FADE_TIME.
func play_act_music(act_key: String) -> void:
	if not TRACK_MAP.has(act_key):
		return
	_current_track = act_key
	var track_data: Dictionary = TRACK_MAP[act_key]
	# Try loading a real .ogg from assets/audio/
	var ogg_path := "res://assets/audio/%s_ambient.ogg" % act_key.to_lower()
	var inactive := _music_player_b if _active_player == _music_player_a else _music_player_a
	if ResourceLoader.exists(ogg_path):
		var stream: AudioStream = load(ogg_path)
		inactive.stream        = stream
		inactive.pitch_scale   = 1.0
	else:
		# No audio file yet — silence the inactive player gracefully
		inactive.stream = null
	inactive.volume_db = linear_to_db(0.0)
	if inactive.stream != null:
		inactive.play()
	# Fade out active, fade in inactive
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_active_player, "volume_db", linear_to_db(0.0), FADE_TIME)
	if inactive.stream != null:
		tw.tween_property(inactive, "volume_db", linear_to_db(music_volume), FADE_TIME)
	tw.chain().tween_callback(func() -> void:
		_active_player.stop()
		_active_player = inactive
	)

## One-shot SFX helper — plays a stream on the SFX bus at the given position.
## If stream is null (no audio file yet) this is a no-op.
func play_sfx(stream: AudioStream, position: Vector2 = Vector2.ZERO, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.stream      = stream
	p.bus         = "SFX"
	p.pitch_scale = pitch
	p.position    = position
	p.autoplay    = true
	p.finished.connect(p.queue_free)
	get_tree().root.add_child(p)

## Set music volume (0.0–1.0) and apply immediately.
func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()
	if _active_player.stream != null:
		_active_player.volume_db = linear_to_db(music_volume)

## Set SFX volume (0.0–1.0) and apply immediately.
func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()
