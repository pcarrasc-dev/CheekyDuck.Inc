extends Node

# ── Volúmenes ─────────────────────────────────────────────────────────────────
const VOL_LOBBY: float = -20.0
const VOL_MATCH: float = -6.0
const VOL_MUTED: float = -80.0


# ── Nodos hijos — asignar streams en el Inspector ────────────────────────────
@onready var _music_player:    AudioStreamPlayer = $MusicPlayer       # Bus: Music | Autoplay: ✅
@onready var _last_min_player: AudioStreamPlayer = $LastMinutePlayer  # Bus: Music | Autoplay: ❌
@onready var _goal_player:     AudioStreamPlayer = $GoalPlayer        # Bus: SFX   | Autoplay: ❌
@onready var _whistle_player:  AudioStreamPlayer = $WhistlePlayer     # Bus: SFX   | Autoplay: ❌

var _muted: bool = false
var _current_target_vol: float = VOL_LOBBY


func _ready() -> void:
	_music_player.volume_db    = VOL_LOBBY
	_last_min_player.volume_db = VOL_MUTED
	_music_player.play()

# ── API pública ───────────────────────────────────────────────────────────────

func start_match() -> void:
	_current_target_vol = VOL_MATCH
	_fade(_music_player, VOL_MATCH)

func play_goal() -> void:
	_goal_player.play()

func trigger_last_minute() -> void:
	_last_min_player.volume_db = VOL_MUTED
	_last_min_player.play()
	_fade(_music_player,    VOL_MUTED)
	_fade(_last_min_player, _vol_or_muted(VOL_MATCH))

func play_final_whistle() -> void:
	_whistle_sequence()

func end_match() -> void:
	_fade(_last_min_player, VOL_MUTED)
	_current_target_vol = VOL_LOBBY
	_fade(_music_player, _vol_or_muted(VOL_LOBBY))

func toggle_mute() -> void:
	_muted = !_muted
	_fade(_music_player, _vol_or_muted(_current_target_vol))
	if _last_min_player.playing:
		_fade(_last_min_player, _vol_or_muted(_current_target_vol))


# ── Internos ──────────────────────────────────────────────────────────────────

func _vol_or_muted(vol: float) -> float:
	return VOL_MUTED if _muted else vol

func _fade(player: AudioStreamPlayer, to_vol: float, duration: float = 1.5) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_vol, duration)

func _whistle_sequence() -> void:
	_whistle_player.play()
	await get_tree().create_timer(1.2).timeout
	_whistle_player.play()
	await get_tree().create_timer(0.8).timeout
	_whistle_player.play()
	
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.is_action_pressed("toggle music"):
		toggle_mute()
