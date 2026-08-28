class_name DifficultyPreset
extends Resource

## A bot difficulty as an editable resource (.tres).
##
## Balancing the bot should never mean editing code: the three presets in
## resources/difficulties/ are data, and the setup screen just lists whatever
## files it finds there.


@export var id: StringName = &"sharp"

@export var display_name: String = "Sharp"

@export_multiline var description: String = ""

## Seconds the bot waits before playing, so its move is readable.
@export_range(0.0, 2.0, 0.05) var bot_think_time: float = 0.45

## 0.0 = random, 1.0 = perfect. BotPlayer decides what to do with it.
@export_range(0.0, 1.0, 0.05) var bot_skill: float = 0.8


func apply_to(config: GameConfig) -> void:
	config.difficulty_id = id
	config.bot_think_time = bot_think_time
	config.bot_skill = bot_skill
