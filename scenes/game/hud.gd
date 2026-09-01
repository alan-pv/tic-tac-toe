class_name HUD
extends Control

## Scoreboard, round counter, turn indicator and the message that flashes in
## the middle of the screen.


signal pause_pressed

const SCORE_ENTRY_SCENE := preload("res://scenes/game/player_score_entry.tscn")

@onready var _score_container: HBoxContainer = %ScoreContainer
@onready var _round_label: Label = %RoundLabel
@onready var _mode_label: Label = %ModeLabel
@onready var _message_label: Label = %MessageLabel
@onready var _pause_button: Button = %PauseButton

var _entries: Array[PlayerScoreEntry] = []


func _ready() -> void:
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_message_label.text = ""


func setup(config: GameConfig) -> void:
	for entry in _entries:
		entry.queue_free()
	_entries.clear()

	for i in config.player_names.size():
		var entry := SCORE_ENTRY_SCENE.instantiate() as PlayerScoreEntry
		_score_container.add_child(entry)
		entry.setup(config.player_names[i], 0)
		entry.set_active(i == 0, false)
		_entries.append(entry)

	if config.infinite_mode:
		_mode_label.text = "Infinite  -  %d marks each" % config.max_marks_per_player
	else:
		_mode_label.text = "Classic"
	set_round(1, config.rounds_to_win)


func set_score(player_index: int, score: int) -> void:
	if player_index < 0 or player_index >= _entries.size():
		return
	_entries[player_index].set_score(score)


func set_turn(player_index: int) -> void:
	for i in _entries.size():
		_entries[i].set_active(i == player_index)


func set_round(round_number: int, rounds_to_win: int) -> void:
	_round_label.text = "Round %d  -  first to %d" % [maxi(round_number, 1), rounds_to_win]


func show_message(text: String, duration: float = 1.2) -> void:
	_message_label.text = text
	_message_label.modulate.a = 1.0
	if duration <= 0.0:
		return
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(_message_label, "modulate:a", 0.0, 0.3)
