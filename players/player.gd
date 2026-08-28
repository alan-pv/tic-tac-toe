class_name Player
extends Node

## Common contract for anyone who can take a turn.
##
##     game.gd asks:   request_pick(state)
##     the player answers: picked(index)
##
## That is the whole conversation. game.gd never finds out whether it is talking
## to a person or to the machine, which is why there is not one `if is_bot:`
## anywhere in this project.


signal picked(index: int)

var player_index: int = 0

var display_name: String = "Player"

## The Mark.Value this player drops on the board.
var mark: int = Mark.Value.NONE

var is_human: bool = true


func setup(p_index: int, p_name: String, p_mark: int, _config: GameConfig) -> void:
	player_index = p_index
	display_name = p_name
	mark = p_mark


## Asked once per turn. Answer with the `picked` signal whenever you are ready,
## this frame or ten frames later.
func request_pick(_state: GameState) -> void:
	push_error("%s does not implement request_pick()" % get_class())


## The turn was abandoned: the match was restarted, or the scene is going away.
## Whatever you were waiting for, stop waiting, and do NOT emit picked.
func cancel_pick() -> void:
	pass
