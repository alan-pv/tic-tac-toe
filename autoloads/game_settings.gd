extends Node

## Settings and match data that survive a scene change.
##
## The setup screen writes `config` here, game.gd reads it, and the results
## screen reads `last_result`. Nobody passes arguments between scenes.


var config: GameConfig

## Filled in by game.gd right before jumping to the results screen.
## Keys: "scores", "names", "winner", "rounds_played", "seconds".
var last_result: Dictionary = {}

var last_difficulty_id: StringName = &"sharp"
var master_volume: float = 1.0
var sfx_volume: float = 0.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func start_new_game(new_config: GameConfig) -> void:
	config = new_config
	last_result = {}


func player_count() -> int:
	return 2
