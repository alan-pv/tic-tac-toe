class_name MoveResult
extends RefCounted

## What happened when a mark was played. Returned by GameState.play().


## Where the mark landed. -1 means the move was rejected.
var index: int = -1

## Which mark was played (a Mark.Value).
var mark: int = Mark.Value.NONE

## In infinite mode, the cell emptied to make room. -1 if nothing left.
var vanished_index: int = -1

## The three cells that won the round, or empty if the move won nothing.
var line: PackedInt32Array = PackedInt32Array()

## True when the move filled the board with nobody winning.
var is_draw: bool = false


func is_valid() -> bool:
	return index >= 0


func is_win() -> bool:
	return not line.is_empty()


## True when this move ended the round, whichever way.
func ends_round() -> bool:
	return is_win() or is_draw


func _to_string() -> String:
	return "MoveResult(%s at %d, vanished %d, win %s, draw %s)" % [
		Mark.to_debug_char(mark), index, vanished_index, is_win(), is_draw
	]
