extends Control

## Title screen.


@onready var _play_button: Button = %PlayButton
@onready var _how_to_button: Button = %HowToButton
@onready var _quit_button: Button = %QuitButton
@onready var _help_panel: Control = %HelpPanel
@onready var _close_help_button: Button = %CloseHelpButton


func _ready() -> void:
	_play_button.pressed.connect(func() -> void: SceneSwitcher.go_to(SceneSwitcher.SETUP))
	_how_to_button.pressed.connect(func() -> void: _set_help_visible(true))
	_close_help_button.pressed.connect(func() -> void: _set_help_visible(false))
	_quit_button.pressed.connect(func() -> void: SceneSwitcher.quit_game())

	_help_panel.visible = false
	_play_button.grab_focus()
	SceneSwitcher.clear_history()


func _intro_config() -> Dictionary:
	return {"labels": false, "buttons": true, "panels": false}


func _set_help_visible(value: bool) -> void:
	_help_panel.visible = value
	if value:
		_close_help_button.grab_focus()
	else:
		_play_button.grab_focus()
