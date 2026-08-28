extends Control

## Reads GameSettings.last_result and shows how the match went.


@onready var _title_label: Label = %TitleLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _detail_label: Label = %DetailLabel
@onready var _again_button: Button = %AgainButton
@onready var _setup_button: Button = %SetupButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_again_button.pressed.connect(func() -> void: SceneSwitcher.go_to(SceneSwitcher.GAME, false))
	_setup_button.pressed.connect(func() -> void: SceneSwitcher.go_to(SceneSwitcher.SETUP, false))
	_menu_button.pressed.connect(func() -> void: SceneSwitcher.go_to(SceneSwitcher.MAIN_MENU, false))
	_show_result()
	_again_button.grab_focus()


func _intro_config() -> Dictionary:
	return {"labels": true, "buttons": true, "panels": false}


func _show_result() -> void:
	var result := GameSettings.last_result
	if result.is_empty():
		_title_label.text = "No match yet"
		_score_label.text = ""
		_detail_label.text = ""
		return

	var names: PackedStringArray = result.get("names", PackedStringArray(["Player 1", "Player 2"]))
	var scores: Array = result.get("scores", [0, 0])
	var winner: int = result.get("winner", -1)

	if winner < 0:
		_title_label.text = "Level"
	else:
		_title_label.text = "%s wins" % names[winner]

	_score_label.text = "%s  %d  -  %d  %s" % [names[0], scores[0], scores[1], names[1]]

	var rounds: int = result.get("rounds_played", 0)
	var seconds: float = result.get("seconds", 0.0)
	_detail_label.text = "%d rounds  ·  %02d:%02d" % [rounds, int(seconds) / 60, int(seconds) % 60]
