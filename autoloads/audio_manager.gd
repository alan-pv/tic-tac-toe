extends Node

## Pool of players for firing sound effects from any scene.
##
## Reused unchanged from Memorandum; only the constants below were renamed to
## match this game. The .wav files are the same ones, so swapping them later is
## a matter of dropping new files into assets/audio/.


const POOL_SIZE := 8

const SFX_PLACE := "res://assets/audio/flip.wav"
const SFX_VANISH := "res://assets/audio/match.wav"
const SFX_ROUND_WON := "res://assets/audio/win.wav"
const SFX_DRAW := "res://assets/audio/fail.wav"
const SFX_MATCH_WON := "res://assets/audio/win.wav"
const SFX_CLICK := "res://assets/audio/click.wav"
const SFX_HOVER := "res://assets/audio/hover.wav"

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func play_sfx(path: String, pitch_variation: float = 0.08) -> void:
	var stream := _get_stream(path)
	if stream == null:
		return
	var player := _get_free_player()
	if player == null:
		return
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(0, pitch_variation)
	player.volume_db = linear_to_db(clampf(GameSettings.sfx_volume, 0.0001, 1.0))
	player.play()


func _get_stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var stream := load(path) as AudioStream
	_cache[path] = stream
	return stream


func _get_free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0] if not _players.is_empty() else null
